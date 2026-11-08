import simd
import Foundation

/// Open multideck dairy case, one 1.2 m section: 2.0 m tall, 0.95 m deep, front toward +Z. Parts: dark
/// plinth with a stainless bumper, white base front, a low glass riser on the well, a black perforated
/// air-return back wall, four stepped shelves with LED strips under their lips and price rails, a canopy
/// with a lit fascia and a rolled night curtain, optional end panels, and dairy stock (gallon jugs,
/// gable-top cartons, cups, cheese trays) under invented brands. Sections abut along X with `endPanels`
/// off; the lit parts use emissive materials.
public struct RefrigeratedCase: RealAsset {
    public static let id = "refrigerated-case"
    public static let summary = "Open multideck dairy case, 1.2 x 2.0 x 0.95 m: stepped lit shelves, canopy light, night curtain, glass riser and dairy stock."
    public static let tags = ["prop", "grocery", "retail", "commercial", "appliance", "metal", "light", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.4, studio: true)

    /// Section width, height and depth (m).
    public var size = V3(1.2, 2.0, 0.95)
    /// Shelf tops above the floor (m); the well deck is at `deckHeight`.
    public var shelfHeights: [Float] = [0.86, 1.13, 1.4, 1.66]
    public var deckHeight: Float = 0.46
    /// Glazed end panels on both sides (off when sections join in a run).
    public var endPanels = true
    /// Stock fill, 0 empty to 1 full.
    public var fill: Float = 0.95
    /// Facings deep (1...6) and packing (0 loose, 0.5 original, 1 shoulder to shoulder).
    public var stockDepth: Int = 6
    public var packing: Float = 0.5
    /// Exterior and interior finishes.
    public var shell: MaterialKey = "metal.powder-white"
    public var interior: MaterialKey = "metal.powdercoat:202327"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [9])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let zb = -D / 2, zf = D / 2
        let backIn = zb + 0.13
        // Plinth, base front and bumper.
        GroceryKit.box(&m, V3(W, 0.12, D - 0.06), V3(0, 0.06, -0.03), "metal.powdercoat:2A2C30", r: 0.004)
        GroceryKit.box(&m, V3(W, deckHeight - 0.12, 0.05), V3(0, 0.12 + (deckHeight - 0.12) / 2, zf - 0.04), shell, r: 0.006)
        GroceryKit.box(&m, V3(W, 0.05, 0.03), V3(0, deckHeight - 0.08, zf - 0.015), "metal.stainless", r: 0.01)
        GroceryKit.box(&m, V3(W, 0.004, 0.012), V3(0, 0.25, zf - 0.013), "plastic.matte:8A8C90")
        // Well deck, riser glass and its rail.
        GroceryKit.box(&m, V3(W, 0.02, zf - 0.065 - backIn), V3(0, deckHeight - 0.01, (backIn + zf - 0.065) / 2), interior, r: 0.003)
        GroceryKit.box(&m, V3(W, 0.12, 0.008), V3(0, deckHeight + 0.06, zf - 0.06), "glass.display", r: 0.002)
        GroceryKit.box(&m, V3(W, 0.015, 0.02), V3(0, deckHeight + 0.125, zf - 0.06), "metal.stainless", r: 0.006)
        // Back: cabinet, black perforated air return.
        GroceryKit.box(&m, V3(W, H, 0.12), V3(0, H / 2, zb + 0.06), shell, r: 0.006)
        GroceryKit.box(&m, V3(W - 0.01, H - deckHeight - 0.2, 0.01), V3(0, deckHeight + (H - deckHeight - 0.2) / 2, backIn + 0.005), "metal.perforated:2A2C30", r: 0.002)
        // Canopy, lit fascia, LED under the canopy, night curtain roll.
        let canD: Float = 0.42
        GroceryKit.box(&m, V3(W, 0.16, canD), V3(0, H - 0.08, zb + canD / 2), shell, r: 0.008)
        GroceryKit.box(&m, V3(W, 0.12, 0.012), V3(0, H - 0.09, zb + canD + 0.004), "plastic.diffuser", r: 0.003)
        GroceryKit.decal(&m, W - 0.02, 0.1, V3(0, H - 0.09, zb + canD + 0.0105), "emissive.panel")
        GroceryKit.print(&m, "DAIRY", height: 0.06, at: V3(0, H - 0.12, zb + canD + 0.011), "plastic.matte:1F4E96")
        GroceryKit.flat(&m, V3(W - 0.04, 0.006, 0.03), V3(0, H - 0.163, zb + canD - 0.05), "emissive.lamp-white")
        m.add(GroceryKit.cyl(0.018, W - 0.04, seg: hi ? 10 : 6, "fabric.blind:D8DADC"),
              Xform(translation: V3(-(W - 0.04) / 2, H - 0.185, zb + canD - 0.02), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        if endPanels {
            for s: Float in [-1, 1] {
                GroceryKit.box(&m, V3(0.04, H, D - 0.02), V3(s * (W / 2 + 0.02), H / 2, -0.01), shell, r: 0.008)
                GroceryKit.box(&m, V3(0.006, H - deckHeight - 0.35, D * 0.45), V3(s * (W / 2 + 0.041), deckHeight + 0.1 + (H - deckHeight - 0.35) / 2, D * 0.12),
                               "glass.display", r: 0.002)
            }
        }
        // Dairy stock: jugs on the deck, cartons, cups and trays above.
        let mixes: [[GroceryKit.Pack]] = [[.jug], [.carton, .carton], [.cup, .tray], [.cup, .jar], [.tray, .box]]
        let levels = [deckHeight] + shelfHeights
        for (li, y) in levels.enumerated() {
            let shelfFront: Float = li == 0 ? zf - 0.075 : backIn + 0.5 - Float(li - 1) * 0.04
            let d = shelfFront - backIn - 0.02
            if li > 0 {
                GroceryKit.box(&m, V3(W - 0.02, 0.014, d + 0.02), V3(0, y - 0.007, backIn + (d + 0.02) / 2), interior, r: 0.002)
                GroceryKit.box(&m, V3(W - 0.02, 0.036, 0.01), V3(0, y - 0.018, shelfFront - 0.005), interior, r: 0.002)
                GroceryKit.decal(&m, W - 0.04, 0.008, V3(0, y - 0.032, shelfFront - 0.012), "emissive.lamp-white",
                                 rot: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
                GroceryKit.priceRail(&m, x0: -W / 2 + 0.02, x1: W / 2 - 0.02, y: y - 0.018, z: shelfFront, rng: &rng, hi: hi)
            }
            let top = li == 0 ? shelfHeights[0] - 0.05 : (li < levels.count - 1 ? levels[li + 1] - 0.04 : H - 0.2)
            GroceryKit.stockShelf(&m, x0: -W / 2 + 0.02, x1: W / 2 - 0.02, y: y, zFront: shelfFront - 0.015, depth: d - 0.01,
                                  maxH: min(0.27, top - y), packs: mixes[li], fill: fill, rng: &rng, hi: hi, coarseAt: 8000, boxAt: 11000,
                                  capAt: 12500, stockDepth: stockDepth, packing: packing)
        }
        groundAO(&m, height: 0.1, floor: 0.75)
        return m
    }
}
