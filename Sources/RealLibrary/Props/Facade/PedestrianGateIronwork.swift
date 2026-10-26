import simd
import Foundation

/// Pedestrian gate ironwork: architectural facade customizer, Contemporary. Parts: steel frame, flat bar pickets, horizontal rails, gate leaf, hinge, magnetic latch, post, striker plate.
public struct PedestrianGateIronwork: RealAsset {
    public static let id = "pedestrian-gate-ironwork"
    public static let summary = "Contemporary powder-coated steel pedestrian gate with slim flat pickets and concealed hardware"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 1.8, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat-worn metal.powdercoat metal.stainless. Gate: realityhd gate pedestrian-gate-ironwork. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat-worn"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
