import simd
import Foundation

/// 15 oz steel food can, 76 x 111 mm: rolled double seams, concentric lid rings, a green paper wrap label with a pea panel,
/// printed brand GREENFIELD and SWEET PEAS, net weight band. Invented brand.
public struct CannedVegetables: RealAsset {
    public static let id = "canned-vegetables"
    public static let summary = "15 oz food can, 11 cm: steel body with double seams and lid rings, green wrap label printed SWEET PEAS, invented brand."
    public static let tags = ["prop", "grocery", "food", "metal", "steel", "container", "pantry", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var label: UInt32 = 0x2F7D45
    public var brand = "GREENFIELD"
    public var product = "SWEET PEAS"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.038, h: Float = 0.111, seg = hi ? 32 : 12
        var prof: [V2] = [V2(0, 0.004), V2(r - 0.006, 0.003), V2(r - 0.002, 0), V2(r + 0.0008, 0.002), V2(r, 0.006), V2(r, h - 0.006),
                          V2(r + 0.0008, h - 0.002), V2(r - 0.001, h)]
        if hi { prof += [V2(r - 0.004, h - 0.003), V2(r - 0.008, h - 0.002), V2(r - 0.012, h - 0.0032), V2(r - 0.018, h - 0.002), V2(r - 0.024, h - 0.0032)] }
        prof += [V2(0, h - 0.003)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.05, material: "metal.aluminum"))
        GroceryKit.band(&m, r: r + 0.0004, 0.008, h - 0.008, seg: seg, GroceryKit.tint("paper.sheet", label))
        GroceryKit.band(&m, r: r + 0.0006, 0.012, 0.024, seg: seg, "paper.sheet:F3EFD9")
        GroceryKit.wrapPanel(&m, w: 0.05, h: 0.034, radius: r, y: 0.05, "paper.sheet:9BC45A")
        if hi {
            for (i, a) in [Float(-0.012), 0, 0.012].enumerated() {
                m.add(Prim.superellipsoid(V3(0.011, 0.011, 0.006), exponent: 2, subdivisions: 2, material: "paper.sheet:4E8F2A"),
                      Xform(translation: V3(a, 0.062 + Float(i % 2) * 0.008, r + 0.0018)))
            }
        }
        GroceryKit.wrapPrint(&m, brand, height: 0.008, radius: r + 0.0012, y: 0.088, "paper.sheet:F6F1E4", maxWidth: 0.046)
        GroceryKit.wrapPrint(&m, product, height: 0.007, radius: r + 0.0012, y: 0.04, "paper.sheet:F2C230", maxWidth: 0.046)
        GroceryKit.wrapPrint(&m, "NET WT 15 OZ", height: 0.0045, radius: r + 0.0012, y: 0.0155, "paper.sheet:2F7D45", maxWidth: 0.05)
        return m
    }
}
