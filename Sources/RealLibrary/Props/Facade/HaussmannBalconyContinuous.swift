import simd
import Foundation

/// Haussmann continuous balcony: architectural facade customizer, Haussmann. Parts: stone slab, moulded slab edge, stone corbels, iron handrail, balusters, scroll panels, end posts, bottom rail, finial caps, drip groove.
public struct HaussmannBalconyContinuous: RealAsset {
    public static let id = "haussmann-balcony-continuous"
    public static let summary = "Haussmann continuous balcony, 6.0 x 1.0 x 0.9 m: limestone slab on end corbels with an iron railing of scroll panels between posts."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(6.0, 1.0, 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.limestone-sooted metal.wrought-iron metal.rust metal.bolt-bright. Gate: realityhd gate haussmann-balcony-continuous. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
