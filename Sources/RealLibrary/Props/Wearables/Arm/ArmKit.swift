import simd
import Foundation

/// Shared helpers for the arm wearables. The invisible limb is a circular cylinder on the Y axis: upper arm above the
/// elbow (y > 0, radius 4.4 to 4.95 cm), forearm below (y < 0, radius 4.45 cm tapering to 2.7 cm at the wrist).
/// Azimuth th = 0 faces front (+Z), th = pi/2 is the outer side (+X), th = pi the back (elbow point).
enum ArmKit {
    typealias K = ChestKit

    static func R(_ y: Float) -> Float {
        if y >= 0 { return 0.0445 + 0.0050 * smoothstep(0, 0.09, y) - 0.0030 * smoothstep(0.2, 0.3, y) }
        let t = -y
        return 0.0445 + 0.0015 * smoothstep(0, 0.06, t) - 0.0185 * smoothstep(0.03, 0.26, t)
    }

    /// Point at azimuth `th`, height `y`, `off` metres outside the limb surface.
    static func P(_ th: Float, _ y: Float, _ off: Float = 0) -> V3 {
        let r = R(y) + off
        return V3(sin(th) * r, y, cos(th) * r)
    }

    static func nrm(_ p: V3) -> V3 {
        let h = V3(p.x, 0, p.z)
        return simd_length(h) > 1e-6 ? simd_normalize(h) : V3(0, 0, 1)
    }

    static func tangent(_ th: Float) -> V3 { V3(cos(th), 0, -sin(th)) }

    /// Closed ring path around the limb.
    static func ring(y: Float, off: Float, count: Int, ry: Float? = nil) -> [V3] {
        let r = R(ry ?? y) + off
        return (0..<count).map { let th = 2 * Float.pi * Float($0) / Float(count); return V3(sin(th) * r, y, cos(th) * r) }
    }

    /// Orientation with local Y = outward normal at `p`, local X = tangent around the limb.
    static func onSurface(_ p: V3) -> simd_quatf {
        let n = nrm(p)
        return K.basis(V3(n.z, 0, -n.x), n)
    }

    /// Arbitrary closed profile (x along the limb axis, y out of the surface, counter clockwise) swept along frames.
    static func skin(_ f: [K.Frame], profile prof: [V2], scale: ((Float) -> Float)? = nil, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let n = prof.count, m = f.count
        var arc: [Float] = [0]
        for i in 1...n { arc.append(arc[i - 1] + simd_distance(prof[i - 1], prof[i % n])) }
        var v: Float = 0
        for j in 0..<m {
            if j > 0 { v += simd_distance(f[j].p, f[j - 1].p) }
            let sc = scale?(Float(j) / Float(max(1, m - 1))) ?? 1
            for k in 0...n {
                let q = prof[k % n]
                s.add(f[j].p + f[j].w * (q.x * sc) + f[j].n * (q.y * sc), .up, V2(arc[k], v))
            }
        }
        let row = UInt32(n + 1)
        for j in 0..<(m - 1) { for k in 0..<n {
            let a = UInt32(j) * row + UInt32(k)
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        s.recomputeNormals(weldSeams: true)
        let tri = Shape2D.triangulate(prof)
        for (end, sign) in [(0, Float(-1)), (m - 1, 1)] {
            let sc = scale?(Float(end) / Float(max(1, m - 1))) ?? 1
            let base = UInt32(s.positions.count)
            for q in prof { s.add(f[end].p + f[end].w * (q.x * sc) + f[end].n * (q.y * sc), f[end].t * sign, q) }
            for t in stride(from: 0, to: tri.count, by: 3) {
                if sign > 0 { s.tri(base + tri[t], base + tri[t + 1], base + tri[t + 2]) }
                else { s.tri(base + tri[t], base + tri[t + 2], base + tri[t + 1]) }
            }
        }
        s.computeTangents()
        return s
    }

    /// Short loose threads fanning out of an edge point (fraying).
    static func fray(_ m: inout Model, rng: inout SeededRNG, from pts: [V3], dir: (V3) -> V3, count: Int, length: ClosedRange<Float>, radius: Float, material: MaterialKey) {
        for _ in 0..<count {
            let p = pts[rng.int(0...(pts.count - 1))]
            let d = simd_normalize(dir(p) + V3(rng.float(-0.4...0.4), rng.float(-0.4...0.4), rng.float(-0.4...0.4)))
            let l = rng.float(length)
            let mid = p + d * l * 0.5 + V3(0, rng.float(-0.002...0.002), 0)
            let end = p + d * l + V3(rng.float(-0.003...0.003), rng.float(-0.003...0.001), rng.float(-0.003...0.003))
            let path = catmull([p, mid, end], per: 3)
            m.add(Prim.tube(path, radii: path.map { _ in radius }, sides: 3, seamTile: 0.01, material: material, capEnd: false))
        }
    }
}
