import simd
import Foundation

/// Allotment fallow weedy plot: an uncultivated season's growth on crusted soil, couch grass, dandelion
/// rosettes, a broad-leaved dock with a rusty seed spike and a stand of stinging nettles.
public struct AllotmentFallowWeedyPlot: RealAsset {
    public static let id = "allotment-fallow-weedy-plot"
    public static let summary = "Fallow allotment plot tile: crusted lumpy soil overgrown with couch grass, dandelion rosettes, dock with a seed spike and nettles."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "grass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Couch grass material.
    public var grass: MaterialKey = "grass.lawn"
    /// Broad weed leaf material.
    public var weedLeaf: MaterialKey = "plant.stem:4A6E30"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.03
        var m = Model(name: Self.id)
        func ground(_ p: V2) -> Float {
            base + 0.03 * Noise.fbm(V3(p.x * 2.5, 0, p.y * 2.5), octaves: 4, seed: sd) + 0.006 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 2, seed: sd + 1)
        }
        AKK.field(&m, w: w, d: d, base: base, segments: 44, material: "ground.dirt:5A4532", ground)
        // Couch grass tufts, denser toward one corner.
        for i in 0..<45 {
            var r = rng.fork(i)
            var p = V2(r.float(-0.78...0.78), r.float(-0.78...0.78))
            if r.chance(0.4) { p = p * 0.5 + V2(0.45, -0.4) }
            AKK.weed(&m, at: V3(p.x, ground(p) - 0.004, p.y), height: r.float(0.12...0.28), count: r.int(10...16), rng: &r, material: grass)
        }
        // Dandelion rosettes.
        for i in 0..<14 {
            var r = rng.fork(100 + i)
            let p = V2(r.float(-0.75...0.75), r.float(-0.75...0.75))
            let b = V3(p.x, ground(p) - 0.002, p.y)
            for k in 0..<9 {
                m.add(AKK.leaf(b, yaw: Float(k) * 0.7 + r.float(-0.2...0.2), length: r.float(0.13...0.2), width: 0.045, lean: r.float(0.85...1.0),
                               curl: 0.1, fold: 0.2, material: "plant.stem:4F7A33"))
            }
            if r.chance(0.5) {
                let top = b + V3(0.01, 0.12, 0)
                m.add(Prim.tube([b, top], radii: [0.0022, 0.0018], sides: 5, seamTile: 0.02, material: "plant.stem:7A8A44"))
                m.add(Prim.superellipsoid(V3(0.018, 0.012, 0.018), exponent: 2.4, subdivisions: 2, material: "plastic.matte:E2B21C") { dd in
                    1 + 0.08 * sin(dd.x * 25) * sin(dd.z * 25) }, Xform(translation: top))
            }
        }
        // Docks: broad leaves and a rusty seed spike.
        for (n, c) in [V2(-0.5, 0.4), V2(0.5, 0.5)].enumerated() {
            var r = rng.fork(200 + n)
            let b = V3(c.x, ground(c) - 0.003, c.y)
            for k in 0..<8 {
                m.add(AKK.leaf(b, yaw: Float(k) * 0.8, length: r.float(0.22...0.3), width: 0.1, lean: r.float(0.45...0.75), curl: 0.35, fold: 0.25,
                               segments: 6, material: weedLeaf))
            }
            if n == 0 {
                let top = b + V3(0.02, 0.31, 0.01)
                m.add(Prim.tube([b, (b + top) * 0.5 + V3(0.005, 0, 0), top], radii: [0.005, 0.004, 0.002], sides: 6, seamTile: 0.03, material: "plant.stem:6B3F22"))
                for k in 0..<18 {
                    let t = 0.45 + Float(k) / 18 * 0.55
                    let q = b + (top - b) * t
                    let a = Float(k) * 2.4
                    m.add(Prim.superellipsoid(V3(0.009, 0.014, 0.009), exponent: 2, subdivisions: 1, material: "plant.stem:7A3A1E"),
                          Xform(translation: q + V3(cos(a) * 0.012, 0, sin(a) * 0.012)))
                }
            }
        }
        // Nettle stand: upright square stems with opposite serrated leaves.
        for i in 0..<7 {
            var r = rng.fork(300 + i)
            let c = V2(-0.45 + r.float(-0.15...0.15), -0.45 + r.float(-0.15...0.15))
            let b = V3(c.x, ground(c) - 0.003, c.y)
            let h = r.float(0.24...0.31)
            let top = b + V3(r.float(-0.03...0.03), h, r.float(-0.03...0.03))
            m.add(Prim.tube([b, (b + top) * 0.5, top], radii: [0.0035, 0.003, 0.0018], sides: 4, seamTile: 0.03, material: "plant.stem:4E6A2E"))
            for k in 0..<5 {
                let t = 0.25 + Float(k) * 0.17
                let q = b + (top - b) * t
                let a = Float(k) * 1.5708 + r.float(0...0.3)
                for s: Float in [-1, 1] {
                    m.add(AKK.leaflet(q, dir: V3(cos(a) * s, -0.15, sin(a) * s), length: 0.07 * (1.1 - t * 0.5), width: 0.04 * (1.1 - t * 0.5),
                                      cup: 0.15, material: "plant.stem:3A5A26"))
                }
            }
        }
        // Clods, stones and old dead stems lying down.
        for i in 0..<20 {
            var r = rng.fork(500 + i)
            let p = V2(r.float(-0.85...0.85), r.float(-0.85...0.85))
            if r.chance(0.5) { AKK.stone(&m, at: p, y: ground(p) - 0.004, size: r.float(0.015...0.04), rng: &r) }
            else { AKK.clod(&m, at: p, y: ground(p) - 0.004, size: r.float(0.03...0.06), rng: &r, material: AKK.dryClod) }
        }
        for i in 0..<6 {
            var r = rng.fork(700 + i)
            let p = V2(r.float(-0.7...0.7), r.float(-0.7...0.7)), a = r.float(0...6.28)
            let e = p + V2(cos(a), sin(a)) * r.float(0.2...0.35)
            m.add(Prim.tube([V3(p.x, ground(p) + 0.003, p.y), V3(e.x, ground(e) + 0.004, e.y)], radii: [0.003, 0.002], sides: 5, seamTile: 0.03,
                            material: "straw.hay:8A7A55"))
        }
        var lite = Model(name: Self.id + "-lite")
        AKK.field(&lite, w: w, d: d, base: base, segments: 12, material: "ground.dirt:5A4532", ground)
        return AKK.finish(&m, lite: lite, ao: 0.08)
    }
}
