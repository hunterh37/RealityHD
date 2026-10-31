import simd
import Foundation

/// Hair dryer: everyday bathroom, plastic. Parts: barrel, nozzle, rear grille, angled handle, switches, cord.
public struct HairDryer: RealAsset {
    public static let id = "hair-dryer"
    public static let summary = "Hair dryer lying on its side: round barrel with nozzle and rear grille, angled handle with switches."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.22, 0.09, 0.2)
    public init() {}

    public var shellMaterial: MaterialKey = "plastic.gloss:B87A7A"
    public var nozzle: MaterialKey = "plastic.matte:2A2D32"
    public var grille: MaterialKey = "metal.stainless"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let seg = hi ? 40 : 16
            let rotZ = simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1))
            let bz: Float = -0.055
            // Barrel along X: lathe runs toward -X from the nozzle end at +X.
            Toiletry.lathe(&m, [V2(0.034, 0.0), V2(0.0385, 0.006), V2(0.0435, 0.045), V2(0.045, 0.07), V2(0.045, 0.16), V2(0.0425, 0.2), V2(0.04, 0.218), V2(0.001, 0.22)], shellMaterial, seg: seg, at: V3(0.11, 0.045, bz), rot: rotZ)
            // Nozzle concentrator with a flared lip and a dark inner.
            Toiletry.lathe(&m, [V2(0.0325, 0.0), V2(0.0338, 0.002), V2(0.0338, 0.032), V2(0.0385, 0.04), V2(0.0385, 0.044), V2(0.0345, 0.0445)], nozzle, seg: seg, at: V3(0.11 + 0.0, 0.045, bz), rot: rotZ)
            Toiletry.lathe(&m, [V2(0.0, 0.0005), V2(0.032, 0.0005), V2(0.032, 0.0015), V2(0.0, 0.0015)], "plastic.black", seg: seg, at: V3(0.11, 0.045, bz), rot: rotZ)
            // Rear grille: ring plus perforation bands, with lint caught in it.
            Toiletry.lathe(&m, [V2(0.0, 0.2199), V2(0.04, 0.2186), V2(0.0412, 0.2125), V2(0.0425, 0.2), V2(0.0405, 0.1995), V2(0.0, 0.2035)], grille, seg: seg, at: V3(0.11, 0.045, bz), rot: rotZ)
            for k in 0..<5 {
                let y = 0.2001 + Float(k) * 0.0035
                Toiletry.band(&m, r: 0.0412 - Float(k) * 0.0003, y, y + 0.0012, "plastic.black", seg: seg, at: V3(0.11, 0.045, bz), rot: rotZ)
            }
            m.add(Prim.superellipsoid(V3(0.004, 0.012, 0.014), exponent: 2, subdivisions: 6, material: "plastic.matte:B9B2A6"), Xform(translation: V3(-0.1085, 0.05, bz + 0.012)))
            // Vent slots along the barrel top.
            for k in 0..<6 {
                m.add(Prim.roundedBox(V3(0.012, 0.0008, 0.0035), radius: 0.0003, bevelSegments: 1, material: nozzle), Xform(translation: V3(-0.05 + Float(k) * 0.016, 0.0903, bz)))
            }
            // Angled handle toward +Z, tilted down so its end rests on the table.
            let hq = simd_quatf(angle: Float.pi / 2 + 0.17, axis: V3(1, 0, 0))
            Toiletry.lathe(&m, [V2(0.016, 0.0), V2(0.0185, 0.01), V2(0.0185, 0.088), V2(0.0165, 0.102), V2(0.001, 0.104)], shellMaterial, seg: hi ? 24 : 10, at: V3(-0.03, 0.036, bz + 0.035), rot: hq)
            for k in 0..<4 {
                Toiletry.band(&m, r: 0.0185, 0.05 + Float(k) * 0.012, 0.054 + Float(k) * 0.012, "plastic.matte:8E5656", seg: hi ? 24 : 10, at: V3(-0.03, 0.036, bz + 0.035), rot: hq)
            }
            // Speed and heat switches on the handle top.
            m.add(Prim.roundedBox(V3(0.007, 0.003, 0.014), radius: 0.001, bevelSegments: 1, material: "plastic.matte:2A2D32"), Xform(translation: V3(-0.03, 0.0545, bz + 0.052)))
            m.add(Prim.roundedBox(V3(0.007, 0.003, 0.014), radius: 0.001, bevelSegments: 1, material: "plastic.gloss:D8352B"), Xform(translation: V3(-0.03, 0.0535, bz + 0.068)))
            // Cord leaving the handle end.
            Toiletry.rod(&m, axis: 2, at: V3(-0.03, 0.021, bz + 0.133), length: 0.018, r: 0.0042, "plastic.matte:2A2D32", seg: hi ? 10 : 6)
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
