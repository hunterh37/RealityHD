import simd
import RealCore
import RealKit

/// What a scene costs from one viewpoint under given settings. Mirrors the runtime: field cells and
/// statics pick their LOD with the same policy as `RealLODSystem`. Without a `view` the counts are
/// pre-frustum; with one, meshes outside both eye frustums drop from the main pass and casters whose
/// shadow cannot reach the view drop from the shadow pass (RealityKit culls per entity, so a field cell
/// counts whole when any of it is in view).
public struct RealSceneCost: Sendable, Equatable {
    /// Triangles of every drawn mesh, instances included.
    public var triangles = 0
    /// Triangles drawn again into the sun shadow map.
    public var shadowTriangles = 0
    public var drawCalls = 0
    public var instances = 0
    /// Mesh entities shown (LOD children, field cells, batches, rig parts).
    public var meshes = 0
    public var lights = 0
    /// Draw calls from live rigs and grabbables (one entity per part, never batched). Included in `drawCalls`.
    public var liveDrawCalls = 0

    /// Rough frame weight: main pass + shadow pass + per-draw overhead (one draw ~ 4k triangles).
    public var weight: Int { triangles + shadowTriangles + drawCalls * 4000 }
}

public extension RealScene {
    /// The headset view volume at the camera hint (or at `viewer` looking along the hint direction).
    func viewVolume(viewer: V3? = nil) -> ViewVolume {
        let eye = viewer ?? camera?.eye ?? V3(0, 1.6, 0)
        let fwd = camera.map { $0.target - $0.eye } ?? V3(0, 0, -1)
        return ViewVolume(eye: eye, forward: simd_length(fwd) > 1e-5 ? fwd : V3(0, 0, -1))
    }

    /// Cost seen from `viewer` (scene space; default: the camera hint) under `settings`. `view` turns on
    /// frustum culling; `sun` (toward the sun) and `shadowReach` shape the shadow pass test.
    func estimate(viewer: V3? = nil, settings perf: RealPerformance = .active, view: ViewVolume? = nil,
                  sun: V3? = nil, shadowReach: Float? = nil) -> RealSceneCost {
        let eye = viewer ?? view?.center ?? camera?.eye ?? V3(0, 1.6, 0)
        let sky = lighting.sky ?? .afternoon
        let toSun = simd_normalize(sun ?? sky.sunDirection)
        // Runtime reach: sun shadow distance scaled by the tier; casters past 1.5x reach plus their size stop.
        let reach = shadowReach ?? (view == nil ? 0 : max(2, sky.shadowDistance * perf.shadowDistanceScale))
        let sinEl = max(0.15, toSun.y)
        var c = RealSceneCost()

        func inView(_ center: V3, _ radius: Float) -> Bool { view?.intersects(center: center, radius: radius) ?? true }
        func shadowInView(_ center: V3, _ radius: Float, height: Float, size: Float) -> Bool {
            if reach > 0, simd_distance(center, eye) > reach * 1.5 + size { return false }
            guard let view else { return true }
            let length = min(80, max(height, radius) / sinEl)
            return view.castsIntoView(center: center, radius: radius, toLight: toSun, shadowLength: length)
        }

        for f in fields {
            let o = f.options
            let all = o.thinnable ? perf.thinned(f.transforms) : f.transforms
            var cells: [SIMD2<Int32>: [simd_float4x4]] = [:]
            for t in all {
                let p = SIMD2(t.columns.3.x, t.columns.3.z) / o.cellSize
                cells[SIMD2<Int32>(Int32(p.x.rounded(.down)), Int32(p.y.rounded(.down))), default: []].append(t)
            }
            let b0 = f.asset.levels[0].bounds
            let size = simd_length(b0.max - b0.min)
            let localCenter = (b0.min + b0.max) / 2
            for (_, list) in cells {
                var center = V3.zero
                for t in list { center += V3(t.columns.3.x, t.columns.3.y, t.columns.3.z) }
                center /= Float(list.count)
                let lodded = f.asset.levels.count > 1 || o.cullDistance > 0
                let level: Int?
                if lodded {
                    level = perf.level(distance: simd_distance(center, eye), switchDistances: f.asset.switchDistances,
                                       cullDistance: o.cullDistance, groundCover: o.thinnable)
                } else { level = 0 }
                guard let li = level else { continue }
                let shown = o.thinnable ? perf.instances(list, level: li, levels: f.asset.levels.count) : list
                guard !shown.isEmpty else { continue }
                // Cell bounds: every instance's bounds sphere.
                var lo = V3(repeating: .infinity), hi = V3(repeating: -.infinity), maxScale: Float = 0
                for t in shown {
                    let s = max(simd_length(SIMD3(t.columns.0.x, t.columns.0.y, t.columns.0.z)), simd_length(SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z)))
                    maxScale = max(maxScale, s)
                    let p4 = t * SIMD4(localCenter, 1)
                    let p = V3(p4.x, p4.y, p4.z)
                    lo = simd_min(lo, p); hi = simd_max(hi, p)
                }
                let cc = (lo + hi) / 2, cr = simd_length(hi - lo) / 2 + size / 2 * maxScale
                let m = f.asset.levels[li]
                let tris = m.triangleCount * shown.count
                let casts = perf.castsShadow(lod: li, size: size, eligible: o.shadowCasterMaxLOD >= 0, lodShift: o.shadowCasterMaxLOD - 1)
                let visible = inView(cc, cr)
                if visible {
                    c.triangles += tris; c.instances += shown.count; c.meshes += 1
                    c.drawCalls += m.surfaces.filter { !$0.isEmpty }.count
                }
                if casts, shadowInView(cc, cr, height: (b0.max.y - b0.min.y) * maxScale, size: size * maxScale) { c.shadowTriangles += tris }
            }
        }

        for s in uploadedStatics(perf) {
            let b = s.asset.levels[0].bounds
            let size = simd_length(b.max - b.min) * s.at.scale.max()
            let center = s.at.point((b.min + b.max) / 2)
            guard let li = perf.level(distance: simd_distance(center, eye), switchDistances: s.asset.switchDistances, size: size) else { continue }
            let m = s.asset.levels[min(li, s.asset.levels.count - 1)]
            let glass = !m.surfaces.isEmpty && m.surfaces.allSatisfy { MaterialLibrary.spec(for: $0.material).mode == .transparent }
            if inView(center, size / 2) {
                c.triangles += m.triangleCount; c.instances += 1; c.meshes += 1
                c.drawCalls += m.surfaces.filter { !$0.isEmpty }.count
            }
            if perf.castsShadow(lod: li, size: size, eligible: !glass && s.castsShadow),
               shadowInView(center, size / 2, height: (b.max.y - b.min.y) * s.at.scale.y, size: size) { c.shadowTriangles += m.triangleCount }
        }

        // Live rigs and grabbables: one entity (and one draw per material) for the base and for every part,
        // as `Rig.entityAsync` builds them. Tris match the posed state.
        for r in rigs {
            let posed = r.rig.posed(r.state)
            let b = posed.levels[0].bounds
            let size = simd_length(b.max - b.min) * r.at.scale.max()
            let center = r.at.point((b.min + b.max) / 2)
            let li = min(perf.level(distance: simd_distance(center, eye), switchDistances: posed.switchDistances, size: .infinity) ?? 0,
                         posed.levels.count - 1)
            let opts = r.rig.options(r.state ?? r.rig.initialState)
            var pieces: [Model] = [r.rig.base[min(li, r.rig.base.count - 1)]]
            for p in r.rig.parts {
                let o = p.option(min(opts[p.name] ?? 0, p.optionCount - 1))
                pieces.append(o[min(li, o.count - 1)])
            }
            pieces = pieces.filter { $0.triangleCount > 0 }
            let tris = pieces.reduce(0) { $0 + $1.triangleCount }
            if inView(center, size / 2) {
                let draws = pieces.reduce(0) { $0 + $1.surfaces.filter { !$0.isEmpty }.count }
                c.triangles += tris; c.instances += pieces.count; c.meshes += pieces.count
                c.drawCalls += draws; c.liveDrawCalls += draws
            }
            if perf.castsShadow(lod: li, size: posed.levels[0].boundsDiagonal),
               shadowInView(center, size / 2, height: (b.max.y - b.min.y) * r.at.scale.y, size: size) { c.shadowTriangles += tris }
        }
        c.lights = min(lights.count, perf.maxSceneLights)
        return c
    }
}
