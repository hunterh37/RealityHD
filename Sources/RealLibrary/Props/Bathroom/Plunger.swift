import simd
import Foundation

/// Plunger: everyday bathroom, rubber and wood. Parts: rubber cup, neck collar, wooden handle, end cap.
public struct Plunger: RealAsset {
    public static let id = "plunger"
    public static let summary = "Toilet plunger: red rubber bell cup on a wooden handle."
    public static let tags = ["prop", "interior", "bathroom", "rubber", "wood"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.15, 0.5, 0.15)
    public init() {}

    public var rubber: MaterialKey = "plastic.matte:B3201C"
    public var handle: MaterialKey = "wood.pine"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let seg = 48
        // Bell cup, rim at y = 0, with a thickened rolled rim.
        Toiletry.lathe(&m, [V2(0.0715, 0.0), V2(0.0745, 0.0), V2(0.0752, 0.003), V2(0.0725, 0.02), V2(0.0585, 0.044), V2(0.038, 0.058), V2(0.022, 0.066), V2(0.019, 0.088), V2(0.0132, 0.092),
                            V2(0.0132, 0.07), V2(0.034, 0.052), V2(0.055, 0.036), V2(0.068, 0.018), V2(0.0705, 0.004)], rubber, seg: seg, seamTile: 0.2)
        // Neck collar.
        Toiletry.lathe(&m, [V2(0.0185, 0.07), V2(0.0215, 0.072), V2(0.0215, 0.1), V2(0.017, 0.103), V2(0.001, 0.103)], rubber, seg: 24)
        // Wooden handle, rounded cap, with a worn lower band where hands grip.
        Toiletry.lathe(&m, [V2(0.0125, 0.085), V2(0.0125, 0.485), V2(0.0118, 0.493), V2(0.0085, 0.4985), V2(0.001, 0.5)], handle, seg: 24, seamTile: 0.1)
        Toiletry.band(&m, r: 0.0125, 0.3, 0.36, "wood.pine-aged", seg: 24)
        // Dirty ring just inside the rim.
        Toiletry.lathe(&m, [V2(0.0712, 0.0), V2(0.0705, 0.006), V2(0.0698, 0.0055), V2(0.0705, 0.0)], "plastic.matte:3B2A26", seg: seg)
        groundAO(&m)
        return LODModel(m)
    }
}
