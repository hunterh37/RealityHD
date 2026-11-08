import simd
import Foundation

/// Six-count granola bar carton, 17 x 13.5 x 5 cm: printed paperboard with a bar photo panel, oat band, brand
/// TRAILCREST and CHEWY GRANOLA BARS, side info panel and scuffed corners on hi. Invented brand.
public struct GranolaBarBox: RealAsset {
    public static let id = "granola-bar-box"
    public static let summary = "Granola bar carton, 13.5 cm: printed paperboard with bar panel, brand TRAILCREST, CHEWY GRANOLA BARS, invented brand."
    public static let tags = ["prop", "grocery", "food", "paper", "cardboard", "container", "pantry", "handheld"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0x6B4A2B
    public var brand = "TRAILCREST"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let s = V3(0.17, 0.135, 0.05)
        GroceryKit.carton(&m, size: s, body: color, panel: 0xF3E6C8, accent: 0xD9A441, ink: 0x5A2E12, brand: brand, line: "CHEWY GRANOLA BARS", hi: hi)
        let fz = s.z / 2 + 0.0012
        GroceryKit.box(&m, V3(0.08, 0.018, 0.002), V3(0, 0.03, fz), "paper.sheet:C79A5B", r: 0.0008)
        GroceryKit.print(&m, "6 BARS", height: 0.007, at: V3(0.055, 0.01, fz), "paper.sheet:F3E6C8")
        if hi { for i in 0..<5 { GroceryKit.decal(&m, 0.005, 0.004, V3(-0.03 + Float(i) * 0.015, 0.03 + Float(i % 2) * 0.004, fz + 0.0012), "paper.sheet:3A2214") } }
        return m
    }
}
