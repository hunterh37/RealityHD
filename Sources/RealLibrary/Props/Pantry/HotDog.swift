import simd
import Foundation

/// HotDog: everyday pantry, baked. Real-size 0.06 x 0.05 x 0.18 m.
public struct HotDog: RealAsset {
    public static let id = "hot-dog"
    public static let summary = "HotDog, 0.06 x 0.05 x 0.18 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "baked"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.bun-crust"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.beef-seared:B5533A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
m.add(Prim.superellipsoid(V3(0.05, 0.024, 0.158), exponent: 3, subdivisions: 8, material: skin), Xform(translation: V3(0, 0.012, 0)))
        for s: Float in [-1, 1] {
            var half = Prim.superellipsoid(V3(0.028, 0.04, 0.156), exponent: 3, subdivisions: 8, material: skin)
            half.deform { p in V3(p.x + s * 0.001, p.y, p.z) }
            m.add(half, Xform(translation: V3(s * 0.0165, 0.031, 0), rotation: simd_quatf(degrees: -s * 10, axis: V3(0, 0, 1))))
            m.add(Prim.superellipsoid(V3(0.012, 0.024, 0.15), exponent: 2.6, subdivisions: 6, material: "food.bun-crumb"), Xform(translation: V3(s * 0.0085, 0.032, 0)))
        }
        m.add(FoodMesh.tube([V3(0, 0.031, -0.085), V3(0, 0.033, -0.03), V3(0, 0.033, 0.03), V3(0, 0.031, 0.085)], radii: [0.0085, 0.0118, 0.0118, 0.0085], sides: 12, endBulge: 0.8, seamTile: 0.03, material: accent))
        var zig: [V3] = []
        for k in 0...16 { let t = Float(k) / 16; zig.append(V3(0.007 * (k % 2 == 0 ? 1 : -1), 0.0455, -0.062 + 0.124 * t)) }
        m.add(FoodMesh.tube(zig, radii: Array(repeating: 0.0016, count: zig.count), sides: 5, endBulge: 0.5, seamTile: 0.01, material: "food.cheddar-melted:E4B31F"))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
