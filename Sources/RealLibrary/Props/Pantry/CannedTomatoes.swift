import simd
import Foundation

/// Wide tomato tin 100 x 120 mm: double-seam rims, three beads, ring-pull lid and rivet, wrapped red paper label with overlap seam, tomato relief and barcode, dent, rust at the bottom seam.
public struct CannedTomatoes: RealAsset {
    public static let id = "canned-tomatoes"
    public static let summary = "Wide tin tomato can with double-seam rims, beads, ring-pull lid and wrapped paper label."
    public static let tags = ["prop", "interior", "pantry", "metal", "paper"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, studio: true)

    /// Can outer diameter and height in meters.
    public var diameter: Float = 0.1
    public var height: Float = 0.12
    /// Label paper, band, front panel, accent and ink colors (sRGB hex).
    public var labelBase: UInt32 = 0xD3271E
    public var labelBand: UInt32 = 0xF2E2B4
    public var labelPanel: UInt32 = 0xF2E2B4
    public var labelAccent: UInt32 = 0xC0231B
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [2])
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let r = diameter / 2, h = height
        let label = DD1JKit.CanLabel(base: labelBase, band: labelBand, panel: labelPanel, accent: labelAccent, bandHeight: 0.014, margin: 0.010)
        let dent = DD1JKit.Dent(a: rng.float(-0.6...0.6) - .pi / 2 + 0.9, y: h * rng.float(0.35...0.55), depth: 0.0022, sigma: 0.0100)
        let accent = labelAccent
        var m = DD1JKit.can(r: r, h: h, label: label, beads: [0.15, 0.5, 0.85], dent: dent, rustArc: 3.4, rustAt: rng.float(0...6),
                            peel: false, detail: detail) { m, lr, mid, ph in
            let fz = lr(mid) + 0.0006
            // Tomato relief: round fruit with a green calyx on the cream panel.
            var tom = Prim.superellipsoid(V3(0.034, 0.030, 0.006), exponent: 2.2, subdivisions: detail ? 4 : 2, material: DD1JKit.tint("plastic.gloss", accent))
            tom.displace { p, _ in 0.0008 * exp(-pow(p.x / 0.004, 2)) * max(0, p.y / 0.015) }
            m.add(tom, Xform(translation: V3(0, mid - 0.003, fz)))
            for k in 0..<5 {
                m.add(Prim.roundedBox(V3(0.0030, 0.0009, 0.0060), radius: 0.0003, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0x3D8B2F)),
                      Xform(translation: V3(sin(Float(k) * 1.2566) * 0.0045, mid + 0.0125 + cos(Float(k) * 1.2566) * 0.0035, fz + 0.0018),
                            rotation: simd_quatf(angle: 1.2566 * Float(k) + 1.57, axis: V3(0, 0, 1))))
            }
        }
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
