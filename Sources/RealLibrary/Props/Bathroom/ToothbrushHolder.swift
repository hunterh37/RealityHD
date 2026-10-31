import simd
import Foundation

/// Toothbrush holder: everyday bathroom, ceramic. Parts: ceramic cup body, base foot, rolled lip, two toothbrush handles.
public struct ToothbrushHolder: RealAsset {
    public static let id = "toothbrush-holder"
    public static let summary = "Ceramic toothbrush cup with foot ring and rolled lip, two toothbrushes standing in it."
    public static let tags = ["prop", "interior", "bathroom", "ceramic"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.08, 0.11, 0.08)
    public init() {}

    public var cup: MaterialKey = "ceramic.vitreous"
    public var glaze: MaterialKey = "ceramic.cobalt"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let seg = 48
        // Cup with foot ring, flaring wall, rolled lip and inner floor.
        Toiletry.lathe(&m, [V2(0.001, 0), V2(0.03, 0), V2(0.033, 0.0012), V2(0.0345, 0.006), V2(0.0365, 0.012), V2(0.0385, 0.06), V2(0.0398, 0.102), V2(0.0405, 0.1065),
                            V2(0.04, 0.1095), V2(0.0375, 0.11), V2(0.0355, 0.1085), V2(0.0345, 0.1055), V2(0.0335, 0.06), V2(0.031, 0.016), V2(0.0285, 0.0105), V2(0.001, 0.0095)], cup, seg: seg, seamTile: 0.2)
        // Glazed band near the lip and a darker mineral stain ring on the floor.
        Toiletry.band(&m, r: 0.0393, 0.082, 0.096, glaze, seg: seg)
        // Glaze drips below the band and a chip on the lip.
        for (i, a) in [0.4, 1.3, 2.2, 3.4, 4.6, 5.5].enumerated() {
            let len: Float = 0.007 + 0.002 * Float(i % 3)
            m.add(Prim.superellipsoid(V3(0.0045, len, 0.0016), exponent: 2, subdivisions: 6, material: glaze),
                  Xform(translation: V3(Float(cos(a)) * 0.0391, 0.082 - len / 2 + 0.001, Float(sin(a)) * 0.0391), rotation: simd_quatf(angle: -Float(a) + Float.pi / 2, axis: V3(0, 1, 0))))
        }
        m.add(Prim.roundedBox(V3(0.006, 0.0025, 0.003), radius: 0.0008, bevelSegments: 1, material: "ceramic.vitreous:B9AE95"),
              Xform(translation: V3(0.0, 0.1088, 0.0388), rotation: simd_quatf(angle: 0, axis: V3(0, 1, 0))))
        Toiletry.lathe(&m, [V2(0.001, 0.0097), V2(0.0275, 0.0107), V2(0.0285, 0.0118), V2(0.001, 0.0108)], "ceramic.vitreous:CFC6B0", seg: 32)
        groundAO(&m)
        return LODModel(m)
    }
}
