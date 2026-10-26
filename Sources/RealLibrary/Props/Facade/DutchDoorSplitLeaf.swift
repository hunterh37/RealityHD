import simd
import Foundation

/// Split-leaf Dutch door: architectural facade customizer, Dutch Colonial. Parts: upper and lower leaves with 4 mm split gap, ledged and braced vertical beaded boards, shelf cap on lower leaf, cast iron strap hinges with pintles, Norfolk thumb latches, barrel bolt linking leaves, moulded casing with drip cap, worn oak threshold, paint chips at latch edge.
public struct DutchDoorSplitLeaf: RealAsset {
    public static let id = "dutch-door-split-leaf"
    public static let summary = "Dutch Colonial split door: two independently hung painted board-and-batten leaves with a shelf cap, strap hinges, thumb latches, a barrel bolt and a worn oak sill."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.95, 2.1, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.painted-shaker-worn wood.painted-exterior wood.oak metal.wrought-iron metal.brass-aged. Gate: realityhd gate dutch-door-split-leaf. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.painted-shaker-worn"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
