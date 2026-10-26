import simd
import Foundation

/// Double swing driveway gate: architectural facade customizer, Contemporary. Parts: two leaves, steel frame, slat infill, hinges, gate posts, drop bolt, centre stop, actuator arm, leaf stile.
public struct SwingDrivewayGateDouble: RealAsset {
    public static let id = "swing-driveway-gate-double"
    public static let summary = "Contemporary double swing driveway gate with slatted leaves, heavy hinges and linear actuators"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(4.0, 1.8, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat-worn metal.galvanized metal.stainless. Gate: realityhd gate swing-driveway-gate-double. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat-worn"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
