import simd
import Foundation

/// Sliding driveway gate: architectural facade customizer, Contemporary. Parts: steel frame, infill slats, top track rail, guide rollers, bottom rail, drive rack, tail wheels, gate post, receiver post.
public struct SlidingDrivewayGate: RealAsset {
    public static let id = "sliding-driveway-gate"
    public static let summary = "Contemporary cantilever sliding gate, aluminium slat infill in steel frame with rack and rollers"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(4.0, 1.8, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat-worn metal.galvanized metal.stainless. Gate: realityhd gate sliding-driveway-gate. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat-worn"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
