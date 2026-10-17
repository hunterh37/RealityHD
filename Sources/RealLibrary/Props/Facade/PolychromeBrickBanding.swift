import simd
import Foundation

/// Polychrome brick banding: a High Victorian Gothic (Ruskinian) constructional-polychromy band, 2.0 m
/// long. Five Flemish-bond courses: red field, a buff Gault band, red stretchers with Staffordshire
/// blue-black headers, a blue-black band, then red again, in recessed lime joints. Over them runs a
/// limestone string course in two stones with a weathered (sloped) top and a drip groove under the nose;
/// soot has darkened the brick course in its shadow.
public struct PolychromeBrickBanding: RealAsset {
    public static let id = "polychrome-brick-banding"
    public static let summary = "Polychrome brick banding, 2.0 m: red brick courses with buff and blue-black bands and a black diaper course under a chamfered limestone string course."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, distance: 3.0)

    /// Band length (m).
    public var length: Float = 2.0
    /// Number of brick courses below the string course.
    public var courses: Int = 5
    /// Joint thickness.
    public var joint: Float = 0.01
    /// Red field brick.
    public var red: MaterialKey = "brick.unit-red"
    /// Buff band brick.
    public var buff: MaterialKey = "brick.unit-buff"
    /// Blue-black engineering brick.
    public var blue: MaterialKey = "brick.unit-blue"
    /// String course stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Mortar.
    public var mortar: MaterialKey = "brick.mortar-lime"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let j = joint, gauge: Float = 0.075, bh: Float = 0.065, half = length / 2, depth: Float = 0.065
        let S: Float = 0.215 + j, Hd: Float = 0.1025 + j
        let reds: [MaterialKey] = [red, red, "brick.unit-red-dark", "brick.unit-red-light"]
        for c in 0..<courses {
            let y0 = Float(c) * gauge + j / 2, y1 = y0 + bh
            var x = -half - (c % 2 == 0 ? 0 : (Hd + S) / 2)
            var isHeader = true, i = 0
            while x < half {
                let w = isHeader ? Hd : S
                let x0 = max(x + j / 2, -half + j / 2), x1 = min(x + w - j / 2, half - j / 2)
                if x1 - x0 > 0.025 {
                    var r = rng.fork(c * 100 + i)
                    let mat: MaterialKey
                    switch c {
                    case 1: mat = r.chance(0.2) ? "brick.unit-buff-dark" : buff
                    case 2: mat = isHeader ? blue : r.pick(reds)
                    case 3: mat = blue
                    case courses - 1: mat = r.chance(0.7) ? "brick.unit-sooted" : r.pick(reds)
                    default: mat = isHeader && r.chance(0.5) ? "brick.unit-header" : r.pick(reds)
                    }
                    FM.brick(&m, x0: x0, x1: x1, y0: y0, y1: y1, depth: depth, mat, rng: &r, chip: c == 0 && i == 7)
                }
                x += w; isHeader.toggle(); i += 1
            }
        }
        let top = Float(courses) * gauge
        FM.mortar(&m, w: length, h: top, recess: 0.005, back: 0.07, mortar)
        // Limestone string course: weathered top, square nose, drip groove; two stones with a 6 mm joint.
        let b = top + 0.002, back: Float = -0.07
        let profile: [V2] = [V2(back, b), V2(0.012, b), V2(0.012, b + 0.008), V2(0.019, b + 0.008), V2(0.019, b), V2(0.03, b),
                             V2(0.03, b + 0.083), V2(0.0, 0.5), V2(back, 0.5)]
        for k in 0..<2 {
            let cx = -half / 2 + Float(k) * half
            FA.run(&m, profile, length: half - 0.006, at: V3(cx, 0, 0), k == 0 ? stone : "stone.limestone-sooted", bevel: 0.003)
        }
        FM.prism(&m, [V2(-0.003, b + 0.004), V2(0.003, b + 0.004), V2(0.003, 0.495), V2(-0.003, 0.495)], front: 0.024, depth: 0.09, mortar, bevel: 0.001)
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
