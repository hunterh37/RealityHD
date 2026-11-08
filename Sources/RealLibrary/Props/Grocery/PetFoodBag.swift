import simd
import Foundation

/// 4 lb dry dog food bag, 24 x 33 x 9 cm: pillowed laminated bag with a crimped heat-seal top and gusset base, white
/// front panel with kibble, printed HEARTH HOUND DOG FOOD CHICKEN & RICE. Invented brand.
public struct PetFoodBag: RealAsset {
    public static let id = "pet-food-bag"
    public static let summary = "4 lb dry dog food bag, 33 cm: laminated bag with crimped top seal, kibble panel, printed invented brand HEARTH HOUND."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "home"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var body: MaterialKey = "plastic.gloss:8A1F2C"
    public var brand = "HEARTH HOUND"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let W: Float = 0.24, Hb: Float = 0.31, D: Float = 0.09
        m.add(Prim.superellipsoid(V3(W, Hb, D), exponent: 6, subdivisions: hi ? 6 : 2, material: body), Xform(translation: V3(0, Hb / 2, 0)))
        GroceryKit.box(&m, V3(W - 0.006, 0.024, 0.01), V3(0, Hb + 0.008, 0), body, r: 0.002)
        let fz = D / 2 + 0.0008
        if hi { for i in 0..<10 { GroceryKit.decal(&m, 0.0012, 0.018, V3(-W / 2 + 0.02 + Float(i) * 0.022, Hb + 0.009, 0.0051), "plastic.gloss:5E141E") } }
        GroceryKit.decal(&m, W * 0.8, 0.13, V3(0, 0.15, fz), "paper.sheet:F6F1E4")
        GroceryKit.print(&m, brand, height: 0.018, at: V3(0, 0.248, fz), "paper.sheet:F2C230", maxWidth: W * 0.84)
        GroceryKit.print(&m, "DOG FOOD", height: 0.014, at: V3(0, 0.19, fz + 0.0003), "paper.sheet:8A1F2C", maxWidth: W * 0.7)
        GroceryKit.print(&m, "CHICKEN & RICE", height: 0.008, at: V3(0, 0.172, fz + 0.0003), "paper.sheet:3A2214", maxWidth: W * 0.7)
        GroceryKit.print(&m, "4 LB", height: 0.012, at: V3(0, 0.035, fz), "paper.sheet:FFFFFF")
        let kibble = Prim.superellipsoid(V3(0.012, 0.01, 0.006), exponent: 2.5, subdivisions: hi ? 2 : 1, material: "food.tomato:7A4A22")
        for i in 0..<(hi ? 9 : 3) {
            m.add(kibble, Xform(translation: V3(-0.05 + Float(i % 5) * 0.025, 0.11 + Float(i / 5) * 0.016, fz + 0.002), rotation: simd_quatf(degrees: Float(i) * 37, axis: V3(0, 0, 1))))
        }
        return m
    }
}
