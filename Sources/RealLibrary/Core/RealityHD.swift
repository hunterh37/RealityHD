import RealMaterials
import Foundation
import RealityKit
import RealKit

/// One-call entry points. Geometry is generated off the main actor (all generators are pure and
/// Sendable); GPU upload, texture synthesis and ShaderGraph compilation happen on the main actor.
public enum RealityHD {
    /// Register systems/components and apply a performance tier. Call once at app start.
    /// `adaptive` overrides the tier's governor switch.
    @MainActor
    public static func setup(_ tier: RealPerformance.Tier = .balanced, adaptive: Bool? = nil) {
        var s = RealPerformance(tier)
        if let adaptive { s.adaptive = adaptive }
        setup(s)
    }

    /// Register systems/components and apply explicit settings.
    @MainActor
    public static func setup(_ settings: RealPerformance) {
        RealKitSetup.register()
        RealPerformance.current = settings
        Task { await TextureSynth.warmUp() }
    }

    /// Await before the first `environment`, `entity` or `scene` call on the main thread (for example
    /// before `openImmersiveSpace`). Compiles texture-synthesis shaders off the main thread.
    public static func prepare() async {
        await TextureSynth.warmUp()
    }

    /// Register systems/components and restore settings saved with `RealPerformance.save()`
    /// (or `fallback` on first launch). Returns the applied settings.
    @MainActor @discardableResult
    public static func setup(restoring key: String = RealPerformance.defaultsKey, fallback: RealPerformance.Tier = .balanced,
                             defaults: UserDefaults = .standard) -> RealPerformance {
        let s = RealPerformance.load(from: defaults, key: key) ?? RealPerformance(fallback)
        setup(s)
        return s
    }

    /// Texture-only presets (RealityHD 4 API).
    @MainActor
    public static func setup(quality: RealQuality.Preset) {
        RealQuality.apply(quality)
        RealKitSetup.register()
        Task { await TextureSynth.warmUp() }
    }

    /// The active performance settings. Assigning applies live settings at once; build-time settings
    /// reach entities built afterwards (`RealPerformance.needsRebuild(from:)`).
    @MainActor
    public static var performance: RealPerformance {
        get { RealPerformance.current }
        set { RealPerformance.current = newValue }
    }

    /// Live frame and scene statistics (fps, triangles, draws, shadow casters, adaptive scale).
    @MainActor public static var stats: RealStats { RealStats.shared }

    /// Outdoor lighting rig. Add `env.root` to the scene and call `env.illuminate(content)`.
    @MainActor
    public static func environment(_ sky: SunSky = SunSky(), skybox: Bool = false) throws -> RealEnvironment {
        try RealEnvironment(sky, skybox: skybox)
    }

    /// Any catalog asset as an entity with LOD children (ShaderGraph wind/fog materials).
    /// `grabbable` (default: assets tagged `handheld`) adds hand pick-up on visionOS.
    public static func entity(_ id: String, seed: UInt64 = 1, grabbable: Bool? = nil) async throws -> Entity {
        guard let t = Catalog.type(id) else { throw RealityHDError.unknown(id) }
        let lod = await Task.detached(priority: .userInitiated) { RealPrebake.model(id: id, seed: seed) { t.init().build(seed: seed) } }.value
        let e = try await upload(lod, name: id)
        if grabbable ?? t.handheld { await MainActor.run { let b = lod.levels[0].bounds; e.makeGrabbable(min: b.min, max: b.max) } }
        return e
    }

    /// Any RealAsset value (custom parameters) as an entity.
    public static func entity<A: RealAsset>(_ asset: A, seed: UInt64 = 1) async throws -> Entity {
        let lod = await Task.detached(priority: .userInitiated) { asset.build(seed: seed) }.value
        return try await upload(lod, name: A.id)
    }

    /// An articulated asset as a live entity: parts move with `entity.setArticulation("open")`,
    /// `nextArticulation()` or, with `interactive`, `realToggle()` from a tap gesture.
    /// `grabbable` (default: assets tagged `handheld`) lets a hand pick the whole object up while taps on
    /// parts still toggle them.
    public static func articulated(_ id: String, seed: UInt64 = 1, state: String? = nil, interactive: Bool = true,
                                   grabbable: Bool? = nil) async throws -> Entity {
        guard let t = Catalog.type(id) as? any RealArticulated.Type else { throw RealityHDError.unknown(id) }
        let rig = await Task.detached(priority: .userInitiated) { t.init().rig(seed: seed) }.value
        return try await rig.entityAsync(name: id, state: state, interactive: interactive, grabbable: grabbable ?? t.handheld)
    }

    /// Lighting rig for a scene: its sky, fog and interior probe hints, with `sky` overriding the hint's sun.
    @MainActor
    public static func environment(for scene: RealScene, sky: SunSky? = nil, skybox: Bool = true) throws -> RealEnvironment {
        var s = sky ?? scene.lighting.sky ?? SunSky()
        if let fog = scene.lighting.fog { s.fogDensity = fog }
        if let k = scene.lighting.sunScale { s.sunLux *= k }
        return try RealEnvironment(s, skybox: skybox, interior: scene.lighting.interior)
    }

    /// A composed scene by id (see SceneCatalog.ids).
    public static func scene(_ id: String, seed: UInt64 = 1) async throws -> Entity {
        if let s = RealPrebake.takePreloaded(id, seed) { return try await s.entity() }
        guard let s = await Task.detached(priority: .userInitiated, operation: { SceneCatalog.build(id, seed: seed) }).value else {
            throw RealityHDError.unknown(id)
        }
        return try await s.entity()
    }

    /// Registers the prebaked folder in the app bundle (`realityhd prebake` output copied as `RealityHDPrebaked`):
    /// asset geometry, scene AO and textures load from files instead of being generated. Call after `setup`.
    /// Returns what was baked, or nil when the bundle holds none (generation runs as before).
    @discardableResult
    public static func usePrebaked(bundle: Bundle = .main) -> RealPrebake.Manifest? { RealPrebake.register(bundle: bundle) }

    /// Progress of `preload`: `fraction` in 0...1 and the item in flight.
    public struct PreloadProgress: Sendable { public var fraction: Double; public var item: String }

    /// Builds everything a screen will need before it appears: asset and scene geometry on background
    /// threads, then textures and ShaderGraph materials on the GPU. A following `entity`/`scene` call for the
    /// same id and seed reuses the work. Run it behind a loading screen, or at launch while the user is in
    /// a menu. Cheap when files were prebaked (see `usePrebaked`).
    @MainActor
    public static func preload(assets: [String] = [], scenes: [String] = [], seed: UInt64 = 1,
                               progress: (@MainActor (PreloadProgress) -> Void)? = nil) async {
        var keys = Set<MaterialKey>()
        var done = 0.0
        var total = Double(assets.count + scenes.count)
        func tick(_ item: String) { done += 1; progress?(PreloadProgress(fraction: min(1, done / max(total, 1)), item: item)) }
        // Geometry: every item in parallel, off the main actor.
        await withTaskGroup(of: (String, Set<MaterialKey>).self) { group in
            for id in assets {
                group.addTask(priority: .userInitiated) {
                    guard let t = Catalog.type(id) else { return (id, []) }
                    let lod = RealPrebake.model(id: id, seed: seed) { t.init().build(seed: seed) }
                    return (id, Set(lod.levels.flatMap(\.materials)))
                }
            }
            for id in scenes {
                group.addTask(priority: .userInitiated) {
                    guard let s = SceneCatalog.build(id, seed: seed) else { return (id, []) }
                    RealPrebake.keepPreloaded(s, id, seed)
                    return (id, s.materialKeys)
                }
            }
            for await (id, k) in group { keys.formUnion(k); tick(id) }
        }
        // GPU: textures (disk or synthesis) and shader variants, one material at a time.
        total += Double(keys.count)
        let cache = RealMaterialCache.shared
        for k in keys.sorted() { await cache.warm([k]); tick(k) }
        progress?(PreloadProgress(fraction: 1, item: ""))
    }

    /// GPU-instanced field of one asset at the given transforms (forests, grass, rocks).
    public static func field<A: RealAsset>(_ asset: A, seed: UInt64 = 1, transforms: [simd_float4x4],
                                           options: RealInstancing.Options = RealInstancing.Options()) async throws -> Entity {
        let lod = await Task.detached(priority: .userInitiated) { asset.build(seed: seed) }.value
        return try await RealInstancing.field(lod, transforms: transforms, name: A.id, options: options)
    }

    @MainActor
    static func upload(_ lod: LODModel, name: String) async throws -> Entity {
        guard lod.levels.count == 1 else { return try await lod.entityAsync(name: name) }
        let e = try await lod.levels[0].modelEntityAsync()
        e.realTagCost(RealRenderCostComponent(triangles: lod.levels[0].triangleCount, drawCalls: lod.levels[0].surfaces.filter { !$0.isEmpty }.count,
                                              size: simd_length(lod.levels[0].bounds.max - lod.levels[0].bounds.min), lod: 0))
        return e
    }

    public enum RealityHDError: Error { case unknown(String) }
}
