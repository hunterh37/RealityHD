import simd
import Foundation

/// Helpers for roof and canopy props: thick slabs on arbitrary planar polygons and randomised shingle or shake
/// courses laid on a quad. Same frame as `FA` (wall at z = 0, projecting toward +Z).
enum FR {
    static func lerp(_ a: V3, _ b: V3, _ t: Float) -> V3 { a + (b - a) * t }

    /// Thick slab whose upper face lies on the plane through `p` (points in order, first three not collinear).
    /// The face normal is flipped to point up. `lift` raises it along the normal.
    static func slab(_ m: inout Model, _ p: [V3], t: Float, lift: Float = 0, bevel: Float = 0, _ mat: MaterialKey) {
        let o = p[0]
        let u = simd_normalize(p[1] - p[0])
        var n = simd_normalize(simd_cross(p[1] - p[0], p[2] - p[0]))
        if n.y < 0 { n = -n }
        let v = simd_cross(n, u)
        let local = p.map { V2(simd_dot($0 - o, u), simd_dot($0 - o, v)) }
        let rot = simd_quatf(simd_float3x3(columns: (u, v, n)))
        m.add(Prim.extrude(local, depth: t, bevel: bevel, bevelSegments: 1, material: mat),
              Xform(translation: o - n * (t / 2) + n * lift, rotation: rot))
    }

    /// Shingle or shake courses on a quad: lower edge lowerL...lowerR, upper edge upperL...upperR (upper edge may
    /// collapse to a point for a triangle). Each piece is a 12 triangle prism with a random width, tint and lift.
    static func shakes(_ m: inout Model, lowerL: V3, lowerR: V3, upperL: V3, upperR: V3, courses: Int, lift: Float,
                       tints: [MaterialKey], rng: inout SeededRNG, minW: Float = 0.09, maxW: Float = 0.16, thick: Float = 0.006) {
        for c in 0..<courses {
            let t0 = Float(c) / Float(courses), t1 = Float(c + 1) / Float(courses)
            let l0 = lerp(lowerL, upperL, t0), r0 = lerp(lowerR, upperR, t0)
            let l1 = lerp(lowerL, upperL, t1), r1 = lerp(lowerR, upperR, t1)
            let w = simd_length(r0 - l0)
            if w < 0.05 { continue }
            var u: Float = -rng.float(0...(minW * 0.8)) / w
            while u < 1 {
                let uw = rng.float(minW...maxW) / w
                let a = max(0, u), b = min(1, u + uw)
                if b - a > 0.02 / w {
                    let j = 0.0025 / w
                    let aa = a + j, bb = b - j
                    let pts = [lerp(l0, r0, aa), lerp(l0, r0, bb), lerp(l1, r1, bb), lerp(l1, r1, aa)]
                    let dd = Set(pts.map { "\($0.x)\($0.y)\($0.z)" }).count
                    if dd >= 3 { slab(&m, pts, t: thick, lift: lift + rng.float(0...0.003), tints[rng.int(0...(tints.count - 1))]) }
                }
                u += uw
            }
        }
    }
}
