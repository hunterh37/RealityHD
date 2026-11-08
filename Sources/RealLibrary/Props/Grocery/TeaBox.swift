import simd
import Foundation

/// Twenty-bag tea carton, 15 x 8 x 7.5 cm: printed paperboard with a cream art panel, gold band, leaf marks, brand
/// STILLWATER GREEN TEA 20 BAGS. Invented brand.
public struct TeaBox: RealAsset {
    public static let id = "tea-box"
    public static let summary = "20-bag tea carton, 8 cm: green printed paperboard with cream panel, gold band and leaf marks, invented brand STILLWATER."
    public static let tags = ["prop", "grocery", "food", "paper", "cardboard", "container", "pantry", "handheld"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0x2F7D45
    public var brand = "STILLWATER"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let s = V3(0.15, 0.08, 0.075)
        GroceryKit.carton(&m, size: s, body: color, panel: 0xF3EFD9, accent: 0xD9A441, ink: 0x2F5D3A, brand: brand, line: "GREEN TEA 20 BAGS", hi: hi)
        if hi {
            for i in 0..<3 {
                GroceryKit.decal(&m, 0.004, 0.007, V3(0.058 + Float(i) * 0.005, 0.073, s.z / 2 + 0.0012), "paper.sheet:4E8F2A",
                                 rot: simd_quatf(degrees: Float(i) * 25 - 25, axis: V3(0, 0, 1)))
            }
        }
        return m
    }
}
