import simd
import Foundation

/// Six-roll paper towel pack (2 x 3) in printed poly film: embossed white rolls with brown cores visible at
/// the ends, a clear film wrap with a printed blue band, a carry handle strap and the invented brand
/// SOFTLEAF.
public struct PaperTowelPack: RealAsset {
    public static let id = "paper-towel-pack"
    public static let summary = "Six-roll paper towel pack, 39 x 28 x 26 cm: white rolls with visible cores in clear film, printed blue band, carry strap."
    public static let tags = ["prop", "grocery", "paper", "plastic", "home", "handheld"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.3, studio: true)

    public var rollRadius: Float = 0.065
    public var rollHeight: Float = 0.28
    public var brand = "SOFTLEAF"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [3])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r = rollRadius, h = rollHeight, seg = hi ? 24 : 10
        let roll = Prim.lathe([V2(0.021, 0.002), V2(r - 0.003, 0), V2(r, 0.004), V2(r, h - 0.004), V2(r - 0.003, h), V2(0.021, h - 0.002)],
                              segments: seg, seamTile: 0.05, material: "paper.sheet:F7F6F2")
        let core = Prim.lathe([V2(0.021, h - 0.002), V2(0.019, h - 0.004), V2(0, h - 0.004)], segments: seg, seamTile: 0.05, material: "paper.screwbox-kraft")
        let coreB = Prim.lathe([V2(0, 0.004), V2(0.019, 0.004), V2(0.021, 0.002)], segments: seg, seamTile: 0.05, material: "paper.screwbox-kraft")
        let W = 3 * 2 * r, D = 2 * 2 * r
        for c in 0..<3 { for k in 0..<2 {
            let p = V3(-W / 2 + r * (2 * Float(c) + 1), 0, -D / 2 + r * (2 * Float(k) + 1))
            m.add(roll, Xform(translation: p)); m.add(core, Xform(translation: p)); m.add(coreB, Xform(translation: p))
        }}
        GroceryKit.box(&m, V3(W + 0.006, h + 0.004, D + 0.006), V3(0, (h + 0.004) / 2, 0), "plastic.clear", r: 0.03)
        GroceryKit.decal(&m, W * 0.8, 0.09, V3(0, h * 0.5, D / 2 + 0.0035), "plastic.gloss:2E73C8")
        GroceryKit.print(&m, brand, height: 0.03, at: V3(0, h * 0.5 - 0.01, D / 2 + 0.0038), "paper.sheet:FFFFFF", maxWidth: W * 0.7)
        GroceryKit.print(&m, "6 ROLLS", height: 0.014, at: V3(0, h * 0.5 - 0.038, D / 2 + 0.0038), "paper.sheet:F2C230")
        // Carry strap over the top.
        GroceryKit.box(&m, V3(0.04, 0.004, D + 0.012), V3(0, h + 0.006, 0), "plastic.translucent:E8E8E4", r: 0.0015)
        GroceryKit.box(&m, V3(0.04, 0.03, 0.06), V3(0, h + 0.022, 0), "plastic.translucent:E8E8E4", r: 0.008)
        return m
    }
}
