import simd
import Foundation

/// Gondola endcap: the promotional end of a gondola run, 0.9 m wide (matches `grocery-gondola` depth),
/// 0.5 m deep, 1.8 m tall plus a header. Parts: two slotted uprights, perforated back panel, base deck
/// with a kick plate, three lipped shelves with price rails, a lit-white header frame carrying a red
/// price card, a stacked case display on the deck and invented-brand stock. Front toward +Z; the back
/// is flat so it sits against the end of a run.
public struct GondolaEndcap: RealAsset {
    public static let id = "gondola-endcap"
    public static let summary = "Supermarket gondola endcap, 0.9 x 1.8 x 0.5 m: promo shelves with price rails, stacked case display and a red price header."
    public static let tags = ["prop", "grocery", "retail", "commercial", "metal", "interior", "sign"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, distance: 1.4, studio: true)

    /// Width, height (without header) and depth (m).
    public var size = V3(0.9, 1.8, 0.5)
    /// Shelf tops above the floor, base deck first (m).
    public var shelfHeights: [Float] = [0.15, 0.75, 1.1, 1.45]
    /// Price shown on the header card.
    public var price = "2/$5"
    /// Header word.
    public var headline = "SAVE"
    /// Stock fill (0 empty to 1 full), facings deep (1...6) and packing (0 loose, 1 shoulder to shoulder).
    public var fill: Float = 0.98
    public var stockDepth: Int = 6
    public var packing: Float = 0.5
    public var steel: MaterialKey = "metal.powdercoat:E4E5E2"
    public var trim: MaterialKey = "metal.powdercoat:3A3E44"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [8])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let zb = -D / 2, zf = D / 2
        for s: Float in [-1, 1] {
            GroceryKit.box(&m, V3(0.03, H, 0.05), V3(s * (W / 2 - 0.015), H / 2, zb + 0.025), steel, r: 0.003)
            GroceryKit.box(&m, V3(0.03, 0.1, D), V3(s * (W / 2 - 0.015), 0.05, 0), trim, r: 0.004)
        }
        GroceryKit.box(&m, V3(W - 0.06, H - 0.15, 0.012), V3(0, 0.15 + (H - 0.15) / 2, zb + 0.03), "metal.perforated:D9DBD8", r: 0.002)
        GroceryKit.box(&m, V3(W - 0.004, shelfHeights[0] - 0.01, 0.015), V3(0, (shelfHeights[0] - 0.01) / 2, zf - 0.008), trim, r: 0.003)
        // Header: frame, white panel, red card and print.
        let hy = H + 0.17
        GroceryKit.box(&m, V3(W, 0.34, 0.04), V3(0, hy, zb + 0.03), trim, r: 0.004)
        GroceryKit.decal(&m, W - 0.04, 0.3, V3(0, hy, zb + 0.0505), "plastic.matte:F6F6F2")
        GroceryKit.decal(&m, W * 0.62, 0.24, V3(W * 0.12, hy, zb + 0.051), "plastic.matte:C8202A")
        GroceryKit.print(&m, headline, height: 0.07, at: V3(-W * 0.3, hy - 0.035, zb + 0.0512), "plastic.matte:C8202A", maxWidth: W * 0.3)
        GroceryKit.print(&m, price, height: 0.13, at: V3(W * 0.12, hy - 0.065, zb + 0.0515), "plastic.matte:FFFFFF", maxWidth: W * 0.56)
        let z0 = zb + 0.04
        for (si, sy) in shelfHeights.enumerated() {
            let isBase = si == 0
            let d = isBase ? zf - z0 : 0.4
            let zFront = z0 + d
            GroceryKit.box(&m, V3(W - 0.064, 0.012, d), V3(0, sy - 0.006, z0 + d / 2), steel, r: 0.002)
            GroceryKit.box(&m, V3(W - 0.064, 0.04, 0.012), V3(0, sy - 0.02, zFront - 0.006), steel, r: 0.002)
            GroceryKit.priceRail(&m, x0: -W / 2 + 0.035, x1: W / 2 - 0.035, y: sy - 0.02, z: zFront, rng: &rng, hi: hi)
            if isBase {
                // Shipper cases stacked two high, one product, opened tops showing the facings.
                let p = GroceryKit.palettes[rng.int(0...(GroceryKit.palettes.count - 1))]
                for row in 0..<2 {
                    for c in 0..<3 {
                        let cx = -W / 2 + 0.05 + 0.135 + Float(c) * 0.27
                        let cy = sy + Float(row) * 0.27
                        GroceryKit.box(&m, V3(0.26, 0.26, 0.36), V3(cx + rng.float(-0.004...0.004), cy + 0.13, z0 + 0.2), "paper.screwbox-kraft", r: 0.003)
                        GroceryKit.decal(&m, 0.22, 0.12, V3(cx, cy + 0.15, z0 + 0.3805), GroceryKit.tint("paper.sheet", p.0))
                        GroceryKit.decal(&m, 0.14, 0.04, V3(cx, cy + 0.06, z0 + 0.381), GroceryKit.tint("paper.sheet", p.1))
                    }
                }
            } else {
                let top = si == shelfHeights.count - 1 ? H - 0.03 : shelfHeights[si + 1] - 0.03
                let mix: [GroceryKit.Pack] = si == 1 ? [.bag, .bag] : (si == 2 ? [.box, .tallBox] : [.bottle, .jar])
                GroceryKit.stockShelf(&m, x0: -W / 2 + 0.035, x1: W / 2 - 0.035, y: sy, zFront: zFront - 0.015, depth: d - 0.02,
                                      maxH: top - sy - 0.02, packs: mix, fill: fill, rng: &rng, hi: hi, coarseAt: 6000, boxAt: 8500,
                                      capAt: 9500, stockDepth: stockDepth, packing: packing)
            }
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return m
    }
}
