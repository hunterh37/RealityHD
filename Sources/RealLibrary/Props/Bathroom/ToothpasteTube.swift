import simd
import Foundation

/// Toothpaste tube: everyday bathroom, laminate. Parts: flattened laminate tube body, crimped end, shoulder, screw cap, printed stripes.
public struct ToothpasteTube: RealAsset {
    public static let id = "toothpaste-tube"
    public static let summary = "Toothpaste tube lying flat: flattened body, crimped end with ridges, shoulder, ringed screw cap."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.04, 0.03, 0.18)
    public init() {}

    public var tube: MaterialKey = "plastic.gloss:F4F4F2"
    public var capMaterial: MaterialKey = "plastic.gloss:2F6FB5"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let seg = 40
        let R: Float = size.x / 2 - 0.0005
        let rot = simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))
        let at = V3(0, 0.0152, -size.z / 2)
        let sz: Float = 0.74
        // Flattened body, shoulder and neck (axis along +Z after rotation).
        Toiletry.lathe(&m, [V2(0.001, 0.0125), V2(R, 0.0125), V2(R, 0.14), V2(R * 0.9, 0.148), V2(R * 0.6, 0.154), V2(0.0085, 0.157), V2(0.0085, 0.166), V2(0.001, 0.166)], tube, seg: seg, sz: sz, at: at, rot: rot)
        // Printed stripes and a label block.
        Toiletry.band(&m, r: R, 0.05, 0.1, "plastic.gloss:2F6FB5", seg: seg, sz: sz, at: at, rot: rot)
        Toiletry.band(&m, r: R * 1.0003, 0.056, 0.059, "plastic.gloss:F4F4F2", seg: seg, sz: sz, at: at, rot: rot)
        Toiletry.band(&m, r: R * 1.0003, 0.088, 0.093, "plastic.gloss:D8352B", seg: seg, sz: sz, at: at, rot: rot)
        Toiletry.band(&m, r: R * 1.0003, 0.118, 0.123, "plastic.gloss:D8352B", seg: seg, sz: sz, at: at, rot: rot)
        // Screw cap with ridge rings and dried paste at the seam.
        Toiletry.lathe(&m, [V2(0.0102, 0.152), V2(0.0145, 0.153), V2(0.0148, 0.176), V2(0.0138, 0.1795), V2(0.001, 0.18)], capMaterial, seg: 32, at: at, rot: rot)
        for y: Float in [0.158, 0.165, 0.172] { Toiletry.band(&m, r: 0.0148, y, y + 0.0014, "plastic.gloss:1F4E86", seg: 32, at: at, rot: rot) }
        Toiletry.band(&m, r: 0.0144, 0.1508, 0.1522, "plastic.gloss:DDF0F5", seg: 32, at: at, rot: rot)
        // Crimped end: flat seal with ridges.
        m.add(Prim.roundedBox(V3(size.x - 0.002, 0.0042, 0.016), radius: 0.0015, bevelSegments: 2, material: tube), Xform(translation: V3(0, 0.0152, -size.z / 2 + 0.008)))
        for k in 0..<5 {
            m.add(Prim.roundedBox(V3(size.x - 0.005, 0.0007, 0.0009), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:C9C9C4"),
                  Xform(translation: V3(0, 0.0152 + 0.0022, -size.z / 2 + 0.0025 + Float(k) * 0.0027)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
