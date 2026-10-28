import simd
import Foundation

/// Espresso cup: everyday tableware, porcelain. Parts: thick-walled cup with rolled rim, unglazed foot ring, pulled loop handle, crema surface, small rim chip.
public struct EspressoCup: RealAsset {
    public static let id = "espresso-cup"
    public static let summary = "Porcelain espresso cup: thick wall, rolled rim, unglazed foot ring, loop handle, crema inside, one small rim chip."
    public static let tags = ["prop", "interior", "ceramic", "kitchen", "handheld"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, studio: true)

    /// Overall size in meters (x width, y height, z depth including the handle).
    public var size = V3(0.06, 0.05, 0.09)
    /// Glaze material.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Unglazed foot ring material.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    /// Chip patch material.
    public var chipMaterial: MaterialKey = "ceramic.porcelain-fracture"
    /// Crema colour (outer ring).
    public var crema: MaterialKey = "plastic.gloss:6B3F1E"
    /// Coffee level below the rim (m).
    public var fillDrop: Float = 0.0075
    public init() {}

    static let outer: [V2] = [V2(0, 0.0042), V2(0.014, 0.0036), V2(0.0182, 0.0014), V2(0.0198, 0.0), V2(0.0218, 0.0014), V2(0.0245, 0.008),
                              V2(0.0272, 0.021), V2(0.0292, 0.036), V2(0.0301, 0.0492)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let off = V3(0, 0, -0.0145)
        let H: Float = 0.0496, wall: Float = 0.0032, floorY: Float = 0.0068
        m.add(Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY), segments: seg, seamTile: 0.2, material: glaze), Xform(translation: off))
        m.add(Prim.lathe([V2(0.0183, 0.0006), V2(0.0198, -0.00006), V2(0.0217, 0.0014)], segments: seg, seamTile: 0.2, material: foot), Xform(translation: off))
        let y = H - fillDrop
        let r = DD1FTableware.radius(Self.outer, at: y) - wall - 0.0003
        m.add(Prim.lathe([V2(r, y + 0.0007), V2(r - 0.0022, y), V2(0.0085, y - 0.0002), V2(0.0085, y - 0.0007), V2(0, y - 0.0007)], segments: seg, seamTile: 0.2, material: crema), Xform(translation: off))
        m.add(Prim.lathe([V2(0.0086, y - 0.0002), V2(0.0035, y - 0.0003), V2(0, y - 0.0003)], segments: seg, seamTile: 0.2, material: "plastic.gloss:3A1E0C"), Xform(translation: off))
        let ctrl = [V2(0.0285, 0.0435), V2(0.042, 0.0468), V2(0.0535, 0.0398), V2(0.0548, 0.0275), V2(0.0478, 0.0182), V2(0.0238, 0.0158)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(0, 0, 1), section: V2(0.0072, 0.0046), detail: detail, material: glaze), Xform(translation: off))
        // Thumb rest bump on the handle top.
        m.add(Prim.superellipsoid(V3(0.0085, 0.0045, 0.012), exponent: 2.4, subdivisions: detail ? 4 : 2, material: glaze),
              Xform(translation: V3(0, 0.0472, 0.0385) + off))
        // Story: small chip on the rim opposite the handle, bare body showing.
        DD1FTableware.chip(&m, radius: 0.0291, y: H - 0.0003, angle: -.pi / 2 + 0.5, size: 0.0065, material: chipMaterial, off: off)
        // Story: a dried coffee drip running down the outside wall from the rim.
        let da: Float = 0.55, dy: Float = H - 0.0090
        let dr = DD1FTableware.radius(Self.outer, at: dy) + 0.00005
        m.add(Prim.superellipsoid(V3(0.0020, 0.0180, 0.0005), exponent: 2.2, subdivisions: 3, material: "plastic.gloss:7A4A28"),
              Xform(translation: V3(cos(da) * dr, dy, sin(da) * dr) + off, rotation: simd_quatf(angle: .pi / 2 - da, axis: V3(0, 1, 0))))
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(48, true), make(24, false)], switchDistances: [3])
    }
}
