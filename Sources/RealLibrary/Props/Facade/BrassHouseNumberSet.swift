import simd
import Foundation

/// Cast brass house numerals on stand-off pins: each digit is a beveled casting with a hand-polished raised
/// face over a darker aged ground, fixed by two threaded pins with brass washers.
public struct BrassHouseNumberSet: RealAsset {
    public static let id = "brass-house-number-set"
    public static let summary = "Three cast brass house numerals 0.3 m on stand-off pins, polished edges and aged faces."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 1.2)

    /// Digits shown.
    public var number = "214"
    /// Digit height (m).
    public var digitHeight: Float = 0.082
    public var casting: MaterialKey = "metal.bronze-weathered"
    public var polish: MaterialKey = "metal.brass"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h = digitHeight, w = h * 0.2, pitch = 5.8 * h / 6, u = h / 6
        let total = strokeTextWidth(number, height: h) + Float(number.count - 1) * 0.4 * u
        // Door panel (painted timber) the numerals are pinned to, with a worn sill line.
        FG.flat(&m, V3(0.3, 0.12, 0.004), V3(0, 0.06, 0.002), "wood.painted-exterior:2F4A3A")
        FG.flat(&m, V3(0.3, 0.004, 0.0006), V3(0, 0.002, 0.0043), "metal.steel:1B1712")
        for (i, ch) in number.enumerated() {
            let cx = -total / 2 + Float(i) * pitch + 2 * u, cy: Float = 0.06
            let s = String(ch)
            FG.soft(&m, s, h: h, stroke: w, depth: 0.011, at: V3(cx, cy, 0.0085), casting, bevel: 0.0022)
            // Polished raised face worn bright by hand and weather, slightly narrower than the casting.
            FG.soft(&m, s, h: h, stroke: w * 0.62, depth: 0.0016, at: V3(cx, cy, 0.0194), rng.chance(0.4) ? casting : polish, bevel: 0.0006)
            // Pins and washers sit on the stroke: first and last vertex of the glyph outline.
            if let lines = fgGlyphs[Character(s)], let f = lines.first?.first, let l = lines.last?.last {
                for g in [f, l] {
                    let p = V3(cx - 2 * u + g.0 * u, cy - h / 2 + g.1 * u, 0)
                    FA.cylZ(&m, r: 0.0022, h: 0.0095, at: p, "metal.stainless", bevel: 0.0003, segments: 8)
                    FA.cylZ(&m, r: 0.0042, h: 0.0012, at: V3(p.x, p.y, 0.0085), "metal.brass", bevel: 0.0003, segments: 10)
                }
            }
            // Verdigris run on the door below the lower pin and a shadow stain behind the numeral.
            if let f = fgGlyphs[Character(s)]?.first?.first {
                let px = cx - 2 * u + f.0 * u, py = cy - h / 2 + f.1 * u
                let len = min(rng.float(0.015...0.03), py - 0.012)
                FG.flat(&m, V3(0.0035, len, 0.0004), V3(px + 0.001, py - len / 2, 0.0042), "metal.copper-patina")
            }
        }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
