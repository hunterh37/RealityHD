import simd
import Foundation

/// Italianate rusticated quoin set, 0.9 m tall: four courses of alternating long and short brownstone
/// blocks with smooth drafted margins, rock-faced centres, chamfered joints over a lime mortar bed and
/// red brick infill beside the short blocks. Chipped arrises and sooted tops. Wall face at z = 0.
public struct RusticatedQuoinBlockSet: RealAsset {
    public static let id = "rusticated-quoin-block-set"
    public static let summary = "Italianate rusticated quoin set, 0.9 m tall: long and short brownstone blocks with chamfered joints, brick infill and soot staining."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 0.9)

    /// Dressed margin stone.
    public var margin: MaterialKey = "stone.brownstone"
    /// Rock-faced centre panels.
    public var rock: MaterialKey = "stone.brownstone-rockface"
    /// Sooted stone for tops and stains.
    public var soot: MaterialKey = "stone.brownstone-sooted"
    /// Brick infill.
    public var brick: MaterialKey = "brick.unit-red-light"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.5, jt: Float = 0.01, depth: Float = 0.106
        let heights: [Float] = [0.25, 0.19, 0.25, 0.18]
        let x0 = -W / 2
        FM.mortar(&m, w: W, h: 0.9, y0: 0, x0: x0, recess: 0.012, back: depth, "brick.mortar-lime")
        var y: Float = 0
        for (c, h) in heights.enumerated() {
            let long = c % 2 == 0
            let xr = long ? W / 2 : x0 + 0.32
            let xa = x0, xb = xr
            FM.brick(&m, x0: xa, x1: xb, y0: y, y1: y + h, depth: depth, margin, rng: &rng, chip: c == 2, proud: 0)
            // Rock-faced centre inside a 16 mm drafted margin, with a pecked rim.
            let inset: Float = 0.016
            FM.prism(&m, [V2(xa + inset, y + inset), V2(xb - inset, y + inset), V2(xb - inset, y + h - inset), V2(xa + inset, y + h - inset)],
                     front: 0.011 + rng.float(-0.002...0.002), depth: 0.012, rock, bevel: 0.007)
            // Sooted top bed and a rain streak on the margin.
            FM.prism(&m, [V2(xa + 0.01, y + h - 0.012), V2(xb - 0.01, y + h - 0.012), V2(xb - 0.01, y + h - 0.003), V2(xa + 0.01, y + h - 0.003)],
                     front: 0.0035, depth: 0.003, soot, bevel: 0.0008)
            // Vermiculation: worm-track grooves on the face of the lower blocks.
            do {
                for _ in 0..<(long ? 7 : 4) {
                    let cx = rng.float((xa + 0.05)...(xb - 0.05)), cy = rng.float((y + 0.05)...(y + h - 0.05))
                    let a = rng.float(0...6.28)
                    let pts = (0..<14).map { i -> V3 in
                        let t = Float(i) / 13
                        let px = cx + cos(a) * (t - 0.5) * 0.09 + 0.005 * sin(t * 22 + a), py = cy + sin(a) * (t - 0.5) * 0.09 + 0.005 * cos(t * 19)
                        return V3(px, py, 0.0225)
                    }
                    FA.path(&m, pts, r: 0.0026, soot, sides: 5)
                }
            }
            // Rain streaks running down the margin below each top bed.
            for _ in 0..<3 {
                let sx = rng.float((xa + 0.03)...(xb - 0.03)), sh = rng.float(0.04...(h * 0.5))
                FM.prism(&m, [V2(sx, y + h - 0.016 - sh), V2(sx + 0.007, y + h - 0.016 - sh), V2(sx + 0.007, y + h - 0.012), V2(sx, y + h - 0.012)],
                         front: 0.0125, depth: 0.0012, soot, bevel: 0.0004)
            }
            // Brick infill beside short blocks: stretcher courses at 75 mm pitch, recessed.
            if !long {
                let bx0 = xr + jt, bx1 = W / 2
                let rows = Int((h) / 0.0675)
                for r in 0..<rows {
                    let ry0 = y + Float(r) * 0.0675 + 0.0035, ry1 = y + Float(r + 1) * 0.0675 - 0.0035
                    let offset: Float = r % 2 == 0 ? 0 : 0.06
                    FM.brick(&m, x0: bx0 + offset, x1: bx1, y0: ry0, y1: min(ry1, y + h - 0.003), depth: 0.07, brick, rng: &rng, chip: rng.chance(0.08), proud: -0.006)
                    if offset > 0 { FM.brick(&m, x0: bx0, x1: bx0 + offset - 0.007, y0: ry0, y1: min(ry1, y + h - 0.003), depth: 0.07, brick, rng: &rng, chip: false, proud: -0.006) }
                }
            }
            y += h + jt
        }
        // Mortar run-off stain below the second joint and a spalled arris on the top long block.
        FA.box(&m, V3(0.12, 0.0015, 0.004), V3(-0.12, 0.2505 + 0.005, 0.0), soot, r: 0.0005)
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
