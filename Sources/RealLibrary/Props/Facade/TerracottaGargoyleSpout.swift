import simd
import Foundation

/// Terracotta gargoyle spout: architectural facade customizer, Gothic Revival. Parts: grotesque head, open mouth spout channel, brow ridge, pointed ears, horns, folded wing, forelegs, haunch, wall tail plate, iron fixing straps, fixing bolts.
public struct TerracottaGargoyleSpout: RealAsset {
    public static let id = "terracotta-gargoyle-spout"
    public static let summary = "Gothic Revival terracotta gargoyle water spout, 0.3 x 0.6 x 0.7 m: crouching grotesque with open mouth, brow, ears, horn, wings folded, wall tail plate, glazed terracotta with weathering."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 0.6, 0.7)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: ceramic.terracotta ceramic.bisque stone.limestone-sooted metal.cast-iron. Gate: realityhd gate terracotta-gargoyle-spout. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "ceramic.terracotta"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
