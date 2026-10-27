import simd
import Foundation

/// Olive oil bottle, 80 x 300 mm: green moulded glass with long shoulder, punt base and mould seams, ribbed pilfer-proof screw cap with tamper band, wrapped paper label with olive relief, neck band, oil drip down the shoulder, scuffed base.
public struct OliveOilBottle: RealAsset {
    public static let id = "olive-oil-bottle"
    public static let summary = "Green glass olive oil bottle with tapered neck, ribbed pilfer-proof cap, oil fill, punt base and wrapped label."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Bottle diameter and overall height (m).
    public var diameter: Float = 0.077
    public var height: Float = 0.30
    /// Label colors (sRGB hex).
    public var labelBase: UInt32 = 0xF1E7C8
    public var labelBand: UInt32 = 0x3F5E2A
    public var glass: MaterialKey = "glass.emerald"
    public var capMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    func bottle() -> DD1JKit.Bottle {
        let r = diameter / 2
        return DD1JKit.Bottle(r: r, knots: [(0, r - 0.0006), (0.005, r), (0.150, r), (0.195, 0.0260), (0.222, 0.0150), (0.238, 0.0134), (0.272, 0.0134)],
                              top: 0.272, wall: 0.0030, punt: 0.0085, fillTop: 0.0, glass: glass, fluid: nil)
    }

    func level(detail: Bool) -> Model {
        let b = bottle()
        var m = DD1JKit.bottleGlass(b, detail: detail)
        let rad: (Float) -> Float = { b.outer($0) + 0.0003 }
        m.add(Prim.lathe([V2(0.0133, 0.2420), V2(0.0156, 0.2427), V2(0.0158, 0.2448), V2(0.0133, 0.2456)], segments: detail ? 48 : 16, seamTile: 0.1, material: glass))
        DD1JKit.wrapLabel(&m, radius: rad, y0: 0.036, y1: 0.150, base: labelBase, band: labelBand, panel: 0xFAF3DC,
                          bandHeight: 0.012, bars: 3, detail: detail) { m, fz in
            // Olive sprig: curved stem, five leaves and three olives.
            var rng = SeededRNG(seed: 11)
            for i in 0..<5 {
                let t = Float(i) / 4, x = (t - 0.5) * 0.030, y = 0.073 + 0.006 * sin(t * 3.1)
                for s in [Float(-1), 1] where !(i == 4 && s > 0) {
                    m.add(Prim.superellipsoid(V3(0.0120, 0.0030, 0.0012), exponent: 2, subdivisions: 1, material: DD1JKit.tint("plastic.matte", 0x5C7A2E)),
                          Xform(translation: V3(x, y + s * 0.0035, fz), rotation: simd_quatf(angle: s * 0.55 + rng.float(-0.1...0.1), axis: V3(0, 0, 1))))
                }
            }
            for k in 0..<3 {
                m.add(Prim.superellipsoid(V3(0.0090, 0.0120, 0.0045), exponent: 2, subdivisions: detail ? 2 : 1, material: DD1JKit.tint("plastic.gloss", 0x2E1F3A)),
                      Xform(translation: V3(-0.011 + Float(k) * 0.011, 0.058 - Float(k % 2) * 0.004, fz)))
            }
        }
        // Neck band and the long drip down the shoulder.
        m.add(DD1JKit.arcPatch(center: 0, width: 2 * .pi * 0.0147, y0: 0.2150, y1: 0.2250, offset: 0.0004, material: DD1JKit.tint("plastic.matte", labelBase), radius: { b.outer($0) }, rows: 2))
        m.add(DD1JKit.arcPatch(center: 0, width: 2 * .pi * 0.0147, y0: 0.2190, y1: 0.2210, offset: 0.0008, material: DD1JKit.tint("plastic.matte", labelBand), radius: { b.outer($0) }, rows: 1))
        m.add(DD1JKit.cap(r: 0.0158, h: 0.0345, y: 0.2650, material: capMaterial, knurls: 40, bandGap: true, button: false, detail: detail))
        DD1JKit.drip(&m, radius: rad, angle: -0.5, yTop: 0.2400, yBottom: 0.1800, material: "food.oil")
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true), level(detail: false)], switchDistances: [2])
    }
}
