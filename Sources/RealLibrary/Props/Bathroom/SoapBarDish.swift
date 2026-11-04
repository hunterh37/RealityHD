import simd
import Foundation

/// Soap bar dish: everyday bathroom, ceramic. Parts: ceramic dish tray, raised rim, drainage ridges, soap bar.
public struct SoapBarDish: RealAsset {
    public static let id = "soap-bar-dish"
    public static let summary = "Rectangular ceramic soap dish with rim and ridges holding a worn soap bar."
    public static let tags = ["prop", "interior", "bathroom", "ceramic"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.03, 0.09)
    public init() {}

    public var dish: MaterialKey = "ceramic.vitreous"
    public var soap: MaterialKey = "plastic.gloss:EFE6C8"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = size.x, d = size.z
        // Tray base and raised rim walls.
        m.add(Prim.roundedBox(V3(w, 0.008, d), radius: 0.004, bevelSegments: 3, material: dish), Xform(translation: V3(0, 0.004, 0)))
        let wall: Float = 0.005
        m.add(Prim.roundedBox(V3(w, 0.012, wall), radius: 0.0022, bevelSegments: 2, material: dish), Xform(translation: V3(0, 0.008, d / 2 - wall / 2)))
        m.add(Prim.roundedBox(V3(w, 0.012, wall), radius: 0.0022, bevelSegments: 2, material: dish), Xform(translation: V3(0, 0.008, -d / 2 + wall / 2)))
        m.add(Prim.roundedBox(V3(wall, 0.012, d), radius: 0.0022, bevelSegments: 2, material: dish), Xform(translation: V3(w / 2 - wall / 2, 0.008, 0)))
        m.add(Prim.roundedBox(V3(wall, 0.012, d), radius: 0.0022, bevelSegments: 2, material: dish), Xform(translation: V3(-w / 2 + wall / 2, 0.008, 0)))
        // Drainage ridges across the tray.
        for k in 0..<7 {
            let z = (Float(k) - 3) * 0.0095
            m.add(Prim.roundedBox(V3(w - 0.016, 0.005, 0.0045), radius: 0.0018, bevelSegments: 2, material: dish), Xform(translation: V3(0, 0.0105, z)))
        }
        // Soap bar, worn smooth, slightly offset.
        m.add(Prim.roundedBox(V3(0.078, 0.0165, 0.05), radius: 0.0075, bevelSegments: 4, material: soap), Xform(translation: V3(-0.004, 0.0132 + 0.0165 / 2, 0.003), rotation: simd_quatf(angle: 0.07, axis: V3(0, 1, 0))))
        // Soap scum puddle at the low end of the tray.
        m.add(Prim.roundedBox(V3(0.03, 0.0008, 0.012), radius: 0.0004, bevelSegments: 1, material: "plastic.gloss:E3DFC9"), Xform(translation: V3(0.032, 0.0084, 0.03)))
        groundAO(&m)
        return LODModel(m)
    }
}
