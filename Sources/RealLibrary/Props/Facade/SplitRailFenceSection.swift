import simd
import Foundation

/// Split rail fence section: architectural facade customizer, Rural. Parts: split posts with mortises, rails with tapered ends, stacked rails, ground wear, cracks and checks.
public struct SplitRailFenceSection: RealAsset {
    public static let id = "split-rail-fence-section"
    public static let summary = "Rural post-and-rail fence, split cedar rails tapering into mortised posts"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.1, 0.15)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar-weathered wood.pole-pine wood.weathered. Gate: realityhd gate split-rail-fence-section. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar-weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
