import simd
import Foundation

/// Post and rope fence: architectural facade customizer, Coastal. Parts: round posts, rope runs, rope sag, eye screws, post caps, knots, base.
public struct PostAndRopeFence: RealAsset {
    public static let id = "post-and-rope-fence"
    public static let summary = "Coastal weathered round posts with sagging manila rope through eye hooks"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.0, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.pole-creosote wood.driftwood wood.pine-aged wood.rattan metal.galvanized. Gate: realityhd gate post-and-rope-fence. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.pole-creosote"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
