import simd
import Foundation

/// Green bell pepper: the `bell-pepper` lobed body and stem with an unripe glossy green skin.
public struct BellPepperGreen: RealAsset {
    public static let id = "bell-pepper-green"
    public static let summary = "Green bell pepper, 9 cm: four-lobed glossy green body with a thick curved stem on a calyx."
    public static let tags = ["prop", "grocery", "food", "vegetable", "handheld"]
    public static let budget = 7000
    public static let author = "realityhd"

    public var skin: MaterialKey = "food.jalapeno"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        BellPepper().with { $0.skin = skin }.build(seed: seed)
    }
}
