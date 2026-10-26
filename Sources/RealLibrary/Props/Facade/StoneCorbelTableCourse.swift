import simd
import Foundation

/// Stone corbel table course: architectural facade customizer, Romanesque Revival. Parts: stepped corbels, carved roll profile, corbel arches, cornice slab with drip, ashlar frieze course, mortar joints, face masks on end corbels, weathering stains.
public struct StoneCorbelTableCourse: RealAsset {
    public static let id = "stone-corbel-table-course"
    public static let summary = "Romanesque Revival stone corbel table, 2.0 m: row of rounded and stepped corbels carrying a cornice slab, round arches between, ashlar frieze, weathered sandstone."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 0.35, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.sandstone stone.brownstone stone.limestone-sooted stone.limestone. Gate: realityhd gate stone-corbel-table-course. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.sandstone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
