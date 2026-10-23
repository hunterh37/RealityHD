import simd
import Foundation

/// Shared builders for details group 03.
enum DetailKit03 {
    static func blob(_ c: V3, _ r: V3, sub: Int = 1, material: MaterialKey) -> Surface {
        Prim.cubeSphere(subdivisions: sub, material: material) { d in c + V3(d.x * r.x, d.y * r.y, d.z * r.z) }
    }

    /// Leaf strip with a rounded or pointed outline. `belly` 1 is round, 0.5 is lance shaped.
    static func leaf(root: V3, yaw: Float, length: Float, width: Float, lean: Float, curl: Float, fold: Float = 0.1,
                     belly: Float = 0.5, tip: Float = 0.1, segments: Int = 3, weight: Float = 0.5, phase: Float = 0,
                     material: MaterialKey) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = length; b.width = width; b.lean = lean; b.curl = curl
        b.fold = fold; b.belly = belly; b.tipWidth = tip; b.segments = segments
        b.weight = V2(weight * 0.5, weight); b.phase = phase; b.ao = V2(0.6, 1)
        return PlantKit.blade(b, material: material)
    }

    /// Trifoliate leaf at the end of a petiole `top`; the side leaflets are smaller and skewed.
    static func trifoliate(top: V3, yaw: Float, size: Float, material: MaterialKey, belly: Float, fold: Float,
                           phase: Float, rng: inout SeededRNG) -> [Surface] {
        var out: [Surface] = []
        for k in 0..<3 {
            let side = Float(k - 1)
            let len = size * (k == 1 ? 1 : rng.float(0.75...0.9))
            out.append(leaf(root: top, yaw: yaw + side * rng.float(0.8...1.2), length: len, width: len * rng.float(0.55...0.75),
                            lean: rng.float(1.0...1.35), curl: rng.float(0.15...0.5), fold: fold, belly: belly, segments: 5,
                            weight: 0.6, phase: phase, material: material))
        }
        return out
    }
}
