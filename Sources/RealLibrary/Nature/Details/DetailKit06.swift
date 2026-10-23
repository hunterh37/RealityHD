import simd
import Foundation

/// Shared builders for details group 06 (river margin: pads, algae, mud, sand).
enum DetailKit06 {
    static func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: V3(0, 1, 0)) }

    /// Soft oriented oval imprint weight (1 at center, 0 at rim) for a point p.
    static func oval(_ p: V2, c: V2, dir: V2, len: Float, wid: Float) -> Float {
        let d = p - c
        let a = simd_dot(d, dir) / len, b = (dir.x * d.y - dir.y * d.x) / wid
        let r2 = a * a + b * b
        return r2 >= 1 ? 0 : (1 - smoothstep(0.35, 1, r2))
    }

    /// Pebble: lumpy flattened superellipsoid with its base on y = 0.
    static func pebble(size: V3, rng: inout SeededRNG, sub: Int, material: MaterialKey) -> Surface {
        var s = DetailKit05.stone(size: size, rng: &rng, sub: sub, material: material)
        let lift = -s.bounds.min.y - 0.001
        s = s.transformed(Xform(translation: V3(0, lift, 0)))
        return s
    }
}
