import simd
import Foundation

/// Gabion wall section: architectural facade customizer, Contemporary. Parts: welded wire cages, stacked stone fill, corner posts, spiral binders, top lid mesh, stone variation, stepped cells.
public struct GabionWallSection: RealAsset {
    public static let id = "gabion-wall-section"
    public static let summary = "Contemporary gabion wall, galvanized welded wire baskets filled with angular stone"
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 1.0, 0.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.granite-paver stone.sandstone metal.galvanized stone.wall-block. Gate: realityhd gate gabion-wall-section. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.granite-paver"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
