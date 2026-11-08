import simd
import Foundation

/// Twelve-pack of 500 ml water bottles (3 x 4) in clear shrink film: ribbed PET bottles with water fill,
/// blue sport caps, wrap labels in blue and white, and a printed film band with a carry slot.
public struct WaterBottlePack: RealAsset {
    public static let id = "water-bottle-pack"
    public static let summary = "Twelve-pack of 500 ml water bottles in shrink film, 27 x 21 x 20 cm: ribbed PET bottles, blue caps, wrap labels."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.3, studio: true)

    public var columns = 4
    public var rows = 3
    public var capColor: MaterialKey = "plastic.gloss:2E73C8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [3])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.033, pitch: Float = 0.067, h: Float = 0.2
        let seg = hi ? 14 : 7
        var prof: [V2] = [V2(0, 0.004), V2(0.022, 0), V2(0.03, 0.002), V2(r, 0.012)]
        let ribs = hi ? 6 : 2
        for i in 0..<ribs { let y = 0.03 + Float(i) * 0.012; prof += [V2(r, y), V2(r * 0.95, y + 0.006)] }
        prof += [V2(r, 0.11), V2(r, 0.135), V2(0.024, 0.165), V2(0.0135, 0.178), V2(0.0135, 0.185), V2(0, 0.185)]
        let bottle = Prim.lathe(prof, segments: seg, seamTile: 0.05, material: "plastic.pvc-clear")
        let water = Prim.lathe([V2(0, 0.006), V2(r * 0.93, 0.008), V2(r * 0.93, 0.15), V2(0, 0.15)], segments: seg, seamTile: 0.05, material: "food.water")
        let label = Prim.lathe([V2(r + 0.0005, 0.108), V2(r + 0.0005, 0.136)], segments: seg, seamTile: 0.05, material: "paper.sheet:2E73C8")
        let stripe = Prim.lathe([V2(r + 0.0008, 0.118), V2(r + 0.0008, 0.126)], segments: seg, seamTile: 0.05, material: "paper.sheet:F4F7FA")
        let cap = GroceryKit.cyl(0.0155, 0.018, seg: seg, capColor, bevel: 0.002)
        let W = Float(columns) * pitch, D = Float(rows) * pitch
        for c in 0..<columns { for rIdx in 0..<rows {
            let p = V3(-W / 2 + pitch * (Float(c) + 0.5), 0, -D / 2 + pitch * (Float(rIdx) + 0.5))
            m.add(bottle, Xform(translation: p)); m.add(water, Xform(translation: p))
            m.add(label, Xform(translation: p)); m.add(stripe, Xform(translation: p))
            m.add(cap, Xform(translation: p + V3(0, 0.182, 0)))
        }}
        // Shrink film: clear sleeve with a printed band and carry slot.
        GroceryKit.box(&m, V3(W + 0.004, h - 0.01, D + 0.004), V3(0, (h - 0.01) / 2, 0), "plastic.clear", r: 0.02)
        GroceryKit.decal(&m, W * 0.7, 0.05, V3(0, 0.07, D / 2 + 0.0035), "plastic.gloss:2E73C8")
        GroceryKit.print(&m, "CLEARSPRING", height: 0.018, at: V3(0, 0.061, D / 2 + 0.0038), "paper.sheet:FFFFFF", maxWidth: W * 0.62)
        GroceryKit.print(&m, "12 X 500 ML", height: 0.01, at: V3(0, 0.03, D / 2 + 0.0036), "plastic.gloss:2E73C8")
        return m
    }
}
