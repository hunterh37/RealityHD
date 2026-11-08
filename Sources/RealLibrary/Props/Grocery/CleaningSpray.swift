import simd
import Foundation

/// 32 oz trigger spray cleaner, 28 cm: oval translucent PET bottle showing blue liquid, a white trigger
/// sprayer with shroud, lever trigger and nozzle, and a front label with the invented brand SHINEWELL.
public struct CleaningSpray: RealAsset {
    public static let id = "cleaning-spray"
    public static let summary = "Trigger spray cleaner bottle, 28 cm: oval translucent bottle with blue liquid, white trigger sprayer and nozzle, front label."
    public static let tags = ["prop", "grocery", "plastic", "container", "home", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.3, studio: true)

    public var liquid: MaterialKey = "plastic.translucent:3A9FD8"
    public var sprayer: MaterialKey = "plastic.matte:F2F2EE"
    public var brand = "SHINEWELL"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 28 : 12, sq = V3(1, 1, 0.6)
        let prof: [V2] = [V2(0, 0.003), V2(0.04, 0), V2(0.048, 0.008), V2(0.05, 0.03), V2(0.048, 0.13), V2(0.044, 0.16), V2(0.03, 0.18),
                          V2(0.016, 0.195), V2(0.0145, 0.21), V2(0, 0.21)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.05, material: liquid), Xform(scale: sq))
        m.add(Prim.lathe([V2(0.0495 + 0.0008, 0.035), V2(0.0485 + 0.0008, 0.125)], segments: seg, seamTile: 0.05, material: "paper.sheet:F7F8FA"), Xform(scale: sq))
        // Sprayer: collar, shroud, nozzle, trigger.
        m.add(GroceryKit.cyl(0.018, 0.02, seg: seg, sprayer, bevel: 0.002), Xform(translation: V3(0, 0.205, 0)))
        GroceryKit.box(&m, V3(0.032, 0.05, 0.075), V3(0, 0.245, 0.012), sprayer, r: 0.008)
        GroceryKit.box(&m, V3(0.02, 0.018, 0.02), V3(0, 0.255, 0.058), sprayer, r: 0.004)
        m.add(GroceryKit.cyl(0.004, 0.003, seg: 10, "plastic.matte:3A9FD8"), Xform(translation: V3(0, 0.255, 0.068), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        GroceryKit.box(&m, V3(0.016, 0.055, 0.01), V3(0, 0.205, 0.045), sprayer, r: 0.004, rot: simd_quatf(degrees: -12, axis: V3(1, 0, 0)))
        // Label print on the flat front.
        let fz: Float = 0.05 * 0.6 + 0.0012
        GroceryKit.decal(&m, 0.05, 0.02, V3(0, 0.1, fz), "paper.sheet:2E73C8")
        GroceryKit.print(&m, brand, height: 0.008, at: V3(0, 0.096, fz + 0.0003), "paper.sheet:FFFFFF", maxWidth: 0.046)
        GroceryKit.print(&m, "GLASS", height: 0.007, at: V3(0, 0.065, fz), "paper.sheet:1F4E96")
        GroceryKit.print(&m, "& SURFACE", height: 0.005, at: V3(0, 0.054, fz), "paper.sheet:1F4E96")
        return m
    }
}
