import simd
import Foundation

/// Roof ridge vent: TODO: era, condition, finish. Parts: .
public struct RoofRidgeVent: RealAsset {
    public static let id = "roof-ridge-vent"
    public static let summary = "TODO: one sentence, what it is and how it's built."
    public static let tags = ["prop"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.0, 0.0, 0.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: . Gate: realityhd gate roof-ridge-vent. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.pine"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
