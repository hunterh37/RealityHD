import simd
import Foundation

/// Floating lily pads: 3 to 5 round leaves 20-30 cm with a radial notch, upturned wavy rims, and one white flower bud.
public struct LilyPad: RealAsset {
    public static let id = "lily-pad"
    public static let summary = "Three to five floating lily pads, 20-30 cm, notched with curled rims, plus one closed white flower bud."
    public static let tags = ["nature", "water", "plant", "flower"]
    public static let budget = 3_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 1.2, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m0 = gen(seed, 0), m1 = gen(seed, 1)
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ coarse: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var placed: [(V2, Float)] = []
        let n = rng.int(3...5)
        var tries = 0
        var first = true
        while placed.count < n && tries < 300 {
            tries += 1
            let r = rng.float(0.10...0.15)
            let p = rng.inDisc(radius: 0.3)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + r) * 0.97 }) { continue }
            placed.append((p, r))
            let notchA = rng.float(0...6.28), notchW = rng.float(0.07...0.13)
            let ph = rng.float(0...100)
            let tint = ["3F6B2A", "4A7A30", "35602A", "56803A"][rng.int(0...3)]
            func da(_ a: Float) -> Float { abs(atan2(sin(a - notchA), cos(a - notchA))) }
            var s = GroundMesh.disc(material: "leaf.plain:" + tint, rings: coarse == 0 ? 8 : 4, sectors: coarse == 0 ? 40 : 20,
                outline: { a in
                    let w = exp(-pow(da(a) / notchW, 2))
                    return r * (1 + 0.03 * sin(a * 3 + ph)) * (1 - 0.98 * w)
                },
                height: { q, t in
                    let rim = pow(t, 3) * 0.010
                    let wav = 0.0025 * Noise.fbm(V3(q.x * 14 + ph, 0, q.y * 14), octaves: 2, seed: 7) * t
                    return 0.004 + rim + wav
                })
            s.paintSplat { _ in 0 }
            m.add(s.transformed(Xform(translation: V3(p.x, 0, p.y), rotation: DetailKit06.yaw(rng.float(0...6.28)))))
            if first {
                first = false
                // Closed bud: stem plus tapered white teardrop with a green sepal ring.
                let bp = V3(p.x + r * 0.2 * cos(notchA + 3), 0.005, p.y + r * 0.2 * sin(notchA + 3))
                let h = rng.float(0.05...0.07)
                let stem = Prim.tube([bp, bp + V3(0.004, h * 0.55, -0.003), bp + V3(0.006, h, -0.004)], radii: [0.0035, 0.003, 0.0028], sides: 5, seamTile: 0.02, material: "plant.stem")
                m.add(stem)
                let top = bp + V3(0.006, h, -0.004)
                var bud = Prim.cubeSphere(subdivisions: coarse == 0 ? 4 : 2, material: "flower.petal:F6F3EA") { d in
                    let y = d.y
                    let w = y > 0 ? (1 - y * 0.85) : (1 + y * 0.3)
                    return V3(d.x * 0.016 * w, y * 0.035 + 0.03 * 0.3, d.z * 0.016 * w) * (1 + 0.04 * sin(d.x * 7))
                }
                bud = bud.transformed(Xform(translation: top + V3(0, 0.006, 0), rotation: simd_quatf(angle: 0.12, axis: V3(1, 0, 0))))
                m.add(bud)
                var sep = Prim.cubeSphere(subdivisions: 2, material: "leaf.plain:4A6B2E") { d in
                    V3(d.x * 0.012, d.y * 0.009, d.z * 0.012)
                }
                sep = sep.transformed(Xform(translation: top))
                m.add(sep)
            }
        }
        // Recenter the pad cluster on X/Z.
        let bb = m.bounds, c = (bb.min + bb.max) / 2
        return m.transformed(Xform(translation: V3(-c.x, 0, -c.z)))
    }
}
