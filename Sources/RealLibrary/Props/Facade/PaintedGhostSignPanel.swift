import simd
import Foundation

/// Painted ghost sign: a 3 x 2 m panel of common-bond brick with a lime-washed advertising ground, hand
/// lettered in faded oxide red, bordered, flaking to bare brick and streaked by rain from the stone cap.
public struct PaintedGhostSignPanel: RealAsset {
    public static let id = "painted-ghost-sign-panel"
    public static let summary = "Faded painted brick advertisement panel, 3.0 x 2.0 m: lime wash ground, flaking lettering, spalled bricks, stone cills."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 12500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 6, distance: 1.2)

    /// Top line of the advertisement (A-Z, 0-9).
    public var headline = "HAYES"
    /// Second line.
    public var subline = "FLOUR AND FEED"
    public var brick: MaterialKey = "brick.red"
    public var stone: MaterialKey = "stone.limestone-sooted"
    public var ground: MaterialKey = "paint.stucco:CFC6AE"
    public var ink: [MaterialKey] = ["paint.stucco:8A3A2C", "paint.stucco:96493A", "paint.stucco:7B3A2F", "paint.stucco:A5594A"]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zb: Float = 0.022
        // Brick field between cill and cap.
        FA.box(&m, V3(2.98, 1.86, zb), V3(0, 1.0, zb / 2), brick, r: 0.002)
        // Dressed limestone cap with a drip nosing and a weathered cill with a washed slope.
        FA.run(&m, [V2(0, 0), V2(0.03, 0), V2(0.03, 0.045), V2(0.022, 0.07), V2(0, 0.07)], length: 3.0, at: V3(0, 1.93, 0), stone, bevel: 0.003)
        FA.run(&m, [V2(0, 0), V2(0.03, 0), V2(0.03, 0.02), V2(0.012, 0.06), V2(0, 0.06)], length: 3.0, at: V3(0, 0.0, 0), stone, bevel: 0.003)
        // Soldier course under the cap and a header course above the cill, each brick proud 2 mm.
        var x: Float = -1.46
        while x < 1.45 {
            let jit = rng.float(-0.002...0.002)
            FG.flat(&m, V3(0.062, 0.2, 0.002), V3(x, 1.8 + jit, zb + 0.001), rng.chance(0.2) ? "brick.unit-red-dark" : "brick.unit-red-light")
            x += 0.068
        }
        x = -1.43
        while x < 1.44 {
            FG.flat(&m, V3(0.212, 0.062, 0.002), V3(x, 0.115, zb + 0.001), rng.chance(0.25) ? "brick.unit-red-dark" : "brick.unit-red")
            x += 0.218
        }
        // Lime-washed ground: three overlapping coats of different age.
        let gz = zb + 0.0008
        FA.box(&m, V3(2.5, 1.38, 0.0016), V3(0, 1.0, gz), ground, r: 0.0004)
        FA.box(&m, V3(2.56, 1.2, 0.0016), V3(0.02, 0.98, gz + 0.0002), "paint.stucco:C5BBA3", r: 0.0004)
        FA.box(&m, V3(2.38, 1.46, 0.0016), V3(-0.03, 1.02, gz - 0.0002), "paint.stucco:D3CBB6", r: 0.0004)
        // Border rule and inner rule.
        for (w, h, x, y) in [(2.46, 0.035, 0.0, 1.62), (2.46, 0.035, 0.0, 0.4), (0.035, 1.25, -1.215, 1.01), (0.035, 1.25, 1.215, 1.01)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, 0.0012), V3(x, y, gz + 0.0016), ink[0], r: 0.0003)
        }
        // Lettering one glyph at a time, each in a different degree of fade.
        func line(_ s: String, h: Float, y: Float, stroke: Float) {
            let w = strokeTextWidth(s, height: h), pitch = 5.4 * h / 6
            for (i, c) in s.enumerated() where c != " " {
                let cx = -w / 2 + (Float(i)) * pitch + 2 * h / 6
                FG.text(&m, String(c), h: h, stroke: stroke, depth: 0.0014, at: V3(cx, y, gz + 0.0017), rng.pick(ink))
            }
        }
        line(headline, h: 0.5, y: 1.25, stroke: 0.09)
        line(subline, h: 0.17, y: 0.83, stroke: 0.03)
        line("EST 1894", h: 0.1, y: 0.62, stroke: 0.018)
        // Spalls: ground lost to bare brick, weathered edges and a flaking top left corner.
        for k in 0..<12 {
            let cx = k == 0 ? -1.1 : rng.float(-1.15...1.15), cy = k == 0 ? 1.52 : rng.float(0.45...1.6)
            for _ in 0..<rng.int(4...7) {
                FG.flat(&m, V3(rng.float(0.05...0.2), rng.float(0.03...0.11), 0.002), V3(cx + rng.float(-0.1...0.1), cy + rng.float(-0.07...0.07), gz + 0.0035),
                       rng.chance(0.6) ? "brick.unit-red-dark" : "brick.common", rot: FA.q(rng.float(-20...20), FA.Z))
            }
        }
        // Dirt bloom and soot patches on the lime wash.
        for _ in 0..<9 {
            FG.flat(&m, V3(rng.float(0.2...0.6), rng.float(0.1...0.3), 0.0004), V3(rng.float(-1.1...1.1), rng.float(0.4...1.65), gz + 0.0026), "paint.stucco:A99F88", rot: FA.q(rng.float(-10...10), FA.Z))
        }
        // Rain streaks from the cap and rust stain below the tie plates.
        for _ in 0..<9 {
            let x = rng.float(-1.45...1.45), len = rng.float(0.3...1.0)
            FG.flat(&m, V3(rng.float(0.02...0.06), len, 0.0012), V3(x, 1.9 - len / 2, zb + 0.0003), "metal.steel:4B4338")
        }
        // Wrought iron tie plates (star anchors) with rust runs.
        for (x, y) in [(-1.3, 1.45), (1.3, 1.45), (-1.3, 0.55), (1.3, 0.55)] as [(Float, Float)] {
            FA.cylZ(&m, r: 0.035, h: 0.006, at: V3(x, y, zb), "metal.rust", bevel: 0.0015, segments: 12)
            FG.flat(&m, V3(0.1, 0.012, 0.007), V3(x, y, zb + 0.004), "metal.rust", rot: FA.q(45, FA.Z))
            FG.flat(&m, V3(0.1, 0.012, 0.007), V3(x, y, zb + 0.004), "metal.rust", rot: FA.q(-45, FA.Z))
            FG.flat(&m, V3(0.014, 0.28, 0.0008), V3(x + 0.01, y - 0.17, zb + 0.0004), "metal.rust-grime")
        }
        // Efflorescence at the foot of the wall.
        for _ in 0..<6 {
            FG.flat(&m, V3(rng.float(0.15...0.5), rng.float(0.03...0.07), 0.001), V3(rng.float(-1.3...1.3), rng.float(0.11...0.22), zb + 0.0004), "sign.white:D9D5CB")
        }
        groundAO(&m, height: 0.3, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
