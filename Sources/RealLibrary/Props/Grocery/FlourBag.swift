import simd
import Foundation

/// 5 lb paper flour bag, 16 x 27 x 9 cm: pillowed kraft-white sack with a folded and glued top, red band, wheat panel,
/// printed MILLSTONE ALL PURPOSE FLOUR, flour dust at the base on hi. Invented brand.
public struct FlourBag: RealAsset {
    public static let id = "flour-bag"
    public static let summary = "5 lb paper flour bag, 27 cm: pillowed sack with folded top, red band, wheat panel, printed invented brand MILLSTONE."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "pantry", "kitchen"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var paper: MaterialKey = "paper.sheet:F4EFE2"
    public var band: MaterialKey = "paper.sheet:C8262B"
    public var brand = "MILLSTONE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let W: Float = 0.16, Hb: Float = 0.245, D: Float = 0.09
        m.add(Prim.superellipsoid(V3(W, Hb, D), exponent: 6, subdivisions: hi ? 5 : 2, material: paper), Xform(translation: V3(0, Hb / 2, 0)))
        GroceryKit.box(&m, V3(W - 0.004, 0.028, 0.03), V3(0, Hb + 0.008, 0), paper, r: 0.003)
        GroceryKit.box(&m, V3(W - 0.006, 0.012, 0.034), V3(0, Hb + 0.024, 0.002), paper, r: 0.002)
        let fz = D / 2 + 0.0008
        GroceryKit.decal(&m, W * 0.86, 0.03, V3(0, 0.185, fz), band)
        GroceryKit.print(&m, brand, height: 0.014, at: V3(0, 0.178, fz + 0.0003), "paper.sheet:F6F1E4", maxWidth: W * 0.78)
        GroceryKit.decal(&m, W * 0.6, 0.06, V3(0, 0.12, fz), "paper.sheet:E3C77E")
        GroceryKit.print(&m, "ALL PURPOSE", height: 0.009, at: V3(0, 0.124, fz + 0.0003), "paper.sheet:7A2E1A", maxWidth: W * 0.55)
        GroceryKit.print(&m, "FLOUR", height: 0.016, at: V3(0, 0.098, fz + 0.0003), "paper.sheet:7A2E1A", maxWidth: W * 0.55)
        GroceryKit.print(&m, "5 LB", height: 0.008, at: V3(0, 0.04, fz + 0.0003), "paper.sheet:1A1D22")
        if hi {
            GroceryKit.decal(&m, W * 0.7, 0.012, V3(0, 0.012, fz), "paper.sheet:FBFAF6")
            GroceryKit.decal(&m, W * 0.97, 0.0015, V3(0, Hb + 0.022, 0.017 + 0.0006), GroceryKit.tint("paper.sheet", 0xCFC6B0))
        }
        return m
    }
}
