import simd
import Foundation

/// Lotion bottle: everyday bathroom, plastic. Parts: oval plastic bottle body, shoulder and neck, pump head and nozzle, label band, base.
public struct LotionBottle: RealAsset {
    public static let id = "lotion-bottle"
    public static let summary = "Lotion bottle: oval blow-moulded plastic body, shoulder taper, pump, wrap label band."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 3500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.06, 0.18, 0.05)
    public init() {}

    public var body: MaterialKey = "plastic.gloss:E8D9B5"
    public var capMaterial: MaterialKey = "plastic.white:F4F1EA"
    public var label: MaterialKey = "plastic.matte:F2F2EE"

    public func build(seed: UInt64) -> LODModel {
        LODModel(BottleKit.model(id: Self.id, size: size, body: body, cap: capMaterial, label: label, capStyle: .pump))
    }
}
