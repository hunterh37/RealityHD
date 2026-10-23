import simd
import Foundation

/// Shared builders for details group 09 (roots, pebbles, mud, ant hill).
enum DetailKit09 {
    /// Builds LOD0 and LOD1 from one closure; both share the same random stream.
    static func lods(seed: UInt64, name: String, switchAt: Float = 4, _ f: (Int, inout SeededRNG) -> [Surface]) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let st = rng.state
        let a = f(0, &rng)
        var r2 = SeededRNG(seed: 1); r2.state = st
        let b = f(1, &r2)
        return LODModel(levels: [finish(name, a), finish(name, b)], switchDistances: [switchAt])
    }

    static func finish(_ name: String, _ surfs: [Surface]) -> Model {
        var m = Model(name: name)
        for var s in surfs where !s.positions.isEmpty { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return m
    }

    static func shift(_ s: Surface, _ t: V3, yaw: Float = 0) -> Surface {
        var o = Surface(material: s.material)
        o.append(s, Xform(translation: t, rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0))))
        return o
    }

    static func blob(_ r: V3, sub: Int, material: MaterialKey, rng: inout SeededRNG, jitter: Float = 0.12) -> Surface {
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            let j = 1 + jitter * sin(d.x * 3.1 + ph[0]) * cos(d.y * 2.7 + ph[1]) + jitter * 0.6 * sin(d.z * 4.3 + ph[2])
            return V3(d.x * r.x, d.y * r.y, d.z * r.z) * j
        }
    }

    static func smooth(_ t: Float) -> Float { let c = min(max(t, 0), 1); return c * c * (3 - 2 * c) }

    /// Square soil patch whose rim sinks to -4 mm.
    static func soil(size: Float, seg: Int, material: MaterialKey, seed: UInt64, base: Float = 0.012, bump: Float = 0.012,
                     extra: ((V2) -> Float)? = nil) -> Surface {
        Prim.terrain(size: V2(size, size), segments: seg, material: material) { p in
            let r = simd_length(p) / (size * 0.5)
            let h = base + bump * Noise.perlin(V3(p.x * 9, 0.3, p.y * 9), seed: UInt32(truncatingIfNeeded: seed)) + (extra?(p) ?? 0)
            let k = smooth((1 - r) * 3)
            return -0.004 + (h + 0.004) * k
        }
    }

    /// Tapered, knobby root tube.
    static func root(_ path: [V3], r0: Float, r1: Float, sides: Int, material: MaterialKey, rng: inout SeededRNG) -> Surface {
        let ph = rng.float(0...6.28)
        let n = path.count
        let radii = (0..<n).map { i -> Float in
            let t = Float(i) / Float(n - 1)
            return (r0 + (r1 - r0) * pow(t, 0.8)) * (1 + 0.14 * sin(t * 11 + ph))
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.2, material: material)
    }
}
