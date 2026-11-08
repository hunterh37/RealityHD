import simd
import Foundation

/// 19 oz dish soap bottle, 24.5 cm: oval translucent green bottle with a tapered shoulder, white flip-top cap and nozzle,
/// front label CLEARBROOK DISH SOAP LIME, a soap drip by the cap on hi. Invented brand.
public struct DishSoapBottle: RealAsset {
    public static let id = "dish-soap-bottle"
    public static let summary = "Dish soap bottle, 24.5 cm: oval translucent green body, white flip-top cap, printed front label, invented brand CLEARBROOK."
    public static let tags = ["prop", "grocery", "plastic", "container", "kitchen", "home", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var soap: MaterialKey = "plastic.translucent:4FB04A"
    public var oval: Float = 0.6
    public var brand = "CLEARBROOK"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 24 : 10, r: Float = 0.0375
        let prof: [V2] = [V2(0, 0.003), V2(0.033, 0), V2(r, 0.01), V2(r, 0.16), V2(0.034, 0.19), V2(0.02, 0.21), V2(0.012, 0.215), V2(0.012, 0.222), V2(0, 0.222)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.05, material: soap), Xform(scale: V3(1, 1, oval)))
        m.add(Prim.lathe([V2(0, 0.218), V2(0.0135, 0.218), V2(0.014, 0.238), V2(0.011, 0.243), V2(0, 0.243)], segments: seg, seamTile: 0.05,
                         material: "plastic.matte:F2F2EE"))
        GroceryKit.box(&m, V3(0.006, 0.006, 0.012), V3(0, 0.244, 0.004), "plastic.matte:F2F2EE", r: 0.002)
        let fz = r * oval + 0.0008
        GroceryKit.decal(&m, 0.058, 0.085, V3(0, 0.095, fz), "paper.sheet:F7F6F0")
        GroceryKit.print(&m, brand, height: 0.008, at: V3(0, 0.115, fz + 0.0003), "paper.sheet:2F7D45", maxWidth: 0.054)
        GroceryKit.print(&m, "DISH SOAP", height: 0.007, at: V3(0, 0.098, fz + 0.0003), "paper.sheet:1A1D22", maxWidth: 0.052)
        GroceryKit.decal(&m, 0.058, 0.012, V3(0, 0.075, fz + 0.0002), "paper.sheet:C6D93A")
        GroceryKit.print(&m, "LIME", height: 0.006, at: V3(0, 0.072, fz + 0.0004), "paper.sheet:2F7D45")
        if hi { GroceryKit.decal(&m, 0.004, 0.016, V3(0.004, 0.207, 0.0135 * oval + 0.002), "plastic.translucent:6CC85E") }
        return m
    }
}
