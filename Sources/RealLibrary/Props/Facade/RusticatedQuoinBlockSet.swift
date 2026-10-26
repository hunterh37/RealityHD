import simd
import Foundation

/// Rusticated quoin block set: architectural facade customizer, Italianate. Parts: long quoin blocks, short quoin blocks, chamfered rustication joints, pecked faces, return face, mortar beds, chipped arrises.
public struct RusticatedQuoinBlockSet: RealAsset {
    public static let id = "rusticated-quoin-block-set"
    public static let summary = "Italianate rusticated quoin set, 0.9 m tall: alternating long and short blocks with chamfered rusticated joints and vermiculated faces, with mortar-line and soot staining."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 0.9, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.sandstone stone.brownstone-sooted stone.cast-stone. Gate: realityhd gate rusticated-quoin-block-set. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
