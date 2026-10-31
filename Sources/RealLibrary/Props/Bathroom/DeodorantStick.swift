import simd
import Foundation

/// Deodorant stick: everyday bathroom, plastic. Parts: oval body, twist knob base, domed cap, label band.
public struct DeodorantStick: RealAsset {
    public static let id = "deodorant-stick"
    public static let summary = "Oval stick deodorant: gloss body, twist base knob, domed cap, label band."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 4000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.04, 0.11, 0.03)
    public init() {}

    public var bodyMaterial: MaterialKey = "plastic.gloss:2C5F8A"
    public var capMaterial: MaterialKey = "plastic.gloss:E8EDF2"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let r = size.x / 2, h = size.y, sz = size.z / size.x
        let seg = 36
        // Twist knob at the base.
        Toiletry.lathe(&m, [V2(0.001, 0), V2(r * 0.88, 0), V2(r * 0.96, 0.0015), V2(r * 0.97, 0.0125), V2(r * 0.93, 0.0145), V2(0.001, 0.0145)], "plastic.matte:D8D8D8", seg: seg, sz: sz)
        // Knurl ribs around the twist knob.
        for k in 0..<18 {
            let a = Float(k) / 18 * 2 * Float.pi
            m.add(Prim.roundedBox(V3(0.0012, 0.0105, 0.0009), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:C4C4C4"),
                  Xform(translation: V3(cos(a) * r * 0.975, 0.0075, sin(a) * r * sz * 0.975), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
        }
        // Body with a filleted lower edge.
        Toiletry.lathe(&m, [V2(r * 0.93, 0.0135), V2(r, 0.0155), V2(r, 0.07), V2(r * 0.97, 0.0715), V2(0.001, 0.0715)], bodyMaterial, seg: seg, sz: sz)
        // Domed cap with a visible seam.
        Toiletry.lathe(&m, [V2(r * 1.01, 0.0695), V2(r * 1.012, 0.072), V2(r * 1.01, 0.092), V2(r * 0.93, 0.104), V2(r * 0.62, 0.1092), V2(r * 0.3, 0.1098), V2(0.001, h)], capMaterial, seg: seg, sz: sz)
        Toiletry.band(&m, r: r, 0.0705, 0.0715, "plastic.matte:E9E4D8", seg: seg, sz: sz)
        // Label art: bar rows on the body.
        Toiletry.band(&m, r: r, 0.045, 0.058, "plastic.matte:F2F2EE", seg: seg, sz: sz)
        Toiletry.band(&m, r: r * 1.0004, 0.049, 0.052, "plastic.matte:3A3F46", seg: seg, sz: sz)
        Toiletry.band(&m, r: r * 1.0004, 0.036, 0.038, "plastic.matte:8A9097", seg: seg, sz: sz)
        groundAO(&m)
        return LODModel(m)
    }
}
