import simd
import Foundation

/// Shallow tuna tin 80 x 30 mm: double-seam rims, embossed ring-pull lid with scored opening and rivet, blue paper wrap band with fish relief and barcode, dent, rust at the bottom seam.
public struct TunaCan: RealAsset {
    public static let id = "tuna-can"
    public static let summary = "Shallow tuna tin with embossed ring-pull lid, double-seam rims and a paper wrap band."
    public static let tags = ["prop", "interior", "pantry", "metal", "paper"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, studio: true)

    /// Can outer diameter and height in meters.
    public var diameter: Float = 0.08
    public var height: Float = 0.03
    /// Label paper, band, front panel, accent and ink colors (sRGB hex).
    public var labelBase: UInt32 = 0x2E5E9C
    public var labelBand: UInt32 = 0xC9CED4
    public var labelPanel: UInt32 = 0xF6F1E3
    public var labelAccent: UInt32 = 0x3F6FB0
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [2])
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let r = diameter / 2, h = height
        let label = DD1JKit.CanLabel(base: labelBase, band: labelBand, panel: labelPanel, accent: labelAccent, bandHeight: 0.005, margin: 0.0065)
        let dent = DD1JKit.Dent(a: rng.float(-0.6...0.6) - .pi / 2 + 0.9, y: h * rng.float(0.35...0.55), depth: 0.0022, sigma: 0.0100)
        let accent = labelAccent
        var m = DD1JKit.can(r: r, h: h, label: label, beads: [], dent: dent, rustArc: 3.4, rustAt: rng.float(0...6),
                            peel: false, detail: detail) { m, lr, mid, ph in
            let fz = lr(mid) + 0.0006
            // Fish: tapered body and forked tail on the cream panel.
            let fish = Prim.superellipsoid(V3(0.0200, 0.0075, 0.0020), exponent: 2.1, subdivisions: detail ? 3 : 1, material: DD1JKit.tint("plastic.gloss", accent))
            m.add(fish, Xform(translation: V3(-0.0030, mid, fz)))
            let tail = Prim.extrude([V2(0, 0), V2(0.0090, 0.0050), V2(0.0070, 0), V2(0.0090, -0.0050)], depth: 0.0012, bevel: 0.0003, bevelSegments: 1,
                                    material: DD1JKit.tint("plastic.gloss", accent))
            m.add(tail, Xform(translation: V3(0.0072, mid, fz)))
            m.add(Prim.cylinder(radius: 0.0012, height: 0.0010, bevel: 0.0003, segments: 8, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0x1C1A18)),
                  Xform(translation: V3(-0.0105, mid + 0.0016, fz + 0.0015), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        }
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
