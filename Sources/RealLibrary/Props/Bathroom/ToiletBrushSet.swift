import simd
import Foundation

/// Toilet brush set: everyday bathroom, plastic. Parts: ceramic holder, rolled rim, brush handle, handle cap, grip rings.
public struct ToiletBrushSet: RealAsset {
    public static let id = "toilet-brush-set"
    public static let summary = "Toilet brush in a round holder: white holder with rim, handle with grip rings and cap."
    public static let tags = ["prop", "interior", "bathroom", "plastic", "ceramic"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.13, 0.4, 0.13)
    public init() {}

    public var holder: MaterialKey = "ceramic.vitreous"
    public var handle: MaterialKey = "plastic.gloss:F4F4F2"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let seg = 48
        // Holder: foot, tapered wall, rolled rim, inner wall.
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.05, 0.0), V2(0.053, 0.0015), V2(0.0545, 0.008), V2(0.0605, 0.1), V2(0.0625, 0.19), V2(0.0645, 0.2), V2(0.0645, 0.206), V2(0.0615, 0.2085),
                            V2(0.0585, 0.2055), V2(0.0575, 0.2), V2(0.053, 0.03), V2(0.001, 0.02)], holder, seg: seg, seamTile: 0.2)
        // Accent band and limescale ring inside the bowl.
        Toiletry.band(&m, r: 0.0618, 0.15, 0.17, "ceramic.vitreous:C9D5DA", seg: seg)
        Toiletry.lathe(&m, [V2(0.0572, 0.1), V2(0.0575, 0.112), V2(0.0568, 0.112), V2(0.0566, 0.1)], "ceramic.vitreous:CFC6B0", seg: seg)
        // Brush: handle rising from the holder, leaning slightly, with grip rings and a rounded cap.
        let lean = simd_quatf(angle: 0.05, axis: V3(0, 0, 1)) * simd_quatf(angle: -0.03, axis: V3(1, 0, 0))
        let at = V3(0.0, 0.02, 0.0)
        Toiletry.lathe(&m, [V2(0.0075, 0.0), V2(0.0075, 0.3), V2(0.0092, 0.31), V2(0.0092, 0.36), V2(0.0078, 0.364), V2(0.0078, 0.372), V2(0.0092, 0.376), V2(0.0092, 0.378), V2(0.006, 0.38), V2(0.001, 0.381)], handle, seg: 24, at: at, rot: lean)
        for k in 0..<5 {
            let y = 0.312 + Float(k) * 0.01
            Toiletry.band(&m, r: 0.0092, y, y + 0.004, "plastic.matte:3A3F46", seg: 24, at: at, rot: lean)
        }
        // Bristle head visible in the bowl mouth.
        Toiletry.lathe(&m, [V2(0.001, 0.15), V2(0.025, 0.152), V2(0.034, 0.17), V2(0.03, 0.192), V2(0.016, 0.206), V2(0.001, 0.208)], "plastic.matte:2B2F34", seg: 28)
        groundAO(&m)
        return LODModel(m)
    }
}
