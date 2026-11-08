import simd
import Foundation

/// 4 lb paper sugar bag, 14 x 25 x 8 cm: pillowed white sack with a folded glued top, blue band, printed CANEBROOK
/// PURE CANE SUGAR, a crease line on hi. Invented brand.
public struct SugarBag: RealAsset {
    public static let id = "sugar-bag"
    public static let summary = "4 lb paper sugar bag, 25 cm: pillowed white sack, folded top, blue band, printed invented brand CANEBROOK."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "pantry", "kitchen"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var band: MaterialKey = "paper.sheet:1F4E96"
    public var brand = "CANEBROOK"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let W: Float = 0.14, Hb: Float = 0.225, D: Float = 0.08
        m.add(Prim.superellipsoid(V3(W, Hb, D), exponent: 7, subdivisions: hi ? 5 : 2, material: "paper.sheet:F7F6F2"), Xform(translation: V3(0, Hb / 2, 0)))
        GroceryKit.box(&m, V3(W - 0.004, 0.024, 0.026), V3(0, Hb + 0.006, 0), "paper.sheet:F7F6F2", r: 0.003)
        let fz = D / 2 + 0.0008
        GroceryKit.decal(&m, W * 0.9, 0.05, V3(0, 0.15, fz), band)
        GroceryKit.print(&m, brand, height: 0.013, at: V3(0, 0.152, fz + 0.0003), "paper.sheet:FFFFFF", maxWidth: W * 0.8)
        GroceryKit.print(&m, "PURE CANE", height: 0.01, at: V3(0, 0.1, fz), "paper.sheet:1F4E96", maxWidth: W * 0.7)
        GroceryKit.print(&m, "SUGAR", height: 0.016, at: V3(0, 0.078, fz), "paper.sheet:C8262B", maxWidth: W * 0.7)
        GroceryKit.print(&m, "4 LB", height: 0.008, at: V3(0, 0.03, fz), "paper.sheet:1A1D22")
        if hi { GroceryKit.decal(&m, W * 0.8, 0.0012, V3(0, 0.05, fz), "paper.sheet:E2E0D8", rot: simd_quatf(degrees: 4, axis: V3(0, 0, 1))) }
        return m
    }
}
