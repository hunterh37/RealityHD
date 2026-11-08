import simd
import Foundation

/// 355 ml aluminum soda can, 66 x 122 mm: domed base on a stand ring, straight wall, necked shoulder,
/// seamed lid with a stay-on tab, printed red coating with a white wave band and a vertical wordmark of
/// the invented brand FIZZO.
public struct SodaCan: RealAsset {
    public static let id = "soda-can"
    public static let summary = "355 ml aluminum soda can, 12 cm: necked shoulder, seamed lid with stay-on tab, red printed coating with white band."
    public static let tags = ["prop", "grocery", "food", "metal", "aluminium", "container", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 1.3, studio: true)

    public var color: UInt32 = 0xB01E23
    public var brand = "FIZZO"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.033, seg = hi ? 32 : 12
        let body: [V2] = [V2(0, 0.006), V2(0.02, 0.0), V2(0.0255, 0.0), V2(0.03, 0.004), V2(r, 0.012), V2(r, 0.103), V2(0.0305, 0.112),
                          V2(0.027, 0.1185), V2(0.0268, 0.1205), V2(0.027, 0.122), V2(0.0255, 0.122), V2(0.0245, 0.1175), V2(0, 0.1172)]
        m.add(Prim.lathe(body, segments: seg, seamTile: 0.05, material: "metal.aluminum"))
        let coat = GroceryKit.tint("paint.car-clearcoat", color)
        m.add(Prim.lathe([V2(r + 0.0002, 0.013), V2(r + 0.0002, 0.102), V2(0.0306, 0.111)], segments: seg, seamTile: 0.05, material: coat))
        m.add(Prim.lathe([V2(r + 0.0004, 0.088), V2(r + 0.0004, 0.095)], segments: seg, seamTile: 0.05, material: "paint.car-clearcoat:F4F4F0"))
        // Vertical wordmark wrapped on the wall.
        let word = GroceryKit.text(brand, height: 0.013, material: "paint.car-clearcoat:F4F4F0")
        var vert = Surface(material: word.material)
        vert.append(word, Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        m.add(GroceryKit.wrap(vert, radius: r + 0.0006), Xform(translation: V3(0, 0.05, 0)))
        // Tab and rivet.
        GroceryKit.box(&m, V3(0.018, 0.0012, 0.03), V3(0, 0.1182, 0.004), "metal.aluminum-brushed", r: 0.0005)
        m.add(GroceryKit.cyl(0.0025, 0.0012, seg: 8, "metal.aluminum"), Xform(translation: V3(0, 0.1176, 0)))
        if hi { GroceryKit.box(&m, V3(0.013, 0.0006, 0.016), V3(0, 0.1176, -0.011), "metal.aluminum-brushed", r: 0.0002) }
        return m
    }
}
