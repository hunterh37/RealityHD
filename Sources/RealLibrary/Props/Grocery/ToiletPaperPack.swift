import simd
import Foundation

/// 12-roll toilet paper pack, 33 x 21 x 22 cm: rolls three wide, two deep, two high with cardboard cores, clear poly
/// overwrap with a printed brand band SOFTCLOUD and a carry strap. Invented brand.
public struct ToiletPaperPack: RealAsset {
    public static let id = "toilet-paper-pack"
    public static let summary = "12-roll toilet paper pack, 21 cm: rolls with cores in a clear printed overwrap, carry strap, invented brand SOFTCLOUD."
    public static let tags = ["prop", "grocery", "paper", "plastic", "bathroom", "home"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var band: MaterialKey = "plastic.gloss:6B9BD6"
    public var brand = "SOFTCLOUD"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.055, h: Float = 0.105, seg = hi ? 18 : 8
        let roll = Prim.lathe([V2(0.021, 0.002), V2(r - 0.003, 0), V2(r, 0.004), V2(r, h - 0.004), V2(r - 0.003, h), V2(0.021, h - 0.002)],
                              segments: seg, seamTile: 0.05, material: "paper.sheet:F9F8F4")
        let core = Prim.lathe([V2(0.021, h - 0.002), V2(0.019, h - 0.004), V2(0, h - 0.004)], segments: seg, seamTile: 0.05, material: "paper.screwbox-kraft")
        let W = 6 * r, D = 4 * r
        for c in 0..<3 { for k in 0..<2 { for l in 0..<2 {
            let p = V3(-W / 2 + r * (2 * Float(c) + 1), Float(l) * h, -D / 2 + r * (2 * Float(k) + 1))
            m.add(roll, Xform(translation: p))
            if l == 1 || hi { m.add(core, Xform(translation: p)) }
        }}}
        let T = 2 * h
        GroceryKit.box(&m, V3(W + 0.006, T + 0.004, D + 0.006), V3(0, (T + 0.004) / 2, 0), "plastic.clear", r: 0.03)
        GroceryKit.decal(&m, W * 0.86, 0.075, V3(0, T * 0.5, D / 2 + 0.0035), band)
        GroceryKit.print(&m, brand, height: 0.026, at: V3(0, T * 0.5 - 0.004, D / 2 + 0.0038), "paper.sheet:FFFFFF", maxWidth: W * 0.7)
        GroceryKit.print(&m, "12 DOUBLE ROLLS", height: 0.011, at: V3(0, T * 0.5 - 0.03, D / 2 + 0.0038), "paper.sheet:1F3F7A", maxWidth: W * 0.6)
        GroceryKit.box(&m, V3(0.04, 0.004, D + 0.012), V3(0, T + 0.006, 0), "plastic.translucent:E8E8E4", r: 0.0015)
        GroceryKit.box(&m, V3(0.04, 0.03, 0.06), V3(0, T + 0.022, 0), "plastic.translucent:E8E8E4", r: 0.008)
        return m
    }
}
