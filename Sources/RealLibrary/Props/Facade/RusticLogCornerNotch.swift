import simd
import Foundation

/// Rustic log corner notch: architectural facade customizer, Rustic Log Cabin. Parts: round logs, saddle notches, log ends, bark, chinking, drift pins, knots.
public struct RusticLogCornerNotch: RealAsset {
    public static let id = "rustic-log-corner-notch"
    public static let summary = "Rustic log cabin corner, 0.5 x 1.2 x 0.5 m: seven courses of round logs with saddle notches, projecting ends, lime chinking and iron drift pins."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 1.2, 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar-weathered wood.endgrain-weathered wood.pole-pine concrete.mortar-lime metal.rust. Gate: realityhd gate rustic-log-corner-notch. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar-weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
