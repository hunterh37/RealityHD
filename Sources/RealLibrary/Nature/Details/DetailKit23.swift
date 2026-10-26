import simd
import Foundation

/// Shared helpers for details group 23: fungi lobes, branching tubes, rays.
enum DetailKit23 {
    /// Scales a subdivision count for LOD level `lod` (0 = full).
    static func q(_ n: Int, _ lod: Int, min lo: Int = 2) -> Int {
        lod == 0 ? n : max(lo, Int((Float(n) * (lod == 1 ? 0.6 : 0.35)).rounded(.up)))
    }

    /// Wobbly ellipsoid lobe centered at `c` with radii `r`; `dish` hollows the top face (cups, ears).
    static func lobe(at c: V3, radii r: V3, q: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)), sub: Int = 5, dish: Float = 0,
                     rng: inout SeededRNG, jitter: Float = 0.1, material: MaterialKey) -> Surface {
        let nz = DetailKit13.Noise(&rng, harmonics: [2, 3, 5], amp: jitter)
        let ph = rng.float(0...6.28)
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            let ang = atan2(d.z, d.x)
            let w = 1 + nz.v(ang + ph * 0.1) + 0.5 * nz.v(d.y * 4 + ph)
            let h = min(1, (d.x * d.x + d.z * d.z).squareRoot())
            var y = d.y * r.y
            if d.y > 0 { y -= dish * r.y * 2 * (1 - h * h) * d.y }
            let p = V3(d.x * r.x * w, y, d.z * r.z * w)
            return c + q.act(p)
        }
    }

    /// Wobbly tapered branch path.
    static func path(from a: V3, dir: V3, len: Float, segs: Int, wobble: Float, rng: inout SeededRNG) -> [V3] {
        DetailKit02.limbPath(from: a, dir: dir, len: len, segs: segs, wobble: wobble, rng: &rng)
    }

    static func tube(_ pts: [V3], r0: Float, r1: Float, sides: Int = 6, material: MaterialKey, cap: Bool = true) -> Surface {
        let n = pts.count
        let radii = (0..<n).map { r0 + (r1 - r0) * pow(Float($0) / Float(n - 1), 0.8) }
        return Prim.tube(pts, radii: radii, sides: sides, seamTile: 0.02, material: material, capEnd: cap)
    }

    /// Recursive coral branching; appends tube surfaces to `out`.
    static func coral(_ out: inout [Surface], from a: V3, dir: V3, len: Float, r: Float, depth: Int,
                      rng: inout SeededRNG, stem: MaterialKey, tip: MaterialKey, lod: Int = 0) {
        let full = path(from: a, dir: dir, len: len, segs: 4, wobble: 0.22, rng: &rng)
        let last = depth == 0
        // same path at every LOD (rng stays in step); fewer points and sides on lower levels
        let pts = lod == 0 ? [full[0], full[2], full[4]] : [full[0], full[4]]
        let tubeSides = lod == 0 ? 4 : 3
        if !(last && lod == 2) { out.append(tube(pts, r0: r, r1: last ? r * 0.25 : r * 0.7, sides: tubeSides, material: last ? tip : stem)) }
        if last { return }
        let end = full[4]
        let fork = depth == 1 ? Int(rng.float(2...3.99)) : Int(rng.float(2...3.99))
        let base = (full[4] - full[3]).normalized
        for k in 0..<fork {
            let ang = Float(k) / Float(fork) * 6.28 + rng.float(-0.6...0.6)
            let side = V3(cos(ang), 0, sin(ang))
            let d = simd_normalize(base * 1.0 + side * rng.float(0.45...0.85) + V3(0, 0.25, 0))
            coral(&out, from: end - base * r * 0.5, dir: d, len: len * rng.float(0.62...0.82), r: r * 0.66, depth: depth - 1,
                  rng: &rng, stem: stem, tip: tip, lod: lod)
        }
    }
}
