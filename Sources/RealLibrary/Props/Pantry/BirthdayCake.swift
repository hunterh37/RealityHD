import simd
import Foundation

/// BirthdayCake: everyday pantry, baked. Real-size 0.24 x 0.12 x 0.24 m.
public struct BirthdayCake: RealAsset {
    public static let id = "birthday-cake"
    public static let summary = "BirthdayCake, 0.24 x 0.12 x 0.24 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "baked"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.cream:F6DDE6"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.chocolate"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
func tier(_ r: Float, _ y0: Float, _ h: Float) -> Surface {
            var s = FoodMesh.revolve(edge: 0.012, seamTile: 0.08, material: skin, curve: FoodMesh.profile([V2(0, y0), V2(r * 0.96, y0), V2(r, y0 + 0.003), V2(r, y0 + h - 0.004), V2(r * 0.97, y0 + h), V2(0, y0 + h)], per: 3))
            s.deform { p in let a = atan2(p.z, p.x); let k = 1 + 0.004 * sin(a * 12); return V3(p.x * k, p.y, p.z * k) }
            return s
        }
        m.add(tier(0.12, 0.0, 0.058))
        m.add(tier(0.078, 0.058, 0.036))
        for k in 0..<22 {
            let a = Float(k) / 22 * 2 * .pi
            m.add(Prim.superellipsoid(V3(0.016, 0.014, 0.016), exponent: 2, subdivisions: 3, material: skin), Xform(translation: V3(cos(a) * 0.112, 0.062, sin(a) * 0.112)))
            m.add(Prim.superellipsoid(V3(0.014, 0.011, 0.014), exponent: 2, subdivisions: 3, material: accent), Xform(translation: V3(cos(a) * 0.111, 0.005, sin(a) * 0.111)))
        }
        for k in 0..<14 {
            let a = Float(k) / 14 * 2 * .pi
            m.add(Prim.superellipsoid(V3(0.013, 0.012, 0.013), exponent: 2, subdivisions: 3, material: skin), Xform(translation: V3(cos(a) * 0.072, 0.096, sin(a) * 0.072)))
        }
        let cols: [MaterialKey] = ["plastic.matte:E24A5A", "plastic.matte:3C8BD6", "plastic.matte:F2C230", "plastic.matte:56B86B", "plastic.matte:A468D8"]
        for k in 0..<5 {
            let a = Float(k) / 5 * 2 * .pi + 0.4
            let c = V3(cos(a) * 0.034, 0, sin(a) * 0.034)
            m.add(Prim.cylinder(radius: 0.0028, height: 0.018, bevel: 0.0006, segments: 8, material: cols[k]), Xform(translation: V3(c.x, 0.094, c.z)))
            m.add(Prim.superellipsoid(V3(0.004, 0.009, 0.004), exponent: 2, subdivisions: 4, material: "food.cheddar-melted:FFC24A"), Xform(translation: V3(c.x, 0.1155, c.z)))
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
