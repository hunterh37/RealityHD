import simd
import Foundation

/// Helpers for the facade library batch (hoods, stacks, parapets, roof facets). Same frame as `FA`:
/// wall plane at z = 0, piece projecting toward +Z.
enum FL {
    /// Smooth S blend 0...1 with zero slope at both ends.
    static func smooth(_ t: Float) -> Float { t * t * (3 - 2 * t) }

    /// Ogee (S curve) between two profile points: x blends smoothly, y is linear, so both ends run vertical.
    static func ogee(from a: V2, to b: V2, steps: Int = 8) -> [V2] {
        (1...steps).map { i in
            let t = Float(i) / Float(steps)
            return V2(a.x + (b.x - a.x) * smooth(t), a.y + (b.y - a.y) * t)
        }
    }

    /// Covers a planar convex facet (3 or 4 points, a0 a1 along the eave, then the opposite edge b0 b1; for
    /// a triangle b0 == b1) with `count` tapering pans of `thick` m, each with a raised standing seam.
    static func pans(_ m: inout Model, a0: V3, a1: V3, b0: V3, b1: V3, count: Int, thick: Float,
                     _ pan: (Int) -> MaterialKey, seam: MaterialKey, seamR: Float = 0.006) {
        var (a0, a1, b0, b1) = (a0, a1, b0, b1)
        let u0 = simd_normalize(a1 - a0)
        let mid = (b0 + b1) / 2 - (a0 + a1) / 2
        var n = simd_normalize(simd_cross(u0, mid))
        if n.y < 0 { swap(&a0, &a1); swap(&b0, &b1); n = -n }
        let u = simd_normalize(a1 - a0)
        let v = simd_cross(n, u)
        let rot = simd_quatf(simd_float3x3(u, v, n))
        func uv(_ p: V3) -> V2 { V2(simd_dot(p - a0, u), simd_dot(p - a0, v)) }
        for i in 0..<count {
            let t0 = Float(i) / Float(count), t1 = Float(i + 1) / Float(count)
            let p0 = simd_mix(a0, a1, V3(repeating: t0)), p1 = simd_mix(a0, a1, V3(repeating: t1))
            let q0 = simd_mix(b0, b1, V3(repeating: t0)), q1 = simd_mix(b0, b1, V3(repeating: t1))
            let gap: Float = 0.0015
            var poly = [uv(p0) + V2(gap, 0), uv(p1) - V2(gap, 0), uv(q1) - V2(gap, 0), uv(q0) + V2(gap, 0)]
            poly = Shape2D.deduped(poly)
            if poly.count >= 3 {
                m.add(Prim.extrude(poly, depth: thick, bevel: 0.001, bevelSegments: 1, material: pan(i)),
                      Xform(translation: a0 + n * (thick / 2), rotation: rot))
            }
            if i > 0 {
                FA.rod(&m, p0 + n * thick, q0 + n * thick, r: seamR, seam, sides: 6)
            }
        }
    }
}
