import simd
import Foundation

/// Shared helpers for details group 20.
enum DetailKit20 {
    /// Builds two LODs from the same seed so both levels share one layout.
    static func lods(_ rng: SeededRNG, dist: Float, _ f: (Int, inout SeededRNG) -> Model) -> LODModel {
        var a = rng, b = rng
        return LODModel(levels: [f(0, &a), f(1, &b)], switchDistances: [dist])
    }

    /// Rotates `part` about the origin, centers it at `xz` and drops it so its lowest point sits `sink` below y = 0.
    static func place(_ part: Surface, q: simd_quatf, at xz: V2, sink: Float = 0) -> Surface {
        let r = part.transformed(Xform(translation: .zero, rotation: q))
        let lo = r.bounds.min.y
        return r.transformed(Xform(translation: V3(xz.x, -lo - sink, xz.y)))
    }

    /// Flat scale or bract: ellipsoid from `base` along `out`, `len` long, `wid` wide, `th` thick, narrowing to the tip.
    static func scaleBlob(base: V3, out: V3, up: V3, len: Float, wid: Float, th: Float, sub: Int, material: MaterialKey) -> Surface {
        let u = simd_normalize(out), t = simd_normalize(simd_cross(u, up)), n = simd_normalize(simd_cross(t, u))
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            let w = 1 - 0.35 * max(0, d.x)
            return base + u * (len * (0.5 + 0.5 * d.x)) + t * (d.z * wid * 0.5 * w) + n * (d.y * th * 0.5)
        }
    }

    /// Thin tapered tube with 3 sides, no caps (needles, pedicels, thorns).
    static func spike(_ pts: [V3], r0: Float, r1: Float, material: MaterialKey) -> Surface {
        let n = pts.count
        let radii = (0..<n).map { r0 + (r1 - r0) * Float($0) / Float(n - 1) }
        return Prim.tube(pts, radii: radii, sides: 3, seamTile: 0.02, material: material, capEnd: false)
    }
}
