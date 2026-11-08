import simd
import Foundation

/// 16 oz energy drink can, 66 x 157 mm: tall aluminum can with necked shoulder and stay-on tab, black coating with a
/// neon green slash band, printed RAVAGE ENERGY, condensation beads on hi. Invented brand.
public struct EnergyDrinkCan: RealAsset {
    public static let id = "energy-drink-can"
    public static let summary = "16 oz energy drink can, 15.7 cm: tall aluminum can, black coating with neon band, stay-on tab, condensation, invented brand RAVAGE."
    public static let tags = ["prop", "grocery", "food", "metal", "aluminium", "container", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0x101214
    public var accent: UInt32 = 0x7CFF3A
    public var brand = "RAVAGE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.033, h: Float = 0.157, seg = hi ? 32 : 12
        let body: [V2] = [V2(0, 0.006), V2(0.02, 0.0), V2(0.0255, 0.0), V2(0.03, 0.004), V2(r, 0.012), V2(r, h - 0.019), V2(0.0305, h - 0.01),
                          V2(0.027, h - 0.0035), V2(0.0268, h - 0.0015), V2(0.027, h), V2(0.0255, h), V2(0.0245, h - 0.0045), V2(0, h - 0.0048)]
        m.add(Prim.lathe(body, segments: seg, seamTile: 0.05, material: "metal.aluminum"))
        m.add(Prim.lathe([V2(r + 0.0002, 0.013), V2(r + 0.0002, h - 0.02), V2(0.0306, h - 0.011)], segments: seg, seamTile: 0.05,
                         material: GroceryKit.tint("paint.car-clearcoat", color)))
        GroceryKit.band(&m, r: r + 0.0004, 0.05, 0.058, seg: seg, GroceryKit.tint("paint.car-clearcoat", accent))
        GroceryKit.band(&m, r: r + 0.0004, 0.118, 0.121, seg: seg, GroceryKit.tint("paint.car-clearcoat", accent))
        GroceryKit.wrapPrint(&m, brand, height: 0.02, radius: r + 0.0006, y: 0.08, GroceryKit.tint("paint.car-clearcoat", accent), maxWidth: 0.044)
        GroceryKit.wrapPrint(&m, "ENERGY", height: 0.008, radius: r + 0.0006, y: 0.064, "paint.car-clearcoat:F4F4F0", maxWidth: 0.05)
        GroceryKit.wrapPrint(&m, "16 FL OZ", height: 0.004, radius: r + 0.0006, y: 0.02, "paint.car-clearcoat:B8BCC2", maxWidth: 0.03)
        GroceryKit.box(&m, V3(0.014, 0.0012, 0.022), V3(0, h - 0.0035, 0.006), "metal.aluminum", r: 0.0005)
        if hi { GroceryKit.droplets(&m, radius: r + 0.0004, 0.015, 0.13, count: 24, seed: 41) }
        return m
    }
}
