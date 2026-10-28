import simd
import Foundation

/// Condensed soup tin 70 x 100 mm: double-seam rims, two rolling beads, ring-pull lid with scored opening and rivet, wrapped paper label with overlap seam and barcode, shallow dent, rust at the bottom seam.
public struct CannedSoup: RealAsset {
    public static let id = "canned-soup"
    public static let summary = "Tin soup can with double-seam rims, rolling beads, pull-tab lid and wrapped paper label with overlap seam."
    public static let tags = ["prop", "interior", "pantry", "metal", "paper"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, studio: true)

    /// Can outer diameter and height in meters.
    public var diameter: Float = 0.067
    public var height: Float = 0.1
    /// Label paper, band, front panel, accent and ink colors (sRGB hex).
    public var labelBase: UInt32 = 0xF1E6CC
    public var labelBand: UInt32 = 0xC8102E
    public var labelPanel: UInt32 = 0xFFF8E8
    public var labelAccent: UInt32 = 0xE8913A
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [2])
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let r = diameter / 2, h = height
        let label = DD1JKit.CanLabel(base: labelBase, band: labelBand, panel: labelPanel, accent: labelAccent, bandHeight: 0.012, margin: 0.008)
        let dent = DD1JKit.Dent(a: rng.float(-0.6...0.6) - .pi / 2 + 0.9, y: h * rng.float(0.35...0.55), depth: 0.0022, sigma: 0.0100)
        let accent = labelAccent
        var m = DD1JKit.can(r: r, h: h, label: label, beads: [0.2, 0.8], dent: dent, rustArc: 3.4, rustAt: rng.float(0...6),
                            peel: false, detail: detail) { m, lr, mid, ph in
            let fz = lr(mid) + 0.0006
            // Soup bowl: orange broth disc inside a rim ring, with three steam wisps.
            m.add(Prim.lathe([V2(0, 0), V2(0.0115, 0.0003), V2(0.0150, 0.0055), V2(0.0156, 0.0068), V2(0.0140, 0.0068), V2(0.0136, 0.0058), V2(0, 0.0058)],
                             segments: detail ? 28 : 12, seamTile: 0.05, material: "ceramic.vitreous"),
                  Xform(translation: V3(0, mid - 0.009, fz), rotation: simd_quatf(angle: 1.35, axis: V3(1, 0, 0)), scale: V3(1, 0.25, 1)))
            m.add(Prim.lathe([V2(0, 0.0050), V2(0.0128, 0.0056), V2(0.0132, 0.0060), V2(0, 0.0060)],
                             segments: detail ? 28 : 12, seamTile: 0.05, material: DD1JKit.tint("plastic.matte", accent)),
                  Xform(translation: V3(0, mid - 0.0086, fz + 0.0005), rotation: simd_quatf(angle: 1.35, axis: V3(1, 0, 0)), scale: V3(1, 0.25, 1)))
        }
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
