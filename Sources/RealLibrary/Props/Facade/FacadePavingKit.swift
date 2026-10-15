import simd
import Foundation

/// Helpers for the facade customizer paving tiles: clipped polygon pavers on a bedding slab.
enum FPK {
    /// Clip a convex or concave polygon (XZ) to an axis-aligned rectangle (Sutherland-Hodgman).
    static func clip(_ poly: [V2], x0: Float, x1: Float, z0: Float, z1: Float) -> [V2] {
        var out = poly
        let planes: [(V2) -> Float] = [{ $0.x - x0 }, { x1 - $0.x }, { $0.y - z0 }, { z1 - $0.y }]
        for f in planes {
            guard !out.isEmpty else { return [] }
            let inp = out; out = []
            for i in 0..<inp.count {
                let a = inp[i], b = inp[(i + 1) % inp.count]
                let fa = f(a), fb = f(b)
                if fa >= 0 { out.append(a) }
                if (fa >= 0) != (fb >= 0) { let t = fa / (fa - fb); out.append(a + (b - a) * t) }
            }
        }
        return out
    }

    /// Clip a polygon to the half-plane dot(p - o, n) <= 0.
    static func clipHalf(_ poly: [V2], o: V2, n: V2) -> [V2] {
        var out: [V2] = []
        for i in 0..<poly.count {
            let a = poly[i], b = poly[(i + 1) % poly.count]
            let fa = -simd_dot(a - o, n), fb = -simd_dot(b - o, n)
            if fa >= 0 { out.append(a) }
            if (fa >= 0) != (fb >= 0) { let t = fa / (fa - fb); out.append(a + (b - a) * t) }
        }
        return out
    }

    static func area(_ p: [V2]) -> Float {
        var s: Float = 0
        for i in 0..<p.count { let a = p[i], b = p[(i + 1) % p.count]; s += a.x * b.y - b.x * a.y }
        return s / 2
    }

    static func centroid(_ p: [V2]) -> V2 { p.reduce(V2(0, 0), +) / Float(max(1, p.count)) }

    /// Shrink a convex polygon toward its edges by `d` (half-plane offset of every edge).
    static func inset(_ poly: [V2], _ d: Float) -> [V2] {
        var p = poly
        if area(p) < 0 { p.reverse() }
        var out = p
        for i in 0..<p.count {
            let a = p[i], b = p[(i + 1) % p.count]
            let e = simd_normalize(b - a)
            let nOut = V2(e.y, -e.x)   // outward for CCW
            out = clipHalf(out, o: a - nOut * d, n: nOut)
            if out.count < 3 { return [] }
        }
        return out
    }

    /// Remove near-duplicate points.
    static func dedup(_ p: [V2], eps: Float = 0.0015) -> [V2] {
        var o: [V2] = []
        for q in p where o.last.map({ simd_distance($0, q) > eps }) ?? true { o.append(q) }
        while o.count > 2, simd_distance(o[0], o[o.count - 1]) <= eps { o.removeLast() }
        return o
    }

    /// Paver prism from an XZ outline: top at `top`, `thick` deep, beveled top edge, tiny tilt.
    static func piece(_ m: inout Model, _ outline: [V2], top: Float, thick: Float, bevel: Float, _ mat: MaterialKey, tilt: Float, rng: inout SeededRNG) {
        var p = dedup(outline)
        guard p.count >= 3, abs(area(p)) > 0.0003 else { return }
        let c = centroid(p)
        p = p.map { V2($0.x - c.x, -($0.y - c.y)) }
        if area(p) < 0 { p.reverse() }
        var s = Prim.extrude(p, depth: thick, bevel: bevel, bevelSegments: 1, material: mat)
        s = s.transformed(Xform(rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        var x = Xform(translation: V3(c.x, top - thick / 2, c.y))
        if tilt > 0 { x.rotation = simd_quatf(degrees: rng.float(-tilt...tilt), axis: rng.unitVector()) }
        m.add(s, x)
    }

    static func rect(_ cx: Float, _ cz: Float, _ w: Float, _ d: Float, yaw: Float = 0) -> [V2] {
        let c = cos(yaw), s = sin(yaw)
        return [V2(-w / 2, -d / 2), V2(w / 2, -d / 2), V2(w / 2, d / 2), V2(-w / 2, d / 2)].map {
            V2(cx + $0.x * c - $0.y * s, cz + $0.x * s + $0.y * c)
        }
    }

    /// Moss cushion tuft at a joint.
    static func moss(_ m: inout Model, at p: V2, y: Float, len: Float, alongX: Bool) {
        let sz = alongX ? V3(len, 0.014, 0.02) : V3(0.02, 0.014, len)
        m.add(Prim.superellipsoid(sz, exponent: 2.4, subdivisions: 2, material: "moss.cushion"), Xform(translation: V3(p.x, y, p.y)))
    }
}
