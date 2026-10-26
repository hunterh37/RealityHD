import simd
import Foundation

/// Reverse channel (halo lit) letter set: stainless faced letters on a black anodised return, held off a
/// rendered wall panel on threaded studs, with the LED glow washing the wall behind each letter.
public struct HaloLitLetterSet: RealAsset {
    public static let id = "halo-lit-letter-set"
    public static let summary = "Reverse channel letter set HOTEL, 1.5 m: stainless faced letters on standoff studs over a lit wall halo."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 10500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 1.2)

    /// Lettering (A-Z, 0-9).
    public var word = "HOTEL"
    /// Letter cap height (m).
    public var letterHeight: Float = 0.27
    public var face: MaterialKey = "metal.powder-white:E4E4E0"
    public var returns: MaterialKey = "metal.anodized-black"
    public var halo: MaterialKey = "paint.stucco:C3D6F2"
    public var haloOuter: MaterialKey = "paint.stucco:9FB0C9"
    public var wall: MaterialKey = "paint.stucco:8E887E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h = letterHeight, stroke = h * 0.17, cy: Float = 0.2
        // Rendered wall panel with a stained lower edge and a hairline crack.
        FA.box(&m, V3(1.5, 0.4, 0.016), V3(0, 0.2, 0.008), wall, r: 0.003)
        FA.box(&m, V3(1.5, 0.05, 0.0006), V3(0, 0.025, 0.0163), "metal.steel:4A4338", r: 0.0003)
        FA.box(&m, V3(0.002, 0.14, 0.0006), V3(0.52, 0.31, 0.0164), "metal.steel:5B5448", r: 0.0003, rot: FA.q(12, FA.Z))
        let w = strokeTextWidth(word, height: h)
        let pitch = 5.4 * h / 6
        for (i, ch) in word.enumerated() {
            let cx = -w / 2 + (Float(i) + 0.5) * pitch - 0.7 * h / 6
            let s = String(ch)
            // Halo wash on the wall, wider than the letter so it rings the edge.
            FG.soft(&m, s, h: h * 1.02, stroke: stroke * 2.7, depth: 0.0006, at: V3(cx, cy, 0.0165), haloOuter, bevel: 0.0002)
            FG.soft(&m, s, h: h * 1.01, stroke: stroke * 1.7, depth: 0.0006, at: V3(cx, cy, 0.0171), halo, bevel: 0.0002)
            FG.soft(&m, s, h: h, stroke: stroke, depth: 0.052, at: V3(cx, cy, 0.04), returns, bevel: 0.002)
            FG.text(&m, s, h: h, stroke: stroke * 0.98, depth: 0.004, at: V3(cx, cy, 0.092), face)
            // Rain streaks running down the render from the stud holes.
            for dx: Float in [-0.35, 0.3] {
                let len = rng.float(0.05...0.16)
                FA.box(&m, V3(0.011, len, 0.0006), V3(cx + dx * h * 0.5, cy - h * 0.2 - len / 2, 0.0168), "metal.steel:3E372E", r: 0.0002)
            }
            // Threaded standoff studs with hex nuts through the return and a nylon spacer at the wall.
            for dy: Float in [-1, 1] {
                let sp = V3(cx - h * 0.1, cy + dy * h * 0.36, 0)
                FA.cylZ(&m, r: 0.003, h: 0.05, at: V3(sp.x, sp.y, 0.012), "metal.stainless", bevel: 0.0004, segments: 8)
                FA.cylZ(&m, r: 0.0065, h: 0.006, at: V3(sp.x, sp.y, 0.0164), "plastic.white", bevel: 0.0005, segments: 10)
            }
        }
        // LED driver box at the right end with a short conduit run to the letters.
        FA.box(&m, V3(0.1, 0.13, 0.045), V3(0.66, 0.1, 0.0385), "metal.galvanized", r: 0.004)
        FA.box(&m, V3(0.07, 0.012, 0.048), V3(0.66, 0.15, 0.04), "metal.steel:1A1A1A", r: 0.001)
        FA.rod(&m, V3(0.61, 0.08, 0.0245), V3(0.5, 0.08, 0.0245), r: 0.006, "metal.galvanized-aged", sides: 10)
        for sx: Float in [-1, 1] { FG.screw(&m, at: V3(0.66 + sx * 0.04, 0.1, 0.061), r: 0.003, mat: "metal.stainless") }
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
