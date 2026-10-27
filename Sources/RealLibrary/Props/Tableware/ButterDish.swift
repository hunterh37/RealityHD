import simd
import Foundation

/// Ceramic butter dish with a glass dome: a rounded rectangular tray with a flat seat ledge and an unglazed
/// foot, a thick-lipped glass dome with a ball knob, a butter block with a knife-cut end and drag marks, crumbs,
/// a scuffed glass lip and a chipped tray rim.
public struct ButterDish: RealAsset {
    public static let id = "butter-dish"
    public static let summary = "Ceramic butter dish with a glass dome, butter block with a knife-cut end, crumbs, scuffed glass lip and tray chip."
    public static let tags = ["prop", "interior", "tableware", "ceramic", "glass"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 28, studio: true)

    /// Tray glaze.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Dome glass.
    public var glass: MaterialKey = "glass.clear"
    /// Butter.
    public var butter: MaterialKey = "food.cream:EFD98A"
    public init() {}

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 41)
        var m = Model(name: Self.id)
        let n = detail ? 10 : 5
        let o: (Float) -> [V2] = { _ in Shape2D.roundedRect(0.18, 0.11, radius: 0.020, segments: n) }
        // Tray: recess ceiling, foot ring, flared wall, wide seat ledge, inner wall, floor.
        let tray: [(Float, Float, Float)] = [
            (0.050, 0.0050, 0), (0.020, 0.0050, 0), (0.0145, 0.0035, 0), (0.0120, 0.0006, 0), (0.0100, 0, 0), (0.0080, 0.0006, 0),
            (0.0055, 0.0030, 0), (0.0030, 0.0090, 0), (0.0008, 0.0150, 0), (0.0, 0.0172, 0), (0.0006, 0.0188, 0), (0.0022, 0.0195, 0),
            (0.0130, 0.0192, 0), (0.0140, 0.0170, 0), (0.0150, 0.0110, 0), (0.0165, 0.0070, 0), (0.0200, 0.0058, 0), (0.050, 0.0056, 0),
        ]
        m.add(DD1GWare.loft(o, tray, capStart: true, capEnd: true, material: glaze))
        let foot: [(Float, Float, Float)] = [(0.0120, -0.00005, 0), (0.0080, -0.00005, 0), (0.0080, 0.0003, 0), (0.0120, 0.0003, 0), (0.0120, -0.00005, 0)]
        m.add(DD1GWare.loft(o, foot, material: DD1GWare.bisque))
        // Glass dome: outer skin closed at the top, inner skin hung below it, lip annulus between them.
        let g = glass
        let outer: [(Float, Float, Float)] = [
            (0.0065, 0.0196, 0), (0.0033, 0.0196, 0), (0.0033, 0.0300, 0), (0.0042, 0.0400, 0), (0.0070, 0.0490, 0), (0.0125, 0.0560, 0),
            (0.0215, 0.0592, 0), (0.0340, 0.0604, 0), (0.0450, 0.0607, 0),
        ]
        m.add(DD1GWare.loft(o, outer, capEnd: true, material: g))
        let inner: [(Float, Float, Float)] = [
            (0.0450, 0.0577, 0), (0.0340, 0.0574, 0), (0.0245, 0.0562, 0), (0.0165, 0.0535, 0), (0.0105, 0.0480, 0), (0.0080, 0.0410, 0),
            (0.0066, 0.0300, 0), (0.0065, 0.0196, 0),
        ]
        m.add(DD1GWare.loft(o, inner, capStart: true, material: g))
        // Scuffed frosted band on the glass lip.
        m.add(DD1GWare.loft(o, [(0.0030, 0.0198, 0), (0.0030, 0.0252, 0)], material: "glass.frosted"))
        // Knob: neck and ball.
        m.add(DD1GWare.lathe(Profile.smooth([V2(0, 0.0603), V2(0.0050, 0.0603), V2(0.0048, 0.0620), V2(0.0072, 0.0640), V2(0.0086, 0.0662),
                                             V2(0.0074, 0.0686), V2(0.0042, 0.0700), V2(0, 0.0705)], per: detail ? 3 : 1), segs: detail ? 28 : 14, g))
        // Butter block with a slanted knife cut at +X, resting on the tray floor.
        let prof: [V2] = [V2(-0.050, 0), V2(0.050, 0), V2(0.0405, 0.031), V2(-0.050, 0.031)]
        var blk = Prim.extrude(prof, depth: 0.044, bevel: 0.0022, bevelSegments: 2, material: butter)
        blk = blk.transformed(Xform(rotation: simd_quatf(degrees: 0, axis: V3(0, 1, 0))))
        m.add(blk, Xform(translation: V3(-0.004, 0.0056, 0)))
        // Knife drag marks across the top and a scraped curl.
        for i in 0..<4 {
            m.add(Prim.roundedBox(V3(rng.float(0.05...0.085), 0.0004, 0.0012), radius: 0.0002, bevelSegments: 1, material: "food.cream:D8BB5F"),
                  Xform(translation: V3(-0.010 + rng.float(-0.006...0.006), 0.0369, -0.015 + 0.010 * Float(i)), rotation: simd_quatf(degrees: rng.float(-2...2), axis: V3(0, 1, 0))))
        }
        // Crumbs on the tray floor.
        DD1GWare.grains(&m, &rng, center: V3(0.058, 0.0056, 0.030), radiusMin: 0.0, radiusMax: 0.010, count: detail ? 8 : 3, size: 0.0024, material: "food.bread-crumb")
        // Chip on the tray seat ledge.
        DD1GWare.chip(&m, at: V3(0.0585, 0.0198, -0.0535), size: 0.0060, yaw: 20)
        DD1GWare.chip(&m, at: V3(-0.0889, 0.0198, 0.0070), size: 0.0030, yaw: 90)
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.010, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 48, detail: true), level(segs: 24, detail: false)], switchDistances: [3])
    }
}
