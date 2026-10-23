import simd
import Foundation

/// Shared helpers for details group 18.
enum DetailKit18 {
    /// Flat irregular leaf lying on a surface: wavy outline, slight rim lift, long axis along +X.
    static func leafDisc(material: MaterialKey, at c: V3, yaw: Float, length: Float, width: Float, y: Float, curl: Float, ph: Float, rings: Int = 5, sectors: Int = 28) -> Surface {
        var s = GroundMesh.disc(material: material, rings: rings, sectors: sectors,
            outline: { a in
                let ex = cos(a) * length / 2, ez = sin(a) * width / 2
                let r = (ex * ex + ez * ez).squareRoot()
                let tip = cos(a) > 0.9 ? 1 + 0.25 * (cos(a) - 0.9) * 10 : 1
                return r * tip * (1 + 0.06 * sin(a * 5 + ph) + 0.03 * sin(a * 9 + ph * 2))
            },
            height: { p, t in
                let mid = -abs(p.y) / max(width, 0.001) * 0.12 * (1 - t)
                return y + t * t * curl + mid + 0.0015 * Noise.fbm(V3(p.x * 40 + ph, 0, p.y * 40), octaves: 2, seed: 5)
            })
        s.paintSplat { _ in 0 }
        return s.transformed(Xform(translation: c, rotation: DetailKit06.yaw(yaw)))
    }

    /// Water bead / droplet.
    static func drop(_ c: V3, _ r: Float, material: MaterialKey = "water.pond") -> Surface {
        DetailKit10.blob(c, V3(r, r * 0.85, r), sub: 1, material: material)
    }

    /// Fern pinna: a narrow blade, yaw about Y, drooping.
    static func pinna(root: V3, yaw: Float, length: Float, width: Float, lean: Float, curl: Float, rng: inout SeededRNG) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = length; b.width = width; b.lean = lean; b.curl = curl
        b.fold = 0.15; b.belly = 0.45; b.tipWidth = 0.15; b.segments = 3
        b.weight = V2(0.3, 0.8); b.phase = rng.float(0...6.28); b.ao = V2(0.6, 1)
        return PlantKit.blade(b, material: "fern.bracken")
    }
}
