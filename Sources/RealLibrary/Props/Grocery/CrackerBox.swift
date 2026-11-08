import simd
import Foundation

/// Saltine cracker box, 20 x 22 x 7 cm: printed red paperboard with a cream panel, yellow band, a stack of crackers,
/// brand SALTWELL ORIGINAL CRACKERS, side panel and scuffs on hi. Invented brand.
public struct CrackerBox: RealAsset {
    public static let id = "cracker-box"
    public static let summary = "Saltine cracker box, 22 cm: red printed paperboard, cream panel, cracker stack graphic, invented brand SALTWELL."
    public static let tags = ["prop", "grocery", "food", "paper", "cardboard", "container", "pantry", "handheld"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0xC8262B
    public var brand = "SALTWELL"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let s = V3(0.2, 0.22, 0.07)
        GroceryKit.carton(&m, size: s, body: color, panel: 0xF6F1E4, accent: 0xF2C230, ink: color, brand: brand, line: "ORIGINAL CRACKERS", hi: hi)
        let fz = s.z / 2 + 0.0014
        for i in 0..<3 {
            GroceryKit.box(&m, V3(0.045, 0.045, 0.002), V3(-0.045 + Float(i) * 0.045, 0.045 + Float(i % 2) * 0.006, fz), "paper.sheet:E3BC7A", r: 0.0006)
            if hi { for d in 0..<4 { GroceryKit.decal(&m, 0.003, 0.003, V3(-0.055 + Float(i) * 0.045 + Float(d % 2) * 0.02, 0.035 + Float(i % 2) * 0.006 + Float(d / 2) * 0.02, fz + 0.0012), "paper.sheet:B88A4E") } }
        }
        return m
    }
}
