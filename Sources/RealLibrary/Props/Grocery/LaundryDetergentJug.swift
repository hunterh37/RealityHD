import simd
import Foundation

/// 150 oz liquid laundry detergent jug, 20 x 30 x 13 cm: rounded HDPE body, integrated rear handle, offset spout with a
/// measuring cap, front label printed BRIGHTWAVE, a drip mark under the spout. Invented brand.
public struct LaundryDetergentJug: RealAsset {
    public static let id = "laundry-detergent-jug"
    public static let summary = "Liquid laundry detergent jug, 30 cm: rounded HDPE body, rear handle, spout with measuring cap, printed front label, invented brand."
    public static let tags = ["prop", "grocery", "plastic", "container", "laundry", "home"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var body: MaterialKey = "plastic.gloss:E8742A"
    public var cap: MaterialKey = "plastic.gloss:1F4E96"
    public var brand = "BRIGHTWAVE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let W: Float = 0.2, Hb: Float = 0.27, D: Float = 0.13, seg = hi ? 20 : 10
        m.add(Prim.superellipsoid(V3(W, Hb, D), exponent: 6, subdivisions: hi ? 6 : 3, material: body), Xform(translation: V3(0, Hb / 2, 0)))
        // Handle: grip bar and two posts at the rear top corner.
        GroceryKit.box(&m, V3(0.075, 0.024, 0.03), V3(0.055, Hb + 0.026, -0.01), body, r: 0.01)
        GroceryKit.box(&m, V3(0.022, 0.04, 0.03), V3(0.085, Hb + 0.006, -0.01), body, r: 0.008)
        GroceryKit.box(&m, V3(0.022, 0.03, 0.03), V3(0.024, Hb + 0.004, -0.01), body, r: 0.008)
        // Spout neck and measuring cap.
        m.add(GroceryKit.cyl(0.022, 0.03, seg: seg, body), Xform(translation: V3(-0.055, Hb - 0.01, 0.005)))
        m.add(Prim.lathe([V2(0, Hb + 0.012), V2(0.029, Hb + 0.012), V2(0.031, Hb + 0.05), V2(0.028, Hb + 0.055), V2(0, Hb + 0.055)], segments: seg,
                         seamTile: 0.05, material: cap), Xform(translation: V3(-0.055, 0, 0.005)))
        let fz = D / 2 + 0.0008
        GroceryKit.decal(&m, 0.13, 0.13, V3(-0.005, 0.12, fz), "paper.sheet:F7F6F0")
        GroceryKit.decal(&m, 0.13, 0.03, V3(-0.005, 0.165, fz + 0.0002), "paper.sheet:1F4E96")
        GroceryKit.print(&m, brand, height: 0.016, at: V3(-0.005, 0.157, fz + 0.0005), "paper.sheet:FFFFFF", maxWidth: 0.12)
        GroceryKit.print(&m, "ULTRA CLEAN", height: 0.01, at: V3(-0.005, 0.12, fz + 0.0005), "paper.sheet:E8742A", maxWidth: 0.11)
        GroceryKit.print(&m, "64 LOADS", height: 0.009, at: V3(-0.005, 0.07, fz + 0.0005), "paper.sheet:1A1D22", maxWidth: 0.1)
        if hi {
            GroceryKit.decal(&m, 0.006, 0.03, V3(-0.06, Hb - 0.03, fz - 0.003), "plastic.gloss:3A6FC8")
            GroceryKit.decal(&m, 0.04, 0.012, V3(-0.005, 0.087, fz + 0.0003), "paper.sheet:F2C230")
        }
        return m
    }
}
