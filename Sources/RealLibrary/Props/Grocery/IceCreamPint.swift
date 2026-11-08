import simd
import Foundation

/// Pint of ice cream, 9 x 10 cm: tapered printed paperboard cup with a rolled bottom bead, a slip-on lid
/// with a printed top disc, a frost bloom near the base, and the invented brand NORTHFIELD CREAMERY
/// wrapped around the wall.
public struct IceCreamPint: RealAsset {
    public static let id = "ice-cream-pint"
    public static let summary = "Pint of ice cream, 10 cm: tapered printed paperboard cup, slip-on lid with printed top, frost bloom, invented brand."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "handheld"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 1.3, studio: true)

    public var cup: UInt32 = 0x5A2E1C
    public var accent: UInt32 = 0xF2C9D4
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 32 : 12
        let cupKey = GroceryKit.tint("paper.sheet", cup)
        m.add(Prim.lathe([V2(0, 0.003), V2(0.037, 0.002), V2(0.039, 0), V2(0.0405, 0.004), V2(0.0445, 0.088), V2(0, 0.088)],
                         segments: seg, seamTile: 0.05, material: cupKey))
        m.add(Prim.lathe([V2(0.0412 + 0.0005, 0.02), V2(0.0432 + 0.0005, 0.062)], segments: seg, seamTile: 0.05, material: GroceryKit.tint("paper.sheet", accent)))
        m.add(Prim.lathe([V2(0.0406, 0.004), V2(0.0415 + 0.0006, 0.014)], segments: seg, seamTile: 0.05, material: "plastic.frosted:EEF2F4"))
        m.add(Prim.lathe([V2(0, 0.083), V2(0.0455, 0.083), V2(0.047, 0.085), V2(0.047, 0.1), V2(0.045, 0.1015), V2(0, 0.1015)],
                         segments: seg, seamTile: 0.05, material: cupKey))
        let top = Prim.lathe([V2(0, 0), V2(0.036, 0), V2(0.036, 0.0005), V2(0, 0.0005)], segments: seg, seamTile: 0.05, material: GroceryKit.tint("paper.sheet", accent))
        m.add(top, Xform(translation: V3(0, 0.1012, 0)))
        GroceryKit.print(&m, "NORTHFIELD", height: 0.008, at: V3(0, 0.1019, 0.004), cupKey, rot: simd_quatf(degrees: -90, axis: V3(1, 0, 0)), maxWidth: 0.06)
        GroceryKit.wrapPrint(&m, "CREAMERY", height: 0.011, radius: 0.0428, y: 0.038, cupKey, maxWidth: 0.07)
        return m
    }
}
