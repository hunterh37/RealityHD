import simd
import Foundation

/// Allotment compost bay floor: a part-rotted heap spread over a bay floor, dark crumbly compost
/// with straw, prunings, eggshell, peelings and wilted cabbage leaves on the fresh top layer.
public struct AllotmentCompostBayFloor: RealAsset {
    public static let id = "allotment-compost-bay-floor"
    public static let summary = "Allotment compost bay floor tile: a low heap of dark crumbly compost with straw, twiggy prunings, eggshells, peelings and wilted cabbage leaves."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Heap crown height (m).
    public var heapHeight: Float = 0.15
    /// Compost material.
    public var compost: MaterialKey = "soil.potting:2E2117"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.025
        var m = Model(name: Self.id)
        func heap(_ p: V2) -> Float {
            let q = V2(p.x * 0.95, p.y + 0.12)
            let r = simd_length(q) / 0.82
            let dome = r < 1 ? pow(cos(r * .pi / 2), 1.4) : 0
            let lumps = 0.035 * Noise.fbm(V3(p.x * 7, 0, p.y * 7), octaves: 4, seed: sd)
            return base + heapHeight * dome + lumps * (0.4 + dome)
        }
        AKK.field(&m, w: w, d: d, base: base, segments: 56, material: compost, heap)
        // Crumbs and lumps.
        for i in 0..<120 {
            var r = rng.fork(i)
            let p = V2(r.float(-0.85...0.85), r.float(-0.85...0.85))
            AKK.clod(&m, at: p, y: heap(p) - 0.006, size: r.float(0.025...0.05), rng: &r, material: compost, sub: 1)
        }
        // Straw strands.
        for i in 0..<140 {
            var r = rng.fork(200 + i)
            let p = V2(r.float(-0.75...0.75), r.float(-0.8...0.6))
            let a = r.float(0...6.28), l = r.float(0.08...0.2)
            let p0 = V3(p.x, heap(p) + 0.002, p.y)
            let e = p + V2(cos(a), sin(a)) * l
            let p1 = V3(e.x, heap(e) + 0.004, e.y)
            m.add(Prim.tube([p0, (p0 + p1) * 0.5 + V3(0, 0.006, 0), p1], radii: [0.0024, 0.0024, 0.0018], sides: 4, seamTile: 0.02,
                            material: r.chance(0.5) ? "straw.hay" : "straw.hay:8A7444"))
        }
        // Twiggy prunings.
        for i in 0..<9 {
            var r = rng.fork(400 + i)
            let p = V2(r.float(-0.6...0.6), r.float(-0.7...0.5))
            let a = r.float(0...6.28), l = r.float(0.18...0.35)
            let e = p + V2(cos(a), sin(a)) * l
            let p0 = V3(p.x, heap(p) + 0.004, p.y), p1 = V3(e.x, heap(e) + 0.006, e.y)
            m.add(Prim.tube([p0, (p0 + p1) * 0.5 + V3(0, 0.01, 0), p1], radii: [0.006, 0.0045, 0.0025], sides: 6, seamTile: 0.04, material: "bark.oak-dry"))
        }
        // Eggshell halves and peelings.
        for i in 0..<10 {
            var r = rng.fork(600 + i)
            let p = V2(r.float(-0.45...0.45), r.float(-0.5...0.3))
            let s = r.float(0.024...0.032)
            m.add(Prim.superellipsoid(V3(s, s * 0.6, s * 1.25), exponent: 2, subdivisions: 2, material: r.chance(0.5) ? "plastic.matte:EDE4D2" : "plastic.matte:C99A6B"),
                  Xform(translation: V3(p.x, heap(p) + 0.002, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        for i in 0..<12 {
            var r = rng.fork(700 + i)
            let p = V2(r.float(-0.55...0.55), r.float(-0.6...0.35))
            let a = r.float(0...6.28)
            m.add(AKK.leaflet(V3(p.x, heap(p) + 0.003, p.y), dir: V3(cos(a), 0.05, sin(a)), length: r.float(0.05...0.09), width: 0.025, cup: 0.5,
                              material: r.chance(0.5) ? "plant.stem:9A8A3A" : "plant.stem:B49A5A"))
        }
        // Wilted cabbage and lettuce leaves.
        for i in 0..<12 {
            var r = rng.fork(800 + i)
            let p = V2(r.float(-0.4...0.4), r.float(-0.45...0.25))
            m.add(AKK.leaf(V3(p.x, heap(p) + 0.008, p.y), yaw: r.float(0...6.28), length: r.float(0.18...0.26), width: 0.17, lean: 1.0,
                           curl: 0.05, fold: -0.15, material: r.chance(0.5) ? "plant.stem:8FA352" : "plant.stem:B5B060"))
        }
        // Brandling worm on the surface.
        var wr = rng.fork(900)
        let wp = V2(0.35, 0.35)
        let wy = heap(wp) + 0.003
        let worm = (0...6).map { k -> V3 in let t = Float(k) / 6; return V3(wp.x + t * 0.06, wy, wp.y + 0.008 * sin(t * 7 + wr.float(0...1))) }
        m.add(Prim.tube(worm, radii: [0.0015, 0.0022, 0.0024, 0.0024, 0.0022, 0.002, 0.0012], sides: 6, seamTile: 0.02, material: "plastic.matte:8A3B2E"))
        var lite = Model(name: Self.id + "-lite")
        AKK.field(&lite, w: w, d: d, base: base, segments: 16, material: compost, heap)
        return AKK.finish(&m, lite: lite, ao: 0.08)
    }
}
