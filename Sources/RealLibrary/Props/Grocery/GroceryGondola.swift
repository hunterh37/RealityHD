import simd
import Foundation

/// Double-sided supermarket gondola section, 1.2 m long along X, 0.9 m deep, 1.8 m tall. Parts: a central
/// slotted upright pair with a perforated back panel, a base deck with kick plates on both faces, four
/// lipped shelf levels per face (y 0.15 base deck, 0.55, 0.95, 1.35), clear price rails with tags on every
/// lip, a header strip, and generic invented-brand stock in facings two or more deep on both faces.
/// Sections abut along X with no gap: uprights sit inside the 1.2 m bounds. Faces point to +Z and -Z.
public struct GroceryGondola: RealAsset {
    public static let id = "grocery-gondola"
    public static let summary = "Double-sided supermarket gondola, 1.2 x 1.8 x 0.9 m: steel uprights, base deck and four shelf levels per face, price rails, stock."
    public static let tags = ["prop", "grocery", "retail", "commercial", "metal", "interior", "container"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.5, studio: true)

    /// Stock mix on the shelves.
    public enum Category: String, Sendable, CaseIterable { case mixed, dry, canned, beverage, snack, breakfast, household }

    /// Section length along X (m).
    public var length: Float = 1.2
    /// Overall depth across both faces (m).
    public var depth: Float = 0.9
    /// Overall height (m).
    public var height: Float = 1.8
    /// Shelf top heights, base deck first (m).
    public var shelfHeights: [Float] = [0.15, 0.55, 0.95, 1.35]
    /// Stock mix and fill (0 empty to 1 full).
    public var category: Category = .mixed
    public var fill: Float = 0.96
    /// Facings deep behind each front facing, 1...6. 6 runs to the natural shelf depth (back stop at packing >= 0.75).
    public var stockDepth: Int = 6
    /// 0 loose gaps and skewed facings, 0.5 the original spacing, 1 shoulder to shoulder and end to end.
    public var packing: Float = 0.5
    /// Mix realistic grocery items (canned-vegetables, cracker-box, ...) into the facings on the hi LOD.
    public var realisticItems = true
    /// Stock on the -Z face as well.
    public var doubleSided = true
    /// Powder coat colors.
    public var steel: MaterialKey = "metal.powdercoat:E4E5E2"
    public var trim: MaterialKey = "metal.powdercoat:3A3E44"
    public init() {}

    func packs() -> [GroceryKit.Pack] {
        switch category {
        case .mixed: return [.box, .can, .bottle, .jar, .bag, .tallBox]
        case .dry: return [.box, .tallBox, .bag, .box]
        case .canned: return [.can, .can, .jar]
        case .beverage: return [.bottle, .can, .jug]
        case .snack: return [.bag, .bag, .box, .tray]
        case .breakfast: return [.box, .box, .jar, .bag]
        case .household: return [.bottle, .roll, .box, .jug]
        }
    }

    /// Realistic items mixed into the stock for the current category (low LOD of each item).
    func heroes() -> [GroceryKit.Hero] {
        guard realisticItems else { return [] }
        typealias H = GroceryKit.Hero
        let can = { H(CannedVegetables().level(hi: false), .can, (0x2F7D45, 0xF3EFD9, 0x9BC45A)) }
        let salsa = { H(SalsaJar().level(hi: false), .jar, (0xB8401E, 0xF6F0DE, 0x2F7D45)) }
        let sauce = { H(PastaSauceJar().level(hi: false), .jar, (0x8E1E12, 0xF2E3C4, 0xC9A042)) }
        let flour = { H(FlourBag().level(hi: false), .bag, (0xF4EFE2, 0xC8262B, 0xE3C77E)) }
        let sugar = { H(SugarBag().level(hi: false), .bag, (0xF7F6F2, 0x1F4E96, 0xC8262B)) }
        let cracker = { H(CrackerBox().level(hi: false), .box, (0xC8262B, 0xF6F1E4, 0xF2C230)) }
        let granola = { H(GranolaBarBox().level(hi: false), .box, (0x6B4A2B, 0xF3E6C8, 0xD9A441)) }
        let tea = { H(TeaBox().level(hi: false), .box, (0x2F7D45, 0xF3EFD9, 0xD9A441)) }
        let oats = { H(OatmealCanister().level(hi: false), .jar, (0xC8262B, 0xF2E3C4, 0xD9A441)) }
        let sport = { H(SportsDrinkBottle().level(hi: false), .bottle, (0x3FA9F5, 0xE8742A, 0xF2F2EE)) }
        let energy = { H(EnergyDrinkCan().level(hi: false), .can, (0x101214, 0x7CFF3A, 0xB8BCC2)) }
        let laundry = { H(LaundryDetergentJug().level(hi: false), .jug, (0xE8742A, 0xF7F6F0, 0x1F4E96)) }
        let tp = { H(ToiletPaperPack().level(hi: false), .box, (0xF9F8F4, 0x6B9BD6, 0xFFFFFF)) }
        let tissue = { H(TissueBox().level(hi: false), .box, (0x8EC5D6, 0xF6FAF8, 0x2E73A8)) }
        let dish = { H(DishSoapBottle().level(hi: false), .bottle, (0x4FB04A, 0xF7F6F0, 0xF2F2EE)) }
        let pet = { H(PetFoodBag().level(hi: false), .bag, (0x8A1F2C, 0xF6F1E4, 0xF2C230)) }
        let pick: [() -> H]
        switch category {
        case .mixed: pick = [can, sauce, cracker, flour, sport, dish, tea, salsa]
        case .dry: pick = [flour, sugar, cracker, sauce]
        case .canned: pick = [can, salsa, sauce]
        case .beverage: pick = [sport, energy]
        case .snack: pick = [cracker, granola, salsa]
        case .breakfast: pick = [oats, granola, tea]
        case .household: pick = [laundry, tp, tissue, dish, pet]
        }
        return pick.map { $0() }
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [8])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let L = length, D = depth, H = height
        let core: Float = 0.06               // back panel and upright thickness
        let shelfD = (D - core) / 2 - 0.01   // per face
        let mix = packs()
        let items = heroes()
        // Uprights at both ends, back panel between, header strip on top.
        for s: Float in [-1, 1] {
            GroceryKit.box(&m, V3(0.03, H - 0.01, core), V3(s * (L / 2 - 0.015), (H - 0.01) / 2, 0), steel, r: 0.003)
            if hi {
                var y: Float = 0.2
                while y < H - 0.08 {
                    for z: Float in [-1, 1] {
                        GroceryKit.decal(&m, 0.006, 0.02, V3(s * (L / 2 - 0.015), y, z * (core / 2 + 0.0005)), "plastic.black:1A1A1C",
                                         rot: simd_quatf(degrees: z > 0 ? 0 : 180, axis: .up))
                    }
                    y += 0.1
                }
            }
            // Base brackets under the deck.
            GroceryKit.box(&m, V3(0.03, 0.1, D - 0.02), V3(s * (L / 2 - 0.015), 0.05, 0), trim, r: 0.004)
        }
        GroceryKit.box(&m, V3(L - 0.06, H - 0.2, 0.012), V3(0, 0.1 + (H - 0.2) / 2, 0), "metal.perforated:D9DBD8", r: 0.002)
        GroceryKit.box(&m, V3(L, 0.05, core + 0.01), V3(0, H - 0.025, 0), trim, r: 0.004)
        let faces: [Float] = doubleSided ? [1, -1] : [1]
        for (fi, f) in faces.enumerated() {
            var rng = SeededRNG(seed: seed &+ UInt64(fi) &* 7919)
            let rot = simd_quatf(degrees: f > 0 ? 0 : 180, axis: .up)
            var face = Model(name: "face")
            // Build the +Z face in local coordinates, rotate for -Z.
            let z0 = core / 2, zF = core / 2 + shelfD
            // Kick plate and base deck.
            GroceryKit.box(&face, V3(L - 0.004, shelfHeights[0] - 0.01, 0.015), V3(0, (shelfHeights[0] - 0.01) / 2, D / 2 - 0.008), trim, r: 0.003)
            for (si, sy) in shelfHeights.enumerated() {
                let isBase = si == 0
                let d = isBase ? D / 2 - z0 : shelfD - (si == shelfHeights.count - 1 ? 0.06 : 0)
                let zFront = z0 + d
                // Shelf sheet with a front lip and a back return.
                GroceryKit.box(&face, V3(L - 0.064, 0.012, d), V3(0, sy - 0.006, z0 + d / 2), steel, r: 0.002)
                GroceryKit.box(&face, V3(L - 0.064, 0.04, 0.012), V3(0, sy - 0.02, zFront - 0.006), steel, r: 0.002)
                if !isBase {
                    // Cantilever brackets into the upright slots.
                    for s: Float in [-1, 1] {
                        let b = Prim.extrude([V2(0, 0), V2(d - 0.02, 0), V2(0, -0.09)], depth: 0.004, bevel: 0.0005, bevelSegments: 1, material: steel)
                        face.add(b, Xform(translation: V3(s * (L / 2 - 0.034), sy - 0.012, z0), rotation: simd_quatf(degrees: -90, axis: .up)))
                    }
                }
                GroceryKit.priceRail(&face, x0: -L / 2 + 0.035, x1: L / 2 - 0.035, y: sy - 0.02, z: zFront, rng: &rng, hi: hi)
                let top = si == shelfHeights.count - 1 ? H - 0.05 : shelfHeights[si + 1] - 0.03
                GroceryKit.stockShelf(&face, x0: -L / 2 + 0.035, x1: L / 2 - 0.035, y: sy, zFront: zFront - 0.015, depth: d - 0.02,
                                      maxH: top - sy - 0.02, packs: mix, fill: fill, rng: &rng, hi: hi, coarseAt: 3200, boxAt: 4600,
                                      capAt: 5800, stockDepth: stockDepth, packing: packing, heroes: items)
            }
            // Aisle-facing header card on the top strip.
            GroceryKit.decal(&face, L - 0.1, 0.034, V3(0, H - 0.025, core / 2 + 0.0055), "paper.sheet:F7F6F0")
            m.add(face, Xform(rotation: rot))
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return m
    }
}
