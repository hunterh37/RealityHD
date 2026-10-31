import simd
import Foundation

/// Soap dispenser: everyday bathroom, pump bottle. Parts: round pump bottle body, chrome pump head and nozzle, collar, label band.
public struct SoapDispenser: RealAsset {
    public static let id = "soap-dispenser"
    public static let summary = "Round liquid soap pump bottle: gloss body, wrap label, chrome collar, stem and nozzle."
    public static let tags = ["prop", "interior", "bathroom", "plastic", "metal"]
    public static let budget = 3500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.07, 0.18, 0.07)
    public init() {}

    public var body: MaterialKey = "plastic.gloss:9CC7B8"
    public var head: MaterialKey = "metal.chrome"
    public var label: MaterialKey = "plastic.matte:F2F2EE"

    public func build(seed: UInt64) -> LODModel {
        LODModel(BottleKit.model(id: Self.id, size: size, body: body, cap: head, label: label, capStyle: .pump))
    }
}
