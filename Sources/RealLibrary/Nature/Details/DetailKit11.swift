import simd
import Foundation

/// Shared helpers for details group 11.
enum DetailKit11 {
    /// Smooth periodic-ish noise from a few random sine harmonics, output roughly in -1...1.
    struct Harmonics {
        var ks: [Float] = [], ph: [Float] = [], amp: [Float] = []
        init(_ rng: inout SeededRNG, count: Int = 4, lowest: Float = 1) {
            var sum: Float = 0
            for i in 0..<count {
                ks.append((lowest + Float(i) * rng.float(0.8...1.6)).rounded() + (i == 0 ? 0 : 1))
                ph.append(rng.float(0...(2 * .pi)))
                let a = 1 / Float(i + 1)
                amp.append(a); sum += a
            }
            for i in amp.indices { amp[i] /= sum }
        }
        func callAsFunction(_ t: Float) -> Float {
            var v: Float = 0
            for i in ks.indices { v += amp[i] * sin(ks[i] * t + ph[i]) }
            return v
        }
    }

    /// Thick curved sheet. `point(u, v)` (both 0...1) gives the top surface; the underside sits `thickness` below along
    /// the local normal. Returns the top surface and a second surface holding bottom and edge walls.
    static func slab(nu: Int, nv: Int, uvScale: V2, topMaterial: MaterialKey, underMaterial: MaterialKey,
                     thickness: (Float, Float) -> Float, point: (Float, Float) -> V3) -> (top: Surface, under: Surface) {
        var top = Surface(material: topMaterial), under = Surface(material: underMaterial)
        var tp: [V3] = [], bp: [V3] = []
        for i in 0...nu { for j in 0...nv {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv), e: Float = 0.01
            let p = point(u, v)
            let du = point(min(u + e, 1), v) - point(max(u - e, 0), v), dv = point(u, min(v + e, 1)) - point(u, max(v - e, 0))
            var n = -simd_cross(du, dv).normalized
            if n.y < -0.2 && false { n = -n }
            tp.append(p); bp.append(p - n * thickness(u, v))
        }}
        func idx(_ i: Int, _ j: Int) -> Int { i * (nv + 1) + j }
        var ti: [UInt32] = [], bi: [UInt32] = []
        for k in tp.indices {
            let i = k / (nv + 1), j = k % (nv + 1)
            let uv = V2(Float(i) / Float(nu) * uvScale.x, Float(j) / Float(nv) * uvScale.y)
            ti.append(top.add(tp[k], V3(0, 1, 0), uv))
            bi.append(under.add(bp[k], V3(0, -1, 0), uv))
        }
        for i in 0..<nu { for j in 0..<nv {
            let a = idx(i, j), b = idx(i + 1, j), c = idx(i + 1, j + 1), d = idx(i, j + 1)
            top.quad(ti[a], ti[d], ti[c], ti[b])
            under.quad(bi[a], bi[b], bi[c], bi[d])
        }}
        func edge(_ a: Int, _ b: Int, flip: Bool) {
            let uvA = V2(0, 0), uvB = V2(simd_distance(tp[a], tp[b]), 0), uvC = V2(uvB.x, thickness(0.5, 0.5)), uvD = V2(0, uvC.y)
            let q0 = under.add(tp[a], V3(0, 1, 0), uvA), q1 = under.add(tp[b], V3(0, 1, 0), uvB)
            let q2 = under.add(bp[b], V3(0, 1, 0), uvC), q3 = under.add(bp[a], V3(0, 1, 0), uvD)
            if flip { under.quad(q1, q0, q3, q2) } else { under.quad(q0, q1, q2, q3) }
        }
        for i in 0..<nu {
            edge(idx(i, 0), idx(i + 1, 0), flip: false)
            edge(idx(i, nv), idx(i + 1, nv), flip: true)
        }
        for j in 0..<nv {
            edge(idx(0, j), idx(0, j + 1), flip: true)
            edge(idx(nu, j), idx(nu, j + 1), flip: false)
        }
        top.recomputeNormals(); under.recomputeNormals()
        return (top, under)
    }

    /// Shift surfaces so the lowest vertex sits at y = 0.
    static func ground(_ ss: inout [Surface]) {
        var lo = Float.greatestFiniteMagnitude
        for s in ss { for p in s.positions { lo = min(lo, p.y) } }
        for k in ss.indices { for i in ss[k].positions.indices { ss[k].positions[i].y -= lo } }
    }
}
