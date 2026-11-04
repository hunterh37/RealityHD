import simd
import Foundation

/// PieWhole: everyday pantry, baked. Real-size 0.24 x 0.05 x 0.24 m.
public struct PieWhole: RealAsset {
    public static let id = "pie-whole"
    public static let summary = "PieWhole, 0.24 x 0.05 x 0.24 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "baked"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.bread-crust"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let tin = FoodMesh.revolve(edge: 0.03, seamTile: 0.1, material: accent, curve: FoodMesh.profile([V2(0, 0), V2(0.083, 0), V2(0.092, 0.001), V2(0.113, 0.031), V2(0.12, 0.032), V2(0.12, 0.034), V2(0.112, 0.034), V2(0.06, 0.030), V2(0, 0.030)], per: 2))
        m.add(tin)
        var filling = FoodMesh.revolve(edge: 0.03, seamTile: 0.08, material: "food.tomato-sauce-reduced:6A1530", curve: FoodMesh.profile([V2(0, 0.03), V2(0.1, 0.03), V2(0.105, 0.036), V2(0.06, 0.04), V2(0, 0.041)], per: 4))
        filling.displace { p, n in 0.0012 * sin(p.x * 120) * sin(p.z * 110) }
        m.add(filling)
        for dirX in [true, false] {
            for k in -3...3 {
                let off = Float(k) * 0.03 + 0.005
                let half = sqrt(max(0.0001, 0.114 * 0.114 - off * off))
                let y: Float = ((k + (dirX ? 0 : 1)) % 2 == 0) ? 0.0425 : 0.0465
                let size = dirX ? V3(2 * half, 0.0065, 0.013) : V3(0.013, 0.0065, 2 * half)
                let at = dirX ? V3(0, y, off) : V3(off, y, 0)
                m.add(Prim.roundedBox(size, radius: 0.0025, bevelSegments: 2, material: skin), Xform(translation: at))
            }
        }
        for k in 0..<40 {
            let a = Float(k) / 40 * 2 * .pi
            m.add(Prim.superellipsoid(V3(0.014, 0.011, 0.008), exponent: 2, subdivisions: 3, material: skin), Xform(translation: V3(cos(a) * 0.114, 0.0385, sin(a) * 0.114), rotation: simd_quatf(degrees: -a * 180 / .pi + 90 + 25, axis: V3(0, 1, 0))))
        }
        m.add(Prim.roundedBox(V3(0.012, 0.004, 0.012), radius: 0.001, bevelSegments: 1, material: skin), Xform(translation: V3(0, 0.0495, 0)))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
