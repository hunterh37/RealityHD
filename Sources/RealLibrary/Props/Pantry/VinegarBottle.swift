import simd
import Foundation

/// Vinegar bottle, 70 x 260 mm: clear moulded glass with shoulder and neck bead, clear fill, ribbed screw cap with tamper band, wrapped paper label with apple relief and barcode, drip from the neck, scuffed base.
public struct VinegarBottle: RealAsset {
    public static let id = "vinegar-bottle"
    public static let summary = "Clear glass vinegar bottle with neck ring, ribbed screw cap, clear vinegar fill and wrapped label."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Bottle diameter and overall height (m).
    public var diameter: Float = 0.067
    public var height: Float = 0.26
    /// Label colors (sRGB hex).
    public var labelBase: UInt32 = 0xF4EBD0
    public var labelBand: UInt32 = 0x9B2423
    public var vinegar: MaterialKey = "glass.water-clear"
    public init() {}

    func bottle() -> DD1JKit.Bottle {
        let r = diameter / 2
        return DD1JKit.Bottle(r: r, knots: [(0, r - 0.0006), (0.004, r), (0.135, r), (0.190, 0.0220), (0.206, 0.0128), (0.216, 0.0125), (0.234, 0.0125)],
                              top: 0.234, wall: 0.0026, punt: 0.0075, fillTop: 0.1960, glass: "glass.clear", fluid: vinegar)
    }

    func level(detail: Bool) -> Model {
        let b = bottle()
        var m = DD1JKit.bottleGlass(b, detail: detail)
        let rad: (Float) -> Float = { b.outer($0) + 0.0003 }
        m.add(Prim.lathe([V2(0.0124, 0.2160), V2(0.0148, 0.2167), V2(0.0150, 0.2188), V2(0.0124, 0.2196)], segments: detail ? 48 : 16, seamTile: 0.1, material: b.glass))
        DD1JKit.wrapLabel(&m, radius: rad, y0: 0.030, y1: 0.125, base: labelBase, band: labelBand, panel: 0xFFF8E4,
                          bandHeight: 0.010, bars: 2, detail: detail) { m, fz in
            // Apple relief with stem and leaf.
            var apple = Prim.superellipsoid(V3(0.026, 0.024, 0.003), exponent: 2.3, subdivisions: detail ? 3 : 1, material: DD1JKit.tint("plastic.gloss", 0xC83A25))
            apple.displace { p, _ in 0.0007 * exp(-pow(p.x / 0.004, 2)) * max(0, p.y / 0.012) }
            m.add(apple, Xform(translation: V3(0, 0.0640, fz)))
            m.add(Prim.roundedBox(V3(0.0012, 0.0070, 0.0012), radius: 0.0004, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0x5A3A22)),
                  Xform(translation: V3(0, 0.0770, fz + 0.0018), rotation: simd_quatf(angle: 0.2, axis: V3(0, 0, 1))))
            m.add(Prim.superellipsoid(V3(0.0100, 0.0042, 0.0012), exponent: 2, subdivisions: 1, material: DD1JKit.tint("plastic.matte", 0x3E7D2C)),
                  Xform(translation: V3(0.0065, 0.0770, fz + 0.0018), rotation: simd_quatf(angle: 0.4, axis: V3(0, 0, 1))))
        }
        m.add(DD1JKit.cap(r: 0.0150, h: 0.0270, y: 0.2330, material: "metal.painted:C8D0D6", knurls: 36, bandGap: true, button: false, detail: detail))
        DD1JKit.drip(&m, radius: rad, angle: -1.3, yTop: 0.2150, yBottom: 0.1880, material: "glass.water-clear")
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true), level(detail: false)], switchDistances: [2])
    }
}
