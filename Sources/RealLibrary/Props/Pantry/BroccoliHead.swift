import simd
import Foundation

/// BroccoliHead: everyday pantry, vegetable. Real-size 0.12 x 0.12 x 0.12 m.
public struct BroccoliHead: RealAsset {
    public static let id = "broccoli-head"
    public static let summary = "BroccoliHead, 0.12 x 0.12 x 0.12 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.broccoli"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.broccoli-stem"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
m.add(FoodMesh.tube([V3(0, 0, 0), V3(0, 0.03, 0), V3(0, 0.055, 0)], radii: [0.016, 0.013, 0.012], sides: 8, seamTile: 0.03, material: accent))
        for b in 0..<8 {
            let ang = Float(b) / 8 * 2 * .pi + rng.float(-0.2...0.2)
            let reach = rng.float(0.026...0.036)
            let top = V3(cos(ang) * reach, 0.088 + rng.float(-0.006...0.012), sin(ang) * reach)
            m.add(FoodMesh.tube([V3(0, 0.05, 0), V3(cos(ang) * reach * 0.5, 0.068, sin(ang) * reach * 0.5), top - V3(0, 0.012, 0)], radii: [0.007, 0.005, 0.0045], sides: 8, seamTile: 0.02, material: accent))
            for f in 0..<4 {
                let o = V3(rng.float(-0.016...0.016), rng.float(-0.006...0.012), rng.float(-0.016...0.016))
                let r = rng.float(0.014...0.019)
                m.add(Prim.superellipsoid(V3(r * 2, r * 1.6, r * 2), exponent: 2, subdivisions: 4, material: skin), Xform(translation: top + o))
            }
        }
        m.add(Prim.superellipsoid(V3(0.06, 0.03, 0.06), exponent: 2, subdivisions: 4, material: skin), Xform(translation: V3(0, 0.098, 0)))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
