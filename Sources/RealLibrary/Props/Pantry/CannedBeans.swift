import simd
import Foundation

/// Baked bean tin 70 x 110 mm: double-seam rims, two beads, ring-pull lid and rivet, wrapped paper label with overlap seam, bean relief and barcode, side dent, rust at the bottom seam.
public struct CannedBeans: RealAsset {
    public static let id = "canned-beans"
    public static let summary = "Tin bean can with double-seam rims, beads, ring-pull lid and wrapped paper label with a side dent."
    public static let tags = ["prop", "interior", "pantry", "metal", "paper"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, studio: true)

    /// Can outer diameter and height in meters.
    public var diameter: Float = 0.07
    public var height: Float = 0.11
    /// Label paper, band, front panel, accent and ink colors (sRGB hex).
    public var labelBase: UInt32 = 0xEADFC4
    public var labelBand: UInt32 = 0x7A1F1A
    public var labelPanel: UInt32 = 0xF3D9A0
    public var labelAccent: UInt32 = 0x8B4A2B
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [2])
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let r = diameter / 2, h = height
        let label = DD1JKit.CanLabel(base: labelBase, band: labelBand, panel: labelPanel, accent: labelAccent, bandHeight: 0.013, margin: 0.008)
        let dent = DD1JKit.Dent(a: rng.float(-0.6...0.6) - .pi / 2 + 0.9, y: h * rng.float(0.35...0.55), depth: 0.0022, sigma: 0.0100)
        let accent = labelAccent
        var m = DD1JKit.can(r: r, h: h, label: label, beads: [0.18, 0.82], dent: dent, rustArc: 3.4, rustAt: rng.float(0...6),
                            peel: false, detail: detail) { m, lr, mid, ph in
            let fz = lr(mid) + 0.0006
            // Beans heaped on the label: eight kidney beans with a sauce-orange tint ring behind them.
            var brng = rng.fork(5)
            let bean = Prim.superellipsoid(V3(0.0120, 0.0066, 0.0036), exponent: 2.4, subdivisions: detail ? 3 : 1, material: DD1JKit.tint("plastic.gloss", accent))
            for i in 0..<8 {
                let x = Float(i % 4 - 1) * 0.0098 + brng.float(-0.002...0.002) - 0.0049 + (i < 4 ? 0 : 0.0049)
                let y = mid - 0.012 + Float(i / 4) * 0.0090 + brng.float(-0.0015...0.0015)
                m.add(bean, Xform(translation: V3(x, y, fz + 0.0006), rotation: simd_quatf(angle: brng.float(-0.9...0.9), axis: V3(0, 0, 1)) * simd_quatf(angle: -0.25, axis: V3(1, 0, 0))))
            }
        }
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
