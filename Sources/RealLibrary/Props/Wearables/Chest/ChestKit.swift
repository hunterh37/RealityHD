import simd
import Foundation

/// Shared geometry helpers for the chest wearables: a torso model (sternum origin, chest surface 12 cm in front)
/// and a ribbon builder whose width direction follows the body surface (leather straps, webbing, lanyards).
enum ChestKit {
    static let rx: Float = 0.175, rzFront: Float = 0.12, rzBack: Float = 0.11

    /// Shoulder taper factor: 1 on the ribcage, 0.6 across the shoulders.
    static func taper(_ y: Float) -> Float { 1 - 0.4 * smoothstep(0.1, 0.24, y) }

    /// Point on the torso cross-section at azimuth `th` (0 = front centre, +x = wearer's left), height `y`, pushed out by `off`.
    static func torso(_ th: Float, _ y: Float, _ off: Float = 0) -> V3 {
        let s = taper(y), c = cos(th)
        return V3(sin(th) * (rx * s + off), y, c * ((c >= 0 ? rzFront : rzBack) * s + off))
    }

    /// Outward surface normal at a world point (horizontal on the ribcage, tipping to +Y over the shoulders).
    static func bodyNormal(_ p: V3) -> V3 {
        let rz: Float = p.z >= 0 ? rzFront : rzBack
        let h = V3(p.x / (rx * rx), 0, p.z / (rz * rz))
        let hn = simd_length(h) > 1e-6 ? simd_normalize(h) : V3(0, 0, 1)
        let wy = smoothstep(0.15, 0.24, p.y)
        return simd_normalize(hn * (1 - wy) + V3(0, 1, 0) * wy)
    }

    struct Frame { var p: V3; var t: V3; var w: V3; var n: V3 }

    /// Frames along a path: t tangent, n surface normal (from `normal`), w = n x t is the strap width direction.
    static func frames(_ path: [V3], normal: (V3) -> V3, closed: Bool = false) -> [Frame] {
        let m = path.count
        return (0..<m).map { i in
            let a = closed ? path[(i + m - 1) % m] : path[max(0, i - 1)]
            let b = closed ? path[(i + 1) % m] : path[min(m - 1, i + 1)]
            let t = simd_normalize(b - a)
            var n = normal(path[i]); n = n - t * simd_dot(n, t)
            n = simd_length(n) > 1e-5 ? simd_normalize(n) : t.anyPerpendicular
            return Frame(p: path[i], t: t, w: simd_normalize(simd_cross(n, t)), n: simd_cross(t, simd_normalize(simd_cross(n, t))))
        }
    }

    /// Flat strap of `width` x `thick` with rounded edges, lying on the surface. `widthScale(u)` tapers the width along u in 0...1.
    static func ribbon(_ f: [Frame], width: Float, thick: Float, radius: Float, segments: Int = 2, closed: Bool = false, caps: Bool = true,
                       widthScale: ((Float) -> Float)? = nil, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let prof = Shape2D.roundedRect(width, thick, radius: radius, segments: segments)
        let n = prof.count, m = f.count
        var arc: [Float] = [0]
        for i in 1...n { arc.append(arc[i - 1] + simd_distance(prof[i - 1], prof[i % n])) }
        let count = closed ? m + 1 : m
        var v: Float = 0
        for j in 0..<count {
            let i = j % m
            if j > 0 { v += simd_distance(f[i].p, f[(j - 1) % m].p) }
            let sc = widthScale?(Float(i) / Float(max(1, m - 1))) ?? 1
            for k in 0...n {
                let q = prof[k % n]
                s.add(f[i].p + f[i].w * (q.x * sc) + f[i].n * q.y, .up, V2(arc[k], v))
            }
        }
        let row = UInt32(n + 1)
        for j in 0..<(count - 1) { for k in 0..<n {
            let a = UInt32(j) * row + UInt32(k)
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        s.recomputeNormals(weldSeams: true)
        if caps && !closed {
            let tri = Shape2D.triangulate(prof)
            for (end, sign) in [(0, Float(-1)), (m - 1, 1)] {
                let sc = widthScale?(Float(end) / Float(max(1, m - 1))) ?? 1
                let base = UInt32(s.positions.count)
                for q in prof { s.add(f[end].p + f[end].w * (q.x * sc) + f[end].n * q.y, f[end].t * sign, q) }
                for t in stride(from: 0, to: tri.count, by: 3) {
                    if sign > 0 { s.tri(base + tri[t], base + tri[t + 1], base + tri[t + 2]) }
                    else { s.tri(base + tri[t], base + tri[t + 2], base + tri[t + 1]) }
                }
            }
        }
        s.computeTangents()
        return s
    }

    /// Points offset sideways (`w`) and out of the surface (`n`) from each frame (stitch lines, edge paint).
    static func offset(_ f: [Frame], w: Float, n: Float) -> [V3] { f.map { $0.p + $0.w * w + $0.n * n } }

    /// Orientation with local X = x, Y = y, Z = x cross y.
    static func basis(_ x: V3, _ y: V3) -> simd_quatf {
        let xx = simd_normalize(x)
        let yy = simd_normalize(y - xx * simd_dot(y, xx))
        return simd_quatf(simd_float3x3(columns: (xx, yy, simd_cross(xx, yy))))
    }

    /// D-ring or O-ring path in the local XY plane: `w` wide along X, `h` tall along Y, corner radius `r`.
    static func loopPath(_ w: Float, _ h: Float, radius r: Float, per: Int = 3) -> [V3] {
        Shape2D.roundedRect(w, h, radius: r, segments: per).map { V3($0.x, $0.y, 0) }
    }

    /// Saddle stitches as open 3-sided capsules (6 triangles each).
    static func stitch(along path: [V3], normal: (V3) -> V3, pitch: Float = 0.0035, thread: Float = 0.0006, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let pts = resample(path, spacing: pitch)
        guard pts.count > 1 else { return s }
        for i in 0..<(pts.count - 1) {
            let a = pts[i], b = pts[i + 1], n = simd_normalize(normal(a))
            let d = b - a, len = simd_length(d) * 0.7
            let mid = (a + b) / 2 + n * thread * 0.4
            let dir = d / max(simd_length(d), 1e-6)
            let tilt = simd_normalize(dir + simd_cross(n, dir) * 0.25)
            s.append(Prim.tube([mid - tilt * len / 2, mid + tilt * len / 2], radii: [thread, thread], sides: 3, seamTile: 0.01, material: material, capEnd: false))
        }
        return s
    }

    /// Smooth metal ring from a rounded-rectangle path.
    static func ring(_ w: Float, _ h: Float, wire: Float, radius: Float, sides: Int = 10, material: MaterialKey) -> Surface {
        Prim.sweep(Shape2D.circle(wire, segments: sides), along: loopPath(w, h, radius: radius, per: 5), up: V3(0, 0, 1), closedPath: true, caps: false, material: material)
    }
}
