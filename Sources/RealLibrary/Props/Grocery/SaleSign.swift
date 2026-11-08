import simd
import Foundation

/// Shelf talker: a red printed card on a clear plastic arm that clips into a shelf price rail and
/// sticks out into the aisle at a right angle to the shelf. The card stands in the XY plane (both faces
/// printed, readable from up and down the aisle); the arm and rail clip run out from its -X edge.
/// Base (card bottom) at y = 0. Print reads SALE, a price and a savings line.
public struct SaleSign: RealAsset {
    public static let id = "sale-sign"
    public static let summary = "Red shelf talker sale sign, 12 x 15 cm card on a clear clip arm: SALE header, large price and savings line on both faces."
    public static let tags = ["prop", "grocery", "retail", "sign", "paper", "plastic", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 6, distance: 1.3, studio: true)

    /// Card size (m).
    public var card = V2(0.12, 0.15)
    public var price = "$2.99"
    public var savings = "SAVE $1.00"
    public var color: MaterialKey = "paper.sheet:D11F26"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = card.x, h = card.y
        GroceryKit.box(&m, V3(w, h, 0.0012), V3(0, h / 2, 0), color, r: 0.0005)
        for f: Float in [1, -1] {
            let rot = simd_quatf(degrees: f > 0 ? 0 : 180, axis: .up)
            let z = f * 0.0008
            GroceryKit.decal(&m, w - 0.012, 0.035, V3(0, h - 0.026, z), "paper.sheet:F6D21E", rot: rot)
            GroceryKit.print(&m, "SALE", height: 0.022, at: V3(0, h - 0.037, z + f * 0.0002), "paper.sheet:D11F26", rot: rot)
            GroceryKit.print(&m, price, height: 0.034, at: V3(0, h * 0.34, z), "paper.sheet:FFFFFF", rot: rot, maxWidth: w - 0.012)
            GroceryKit.print(&m, savings, height: 0.009, at: V3(0, 0.014, z), "paper.sheet:FFFFFF", rot: rot, maxWidth: w - 0.016)
        }
        // Clear arm from the card's -X edge to the rail clip.
        GroceryKit.box(&m, V3(0.06, 0.03, 0.002), V3(-w / 2 - 0.028, h * 0.5, 0), "plastic.clear", r: 0.0006)
        GroceryKit.box(&m, V3(0.003, 0.034, 0.03), V3(-w / 2 - 0.059, h * 0.5, 0), "plastic.clear", r: 0.0008)
        return LODModel(m)
    }
}
