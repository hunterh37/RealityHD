import simd
import Foundation

/// Combined straight-and-left lane arrow, 2.0 x 4.5 m slab: 3.0 m painted arrow with a 25 cm shaft,
/// triangular head and a left-turn branch, in worn white road paint.
public struct TurnArrowMarking: RealAsset {
    public static let id = "turn-arrow-marking"
    public static let summary = "Lane arrow marking, 2 x 4.5 m: white straight-and-left turn arrow painted on asphalt."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 5, studio: true)

    /// Shaft width (m).
    public var shaft: Float = 0.25
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04
        GK.slab(&m, w: 2.0, d: 4.5, h: top, "asphalt.road", r: 0.01)
        let hw = shaft / 2, z0: Float = -1.9, z1: Float = 0.5
        // Main stem and arrowhead pointing +Z.
        GK.poly(&m, [V2(-hw, z0), V2(hw, z0), V2(hw, z1), V2(-hw, z1)], top: top, GK.paintWhite)
        GK.poly(&m, [V2(-0.45, z1 - 0.02), V2(0.45, z1 - 0.02), V2(0, z1 + 1.1)], top: top, GK.paintWhite)
        // Left branch angled out of the stem.
        let a = V2(-hw, -0.3), dirv = simd_normalize(V2(-0.55, 0.85)), n = V2(-dirv.y, dirv.x) * hw
        let b = a + dirv * 1.2
        GK.poly(&m, [a - n, b - n, b + n, a + n], top: top, GK.paintWhite)
        GK.poly(&m, [b + V2(-0.28, -0.02), b + V2(0.1, 0.38), b + V2(0.38, -0.2)].map { $0 }, top: top, GK.paintWhite)
        // Worn tyre track.
        GK.layer(&m, x: rng.float(-0.4...0.4), z: rng.float(-1...0), w: 0.35, d: 1.2, top: top + 0.0015, "asphalt.worn")
        return GK.finish(&m, ao: 0.03)
    }
}
