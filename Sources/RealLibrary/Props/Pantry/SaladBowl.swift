import simd
import Foundation

/// SaladBowl: everyday pantry, pantry. Real-size 0.24 x 0.09 x 0.24 m.
public struct SaladBowl: RealAsset {
    public static let id = "salad-bowl"
    public static let summary = "SaladBowl, 0.24 x 0.09 x 0.24 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "ceramic.stoneware:EFEAE0"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.basil:7DB04A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
func bowl(_ pts: [V2], _ mat: MaterialKey) -> Surface {
            FoodMesh.revolve(edge: 0.014, seamTile: 0.08, material: mat, curve: FoodMesh.profile(pts, per: 4))
        }
        m.add(bowl([V2(0, 0), V2(0.05, 0), V2(0.058, 0.008), V2(0.1, 0.04), V2(0.12, 0.078), V2(0.12, 0.08), V2(0.115, 0.08), V2(0.096, 0.044), V2(0.052, 0.016), V2(0, 0.013)], skin))
        for _ in 0..<30 {
            let c = rng.inDisc(radius: 0.095)
            let r = simd_length(c)
            let y = 0.04 + 0.044 * (1 - (r / 0.1) * (r / 0.1)) + rng.float(-0.006...0.006)
            var leaf = Prim.superellipsoid(V3(0.05, 0.003, 0.034), exponent: 2.4, subdivisions: 4, material: accent)
            let ph = rng.float(0...6.28)
            leaf.deform { p in V3(p.x, p.y + 0.004 * sin(p.x * 120 + ph) + 3 * p.z * p.z, p.z) }
            let q = simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0)) * simd_quatf(degrees: rng.float(-30...30), axis: V3(1, 0, 0))
            m.add(leaf, Xform(translation: V3(c.x, y, c.y), rotation: q))
        }
        for _ in 0..<7 {
            let c = rng.inDisc(radius: 0.08)
            m.add(Prim.superellipsoid(V3(0.032, 0.02, 0.032), exponent: 2.2, subdivisions: 4, material: "food.tomato"), Xform(translation: V3(c.x, 0.074 + rng.float(-0.01...0.006), c.y)))
        }
        for _ in 0..<8 {
            let c = rng.inDisc(radius: 0.085)
            m.add(Prim.cylinder(radius: 0.015, height: 0.003, bevel: 0.0008, segments: 12, material: "food.pepper-flesh:C9DDA8"), Xform(translation: V3(c.x, 0.07 + rng.float(-0.008...0.01), c.y), rotation: simd_quatf(degrees: rng.float(-35...35), axis: V3(1, 0, 0))))
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
