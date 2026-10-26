import simd
import Foundation

/// Shared helpers for details group 26.
enum DetailKit26 {
    /// Gentle ground height used by the river-bank assets.
    static func wobble(_ x: Float, _ z: Float, _ ph: Float, _ a: Float) -> Float {
        a * (sin(x * 21 + ph) * cos(z * 17 + ph * 0.7) + 0.5 * sin(x * 47 + z * 31 + ph))
    }

    /// Light plate wrapped around a cobble at offset `z0` along its short axis (a gneiss stripe).
    static func band(size: V3, z0: Float, th: Float, rng: inout SeededRNG, sub: Int, material: MaterialKey) -> Surface {
        let k = sqrt(max(0.08, 1 - pow(2 * z0 / size.z, 2))) * 1.03
        let s = DetailKit05.stone(size: V3(size.x * k, size.y * k, th), rng: &rng, sub: sub, e: 4, material: material)
        return s.transformed(Xform(translation: V3(0, 0, z0), rotation: .identity))
    }

    /// Surface-hugging flat bubble cluster.
    static func bubbles(center: V2, radius: Float, count: Int, y: Float, rng: inout SeededRNG, material: MaterialKey) -> [Surface] {
        (0..<count).map { _ in
            let p = rng.inDisc(radius: radius)
            let r = rng.float(0.003...0.011) * (1.2 - 0.6 * simd_length(p) / radius)
            return DetailKit10.blob(V3(center.x + p.x, y + r * 0.2, center.y + p.y), V3(r, r * rng.float(0.6...0.9), r), sub: 1, material: material)
        }
    }
}
