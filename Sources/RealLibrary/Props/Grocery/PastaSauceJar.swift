import simd
import Foundation

/// 24 oz glass pasta sauce jar, 15.5 cm: shouldered clear glass with embossed rings showing deep red marinara, gold
/// lug lid, cream label printed NONNA ROSA MARINARA with a basil band. Invented brand.
public struct PastaSauceJar: RealAsset {
    public static let id = "pasta-sauce-jar"
    public static let summary = "24 oz pasta sauce jar, 15.5 cm: shouldered glass showing marinara, gold lug lid, cream label, invented brand NONNA ROSA."
    public static let tags = ["prop", "grocery", "food", "glass", "container", "pantry", "kitchen"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var sauce: MaterialKey = "food.tomato:8E1E12"
    public var lid: MaterialKey = "paint.car-clearcoat:C9A042"
    public var brand = "NONNA ROSA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.045, seg = hi ? 28 : 10
        var g: [V2] = [V2(0, 0.003), V2(r - 0.005, 0), V2(r, 0.006)]
        if hi { g += [V2(r, 0.012), V2(r + 0.0012, 0.014), V2(r, 0.016)] }
        g += [V2(r, 0.11), V2(0.04, 0.127), V2(0.034, 0.135), V2(0.034, 0.142), V2(0, 0.142)]
        m.add(Prim.lathe(g, segments: seg, seamTile: 0.05, material: "glass.clear"))
        m.add(Prim.lathe([V2(0, 0.004), V2(r - 0.003, 0.004), V2(r - 0.0015, 0.009), V2(r - 0.0015, 0.108), V2(0.038, 0.124), V2(0, 0.124)],
                         segments: seg, seamTile: 0.05, material: sauce))
        var lp: [V2] = [V2(0, 0.155), V2(0.035, 0.155), V2(0.0365, 0.152)]
        if hi { for i in 0..<4 { let y = 0.151 - Float(i) * 0.003; lp += [V2(0.0368, y), V2(0.036, y - 0.0015)] } }
        lp += [V2(0.0365, 0.139), V2(0.0345, 0.139)]
        m.add(Prim.lathe(lp, segments: seg, seamTile: 0.05, material: lid))
        GroceryKit.band(&m, r: r + 0.0004, 0.03, 0.098, seg: seg, "paper.sheet:F2E3C4")
        GroceryKit.band(&m, r: r + 0.0006, 0.032, 0.04, seg: seg, "paper.sheet:3E7A2A")
        GroceryKit.wrapPrint(&m, brand, height: 0.01, radius: r + 0.0008, y: 0.074, "paper.sheet:9A2E24", maxWidth: 0.055)
        GroceryKit.wrapPrint(&m, "MARINARA", height: 0.009, radius: r + 0.0008, y: 0.056, "paper.sheet:1A1D22", maxWidth: 0.055)
        GroceryKit.wrapPrint(&m, "24 OZ", height: 0.004, radius: r + 0.0008, y: 0.045, "paper.sheet:3E7A2A", maxWidth: 0.03)
        return m
    }
}
