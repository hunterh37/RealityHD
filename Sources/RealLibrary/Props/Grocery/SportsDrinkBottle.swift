import simd
import Foundation

/// 28 oz sports drink bottle, 23.5 cm: PET body with a grip waist and shoulder, translucent blue drink, wide ribbed cap,
/// printed shrink sleeve VOLTADE, condensation beads on hi. Invented brand.
public struct SportsDrinkBottle: RealAsset {
    public static let id = "sports-drink-bottle"
    public static let summary = "28 oz sports drink bottle, 23.5 cm: grip-waist PET body, blue drink, ribbed cap, printed sleeve, condensation beads, invented brand."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var drink: MaterialKey = "plastic.translucent:3FA9F5"
    public var sleeve: UInt32 = 0xE8742A
    public var brand = "VOLTADE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.0375, seg = hi ? 28 : 10
        let prof: [V2] = [V2(0, 0.004), V2(0.028, 0), V2(r, 0.008), V2(r, 0.07), V2(0.033, 0.088), V2(0.033, 0.1), V2(r, 0.118), V2(r, 0.168),
                          V2(0.03, 0.19), V2(0.019, 0.204), V2(0.0175, 0.21), V2(0, 0.21)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.05, material: drink))
        GroceryKit.band(&m, r: r + 0.0005, 0.12, 0.166, seg: seg, GroceryKit.tint("plastic.gloss", sleeve))
        GroceryKit.band(&m, r: r + 0.0007, 0.128, 0.134, seg: seg, "plastic.gloss:F6F6F2")
        GroceryKit.wrapPrint(&m, brand, height: 0.012, radius: r + 0.0008, y: 0.143, "plastic.gloss:FFFFFF", maxWidth: 0.046)
        GroceryKit.wrapPrint(&m, "ICE BLUE", height: 0.005, radius: r + 0.0008, y: 0.1245, "plastic.gloss:1F4E96", maxWidth: 0.04)
        var cap: [V2] = [V2(0, 0.207), V2(0.0195, 0.207)]
        if hi { for i in 0..<6 { let y = 0.209 + Float(i) * 0.0035; cap += [V2(0.0205, y), V2(0.0198, y + 0.0017)] } }
        cap += [V2(0.0205, 0.23), V2(0.019, 0.232), V2(0, 0.232)]
        m.add(Prim.lathe(cap, segments: seg, seamTile: 0.05, material: "plastic.matte:F2F2EE"))
        if hi { GroceryKit.droplets(&m, radius: r, 0.012, 0.115, count: 26, seed: 29) }
        return m
    }
}
