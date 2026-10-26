import simd
import Foundation

/// Shared helpers for details group 22.
enum DetailKit22 {
    /// Wobbly tapered limb from `a` to `b` with a sideways bow and per-ring radius noise.
    static func limb(_ rng: inout SeededRNG, from a: V3, to b: V3, r0: Float, r1: Float, segs: Int, sides: Int,
                     bend: Float = 0.05, seam: Float = 0.05, cap: Bool = true, material: MaterialKey) -> Surface {
        let d = b - a, len = simd_length(d)
        var perp = simd_cross(d, V3(rng.float(-1...1), rng.float(-1...1), rng.float(-1...1)))
        if simd_length(perp) < 1e-5 { perp = V3(0, 0, 1) }
        perp = simd_normalize(perp)
        var pts: [V3] = [], radii: [Float] = []
        for k in 0...segs {
            let t = Float(k) / Float(segs)
            var p = a + d * t + perp * (bend * len * sin(.pi * t))
            if k > 0 && k < segs { p += V3(rng.float(-1...1), rng.float(-1...1), rng.float(-1...1)) * r0 * 0.3 }
            pts.append(p)
            radii.append(max(0.0008, (r0 + (r1 - r0) * t) * (1 + rng.float(-0.1...0.12))))
        }
        return Prim.tube(pts, radii: radii, sides: sides, seamTile: seam, material: material, capEnd: cap)
    }

    /// Rotates the parts together, centers at `xz`, drops the lowest point to `sink` below y = 0 plus `lift`.
    static func lay(_ parts: [Surface], q: simd_quatf, at xz: V2, lift: Float = 0, sink: Float = 0.002) -> [Surface] {
        let rot = parts.map { $0.transformed(Xform(translation: .zero, rotation: q)) }
        let lo = rot.map { $0.bounds.min.y }.min() ?? 0
        return rot.map { $0.transformed(Xform(translation: V3(xz.x, -lo - sink + lift, xz.y), rotation: simd_quatf(angle: 0, axis: V3(0, 1, 0)))) }
    }

    static func model(_ id: String, _ parts: [Surface]) -> Model {
        var m = Model(name: id)
        for var s in parts where !s.indices.isEmpty { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return m
    }

    /// Flat chunk (ash flake, char scale) centered at `c`, long axis `u`, resting on normal `n`.
    static func chunk(_ c: V3, u: V3, n: V3, len: Float, wid: Float, th: Float, material: MaterialKey) -> Surface {
        let uu = simd_normalize(u - n * simd_dot(u, n)), t = simd_cross(n, uu)
        var s = Prim.cubeSphere(subdivisions: 1, material: material) { d in
            c + uu * (d.x * len * 0.5) + t * (d.z * wid * 0.5) + n * (d.y * th * 0.5)
        }
        s.uvs = s.uvs.map { $0 * 1.2 }
        return s
    }
}
