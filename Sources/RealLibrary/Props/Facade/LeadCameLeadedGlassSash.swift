import simd
import Foundation

/// Lead came leaded glass sash, Tudor Revival: a 0.9 x 1.3 m oak casement with an ovolo-moulded
/// frame, diamond quarries (75 x 120 mm) set in lead cames with soldered nodes, three iron saddle bars
/// tied with copper wire, two strap hinges, a stay and a cockspur fastener.
public struct LeadCameLeadedGlassSash: RealAsset {
    public static let id = "lead-came-leaded-glass-sash"
    public static let summary = "Lead came leaded glass sash, 0.9 x 1.3 m: oak casement, diamond quarries, saddle bars, strap hinges, stay."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 2.6)

    /// Oak frame.
    public var oak: MaterialKey = "wood.walnut"
    /// Weathered oak (bottom rail takes the rain).
    public var weathered: MaterialKey = "wood.weathered"
    /// Quarry glass.
    public var glass: MaterialKey = "glass.pane"
    /// Cames and solder.
    public var lead: MaterialKey = "metal.blued-steel"
    /// Hinges, bars and ironmongery.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.9, H: Float = 1.3, D: Float = 0.048, st: Float = 0.052, bot: Float = 0.085
        let iw = W - 2 * st, ih = H - st - bot, cy = (bot - st) / 2
        // Frame: stiles, head and a deeper weathered bottom rail, each with half-lap corners hidden under the mould.
        for e: Float in [-1, 1] { FA.box(&m, V3(st, H, D), V3(e * (W / 2 - st / 2), 0, D / 2), oak, r: 0.003) }
        FA.box(&m, V3(iw + 0.004, st, D), V3(0, H / 2 - st / 2, D / 2), oak, r: 0.003)
        FA.box(&m, V3(iw + 0.004, bot, D), V3(0, -H / 2 + bot / 2, D / 2), weathered, r: 0.003)
        FA.box(&m, V3(iw + 0.02, 0.012, D + 0.012), V3(0, -H / 2 + 0.006, (D + 0.012) / 2), weathered, r: 0.0025)
        FJ.mouldedFrame(&m, cx: 0, cy: cy, w: iw + 0.01, h: ih + 0.01, z: D - 0.001, profile: FJ.ovoloProfile(width: 0.026, height: 0.014), oak, r: 0.004)
        // Quarry glass behind the cames.
        FJ.slab(&m, V3(iw, ih, 0.004), V3(0, cy, 0.026), glass)
        // Diamond lattice: two families of diagonal cames clipped to the opening, nodes soldered.
        let dw: Float = 0.075, dh: Float = 0.12, a = dh / dw
        let hw = iw / 2, hh = ih / 2
        let came: Float = 0.007
        let steps = Int((hh + a * hw) / dh) + 2
        func line(_ c: Float, _ s: Float) {
            // y = s * a * x + c clipped to the rectangle.
            let k = s * a
            var x0 = -hw, x1 = hw
            let xa = (-hh - c) / k, xb = (hh - c) / k
            x0 = max(x0, min(xa, xb)); x1 = min(x1, max(xa, xb))
            if x1 - x0 < 0.01 { return }
            let p0 = V2(x0, k * x0 + c), p1 = V2(x1, k * x1 + c)
            let len = simd_length(p1 - p0), mid = (p0 + p1) / 2
            FJ.slab(&m, V3(len, came, 0.006), V3(mid.x, cy + mid.y, 0.029), lead, rot: FA.q(atan2(p1.y - p0.y, p1.x - p0.x) * 180 / .pi, FA.Z))
        }
        for k in -steps...steps {
            line(Float(k) * dh, 1)
            line(Float(k) * dh, -1)
        }
        for i in -steps...steps { for j in -steps...steps {
            let c1 = Float(i) * dh, c2 = Float(j) * dh
            let x = (c2 - c1) / (2 * a), y = (c1 + c2) / 2
            if abs(x) < hw - 0.004 && abs(y) < hh - 0.004 && rng.chance(0.85) {
                FJ.slab(&m, V3(0.011, 0.011, 0.0075), V3(x, cy + y, 0.0295), lead)
            }
        }}
        // Lead border came against the frame.
        FJ.slab(&m, V3(iw, 0.012, 0.007), V3(0, cy + hh - 0.006, 0.0295), lead)
        FJ.slab(&m, V3(iw, 0.012, 0.007), V3(0, cy - hh + 0.006, 0.0295), lead)
        for e: Float in [-1, 1] { FJ.slab(&m, V3(0.012, ih, 0.007), V3(e * (hw - 0.006), cy, 0.0295), lead) }
        // Saddle bars: iron flats across the sash, tied with copper wire every 0.12 m.
        for k in 1...3 {
            let y = cy - hh + ih * Float(k) / 4
            FJ.slab(&m, V3(iw, 0.011, 0.005), V3(0, y, 0.034), iron)
            var x = -hw + 0.07
            while x < hw {
                FJ.slab(&m, V3(0.0035, 0.034, 0.003), V3(x, y, 0.0375), "metal.copper")
                x += 0.12
            }
        }
        // Strap hinges on the left stile, stay on the right, cockspur fastener at mid height.
        for y in [H / 2 - 0.2, -H / 2 + 0.22] {
            FJ.strapHinge(&m, from: -W / 2 + 0.002, to: -W / 2 + 0.27, y: y, z: D, width: 0.022, thick: 0.004, iron, nails: 3, rng: &rng)
        }
        FJ.slab(&m, V3(0.012, 0.22, 0.004), V3(W / 2 - st / 2, -H / 2 + bot + 0.12, D + 0.002), iron, rot: FA.q(-18, FA.Z))
        FA.cylZ(&m, r: 0.007, h: 0.006, at: V3(W / 2 - st / 2, -H / 2 + bot + 0.02, D), iron, bevel: 0.001, segments: 10)
        FA.cylZ(&m, r: 0.008, h: 0.008, at: V3(W / 2 - st / 2, 0.0, D), iron, bevel: 0.001, segments: 10)
        FJ.slab(&m, V3(0.04, 0.008, 0.006), V3(W / 2 - st / 2 - 0.02, 0.0, D + 0.01), iron)
        FJ.slab(&m, V3(0.008, 0.03, 0.006), V3(W / 2 - st / 2 - 0.04, -0.013, D + 0.01), iron)
        // Paint-free wear: dark grime band above the bottom rail and a split in the sill.
        FJ.slab(&m, V3(iw, 0.02, 0.0012), V3(0, -H / 2 + bot + 0.009, D + 0.0005), weathered)
        FJ.slab(&m, V3(0.18, 0.0015, 0.002), V3(-0.1, -H / 2 + 0.05, D + 0.001), "wood.deadwood", rot: FA.q(3, FA.Z))
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
