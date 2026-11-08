import simd
import Foundation

/// 20 oz squeeze ketchup bottle, 21 cm: oval PET body showing the red ketchup, a shoulder and neck, a white
/// flip-top cap with a hinge and spout, and a white wrap label with a tomato disc and the invented brand
/// RUBYVALE.
public struct KetchupBottle: RealAsset {
    public static let id = "ketchup-bottle"
    public static let summary = "Squeeze ketchup bottle, 21 cm: oval red PET body, white flip-top cap, wrap label with tomato graphic and invented brand."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "kitchen", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 14, distance: 1.3, studio: true)

    /// Body depth as a fraction of width (oval).
    public var oval: Float = 0.64
    public var body: MaterialKey = "plastic.gloss:9E130E"
    public var brand = "RUBYVALE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 28 : 12, r: Float = 0.036
        let sq = V3(1, 1, oval)
        let prof: [V2] = [V2(0, 0.003), V2(0.03, 0), V2(r, 0.008), V2(r, 0.12), V2(0.033, 0.15), V2(0.02, 0.172), V2(0.014, 0.178), V2(0.014, 0.182), V2(0, 0.182)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.05, material: body), Xform(scale: sq))
        let lab = Prim.lathe([V2(r + 0.0006, 0.035), V2(r + 0.0006, 0.115)], segments: seg, seamTile: 0.05, material: "paper.sheet:F6F2E8")
        m.add(lab, Xform(scale: sq))
        // Cap: base, hinged flip lid, spout.
        m.add(Prim.lathe([V2(0, 0.178), V2(0.0175, 0.178), V2(0.0185, 0.2), V2(0.017, 0.205), V2(0, 0.205)], segments: seg, seamTile: 0.05,
                         material: "plastic.matte:F2F2EE"))
        GroceryKit.box(&m, V3(0.012, 0.004, 0.006), V3(0, 0.203, -0.017), "plastic.matte:F2F2EE", r: 0.0015)
        if hi { m.add(GroceryKit.cyl(0.003, 0.004, seg: 8, "plastic.matte:E2E2DE"), Xform(translation: V3(0, 0.205, 0.004))) }
        // Front print: tomato disc, brand, KETCHUP.
        let fz = r * oval + 0.001
        let disc = Prim.lathe([V2(0, 0), V2(0.014, 0), V2(0.014, 0.0004), V2(0, 0.0004)], segments: hi ? 20 : 10, seamTile: 0.05, material: "paper.sheet:C8261E")
        m.add(disc, Xform(translation: V3(0, 0.09, fz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        GroceryKit.decal(&m, 0.008, 0.004, V3(0, 0.104, fz + 0.0005), "paper.sheet:3E7A2A")
        GroceryKit.print(&m, brand, height: 0.007, at: V3(0, 0.064, fz), "paper.sheet:9E130E", maxWidth: 0.03)
        GroceryKit.print(&m, "KETCHUP", height: 0.009, at: V3(0, 0.048, fz), "paper.sheet:1A1D22", maxWidth: 0.032)
        return m
    }
}
