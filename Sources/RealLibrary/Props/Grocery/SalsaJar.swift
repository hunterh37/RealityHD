import simd
import Foundation

/// 16 oz glass salsa jar, 12 cm: clear glass with a shoulder showing chunky red salsa, lug lid with a printed top,
/// cream wrap label printed SOL VERDE SALSA MEDIUM with a chili band. Invented brand.
public struct SalsaJar: RealAsset {
    public static let id = "salsa-jar"
    public static let summary = "16 oz glass salsa jar, 12 cm: clear glass showing red salsa, green lug lid, wrap label with invented brand SOL VERDE."
    public static let tags = ["prop", "grocery", "food", "glass", "container", "pantry", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var salsa: MaterialKey = "food.tomato:B8401E"
    public var lid: MaterialKey = "paint.car-clearcoat:2F7D45"
    public var brand = "SOL VERDE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.042, seg = hi ? 28 : 10
        m.add(Prim.lathe([V2(0, 0.002), V2(r - 0.004, 0), V2(r, 0.005), V2(r, 0.09), V2(0.036, 0.1), V2(0.035, 0.112), V2(0, 0.112)],
                         segments: seg, seamTile: 0.05, material: "glass.clear"))
        m.add(Prim.lathe([V2(0, 0.004), V2(r - 0.003, 0.004), V2(r - 0.0015, 0.008), V2(r - 0.0015, 0.088), V2(0.034, 0.096), V2(0, 0.096)],
                         segments: seg, seamTile: 0.05, material: salsa))
        var lp: [V2] = [V2(0, 0.124), V2(0.036, 0.124), V2(0.0375, 0.121)]
        if hi { for i in 0..<4 { let y = 0.12 - Float(i) * 0.0032; lp += [V2(0.0378, y), V2(0.037, y - 0.0016)] } }
        lp += [V2(0.0375, 0.108), V2(0.0355, 0.108)]
        m.add(Prim.lathe(lp, segments: seg, seamTile: 0.05, material: lid))
        GroceryKit.band(&m, r: r + 0.0004, 0.022, 0.078, seg: seg, "paper.sheet:F6F0DE")
        GroceryKit.band(&m, r: r + 0.0006, 0.024, 0.032, seg: seg, "paper.sheet:2F7D45")
        GroceryKit.wrapPrint(&m, brand, height: 0.009, radius: r + 0.0008, y: 0.058, "paper.sheet:C8262B", maxWidth: 0.05)
        GroceryKit.wrapPrint(&m, "SALSA", height: 0.008, radius: r + 0.0008, y: 0.044, "paper.sheet:1A1D22", maxWidth: 0.045)
        GroceryKit.wrapPrint(&m, "MEDIUM", height: 0.004, radius: r + 0.0008, y: 0.0365, "paper.sheet:C8262B", maxWidth: 0.04)
        if hi { m.add(GroceryKit.text("SOL", height: 0.008, material: "paper.sheet:F6F0DE"), Xform(translation: V3(0, 0.1245, 0.004), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))) }
        return m
    }
}
