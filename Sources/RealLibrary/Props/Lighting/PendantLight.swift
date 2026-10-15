import simd
import Foundation

/// 450 mm dome pendant, authored in place: the canopy top touches the ceiling plane at y = 2.6 and the shade rim
/// hangs at y = 1.7. Spun enamel dome with a rolled rim and white reflector, brass socket neck, fabric cord with a
/// cord grip, round canopy with set screw, clear globe bulb with a lit filament.
public struct PendantLight: RealAsset {
    public static let id = "pendant-light"
    public static let summary = "Dome pendant light: enamel metal shade, glass bulb, fabric cord and ceiling canopy."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "light", "metal", "glass"]
    public static let budget = 4400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: -28, distance: 1.25, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.45, 0.9, 0.45)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Shade enamel color.
    public var shadeColor: UInt32 = 0x1F3A33
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let top = ceilingY, bottom = ceilingY - size.y
        let R = size.x / 2
        let enamel: MaterialKey = "metal.painted:" + String(format: "%06X", shadeColor)
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 32 : 16
            // Canopy: low disc with rolled edge, set screw on the rim.
            m.add(Prim.lathe([V2(0, top), V2(0.052, top), V2(0.058, top - 0.003), V2(0.058, top - 0.012), V2(0.052, top - 0.019), V2(0.03, top - 0.022), V2(0, top - 0.022)],
                             segments: 28, seamTile: 0.1, material: "metal.powder-white"))
            if lod == 0 { rivet(&m, at: V3(0.058, top - 0.009, 0), normal: V3(1, 0, 0), radius: 0.0025, segments: 6, material: "metal.chrome") }
            // Cord and cord grip.
            let cordTop = top - 0.02, neckTop = bottom + 0.2 + 0.034
            m.add(Prim.tube([V3(0, cordTop, 0), V3(0, (cordTop + neckTop) / 2, 0), V3(0, neckTop, 0)], radii: [0.0038, 0.0038, 0.0038], sides: lod == 0 ? 8 : 5, seamTile: 0.02, material: "fabric.webbing"))
            m.add(Prim.lathe([V2(0, top - 0.02), V2(0.011, top - 0.02), V2(0.011, top - 0.06), V2(0.0085, top - 0.066), V2(0, top - 0.066)], segments: 16, seamTile: 0.03, material: "metal.brass-aged"))
            // Neck and socket cap: brass stack on top of the dome.
            m.add(Prim.lathe([V2(0, neckTop + 0.012), V2(0.013, neckTop + 0.012), V2(0.0155, neckTop + 0.006), V2(0.0155, neckTop - 0.012), V2(0.028, neckTop - 0.02), V2(0.028, neckTop - 0.032), V2(0, neckTop - 0.032)],
                             segments: 24, seamTile: 0.05, material: "metal.brass-aged"))
            // Dome shade: thin spun shell, rolled rim, white reflector inside.
            let H: Float = 0.2
            let hy = bottom + H
            let outer: [V2] = [V2(0.03, hy + 0.0), V2(0.07, hy - 0.004), V2(0.12, hy - 0.022), V2(0.17, hy - 0.06), V2(0.205, hy - 0.115), V2(0.2215, hy - 0.17), V2(R, hy - 0.2)]
            let sm = Profile.smooth(outer, per: lod == 0 ? 3 : 1)
            var prof = sm
            prof.append(V2(R - 0.0025, bottom - 0.0015)); prof.append(V2(R - 0.007, bottom - 0.0005)); prof.append(V2(R - 0.0085, bottom + 0.004))
            m.add(Prim.lathe(prof.reversed(), segments: seg, seamTile: 0.2, material: enamel))
            let inner: [V2] = sm.map { V2(max($0.x - 0.0085, 0.001), $0.y - 0.0035) }
            m.add(Prim.lathe(inner, segments: lod == 0 ? 24 : 12, seamTile: 0.2, material: "metal.powder-white"))
            // Socket holder inside the dome.
            m.add(Prim.lathe([V2(0.0, hy - 0.008), V2(0.016, hy - 0.008), V2(0.016, hy - 0.05), V2(0.0, hy - 0.05)], segments: 16, seamTile: 0.03, material: "plastic.white"))
            m.add(Prim.lathe([V2(0.0, hy - 0.05), V2(0.014, hy - 0.05), V2(0.0145, hy - 0.056), V2(0.0145, hy - 0.07), V2(0, hy - 0.07)], segments: 16, seamTile: 0.03, material: "metal.brass-aged"))
            // Globe bulb (clear glass) with a lit filament, hanging inside the rim line.
            let by = hy - 0.14
            m.add(Prim.lathe(Profile.smooth([V2(0.0125, hy - 0.07), V2(0.02, hy - 0.085), V2(0.038, hy - 0.115), V2(0.048, hy - 0.14), V2(0.042, hy - 0.165), V2(0.022, hy - 0.185), V2(0, hy - 0.19)], per: lod == 0 ? 3 : 1),
                             segments: 16, seamTile: 0.1, material: "glass.clear"))
            m.add(Prim.superellipsoid(V3(0.022, 0.05, 0.022), exponent: 2, subdivisions: 4, material: "emissive.bulb"), Xform(translation: V3(0, by, 0)))
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
