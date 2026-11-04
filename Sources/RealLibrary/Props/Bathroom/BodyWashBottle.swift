import simd
import Foundation

/// Body wash bottle: everyday bathroom, plastic. Parts: oval plastic bottle body, shoulder and neck, cap, label band, base.
public struct BodyWashBottle: RealAsset {
    public static let id = "body-wash-bottle"
    public static let summary = "Body wash bottle: oval blow-moulded plastic body, shoulder taper, flip cap, wrap label band."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 3500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.07, 0.22, 0.05)
    public init() {}

    public var body: MaterialKey = "plastic.gloss:4FA36B"
    public var capMaterial: MaterialKey = "plastic.white"
    public var label: MaterialKey = "plastic.matte:F2F2EE"

    public func build(seed: UInt64) -> LODModel {
        LODModel(BottleKit.model(id: Self.id, size: size, body: body, cap: capMaterial, label: label, capStyle: .flip))
    }
}
