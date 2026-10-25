import simd
import Foundation

/// Shared helpers for details group 15.
enum DetailKit15 {
    /// Lumpy ellipsoid: low-frequency random harmonics plus fine noise, base clipped to `floorY`.
    static func blob(at c: V3, radii: V3, lump: Float, fine: Float = 0, sub: Int = 8, floorY: Float = -0.003,
                     material: MaterialKey, rng: inout SeededRNG, ridges: Int = 0, ridgeDepth: Float = 0) -> Surface {
        var h: [(V3, Float, Float)] = []
        for _ in 0..<5 { h.append((V3(rng.float(-1...1), rng.float(-1...1), rng.float(-1...1)).normalized, rng.float(1.5...4), rng.float(0...6.28))) }
        let ph = rng.float(0...6.28)
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            var k: Float = 1
            for (a, f, p) in h { k += lump * 0.4 * sin(simd_dot(a, d) * f * 2 + p) }
            if fine > 0 { k += fine * sin(d.x * 23 + d.y * 17 + ph) * sin(d.z * 19 + d.x * 11) }
            if ridges > 0 { k -= ridgeDepth * abs(sin(atan2(d.z, d.x) * Float(ridges) * 0.5 + ph)) * (1 - abs(d.y)) }
            var p = c + V3(d.x * radii.x, d.y * radii.y, d.z * radii.z) * k
            p.y = max(p.y, floorY)
            return p
        }
    }

    /// Spines scattered over an ellipsoid-ish burr, pointing outward with slight random bend.
    static func spines(into m: inout Model, center: V3, r: Float, count: Int, len: ClosedRange<Float>, material: MaterialKey, rng: inout SeededRNG, minY: Float = 0.004) {
        for _ in 0..<count {
            var d = V3(rng.float(-1...1), rng.float(-1...1), rng.float(-1...1)).normalized
            if center.y + d.y * r < minY { d.y = abs(d.y) * 0.3; d = d.normalized }
            let l = rng.float(len)
            let p0 = center + d * r * 0.93
            let bend = V3(rng.float(-0.3...0.3), rng.float(-0.3...0.3), rng.float(-0.3...0.3))
            let dir = simd_normalize(d + bend)
            m.add(Prim.tube([p0, p0 + dir * l * 0.5, p0 + dir * l], radii: [0.0009, 0.0006, 0.00008], sides: 3, seamTile: 0.004, material: material, capEnd: false))
        }
    }
}
