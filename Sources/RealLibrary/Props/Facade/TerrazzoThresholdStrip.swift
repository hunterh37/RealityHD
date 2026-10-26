import simd
import Foundation

/// Mid-century terrazzo threshold: three poured panels divided by brass strips, marble chip aggregate
/// on the polished face, eased nosing, brass screws, one hairline crack. Lies flat, long axis X.
public struct TerrazzoThresholdStrip: RealAsset {
    public static let id = "terrazzo-threshold-strip"
    public static let summary = "Terrazzo threshold strip, 1.2 m: chip aggregate slab with brass divider strips and a worn nosing."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 28, distance: 1.7)

    public var length: Float = 1.2
    public var depth: Float = 0.25
    public var terrazzo: MaterialKey = "stone.terrazzo"
    public var brass: MaterialKey = "metal.brass"
    public var chipMats: [MaterialKey] = ["stone.marble-dark", "stone.marble-honed", "stone.sandstone", "stone.cast-stone"]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, D = depth, T: Float = 0.0265
        let divider: Float = 0.006
        // Three poured panels with a hair of height difference between them.
        let xs: [Float] = [-L / 2, -0.2, 0.2, L / 2]
        for i in 0..<3 {
            let x0 = xs[i] + (i == 0 ? 0 : divider / 2), x1 = xs[i + 1] - (i == 2 ? 0 : divider / 2)
            let t = T + rng.float(-0.0006...0.0006)
            m.add(Prim.roundedBox(V3(x1 - x0, t, D - 2 * divider), radius: 0.0035, bevelSegments: 2, material: terrazzo),
                  Xform(translation: V3((x0 + x1) / 2, t / 2, 0)))
        }
        // Brass dividers: two long strips at the front and back edge, two cross strips between panels.
        for z in [-D / 2 + divider / 2, D / 2 - divider / 2] as [Float] {
            FA.box(&m, V3(L, 0.0292, divider), V3(0, 0.0146, z), brass, r: 0.0012)
        }
        for x in [-0.2, 0.2] as [Float] {
            FA.box(&m, V3(divider, 0.0292, D - 2 * divider), V3(x, 0.0146, 0), brass, r: 0.0012)
        }
        // Aggregate: flat, irregular chips, bigger where it is poured, smaller near the edges.
        let panels: [(Float, Float)] = [(-L / 2 + 0.01, -0.21), (-0.19, 0.19), (0.21, L / 2 - 0.01)]
        for (a, b) in panels {
            let area = (b - a) * D
            let n = Int(area * 600)
            for _ in 0..<n {
                let x = rng.float(a...b), z = rng.float(-D / 2 + 0.014...D / 2 - 0.014)
                let r = rng.float(0.0035...0.0095)
                let sides = rng.int(5...7)
                var pts: [V2] = []
                for k in 0..<sides {
                    let ang = Float(k) / Float(sides) * 2 * .pi
                    pts.append(V2(cos(ang), sin(ang)) * (r * rng.float(0.65...1.0)))
                }
                let mat = chipMats[rng.int(0...(chipMats.count - 1))]
                m.add(Prim.extrude(pts, depth: 0.0012, bevel: 0.0004, bevelSegments: 1, material: mat),
                      Xform(translation: V3(x, T + 0.00005, z), rotation: FA.q(90, FA.X) * FA.q(rng.float(0...360), FA.Z)))
            }
        }
        // Countersunk brass screws at the strip ends.
        for z in [-D / 2 + 0.03, D / 2 - 0.03] as [Float] {
            for x in [-L / 2 + 0.04, L / 2 - 0.04, -0.2, 0.2] as [Float] {
                m.add(Prim.cylinder(radius: 0.0045, height: 0.0012, bevel: 0.0004, segments: 10, bevelSegments: 1, material: brass),
                      Xform(translation: V3(x, 0.0286, z)))
            }
        }
        // Hairline crack across the centre panel and a worn, lighter walking path.
        FA.box(&m, V3(0.24, 0.0006, 0.0028), V3(0.02, T + 0.0003, 0.02), "stone.slate", r: 0.0002, rot: FA.q(24, FA.Y))
        FA.box(&m, V3(0.1, 0.0006, 0.0022), V3(-0.43, T + 0.0003, -0.05), "stone.slate", r: 0.0002, rot: FA.q(-61, FA.Y))
        // Anti-slip inlay: three fine brass strips set in the front of each panel.
        for k in 0..<3 {
            FA.box(&m, V3(L - 0.04, 0.0008, 0.0025), V3(0, T + 0.0004, D / 2 - 0.036 - Float(k) * 0.012), brass, r: 0.0003)
        }
        // Cement repair patches at two worn corners: irregular fills a hair below the polished face.
        for (px, pz, pr) in [(Float(-0.55), Float(0.07), Float(0.03)), (Float(0.52), Float(-0.06), Float(0.025))] {
            var pts: [V2] = []
            for k in 0..<7 { let a = Float(k) / 7 * 2 * .pi; pts.append(V2(cos(a), sin(a)) * (pr * rng.float(0.7...1.1))) }
            m.add(Prim.extrude(pts, depth: 0.0016, bevel: 0.0004, bevelSegments: 1, material: "stone.cast-stone"),
                  Xform(translation: V3(px, T + 0.0001, pz), rotation: FA.q(90, FA.X)))
        }
        groundAO(&m, height: 0.02, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
