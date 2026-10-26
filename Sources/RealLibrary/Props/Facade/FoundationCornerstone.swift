import simd
import Foundation

/// Civic foundation cornerstone: a dressed limestone block with a chiselled margin draft round a smooth
/// inscription panel, an incised dated dedication filled with black paint, a compass and square
/// emblem, lime mortar bed joints, lewis holes in the top bed, chipped arrises and weathering.
public struct FoundationCornerstone: RealAsset {
    public static let id = "foundation-cornerstone"
    public static let summary = "Civic cornerstone block 0.6 x 0.4 x 0.3 m: dressed limestone with margin draft, incised dated inscription, mortar bed joints, weathered arris."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 14, distance: 1.2)

    /// Inscription lines, top to bottom (A-Z, 0-9).
    public var lines = ["THIS STONE LAID", "14 MAY 1928", "BY ALD J REED", "MAYOR"]
    public var block: MaterialKey = "stone.cast-stone"
    public var panel: MaterialKey = "stone.limestone"
    public var inlay: MaterialKey = "paint.stucco:26231F"
    public var mortar: MaterialKey = "concrete.rough"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.6, H: Float = 0.4, D: Float = 0.3, j: Float = 0.008
        // Stone body between two mortar beds, edges arrised 4 mm.
        FA.box(&m, V3(W, H - 2 * j, D), V3(0, H / 2, D / 2), block, r: 0.006)
        FA.box(&m, V3(W + 0.004, j, D + 0.004), V3(0, j / 2, D / 2), mortar, r: 0.002)
        FA.box(&m, V3(W + 0.004, j, D + 0.004), V3(0, H - j / 2, D / 2), mortar, r: 0.002)
        // Smooth inscription panel inside a 28 mm chiselled margin draft, proud 3 mm with a chamfer.
        let pz = D + 0.0015
        FA.box(&m, V3(W - 0.056, H - 0.056 - 2 * j, 0.004), V3(0, H / 2, pz), panel, r: 0.0012)
        // Margin draft strips in a warmer, tooled finish.
        let mh = (H - 2 * j) / 2
        for (w, h, x, y) in [(W - 0.004, 0.026, 0.0, H - j - 0.013), (W - 0.004, 0.026, 0.0, j + 0.013), (0.026, 2 * mh - 0.052, -W / 2 + 0.015, H / 2), (0.026, 2 * mh - 0.052, W / 2 - 0.015, H / 2)] as [(Float, Float, Float, Float)] {
            FG.flat(&m, V3(w, h, 0.0008), V3(x, y, D + 0.0004), "stone.sandstone")
        }
        // Chisel marks on the draft: short diagonal strokes, darker.
        for _ in 0..<70 {
            let onSide = rng.chance(0.5)
            let x = onSide ? (rng.chance(0.5) ? -1 : 1) * (W / 2 - 0.013) : rng.float(-W / 2 + 0.02...W / 2 - 0.02)
            let y = onSide ? rng.float(0.03...H - 0.03) : (rng.chance(0.5) ? j + 0.012 : H - j - 0.012)
            FG.flat(&m, V3(0.014, 0.0012, 0.0004), V3(x + rng.float(-0.003...0.003), y, D + 0.0003), "stone.cast-grey", rot: FA.q(rng.float(25...55), FA.Z))
        }
        // Compass and square emblem above the text.
        let ez = pz + 0.0022
        for sx: Float in [-1, 1] { FG.flat(&m, V3(0.006, 0.062, 0.0006), V3(sx * 0.0145, 0.338, ez), inlay, rot: FA.q(sx * -13, FA.Z)) }
        FG.text(&m, "G", h: 0.016, stroke: 0.0026, depth: 0.0006, at: V3(0, 0.326, ez), inlay)
        FG.flat(&m, V3(0.034, 0.0032, 0.0006), V3(0, 0.307, ez), inlay)
        // Incised, black filled lettering.
        let ys: [Float] = [0.262, 0.2, 0.14, 0.092], hs: [Float] = [0.04, 0.046, 0.028, 0.026]
        for (i, s) in lines.enumerated() where i < ys.count {
            FG.text(&m, s, h: hs[i], stroke: hs[i] * 0.16, depth: 0.0006, at: V3(0, ys[i], ez), inlay)
        }
        FG.flat(&m, V3(0.36, 0.0035, 0.0006), V3(0, 0.226, ez), inlay)
        FG.flat(&m, V3(0.2, 0.0035, 0.0006), V3(0, 0.063, ez), inlay)
        // Lewis holes on the top bed and a weathered pocket at the front arris.
        for sx: Float in [-1, 1] { FG.flat(&m, V3(0.028, 0.0006, 0.024), V3(sx * 0.12, H - j + 0.0003, D / 2), "paint.stucco:171512") }
        // Chipped arrises: lighter fresh stone showing at the corners.
        for (x, y) in [(-W / 2 + 0.004, H - j - 0.006), (W / 2 - 0.004, j + 0.006), (W / 2 - 0.004, H - j - 0.008), (-W / 2 + 0.004, j + 0.01)] as [(Float, Float)] {
            FG.flat(&m, V3(0.012, rng.float(0.012...0.026), 0.003), V3(x, y, D - 0.0004), "stone.limestone", rot: FA.q(rng.float(-20...20), FA.Z))
        }
        // Soot streaks from the top bed, a hairline crack, and moss at the foot.
        for _ in 0..<9 {
            let len = rng.float(0.04...0.14)
            FG.flat(&m, V3(rng.float(0.006...0.018), len, 0.0006), V3(rng.float(-0.26...0.26), H - j - 0.03 - len / 2, pz + 0.0016), "paint.stucco:6B655C")
        }
        FG.flat(&m, V3(0.0016, 0.07, 0.0005), V3(0.19, 0.17, ez), "paint.stucco:35302B", rot: FA.q(14, FA.Z))
        for k in 0..<4 {
            let cx = rng.float(-0.25...0.25)
            for _ in 0..<4 { FG.flat(&m, V3(rng.float(0.008...0.03), rng.float(0.006...0.014), 0.002), V3(cx + rng.float(-0.025...0.025), j + 0.012 + rng.float(0...0.01), pz + 0.0015), "moss.cushion", rot: FA.q(rng.float(-30...30), FA.Z)) }
            _ = k
        }
        // Incised keyline 9 mm inside the panel edge, with eight point rosettes in the corners.
        let kx = (W - 0.056) / 2 - 0.009, ky = (H - 0.056 - 2 * j) / 2 - 0.009
        FG.flat(&m, V3(2 * kx, 0.0026, 0.0006), V3(0, H / 2 + ky, ez), inlay)
        FG.flat(&m, V3(2 * kx, 0.0026, 0.0006), V3(0, H / 2 - ky, ez), inlay)
        FG.flat(&m, V3(0.0026, 2 * ky, 0.0006), V3(-kx, H / 2, ez), inlay)
        FG.flat(&m, V3(0.0026, 2 * ky, 0.0006), V3(kx, H / 2, ez), inlay)
        var rosette: [V2] = []
        for k in 0..<16 { let a = Float(k) * .pi / 8; rosette.append(V2(cos(a), sin(a)) * (k % 2 == 0 ? 0.012 : 0.0055)) }
        for (sx, sy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            m.add(Prim.extrude(rosette, depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: inlay), Xform(translation: V3(sx * (kx - 0.02), H / 2 + sy * (ky - 0.02), ez + 0.0004)))
        }
        // Copper plate sealing the time capsule cavity, four screws, verdigris at the edges.
        let cp = V3(0.2, 0.082, ez)
        FA.box(&m, V3(0.07, 0.07, 0.003), cp + V3(0, 0, 0.0015), "metal.copper", r: 0.001)
        FA.box(&m, V3(0.07, 0.006, 0.0032), cp + V3(0, -0.032, 0.0016), "metal.copper-patina", r: 0.0006)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] { FG.dome(&m, at: cp + V3(sx * 0.027, sy * 0.027, 0.0034), r: 0.0032, mat: "metal.brass-aged") } }
        // Tonal blotches across the panel (washed and dirty patches) and copper staining below the plate.
        // Splash soot band on the lower panel, ragged at its upper edge.
        for k in 0..<10 {
            let x = -0.26 + Float(k) * 0.058, hgt = rng.float(0.02...0.05)
            FG.flat(&m, V3(0.062, hgt, 0.0004), V3(x, 0.06 + hgt / 2 - 0.028, ez + 0.0001), "stone.limestone-sooted")
        }
        FG.flat(&m, V3(0.022, 0.05, 0.0004), V3(0.2, 0.037, ez + 0.0003), "paint.stucco:6F9078")
        FG.flat(&m, V3(0.01, 0.03, 0.0004), V3(0.208, 0.015, ez + 0.0003), "paint.stucco:5C7A66")
        groundAO(&m, height: 0.1, floor: 0.88)
        return LODModel(FC.place(m))
    }
}
