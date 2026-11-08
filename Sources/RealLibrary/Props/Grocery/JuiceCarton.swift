import simd
import Foundation

/// 64 oz gable-top orange juice carton, 9.5 x 25 x 9.5 cm: coated paperboard body, folded gable with a
/// sealed fin, an orange screw cap on a spout set in the gable slope, and a printed front with an orange
/// disc and the invented brand SUNNYRIDGE.
public struct JuiceCarton: RealAsset {
    public static let id = "juice-carton"
    public static let summary = "Gable-top orange juice carton, 25 cm: coated board body, sealed fin, screw cap spout, printed orange and invented brand."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "handheld"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.3, studio: true)

    public var size = V3(0.095, 0.25, 0.095)
    public var brand = "SUNNYRIDGE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let s = size
        GroceryKit.product(&m, .carton, size: s, at: .zero, palette: (0xE8781A, 0xFBF6EA, 0x2F7D45), hi: true)
        // Cap on the front slope of the gable.
        let slope = atan2(s.y * 0.14, s.z / 2)
        let cp = V3(0, s.y * 0.82 + s.y * 0.07, s.z * 0.25)
        m.add(GroceryKit.cyl(0.014, 0.012, seg: 16, "plastic.gloss:E8781A", bevel: 0.002), Xform(translation: cp, rotation: simd_quatf(angle: slope, axis: V3(1, 0, 0))))
        // Front print: orange with leaf, brand, product line.
        let fz = s.z / 2 + 0.0012
        let disc = Prim.lathe([V2(0, 0), V2(0.022, 0), V2(0.022, 0.0004), V2(0, 0.0004)], segments: 20, seamTile: 0.05, material: "paper.sheet:F28C1C")
        m.add(disc, Xform(translation: V3(0, s.y * 0.53, fz - 0.0004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        GroceryKit.decal(&m, 0.012, 0.007, V3(0.008, s.y * 0.53 + 0.024, fz), "paper.sheet:3E7A2A", rot: simd_quatf(degrees: 25, axis: V3(0, 0, 1)))
        GroceryKit.print(&m, brand, height: 0.009, at: V3(0, s.y * 0.7, fz + 0.0002), "paper.sheet:1A3A6E", maxWidth: s.x * 0.9)
        GroceryKit.print(&m, "ORANGE JUICE", height: 0.008, at: V3(0, s.y * 0.22, fz + 0.0002), "paper.sheet:FFFFFF", maxWidth: s.x * 0.86)
        GroceryKit.print(&m, "64 FL OZ", height: 0.005, at: V3(0, s.y * 0.06, fz + 0.0002), "paper.sheet:FFFFFF")
        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
