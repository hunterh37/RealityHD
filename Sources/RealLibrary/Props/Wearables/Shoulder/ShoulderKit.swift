import simd
import Foundation

/// Shared helpers for the shoulder wearables. The invisible shoulder is a sphere (deltoid, radius 6.2 cm) at the origin,
/// a 4.7 cm arm cylinder hanging down -Y, and a trapezius slope rising toward the neck at -X.
enum ShoulderKit {
    static let R: Float = 0.062, armR: Float = 0.047, trapR: Float = 0.058, slope: Float = 0.17

    /// Height of the shoulder top at x (z = 0).
    static func topY(_ x: Float) -> Float {
        x >= 0 ? sqrt(max(0, R * R - x * x)) : R + slope * (-x)
    }
    static func tubeCentreY(_ x: Float) -> Float { x >= 0 ? 0 : topY(x) - trapR }

    /// Outward normal of the invisible shoulder at a point.
    static func bodyNormal(_ p: V3) -> V3 {
        let a: V3
        if p.x < 0 { a = V3(p.x, tubeCentreY(p.x), 0) }
        else if p.y < 0 { a = V3(0, p.y, 0) }
        else { a = .zero }
        let d = p - a
        return simd_length(d) > 1e-6 ? simd_normalize(d) : V3(0, 1, 0)
    }

    /// Path over the shoulder in the plane x = const, front leg (z > 0) over the top to the back leg. `off` lifts it off the
    /// surface. With `legY` the path continues straight down both sides to that height, flaring out by `legSpread`.
    static func over(x: Float, off: Float, steps: Int = 24, legY: Float? = nil, legSpread: Float = 0, legSteps: Int = 8) -> [V3] {
        let r: Float, cy: Float
        if x >= 0 { r = sqrt(max(1e-6, R * R - x * x)); cy = 0 } else { r = trapR; cy = tubeCentreY(x) }
        let a = r + off
        var pts: [V3] = []
        if let ly = legY {
            for k in 0..<legSteps {
                let t = Float(k) / Float(legSteps)
                pts.append(V3(x, ly + (cy - ly) * t, a + legSpread * pow(1 - t, 2)))
            }
        }
        for k in 0...steps {
            let ph = Float.pi / 2 - Float.pi * Float(k) / Float(steps)
            pts.append(V3(x, cy + a * cos(ph), a * sin(ph)))
        }
        if let ly = legY {
            for k in 1...legSteps {
                let t = Float(k) / Float(legSteps)
                pts.append(V3(x, cy + (ly - cy) * t, -(a + legSpread * pow(t, 2))))
            }
        }
        return pts
    }

    /// Surface point along the shoulder line: `s` metres of arc from the top (+ outward and down the deltoid, - toward the neck),
    /// `b` the sideways angle around the shoulder tube (+ toward the front), `off` the lift off the surface.
    static func surf(_ s: Float, _ b: Float, _ off: Float) -> V3 {
        if s >= 0 {
            let a = s / R
            return (V3(sin(a), cos(a), 0) * cos(b) + V3(0, 0, 1) * sin(b)) * (R + off)
        }
        let n = simd_normalize(V3(-slope, 1, 0))
        let c = V3(s, topY(s), 0) - n * trapR
        return c + (n * cos(b) + V3(0, 0, 1) * sin(b)) * (trapR + off)
    }

    /// Double-walled shell from a parametric grid (u over `cols`, v over `rows`, both 0...1). Open edges are closed with a strip.
    /// `centre` is a point inside the form; it decides which side is outward.
    static func shell(cols: Int, rows: Int, thick: Float, centre: V3, material: MaterialKey, point: (Float, Float) -> V3) -> Surface {
        var g = [[V3]](repeating: [V3](repeating: .zero, count: rows + 1), count: cols + 1)
        for i in 0...cols { for j in 0...rows { g[i][j] = point(Float(i) / Float(cols), Float(j) / Float(rows)) } }
        func geoN(_ i: Int, _ j: Int) -> V3 {
            let du = g[min(cols, i + 1)][j] - g[max(0, i - 1)][j]
            let dv = g[i][min(rows, j + 1)] - g[i][max(0, j - 1)]
            let n = simd_cross(du, dv)
            return simd_length(n) > 1e-12 ? simd_normalize(n) : V3(0, 1, 0)
        }
        let mi = cols / 2, mj = rows / 2
        let sign: Float = simd_dot(geoN(mi, mj), g[mi][mj] - centre) >= 0 ? 1 : -1
        let flip = sign < 0
        var s = Surface(material: material)
        let row = rows + 1
        var uArc = [Float](repeating: 0, count: cols + 1), vArc = [Float](repeating: 0, count: rows + 1)
        for i in 1...cols { uArc[i] = uArc[i - 1] + simd_distance(g[i][rows / 2], g[i - 1][rows / 2]) }
        for j in 1...rows { vArc[j] = vArc[j - 1] + simd_distance(g[cols / 2][j], g[cols / 2][j - 1]) }
        for i in 0...cols { for j in 0...rows { s.add(g[i][j], sign * geoN(i, j), V2(uArc[i], vArc[j])) } }
        let inner = UInt32((cols + 1) * row)
        for i in 0...cols { for j in 0...rows { s.add(g[i][j] - sign * geoN(i, j) * thick, -sign * geoN(i, j), V2(uArc[i], vArc[j])) } }
        func id(_ i: Int, _ j: Int) -> UInt32 { UInt32(i * row + j) }
        func q(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) { if flip { s.quad(a, d, c, b) } else { s.quad(a, b, c, d) } }
        for i in 0..<cols { for j in 0..<rows {
            q(id(i, j), id(i + 1, j), id(i + 1, j + 1), id(i, j + 1))
            q(inner + id(i, j), inner + id(i, j + 1), inner + id(i + 1, j + 1), inner + id(i + 1, j))
        }}
        for i in 0..<cols {
            q(id(i, 0), inner + id(i, 0), inner + id(i + 1, 0), id(i + 1, 0))
            q(id(i, rows), id(i + 1, rows), inner + id(i + 1, rows), inner + id(i, rows))
        }
        for j in 0..<rows {
            q(id(0, j), id(0, j + 1), inner + id(0, j + 1), inner + id(0, j))
            q(id(cols, j), inner + id(cols, j), inner + id(cols, j + 1), id(cols, j + 1))
        }
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    /// Twisted rope: `strands` tubes spiralling around `path` (radius `r` each), `pitch` metres per turn.
    static func rope(_ path: [V3], radius r: Float, pitch: Float, strands: Int = 2, sides: Int = 5, material: MaterialKey) -> Surface {
        var out = Surface(material: material)
        let pts = resample(path, spacing: pitch / 6)
        guard pts.count > 3 else { return out }
        var n = simd_normalize((pts[1] - pts[0]).anyPerpendicular)
        var frames: [(V3, V3)] = []
        var cum: [Float] = [0]
        for i in pts.indices {
            let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
            let t = simd_normalize(b - a)
            n = simd_normalize(n - t * simd_dot(n, t))
            frames.append((n, simd_cross(t, n)))
            if i > 0 { cum.append(cum[i - 1] + simd_distance(pts[i], pts[i - 1])) }
        }
        for k in 0..<strands {
            let ph = 2 * Float.pi * Float(k) / Float(strands)
            let sp = pts.indices.map { i -> V3 in
                let a = 2 * Float.pi * cum[i] / pitch + ph
                return pts[i] + (frames[i].0 * cos(a) + frames[i].1 * sin(a)) * r * 0.9
            }
            out.append(Prim.tube(sp, radii: sp.map { _ in r }, sides: sides, seamTile: 0.01, material: material, capEnd: false))
        }
        return out
    }

    /// Flips a vertical tube-like surface so its normals point away from (`outward`) or toward the vertical axis at x = `axisX`.
    static func facing(_ s: Surface, outward: Bool, axisX: Float) -> Surface {
        var sum: Float = 0
        for i in s.positions.indices {
            let d = V3(s.positions[i].x - axisX, 0, s.positions[i].z)
            sum += simd_dot(s.normals[i], d)
        }
        return (sum >= 0) == outward ? s : s.flipped()
    }

    /// Smooth metal ring from a rounded-rectangle path (cheaper than `ChestKit.ring`: 2 points per corner).
    static func ring(_ w: Float, _ h: Float, wire: Float, radius: Float, sides: Int = 6, per: Int = 2, material: MaterialKey) -> Surface {
        Prim.sweep(Shape2D.circle(wire, segments: sides), along: ChestKit.loopPath(w, h, radius: radius, per: per), up: V3(0, 0, 1), closedPath: true, caps: false, material: material)
    }

    /// Catmull-Rom smoothing for a handful of control points.
    static func smooth(_ p: [V3], per: Int = 6) -> [V3] { catmull(p, per: per) }
}
