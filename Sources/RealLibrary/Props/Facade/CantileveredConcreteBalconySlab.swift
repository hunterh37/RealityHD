import simd
import Foundation

/// Cantilevered concrete balcony slab: architectural facade customizer, Brutalist. Parts: slab, board-formed texture, drip groove, upstand kerb, tie holes, thermal break strip, drain scupper, stainless balustrade posts.
public struct CantileveredConcreteBalconySlab: RealAsset {
    public static let id = "cantilevered-concrete-balcony-slab"
    public static let summary = "Brutalist cantilevered balcony slab, 2.4 m wide, 1.2 m projection: board-formed concrete with drip groove, upturned parapet kerb, tie holes, thermal break strip and stainless rail posts."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 0.2, 1.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: concrete.rough concrete.river-algae metal.galvanized metal.stainless. Gate: realityhd gate cantilevered-concrete-balcony-slab. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "concrete.rough"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
