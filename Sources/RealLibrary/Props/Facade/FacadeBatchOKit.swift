import simd
import Foundation

/// Helpers for the roofline, cornice and storefront facade props of batch O. Same frame as `FA`: wall plane at
/// z = 0 for wall pieces; free-standing gables are centered on z.
enum FO8 {
    /// Courses of dressed blocks standing proud of a wall face. Joints are 8 mm, courses stagger by half a block,
    /// block width varies +-20 %. `top` / `bottom` clip the field to a profile (blocks that would cross are skipped).
    static func courses(_ m: inout Model, _ rng: inout SeededRNG, xr: ClosedRange<Float>, yr: ClosedRange<Float>,
                        course: Float, block: Float, z: Float, depth: Float, mats: [MaterialKey],
                        top: (Float) -> Float = { _ in 99 }, bottom: (Float) -> Float = { _ in -99 },
                        skip: (Float, Float, Float, Float) -> Bool = { _, _, _, _ in false }) {
        var row = 0
        var y = yr.lowerBound
        while y + course <= yr.upperBound + 0.001 {
            let h = course - 0.008
            var x0 = xr.lowerBound
            var first = true
            while x0 < xr.upperBound - 0.02 {
                let w = first && row % 2 == 1 ? block * 0.5 : block * rng.float(0.8...1.2)
                let x1 = min(x0 + w, xr.upperBound)
                first = false
                if x1 - x0 > 0.04 {
                    let t = min(top(x0 + 0.004), top(x1 - 0.004)), b = max(bottom(x0 + 0.004), bottom(x1 - 0.004))
                    if t >= y + course - 0.002 && b <= y + 0.002 && !skip(x0, x1, y, y + h) {
                        let mat = mats[rng.int(0...(mats.count - 1))]
                        slab(&m, x1 - x0 - 0.008, h, depth, V3((x0 + x1) / 2, y + course / 2, z), mat)
                    }
                }
                x0 = x1
            }
            y += course
            row += 1
        }
    }

    /// Flat dressed block: rectangle extruded `d` along Z with a 2 mm arris (about 30 tris against 80 for a rounded box).
    static func slab(_ m: inout Model, _ w: Float, _ h: Float, _ d: Float, _ c: V3, _ mat: MaterialKey, bevel: Float = 0.002) {
        m.add(Prim.extrude(Shape2D.rect(w, h), depth: d, bevel: min(bevel, d * 0.3), bevelSegments: 1, material: mat), Xform(translation: c))
    }

    /// A profile (x out from the wall, y up) run along X on both faces of a wall of half-thickness `zWall`.
    static func runBoth(_ m: inout Model, _ profile: [V2], length: Float, x: Float = 0, y: Float, zWall: Float,
                        _ mat: MaterialKey, bevel: Float = 0.002) {
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(profile, depth: length, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x, y, s * zWall), rotation: FA.q(s > 0 ? -90 : 90, FA.Y)))
        }
    }

    /// Thin proud patches on both faces of a free-standing wall: weathering (soot, lichen, efflorescence, rust runs).
    static func patches(_ m: inout Model, _ rng: inout SeededRNG, count: Int, xr: ClosedRange<Float>, yr: ClosedRange<Float>,
                        w: ClosedRange<Float>, h: ClosedRange<Float>, zFace: Float, mats: [MaterialKey]) {
        for _ in 0..<count {
            let s: Float = rng.chance(0.5) ? 1 : -1
            slab(&m, rng.float(w), rng.float(h), 0.0025,
                 V3(rng.float(xr), rng.float(yr), s * (zFace + 0.0004 * Float(rng.int(0...3)))),
                 mats[rng.int(0...(mats.count - 1))], bevel: 0.0006)
        }
    }

    /// Half width of a symmetric outline given as its right half (x, y) points, at height y.
    static func halfWidth(_ right: [V2], at y: Float) -> Float {
        var best: Float = 0
        for i in 0..<(right.count - 1) {
            let a = right[i], b = right[i + 1]
            let lo = min(a.y, b.y), hi = max(a.y, b.y)
            if y >= lo - 1e-5 && y <= hi + 1e-5 {
                let t = hi - lo < 1e-6 ? 0 : (y - a.y) / (b.y - a.y)
                best = max(best, a.x + (b.x - a.x) * t)
            }
        }
        return best
    }
}
