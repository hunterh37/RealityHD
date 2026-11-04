import simd
import Foundation

/// Toilet paper holder: everyday bathroom, chrome. Parts: two wall flanges, two arms, spring roller bar, screw heads.
public struct ToiletPaperHolder: RealAsset {
    public static let id = "toilet-paper-holder"
    public static let summary = "Wall toilet paper holder: two chrome flanges and arms with a roller bar between."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 4000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.15, 0.08, 0.12)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var rod: MaterialKey = "metal.stainless"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let wall = -size.z / 2
        let ax = size.x / 2 - 0.0085
        for sx: Float in [-1, 1] {
            // Wall flange, rounded plate with two slotted screw heads.
            m.add(Prim.roundedBox(V3(0.01, 0.08, 0.007), radius: 0.003, bevelSegments: 2, material: chrome), Xform(translation: V3(sx * ax, 0.04, wall + 0.0035)))
            for y: Float in [0.02, 0.06] {
                Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0028, 0.0), V2(0.0026, 0.0014), V2(0.0014, 0.0022), V2(0.001, 0.0022)], rod, seg: 14, at: V3(sx * ax, y, wall + 0.007), rot: simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0)))
            }
            // Arm: rounded bar projecting forward from the flange.
            m.add(Prim.roundedBox(V3(0.009, 0.026, size.z - 0.014), radius: 0.0038, bevelSegments: 3, material: chrome), Xform(translation: V3(sx * ax, 0.04, wall + 0.007 + (size.z - 0.014) / 2)))
            // Round end cap on the arm tip.
            Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0058, 0.0), V2(0.0058, 0.0015), V2(0.0035, 0.0035), V2(0.001, 0.0038)], chrome, seg: 16,
                           at: V3(sx * (ax + 0.0045), 0.04, wall + size.z - 0.0075), rot: simd_quatf(angle: sx * -Float.pi / 2, axis: V3(0, 0, 1)))
        }
        // Spring roller bar between the arms, 0.07 m from the wall.
        let bz = wall + 0.075
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0048, 0.0), V2(0.0048, 2 * ax - 0.009), V2(0.001, 2 * ax - 0.009)], rod, seg: 20,
                       at: V3(ax - 0.0045, 0.04, bz), rot: simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1)))
        // Spring-loaded end collars on the bar.
        for sx: Float in [-1, 1] {
            Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0062, 0.0), V2(0.0062, 0.012), V2(0.001, 0.012)], chrome, seg: 20,
                           at: V3(sx * (ax - 0.0045), 0.04, bz), rot: simd_quatf(angle: sx * -Float.pi / 2, axis: V3(0, 0, 1)))
        }
        // Water-spot film on the lower arm edges.
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0092, 0.0012, 0.03), radius: 0.0004, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(sx * ax, 0.0275, wall + 0.04)))
        }
        // Dull, smudged strips along the arm tops where hands rest.
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0072, 0.0008, 0.06), radius: 0.0003, bevelSegments: 1, material: "metal.stainless-smudged"), Xform(translation: V3(sx * ax, 0.0535, wall + 0.06)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
