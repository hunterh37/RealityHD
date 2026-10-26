import simd
import Foundation

/// Wear helpers for the o-batch facade props: thin flaked-paint patches and grime streaks lying on a flat face.
extension FJ {
    /// Flaked patch of exposed substrate on a face at plane `z` (facing +Z), centred at `c`, rotated about Z.
    static func peel(_ m: inout Model, at c: V3, w: Float, h: Float, _ mat: MaterialKey, rng: inout SeededRNG, rot: Float? = nil) {
        let pts = Shape2D.rounded([V2(-w / 2, -h / 2), V2(w / 2, -h * 0.4), V2(w * 0.45, h / 2), V2(-w * 0.1, h * 0.45), V2(-w / 2, h * 0.15)],
                                  radius: min(0.004, h * 0.2), segments: 1)
        m.add(Prim.extrude(pts, depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: mat),
              Xform(translation: V3(c.x, c.y, c.z + 0.0006), rotation: FA.q(rot ?? rng.float(-14...14), FA.Z)))
    }
    /// Vertical grime or rust streak hanging from `top` on a face at plane `z`.
    static func streak(_ m: inout Model, x: Float, top: Float, length: Float, width: Float, z: Float, _ mat: MaterialKey) {
        slab(&m, V3(width, length, 0.0012), V3(x, top - length / 2, z + 0.0006), mat)
    }
}
