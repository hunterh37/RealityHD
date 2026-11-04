import simd
import Foundation

/// Perfume bottle: everyday bathroom, glass. Parts: glass body, liquid, collar, cap.
public struct PerfumeBottle: RealAsset {
    public static let id = "perfume-bottle"
    public static let summary = "Rectangular glass perfume bottle with liquid, chrome collar and gloss cap."
    public static let tags = ["prop", "interior", "bathroom", "glass"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.05, 0.1, 0.04)
    public init() {}

    public var glassMaterial: MaterialKey = "glass.clear"
    public var liquid: MaterialKey = "glass.tinted"
    public var capMaterial: MaterialKey = "plastic.gloss:1E1E22"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = size.x, d = size.z
        let bodyH: Float = 0.058
        // Thick glass base and walls.
        m.add(Prim.roundedBox(V3(w, bodyH, d), radius: 0.005, bevelSegments: 3, material: glassMaterial), Xform(translation: V3(0, bodyH / 2, 0)))
        m.add(Prim.roundedBox(V3(w - 0.01, bodyH - 0.016, d - 0.01), radius: 0.003, bevelSegments: 2, material: "glass.tinted:E3A94A"), Xform(translation: V3(0, 0.0105 + (bodyH - 0.016) / 2 - 0.0005, 0)))
        // Front nameplate and dried fragrance residue at the collar.
        m.add(Prim.roundedBox(V3(0.024, 0.014, 0.0008), radius: 0.0003, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(0, 0.03, d / 2 + 0.0003)))
        Toiletry.lathe(&m, [V2(0.0126, bodyH + 0.0055), V2(0.0142, bodyH + 0.0045), V2(0.0138, bodyH + 0.0025), V2(0.0126, bodyH + 0.002)], "plastic.matte:E9E4D8", seg: 24)
        // Neck, chrome collar and spray nozzle.
        Toiletry.lathe(&m, [V2(0.001, bodyH - 0.001), V2(0.0125, bodyH - 0.001), V2(0.0125, bodyH + 0.004), V2(0.0105, bodyH + 0.0045), V2(0.001, bodyH + 0.0045)], "glass.clear", seg: 24)
        Toiletry.lathe(&m, [V2(0.0128, bodyH + 0.002), V2(0.0135, bodyH + 0.003), V2(0.0135, bodyH + 0.0105), V2(0.0125, bodyH + 0.011), V2(0.001, bodyH + 0.011)], "metal.chrome", seg: 28)
        // Cap: rounded cylinder with a chrome ring at its base.
        Toiletry.lathe(&m, [V2(0.0145, bodyH + 0.0105), V2(0.0165, bodyH + 0.0115), V2(0.0165, size.y - 0.003), V2(0.0145, size.y - 0.0005), V2(0.001, size.y)], capMaterial, seg: 32)
        Toiletry.lathe(&m, [V2(0.0166, bodyH + 0.0105), V2(0.0166, bodyH + 0.0135), V2(0.0148, bodyH + 0.0135), V2(0.0148, bodyH + 0.0105)], "metal.chrome", seg: 32)
        groundAO(&m)
        return LODModel(m)
    }
}
