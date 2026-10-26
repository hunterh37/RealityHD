import simd
import Foundation

/// Helpers for the o7 facade batch (arched heads, block runs). Same frame as `FA`: wall plane at z = 0,
/// piece projecting toward +Z.
enum FO7 {
    /// Wedge-shaped blocks around centre `c` (x, y), angles in degrees `a0...a1` (counter-clockwise), radii
    /// `rIn...rOut`, extruded `depth` along Z from `z0`. Each block is a separate beveled solid with a joint gap.
    static func voussoirs(_ m: inout Model, c: V2, rIn: Float, rOut: Float, from a0: Float, to a1: Float, count: Int,
                          z0: Float, depth: Float, gap: Float = 0.004, bevel: Float = 0.002,
                          _ mat: (Int) -> MaterialKey) {
        for i in 0..<count {
            let t0 = a0 + (a1 - a0) * Float(i) / Float(count)
            let t1 = a0 + (a1 - a0) * Float(i + 1) / Float(count)
            let da0 = (gap / 2) / rIn * 180 / .pi, da1 = (gap / 2) / rOut * 180 / .pi
            func pt(_ r: Float, _ a: Float) -> V2 { V2(c.x + r * cos(a * .pi / 180), c.y + r * sin(a * .pi / 180)) }
            let poly = Shape2D.deduped([pt(rIn, t0 + da0), pt(rOut, t0 + da1), pt(rOut, t1 - da1), pt(rIn, t1 - da0)])
            m.add(Prim.extrude(poly, depth: depth, bevel: bevel, bevelSegments: 1, material: mat(i)),
                  Xform(translation: V3(0, 0, z0 + depth / 2)))
        }
    }

    /// Points on an ellipse arc (centre c, radii rx, ry) from `a0` to `a1` degrees at depth z.
    static func ellipse(c: V2, rx: Float, ry: Float, from a0: Float, to a1: Float, steps: Int, z: Float) -> [V3] {
        (0...steps).map { i in
            let a = (a0 + (a1 - a0) * Float(i) / Float(steps)) * .pi / 180
            return V3(c.x + rx * cos(a), c.y + ry * sin(a), z)
        }
    }

    /// Flat stain quad (soot, rust bleed, lime wash) hanging down a +Z face at z, `w` wide and `h` tall: two triangles.
    static func streak(_ m: inout Model, x: Float, top: Float, w: Float, h: Float, z: Float, _ mat: MaterialKey) {
        decal(&m, c: V3(x, top - h / 2, z + 0.0008), w: w, h: h, mat)
    }
    /// Flat quad facing +Z centred on c.
    static func decal(_ m: inout Model, c: V3, w: Float, h: Float, _ mat: MaterialKey) {
        var s = Surface(material: mat)
        let n = V3(0, 0, 1)
        let a = s.add(c + V3(-w / 2, -h / 2, 0), n, V2(0, 0))
        let b = s.add(c + V3(w / 2, -h / 2, 0), n, V2(w, 0))
        let d = s.add(c + V3(w / 2, h / 2, 0), n, V2(w, h))
        let e = s.add(c + V3(-w / 2, h / 2, 0), n, V2(0, h))
        s.quad(a, b, d, e)
        s.computeTangents()
        m.add(s)
    }

    /// Four-point rosette: a boss with petals around it, facing +Z.
    static func rosette(_ m: inout Model, at c: V3, r: Float, petals: Int = 8, _ mat: MaterialKey) {
        let sub = 2
        for i in 0..<petals {
            let a = Float(i) / Float(petals) * 2 * .pi
            m.add(Prim.superellipsoid(V3(r * 0.5, r * 0.9, r * 0.35), exponent: 2, subdivisions: sub, material: mat),
                  Xform(translation: c + V3(cos(a) * r * 0.55, sin(a) * r * 0.55, 0),
                        rotation: FA.q(a * 180 / .pi - 90, FA.Z)))
        }
        FC.bead(&m, r: r * 0.3, at: c + V3(0, 0, r * 0.12), mat, sub: 2)
    }

    /// Returns the outline wound counter-clockwise.
    static func ccw(_ pts: [V2]) -> [V2] {
        var a: Float = 0
        for i in 0..<pts.count { let p = pts[i], q = pts[(i + 1) % pts.count]; a += p.x * q.y - q.x * p.y }
        return a < 0 ? pts.reversed() : pts
    }

    /// Turned baluster (r, y) profile, `h` tall with base radius `r`.
    static func baluster(_ m: inout Model, at c: V3, h: Float, r: Float, _ mat: MaterialKey, segments: Int = 8) {
        let f: [(Float, Float)] = [(0, 0), (0.9, 0), (0.9, 0.06), (0.5, 0.12), (0.95, 0.3), (0.42, 0.55), (0.42, 0.78), (0.7, 0.86),
                                   (0.9, 0.93), (0.9, 1), (0, 1)]
        m.add(Prim.lathe(f.map { V2($0.0 * r, $0.1 * h) }, segments: segments, seamTile: 0.2, material: mat), Xform(translation: c))
    }

    /// Comb of square teeth (dentils, blocks) as one extruded outline: `count` teeth `w` wide at `pitch`,
    /// `h` tall with a `bar` thick backing strip at the top, spanning X centred on 0, y from 0, extruded `depth` along Z from z0.
    static func comb(_ m: inout Model, count: Int, pitch: Float, w: Float, h: Float, bar: Float = 0.006, y0: Float, z0: Float,
                     depth: Float, _ mat: MaterialKey) {
        let xs = -Float(count - 1) * pitch / 2 - w / 2
        let valley = h - bar
        var pts: [V2] = []
        for i in 0..<count {
            let x = xs + Float(i) * pitch
            pts += [V2(x, 0), V2(x + w, 0)]
            if i < count - 1 { pts += [V2(x + w, valley), V2(x + pitch, valley)] }
        }
        let xe = xs + Float(count - 1) * pitch + w
        pts += [V2(xe, h), V2(xs, h)]
        m.add(Prim.extrude(ccw(Shape2D.deduped(pts)), depth: depth, bevel: 0.0015, bevelSegments: 1, material: mat),
              Xform(translation: V3(0, y0, z0 + depth / 2)))
    }

    /// Acute (lancet) arch with half width `hw`, arc radius `R` > hw, springing at `spring`, offset outward by `delta`
    /// (concentric arcs). Arcs only, right springing to left springing over the apex, at depth z and x offset cx.
    static func lancetArc(hw: Float, R: Float, spring: Float, delta: Float = 0, cx: Float = 0, z: Float = 0, steps: Int = 12) -> [V3] {
        let r = R + delta
        let aMax = acos((R - hw) / r)
        var pts: [V3] = []
        for i in 0...steps {   // right arc, centre (hw - R, spring)
            let a = Float(i) / Float(steps) * aMax
            pts.append(V3(cx + hw - R + r * cos(a), spring + r * sin(a), z))
        }
        for i in stride(from: steps - 1, through: 0, by: -1) {   // left arc mirrored
            let a = Float(i) / Float(steps) * aMax
            pts.append(V3(cx - (hw - R + r * cos(a)), spring + r * sin(a), z))
        }
        // The apex point is shared; drop the duplicate.
        return pts
    }
    /// Closed outline of a lancet opening: base on y = 0, straight jambs to `spring`, then the acute arch.
    static func lancetOutline(hw: Float, R: Float, spring: Float, steps: Int = 12) -> [V2] {
        var pts: [V2] = [V2(-hw, 0), V2(hw, 0)]
        for p in lancetArc(hw: hw, R: R, spring: spring, steps: steps) { pts.append(V2(p.x, p.y)) }
        return Shape2D.deduped(pts)
    }
    /// Apex height of a lancet arch.
    static func lancetApex(hw: Float, R: Float, spring: Float, delta: Float = 0) -> Float {
        let r = R + delta
        return spring + r * sin(acos((R - hw) / r))
    }
}
