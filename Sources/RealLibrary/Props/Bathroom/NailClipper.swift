import simd
import Foundation

/// Nail clipper: everyday bathroom, steel. Parts: lower jaw plate, upper lever, cutting tip, pivot pin, file lever.
public struct NailClipper: RealAsset {
    public static let id = "nail-clipper"
    public static let summary = "Steel nail clipper lying flat: jaw plates, curved upper lever, pivot pin and file lever."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 4000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.01, 0.01, 0.06)
    public init() {}

    public var steel: MaterialKey = "metal.stainless"
    public var chrome: MaterialKey = "metal.chrome"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        // Lower jaw plate and curved upper lever with a cutting tip.
        m.add(Prim.roundedBox(V3(0.0094, 0.0022, 0.056), radius: 0.0008, bevelSegments: 2, material: steel), Xform(translation: V3(0, 0.0011, 0)))
        m.add(Prim.roundedBox(V3(0.0100, 0.0018, 0.036), radius: 0.0007, bevelSegments: 2, material: steel), Xform(translation: V3(0, 0.0034, -0.01)))
        m.add(Prim.roundedBox(V3(0.0100, 0.0018, 0.016), radius: 0.0007, bevelSegments: 2, material: steel), Xform(translation: V3(0, 0.0028, 0.0245), rotation: simd_quatf(angle: -0.09, axis: V3(1, 0, 0))))
        // Smudged strip where the lever is pressed.
        m.add(Prim.roundedBox(V3(0.0068, 0.0004, 0.014), radius: 0.0002, bevelSegments: 1, material: "metal.stainless-smudged"), Xform(translation: V3(0, 0.0045, -0.012)))
        // File lever: rod along the top, held by the pivot pin.
        Toiletry.rod(&m, axis: 2, at: V3(0, 0.0064, -0.0285), length: 0.047, r: 0.0017, chrome, seg: 10)
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0016, 0.0), V2(0.0016, 0.0078), V2(0.0028, 0.0082), V2(0.0028, 0.0094), V2(0.0014, 0.0098), V2(0.001, 0.0098)], chrome, seg: 14, at: V3(0, 0.0, 0.0185))
        // Notch cut into the lower jaw tip.
        m.add(Prim.roundedBox(V3(0.0042, 0.0006, 0.0035), radius: 0.0002, bevelSegments: 1, material: "metal.stainless-smudged"), Xform(translation: V3(0, 0.0023, 0.0285)))
        groundAO(&m)
        return LODModel(m)
    }
}
