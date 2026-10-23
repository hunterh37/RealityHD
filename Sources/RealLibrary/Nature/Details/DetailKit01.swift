import simd
import Foundation

/// Shared builders for details group 01 (twigs, branches, needles, cones, acorns).
enum DetailKit01 {
    /// Wandering tapered limb with optional forks, appended to `s`. Ends are left blunt (snapped).
    static func limb(_ s: inout Surface, rng: inout SeededRNG, from a: V3, dir: V3, len: Float, r: Float,
                     fork: Int, sides: Int, material: MaterialKey, floorY: Float = 0.002) {
        let segs = 4
        var p = a, d = simd_normalize(dir)
        var pts = [p]
        for _ in 0..<segs {
            d = simd_normalize(d + V3(rng.float(-0.18...0.18), rng.float(-0.1...0.05), rng.float(-0.18...0.18)))
            p += d * len / Float(segs)
            p.y = max(p.y, floorY + r * 0.5)
            pts.append(p)
        }
        let radii = (0...segs).map { r * (1 - 0.55 * Float($0) / Float(segs)) * rng.float(0.92...1.08) }
        s.append(Prim.tube(pts, radii: radii, sides: sides, seamTile: 0.05, material: material, capEnd: true))
        guard fork > 0 else { return }
        for _ in 0..<fork {
            let k = rng.int(1...3)
            let side = simd_normalize(simd_cross(d, V3(0, 1, 0)) * (rng.chance(0.5) ? 1 : -1) + d * 1.1 + V3(0, rng.float(0...0.25), 0))
            limb(&s, rng: &rng, from: pts[k], dir: side, len: len * rng.float(0.3...0.5), r: radii[k] * 0.6,
                 fork: 0, sides: sides, material: material, floorY: floorY)
        }
    }

    static func yawQuat(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: V3(0, 1, 0)) }
}
