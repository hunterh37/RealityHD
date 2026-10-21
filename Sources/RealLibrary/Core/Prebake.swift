import Foundation
import CryptoKit
import RealCore
import RealMaterials
import RealKit

/// Prebaked and cached generation results. Three layers skip work at load time:
/// - asset geometry (`.rfasset`): generation, LOD simplification and AO for one `id` + `seed`
/// - scene AO (`.rfao`): the ray-cast occlusion of a scene's baked statics
/// - textures: `RealTextureDiskCache` files shipped in the bundle (see `register(bundle:)`)
///
/// `realityhd prebake` writes the files into a folder that an app adds to its bundle. At launch the app
/// calls `RealityHD.usePrebaked()`; every lookup then reads the bundle first, then the runtime cache.
/// Missing or unreadable files fall back to generation, so prebaking is optional per asset.
public enum RealPrebake {
    public static let folderName = "RealityHDPrebaked"

    /// Master switch. REALITYHD_NO_PREBAKE=1 or REALITYHD_NO_DISK_CACHE=1 turns every layer off.
    nonisolated(unsafe) public static var isEnabled = ProcessInfo.processInfo.environment["REALITYHD_NO_PREBAKE"] == nil
        && ProcessInfo.processInfo.environment["REALITYHD_NO_DISK_CACHE"] == nil

    /// Read-only folders holding `assets/` and `ao/` (searched in order).
    nonisolated(unsafe) public static var directories: [URL] = []

    /// Write results of generation to the runtime cache so the next launch skips them. On by default in
    /// Release; off in Debug so edits to asset code show up.
    nonisolated(unsafe) public static var writeThrough: Bool = {
        #if DEBUG
        false
        #else
        true
        #endif
    }()

    /// Runtime cache folder, versioned by the app's build so an update starts clean.
    nonisolated(unsafe) public static var cacheDirectory: URL = {
        let info = Bundle.main.infoDictionary
        let build = "\(info?["CFBundleShortVersionString"] ?? "0")-\(info?["CFBundleVersion"] ?? "0")"
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RealityHD/prebake-\(build)", isDirectory: true)
    }()

    static let writer = DispatchQueue(label: "realityhd.prebake", qos: .utility)

    // MARK: registration

    /// Adds `<bundle>/RealityHDPrebaked` to the lookup path for assets, scene AO and textures.
    /// Textures are skipped when the folder was baked against a different Metal source. Returns the
    /// manifest, or nil when the bundle has no prebaked folder.
    @discardableResult
    public static func register(bundle: Bundle = .main, folder: String = folderName) -> Manifest? {
        guard let root = bundle.resourceURL?.appendingPathComponent(folder, isDirectory: true) else { return nil }
        return register(directory: root)
    }

    @discardableResult
    public static func register(directory root: URL) -> Manifest? {
        guard let data = try? Data(contentsOf: root.appendingPathComponent("manifest.json")),
              let m = try? JSONDecoder().decode(Manifest.self, from: data) else { return nil }
        if !directories.contains(root) { directories.append(root) }
        if m.metalFingerprint == TextureSynth.sourceFingerprint {
            let t = root.appendingPathComponent("textures", isDirectory: true)
            if !RealTextureDiskCache.bundledDirectories.contains(t) { RealTextureDiskCache.bundledDirectories.append(t) }
        }
        return m
    }

    /// What a prebake run wrote.
    public struct Manifest: Codable, Sendable {
        public var formatVersion: UInt32
        public var metalFingerprint: String
        public var tier: String
        public var assets: [String]
        public var scenes: [String]
        public var textureFiles: Int
        public var bytes: Int
        public var seconds: Double
        public init(formatVersion: UInt32 = LODModelCodec.version, metalFingerprint: String = TextureSynth.sourceFingerprint, tier: String = "balanced",
                    assets: [String] = [], scenes: [String] = [], textureFiles: Int = 0, bytes: Int = 0, seconds: Double = 0) {
            self.formatVersion = formatVersion; self.metalFingerprint = metalFingerprint; self.tier = tier
            self.assets = assets; self.scenes = scenes; self.textureFiles = textureFiles; self.bytes = bytes; self.seconds = seconds
        }
    }

    // MARK: asset geometry

    public static func assetFile(id: String, seed: UInt64) -> String { "\(id)-\(seed).rfasset" }

    /// The prebaked model for `id` + `seed`, if a file exists and decodes.
    public static func load(id: String, seed: UInt64) -> LODModel? {
        guard isEnabled, let url = find("assets/" + assetFile(id: id, seed: seed)),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        return LODModelCodec.decode(data)
    }

    /// Prebaked model, else `build()`; the result is written to the runtime cache when `writeThrough` is on.
    public static func model(id: String, seed: UInt64, build: () -> LODModel) -> LODModel {
        if let m = load(id: id, seed: seed) { return m }
        let m = build()
        if isEnabled && writeThrough { store(m, id: id, seed: seed, in: cacheDirectory) }
        return m
    }

    public static func store(_ m: LODModel, id: String, seed: UInt64, in dir: URL) {
        let data = LODModelCodec.encode(m)
        let url = dir.appendingPathComponent("assets/" + assetFile(id: id, seed: seed))
        writer.async {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: scene AO

    /// Cached occlusion arrays for a scene's baked receivers: [receiver][surface] -> per-vertex AO.
    static func loadAO(key: String) -> [[[Float]]]? {
        guard isEnabled, let url = find("ao/\(key).rfao"), let d = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        var o = 0
        func u32() -> Int? {
            guard o + 4 <= d.count else { return nil }
            let v = d.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: o, as: UInt32.self) }
            o += 4; return Int(v)
        }
        guard let rc = u32() else { return nil }
        var out: [[[Float]]] = []
        for _ in 0..<rc {
            guard let sc = u32() else { return nil }
            var surfaces: [[Float]] = []
            for _ in 0..<sc {
                guard let n = u32(), o + n * 4 <= d.count else { return nil }
                let a = [Float](unsafeUninitializedCapacity: n) { buf, c in
                    if n > 0 { d.withUnsafeBytes { memcpy(buf.baseAddress!, $0.baseAddress! + o, n * 4) } }
                    c = n
                }
                o += n * 4
                surfaces.append(a)
            }
            out.append(surfaces)
        }
        return out
    }

    static func storeAO(_ ao: [[[Float]]], key: String, in dir: URL) {
        var d = Data()
        func u32(_ v: Int) { var x = UInt32(v); d.append(Data(bytes: &x, count: 4)) }
        u32(ao.count)
        for r in ao { u32(r.count); for s in r { u32(s.count); s.withUnsafeBytes { d.append(contentsOf: $0) } } }
        let url = dir.appendingPathComponent("ao/\(key).rfao")
        writer.async {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? d.write(to: url, options: .atomic)
        }
    }

    /// Hash of everything the AO bake reads: scene name, settings, receiver and occluder geometry.
    static func aoKey(scene: String, settings: AOBake.Settings, receivers: [Model], occluders: [Model]) -> String {
        var h = SHA256()
        func feed(_ s: String) { h.update(data: Data(s.utf8)) }
        feed("v\(LODModelCodec.version)|\(scene)|\(settings)")
        for m in receivers + occluders {
            feed("|\(m.vertexCount)|\(m.triangleCount)")
            for s in m.surfaces {
                // Sparse position sample: cheap, and any geometry edit moves some vertex it hits.
                let step = max(1, s.positions.count / 64)
                for i in stride(from: 0, to: s.positions.count, by: step) { feed("\(s.positions[i])") }
            }
        }
        return h.finalize().prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: lookup

    static func find(_ relative: String) -> URL? {
        for dir in directories + [cacheDirectory] {
            let u = dir.appendingPathComponent(relative)
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }
        return nil
    }

    /// Deletes the runtime cache.
    public static func clear() { try? FileManager.default.removeItem(at: cacheDirectory) }

    /// Waits for pending cache writes (CLI commands that exit right after building).
    public static func flush() { writer.sync {} }

    // MARK: scene memo

    /// Scenes built by `RealityHD.preload`, handed to the next `RealityHD.scene(id)` for the same id and seed.
    nonisolated(unsafe) static var preloadedScenes: [String: RealScene] = [:]
    static let preloadLock = NSLock()
    static func sceneKey(_ id: String, _ seed: UInt64) -> String { "\(id)#\(seed)" }
    static func takePreloaded(_ id: String, _ seed: UInt64) -> RealScene? {
        preloadLock.lock(); defer { preloadLock.unlock() }
        return preloadedScenes.removeValue(forKey: sceneKey(id, seed))
    }
    static func keepPreloaded(_ s: RealScene, _ id: String, _ seed: UInt64) {
        preloadLock.lock(); defer { preloadLock.unlock() }
        preloadedScenes[sceneKey(id, seed)] = s
    }
    /// Drops scenes built by `preload` and never used.
    public static func releasePreloaded() {
        preloadLock.lock(); defer { preloadLock.unlock() }
        preloadedScenes.removeAll()
    }
}

public extension RealScene {
    /// Every material key the scene draws, for texture and shader warm-up.
    var materialKeys: Set<MaterialKey> {
        var keys = Set<MaterialKey>()
        for lod in fields.map(\.asset) + singles.map(\.asset) { for m in lod.levels { keys.formUnion(m.materials) } }
        for r in rigs { for m in r.rig.posed(r.state).levels { keys.formUnion(m.materials) } }
        if let farGround { keys.insert(farGround) }
        return keys
    }
}
