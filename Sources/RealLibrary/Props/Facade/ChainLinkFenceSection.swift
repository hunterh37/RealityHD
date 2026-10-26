import simd
import Foundation

/// Chain link fence section: architectural facade customizer, Commercial. Parts: terminal posts, line post, top rail, chain link mesh, tension bar, tension band, tie wires, post caps, bottom tension wire.
public struct ChainLinkFenceSection: RealAsset {
    public static let id = "chain-link-fence-section"
    public static let summary = "Commercial galvanized chain link fence, 2 inch mesh, tubular posts and top rail"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.8, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.galvanized metal.galvanized-aged metal.steel. Gate: realityhd gate chain-link-fence-section. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.galvanized"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
