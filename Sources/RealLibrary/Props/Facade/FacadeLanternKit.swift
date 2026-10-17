import simd
import Foundation

/// Tapered four-pane lantern shared by the wall lamp props. Axis is +Y through `c` (x, z used).
extension FC {
    /// Half width of a tapering square body at height `y`.
    static func lanternHalf(y: Float, y0: Float, y1: Float, h0: Float, h1: Float) -> Float {
        h0 + (h1 - h0) * (y - y0) / (y1 - y0)
    }

    /// Glass skin, four corner posts, base and top frame bars and optional muntin crosses.
    static func lantern(_ m: inout Model, c: V3, y0: Float, y1: Float, h0: Float, h1: Float, post: Float,
                        frame: MaterialKey, glass: MaterialKey, muntins: Bool, rng: inout SeededRNG) {
        let gi: Float = 0.004
        let rings = [y0, (y0 + y1) / 2, y1].map { y -> [V3] in
            let h = lanternHalf(y: y, y0: y0, y1: y1, h0: h0, h1: h1) - gi
            return Prim.ring(Shape2D.rect(2 * h, 2 * h), y: y, offset: V3(c.x, 0, c.z))
        }
        let skin = Prim.loft(rings, material: glass)
        m.add(skin)
        m.add(skin.flipped())
        // Corner posts: square section, tapering with the body.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let a = V3(c.x + sx * h0, y0, c.z + sz * h0), b = V3(c.x + sx * h1, y1, c.z + sz * h1)
            m.add(Prim.tube([a, b], radii: [post, post], sides: 8, seamTile: 0.1, material: frame, capEnd: true))
        } }
        // Base and top frame bars with a rail thickness of 1.6 post radii.
        let t = post * 1.5
        for y in [y0 + t / 2, y1 - t / 2] {
            let h = lanternHalf(y: y, y0: y0, y1: y1, h0: h0, h1: h1)
            FA.box(&m, V3(2 * h, t, t), V3(c.x, y, c.z + h), frame, r: 0.0012)
            FA.box(&m, V3(2 * h, t, t), V3(c.x, y, c.z - h), frame, r: 0.0012)
            FA.box(&m, V3(t, t, 2 * h), V3(c.x + h, y, c.z), frame, r: 0.0012)
            FA.box(&m, V3(t, t, 2 * h), V3(c.x - h, y, c.z), frame, r: 0.0012)
        }
        guard muntins else { return }
        // Muntin cross on each face: one vertical, one horizontal bar, slightly proud of the glass.
        let ym = (y0 + y1) / 2
        let w = post * 0.55
        for f in 0..<4 {
            let ang = Float(f) * .pi / 2
            let d = V3(cos(ang), 0, sin(ang)), s = V3(-sin(ang), 0, cos(ang))
            let pa = c + d * (h0 + 0.002) + V3(0, y0, 0), pb = c + d * (h1 + 0.002) + V3(0, y1, 0)
            m.add(Prim.tube([pa, pb], radii: [w, w], sides: 4, seamTile: 0.1, material: frame, capEnd: true))
            let hm = lanternHalf(y: ym, y0: y0, y1: y1, h0: h0, h1: h1)
            m.add(Prim.tube([c + d * (hm + 0.002) + s * (-hm) + V3(0, ym, 0), c + d * (hm + 0.002) + s * hm + V3(0, ym, 0)],
                            radii: [w, w], sides: 4, seamTile: 0.1, material: frame, capEnd: true))
        }
    }
}
