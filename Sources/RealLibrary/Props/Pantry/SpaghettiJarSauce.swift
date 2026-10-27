import simd
import Foundation

/// Spaghetti sauce jar, 80 x 140 mm: moulded glass with shoulder and neck bead, tomato sauce fill with headspace, lugged twist-off lid with safety button, wrapped paper label with overlap seam and barcode, dried sauce drip under the lid, scuffed base.
public struct SpaghettiJarSauce: RealAsset {
    public static let id = "spaghetti-jar-sauce"
    public static let summary = "Glass spaghetti sauce jar filled with tomato sauce, lugged twist-off lid with safety button and wrapped paper label."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Jar body diameter and overall height (m).
    public var diameter: Float = 0.075
    public var height: Float = 0.14
    /// Lid and label colors (sRGB hex).
    public var lidColor: UInt32 = 0xC4262A
    public var labelBase: UInt32 = 0xF3E9D2
    public var labelBand: UInt32 = 0xB8221F
    public var sauce: MaterialKey = "food.tomato-sauce"
    public init() {}

    func jar(detail: Bool) -> DD1JKit.Bottle {
        let r = diameter / 2
        return DD1JKit.Bottle(r: r, knots: [(0, r - 0.0006), (0.004, r), (0.100, r), (0.108, r - 0.0035), (0.116, 0.0345), (0.121, 0.0305), (0.1285, 0.0300)],
                              top: 0.1285, wall: 0.0026, punt: 0.0055, fillTop: 0.111, glass: "glass.clear", fluid: sauce)
    }

    func level(detail: Bool) -> Model {
        let b = jar(detail: detail), r = b.r
        var m = DD1JKit.bottleGlass(b, detail: detail)
        let rad: (Float) -> Float = { b.outer($0) + 0.0003 }
        // Neck bead under the lid, and the embossed ring around the shoulder.
        m.add(Prim.lathe([V2(0.0299, 0.1190), V2(0.0338, 0.1194), V2(0.0342, 0.1210), V2(0.0300, 0.1218)], segments: detail ? 48 : 16, seamTile: 0.1, material: b.glass))
        DD1JKit.wrapLabel(&m, radius: { b.outer($0) + 0.0003 }, y0: 0.016, y1: 0.098, base: labelBase, band: labelBand, panel: 0xFBF4E2,
                          bandHeight: 0.010, bars: 2, detail: detail) { m, fz in
            // Tomato relief with calyx, and two basil leaves, centred on the front panel.
            var tom = Prim.superellipsoid(V3(0.026, 0.024, 0.003), exponent: 2.2, subdivisions: detail ? 3 : 1, material: DD1JKit.tint("plastic.gloss", 0xD2231B))
            tom.displace { p, _ in 0.0006 * exp(-pow(p.x / 0.004, 2)) * max(0, p.y / 0.012) }
            m.add(tom, Xform(translation: V3(0, 0.050, fz)))
            for k in 0..<5 {
                m.add(Prim.roundedBox(V3(0.0026, 0.0008, 0.0050), radius: 0.0003, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0x3D8B2F)),
                      Xform(translation: V3(sin(Float(k) * 1.2566) * 0.0040, 0.0625 + cos(Float(k) * 1.2566) * 0.0030, fz + 0.0015),
                            rotation: simd_quatf(angle: 1.2566 * Float(k) + 1.57, axis: V3(0, 0, 1))))
            }
            for s in [Float(-1), 1] {
                m.add(Prim.superellipsoid(V3(0.0100, 0.0042, 0.0014), exponent: 2, subdivisions: 1, material: DD1JKit.tint("plastic.matte", 0x2F7A2C)),
                      Xform(translation: V3(s * 0.0125, 0.0345, fz - 0.0004), rotation: simd_quatf(angle: s * 0.5, axis: V3(0, 0, 1))))
            }
        }
        // Lid with safety button; chipped paint shows bare metal at two points.
        m.add(DD1JKit.cap(r: 0.0318, h: 0.0185, y: 0.1210, material: "metal.painted:" + String(format: "%06X", lidColor), knurls: 30, bandGap: false, button: true, detail: detail))
        for (a, y) in [(Float(-0.9), Float(0.1345)), (0.7, 0.1230), (-2.4, 0.1290)] {
            m.add(DD1JKit.arcPatch(center: a, width: 0.0045, y0: y, y1: y + 0.0022, offset: 0.0006, material: "metal.galvanized-aged",
                                   radius: { _ in 0.0318 }, rows: 1))
        }
        // Dried sauce drip from under the lid.
        DD1JKit.drip(&m, radius: { b.outer($0) + 0.0003 }, angle: -1.15, yTop: 0.1210, yBottom: 0.1020, material: "food.tomato-sauce-reduced")
        _ = r
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true), level(detail: false)], switchDistances: [2])
    }
}
