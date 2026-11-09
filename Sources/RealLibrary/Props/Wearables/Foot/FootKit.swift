import simd
import Foundation

/// Shared helpers for the foot wearables. Origin is the ankle joint centre, +Z toes, +Y up, +X the wearer's left. The invisible
/// foot is 29 cm long (heel at z -7.8 cm, toe at z +21.2 cm) with the sole 8.2 cm below the origin. The ankle is a 23 cm
/// circumference oval of radii 3.4 cm (X) by 4.0 cm (Z) centred on the Y axis.
enum FootKit {
    typealias K = ChestKit
    static let zHeel: Float = -0.078, zToe: Float = 0.212, soleY: Float = -0.082

    /// Half width of the footprint at normalised length `v` (-1 heel ... +1 toe).
    static func width(_ v: Float) -> Float {
        0.0505 * (0.70 + 0.30 * smoothstep(-0.75, 0.30, v)) * (1 - 0.20 * smoothstep(0.40, 1.0, v))
    }

    /// Station of a shoe body: outline at height `y` spans z `zb` (back) to `zf` (front), `sx` scales the width, `grow` offsets outward.
    struct Station {
        var y: Float, zb: Float, zf: Float, sx: Float = 1, grow: Float = 0
    }

    static func interp(_ s: [Station], _ y: Float) -> Station {
        if y <= s[0].y { return s[0] }
        if y >= s[s.count - 1].y { return s[s.count - 1] }
        var i = 0
        while s[i + 1].y < y { i += 1 }
        let a = s[i], b = s[i + 1]
        let f = (y - a.y) / (b.y - a.y)
        let t = f * f * (3 - 2 * f) * 0.5 + f * 0.5
        return Station(y: y, zb: a.zb + (b.zb - a.zb) * t, zf: a.zf + (b.zf - a.zf) * t, sx: a.sx + (b.sx - a.sx) * t, grow: a.grow + (b.grow - a.grow) * t)
    }

    /// Closed outline, toe at angle -pi/2 (same winding as the sneaker lofts).
    static func ring(_ n: Int, _ st: Station, grow: Float = 0, e: Float = 2.6) -> [V3] {
        let zc = (st.zb + st.zf) / 2, h = (st.zf - st.zb) / 2
        return (0..<n).map { k in
            let a = 2 * Float.pi * Float(k) / Float(n)
            let c = cos(a), s = -sin(a)
            let u = copysign(pow(abs(c), 2 / e), c), v = copysign(pow(abs(s), 2 / e), s)
            let g = st.grow + grow
            return V3(u * (width(v) * st.sx + g), st.y, zc + v * (h + g))
        }
    }

    static func rings(_ n: Int, _ prof: [Station], _ ys: [Float], grow: Float = 0) -> [[V3]] {
        ys.map { ring(n, interp(prof, $0), grow: grow) }
    }

    /// Point on the front half (toe side) of the outline at height `y` and lateral position `x`, with an outward normal.
    static func front(_ prof: [Station], y: Float, x: Float, lift: Float = 0) -> (p: V3, n: V3) {
        let st = interp(prof, y)
        let pts = ring(360, st)
        let zc = (st.zb + st.zf) / 2
        var best = pts[0]
        var found = false
        for k in 0..<pts.count {
            let a = pts[k], b = pts[(k + 1) % pts.count]
            if a.z > zc && b.z > zc && (a.x - x) * (b.x - x) <= 0 && a.x != b.x {
                let f = (x - a.x) / (b.x - a.x)
                best = lerp(a, b, f); found = true; break
            }
        }
        if !found { best = pts.min { abs($0.x - x) + (($0.z > zc) ? 0 : 1) < abs($1.x - x) + (($1.z > zc) ? 0 : 1) }! }
        let dz = (interp(prof, y + 0.002).zf - interp(prof, y - 0.002).zf) / 0.004
        let n = simd_normalize(V3(x * 8, -dz, 1))
        return (best + n * lift, n)
    }

    /// Toe spring: lifts the forefoot so the sole rocks like a worn shoe.
    static func spring(_ p: V3) -> V3 {
        let t = smoothstep(0.10, 0.215, p.z)
        return V3(p.x, p.y + 0.013 * t * t, p.z)
    }

    static func sprung(_ s: Surface) -> Surface { var t = s; t.deform(spring); return t }
}
