import simd
import Foundation

/// Espaliered fruit tree wire trellis: architectural facade customizer, English Cottage. Parts: wall eye bolts, tensioned galvanised wires, straining screws, tree trunk, tiered horizontal branches, leaves, fruit, twine ties, soil mound.
public struct EspalieredFruitTreeWireTrellis: RealAsset {
    public static let id = "espaliered-fruit-tree-wire-trellis"
    public static let summary = "English Cottage espalier trellis, 1.5 m x 2.0 m: horizontal galvanised wires on eye bolts and straining screws trained with a fruit tree in a tiered candelabra form, tied with twine."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.5, 2.0, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.galvanized metal.galvanized-aged wood.lumber-oak wood.pole-pine. Gate: realityhd gate espaliered-fruit-tree-wire-trellis. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.galvanized"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
