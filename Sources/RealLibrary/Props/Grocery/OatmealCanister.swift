import simd
import Foundation

/// 42 oz round oatmeal canister, 13 x 18.5 cm: spiral-wound paperboard tube with a cream wrap, red band, snap-on plastic
/// lid, printed HEARTHSIDE OLD FASHIONED OATS. Invented brand.
public struct OatmealCanister: RealAsset {
    public static let id = "oatmeal-canister"
    public static let summary = "42 oz oatmeal canister, 18.5 cm: paperboard tube, red and cream wrap, snap-on lid, printed invented brand HEARTHSIDE."
    public static let tags = ["prop", "grocery", "food", "paper", "cardboard", "container", "pantry"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0xC8262B
    public var brand = "HEARTHSIDE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.064, h: Float = 0.17, seg = hi ? 32 : 12
        m.add(Prim.lathe([V2(0, 0), V2(r - 0.002, 0), V2(r, 0.002), V2(r, h), V2(0, h)], segments: seg, seamTile: 0.05, material: "paper.sheet:F2E3C4"))
        GroceryKit.band(&m, r: r + 0.0004, 0.01, 0.06, seg: seg, GroceryKit.tint("paper.sheet", color))
        GroceryKit.band(&m, r: r + 0.0004, 0.13, 0.165, seg: seg, GroceryKit.tint("paper.sheet", color))
        GroceryKit.wrapPrint(&m, brand, height: 0.014, radius: r + 0.0006, y: 0.142, "paper.sheet:F6F1E4", maxWidth: 0.075)
        GroceryKit.wrapPrint(&m, "OLD FASHIONED", height: 0.01, radius: r + 0.0006, y: 0.1, "paper.sheet:7A2E1A", maxWidth: 0.075)
        GroceryKit.wrapPrint(&m, "OATS", height: 0.018, radius: r + 0.0006, y: 0.072, "paper.sheet:7A2E1A", maxWidth: 0.08)
        GroceryKit.wrapPrint(&m, "42 OZ", height: 0.007, radius: r + 0.0006, y: 0.025, "paper.sheet:F6F1E4", maxWidth: 0.05)
        m.add(Prim.lathe([V2(r - 0.001, h - 0.012), V2(r + 0.0025, h - 0.011), V2(r + 0.0025, h + 0.012), V2(r - 0.002, h + 0.015), V2(0, h + 0.014)],
                         segments: seg, seamTile: 0.05, material: "plastic.matte:D9A441"))
        if hi { GroceryKit.band(&m, r: r + 0.0007, 0.0, 0.004, seg: seg, "paper.sheet:B9A88A") }
        return m
    }
}
