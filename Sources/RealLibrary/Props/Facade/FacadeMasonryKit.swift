import simd
import Foundation

/// Helpers for modelled masonry panels: individual bricks and stones over a recessed mortar bed.
/// Frame as `FA`: wall face at z = 0, units project to z = 0 and run back toward -Z.
enum FM {
    /// Clips a convex polygon to an axis-aligned rectangle (Sutherland-Hodgman).
    static func clip(_ poly: [V2], minX: Float, maxX: Float, minY: Float, maxY: Float) -> [V2] {
        var out = poly
        let edges: [(V2) -> Float] = [{ $0.x - minX }, { maxX - $0.x }, { $0.y - minY }, { maxY - $0.y }]
        for d in edges {
            guard !out.isEmpty else { break }
            let inp = out
            out = []
            for i in inp.indices {
                let a = inp[i], b = inp[(i + 1) % inp.count]
                let da = d(a), db = d(b)
                if da >= 0 { out.append(a) }
                if (da >= 0) != (db >= 0) { out.append(a + (b - a) * (da / (da - db))) }
            }
        }
        return Shape2D.deduped(out)
    }

    static func area(_ p: [V2]) -> Float {
        var s: Float = 0
        for i in p.indices { let a = p[i], b = p[(i + 1) % p.count]; s += a.x * b.y - b.x * a.y }
        return s / 2
    }

    /// Prism from an XY outline, front face at `front`, running back `depth`.
    static func prism(_ m: inout Model, _ outline: [V2], front: Float, depth: Float, _ mat: MaterialKey, bevel: Float = 0.003) {
        var o = outline
        if area(o) < 0 { o.reverse() }
        guard o.count >= 3, abs(area(o)) > 1e-5 else { return }
        m.add(Prim.extrude(o, depth: depth, bevel: bevel, bevelSegments: 1, material: mat),
              Xform(translation: V3(0, 0, front - depth / 2)))
    }

    /// One brick between x0...x1, y0...y1 (joint already removed), with small lay jitter. A chip knocks
    /// a corner off the outline (arris damage).
    static func brick(_ m: inout Model, x0: Float, x1: Float, y0: Float, y1: Float, depth: Float, _ mat: MaterialKey,
                      rng: inout SeededRNG, chip: Bool = false, proud: Float = 0) {
        let z = proud + rng.float(-0.002...0.0015)
        if chip {
            let c = rng.float(0.012...0.02), corner = rng.int(0...3)
            var pts = [V2(x0, y0), V2(x1, y0), V2(x1, y1), V2(x0, y1)]
            let p = pts[corner], nx = pts[(corner + 1) % 4], pv = pts[(corner + 3) % 4]
            let a = p + simd_normalize(pv - p) * c, b = p + simd_normalize(nx - p) * c * 0.7
            pts.remove(at: corner)
            pts.insert(contentsOf: [a, b], at: corner)
            // Chip is shallow: full-depth cut outline set slightly back plus a front skin keeps it simple.
            prism(&m, pts, front: z, depth: depth, mat, bevel: 0.0025)
            prism(&m, [V2(x0, y0), V2(x1, y0), V2(x1, y1), V2(x0, y1)], front: z - 0.012, depth: depth - 0.012, mat, bevel: 0.002)
        } else {
            prism(&m, [V2(x0, y0), V2(x1, y0), V2(x1, y1), V2(x0, y1)], front: z, depth: depth, mat, bevel: 0.003)
        }
    }

    /// Mortar bed behind the units: slab from z = -back to z = -recess with a lightly trowelled face.
    static func mortar(_ m: inout Model, w: Float, h: Float, y0: Float = 0, x0: Float? = nil, recess: Float, back: Float,
                       _ mat: MaterialKey) {
        let d = back - recess
        let s = Prim.roundedBox(V3(w, h, d), radius: 0.002, bevelSegments: 1, material: mat)
        m.add(s, Xform(translation: V3((x0 ?? -w / 2) + w / 2, y0 + h / 2, -recess - d / 2)))
    }
}
