import simd
import Foundation

/// Arbor gate: architectural facade customizer, Cottage. Parts: posts, arched top, lattice side panels, picket gate leaf, strap hinges, latch, post caps, cross rails.
public struct ArborGate: RealAsset {
    public static let id = "arbor-gate"
    public static let summary = "Cottage garden arbor with arched head, lattice sides and picket gate, painted cedar"
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 2.4, 0.6)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar wood.cedar-weathered metal.wrought-iron. Gate: realityhd gate arbor-gate. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
