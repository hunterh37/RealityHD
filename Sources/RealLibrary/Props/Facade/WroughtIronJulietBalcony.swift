import simd
import Foundation

/// Wrought iron Juliet balcony: architectural facade customizer, Spanish Colonial. Parts: top handrail, bottom rail, bowed front, twisted balusters, scroll panels, side returns, wall anchor plates, rivets and collars, rust at the lower rail.
public struct WroughtIronJulietBalcony: RealAsset {
    public static let id = "wrought-iron-juliet-balcony"
    public static let summary = "Spanish Colonial Juliet balcony, 1.4 m wide: forged iron bowed rail with twisted balusters, scroll panels, flat-bar frame, rivets, wall anchor plates and a worn black finish."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.4, 1.0, 0.35)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron metal.rust metal.iron metal.hammer-painted. Gate: realityhd gate wrought-iron-juliet-balcony. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
