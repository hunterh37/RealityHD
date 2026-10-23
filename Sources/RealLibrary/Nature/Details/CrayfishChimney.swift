import simd
import Foundation

/// Crayfish burrow chimney: 15 cm turret of pelleted mud balls stacked in rings around a dark burrow hole, on a mud apron.
public struct CrayfishChimney: RealAsset {
    public static let id = "crayfish-chimney"
    public static let summary = "Fifteen-centimeter crayfish burrow chimney of stacked mud pellets around a dark hole on a mud apron."
    public static let tags = ["nature", "ground", "river"]
    public static let budget = 6_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50)
        m.add(GroundMesh.disc(material: "ground.mud", rings: lod == 0 ? 10 : 5, sectors: lod == 0 ? 32 : 16,
            outline: { a in 0.11 * (1 + 0.15 * sin(a * 3 + ph) + 0.05 * sin(a * 7)) },
            height: { q, t in
                let r = simd_length(q)
                return (0.012 * exp(-pow(r / 0.07, 2)) + 0.003 + 0.002 * Noise.fbm(V3(q.x * 30 + ph, 0, q.y * 30), octaves: 2, seed: 3)) * GroundMesh.rim(t, from: 0.6)
            }))
        let layers = 8
        let lean = V2(rng.float(-0.01...0.01), rng.float(-0.01...0.01))
        var y: Float = 0.008
        for L in 0..<layers {
            let t = Float(L) / Float(layers - 1)
            let ring = 0.040 - 0.012 * t + 0.004 * sin(t * 3)
            let cnt = Int(Float(lod == 0 ? 15 : 11) - Float(L) * 0.5)
            let off = rng.float(0...6.28)
            for k in 0..<cnt {
                let a = off + (Float(k) + rng.float(-0.25...0.25)) / Float(cnt) * 2 * .pi
                if L > 4 && rng.chance(0.2) { continue }   // ragged rim
                let bs = rng.float(0.022...0.032)
                let rr = ring + rng.float(-0.004...0.004)
                let c = V3(cos(a) * rr + lean.x * t * 10, y + bs * 0.35 + rng.float(-0.002...0.004), sin(a) * rr + lean.y * t * 10)
                let tint = ["6B5640", "5A4833", "76624A", "4F3E2C"][rng.int(0...3)]
                var s = DetailKit05.stone(size: V3(bs, bs * rng.float(0.7...0.95), bs * rng.float(0.85...1.1)) * 1.0, rng: &rng, sub: lod == 0 ? 2 : 1, e: 2.0, material: "ground.mud:" + tint)
                s = s.transformed(Xform(translation: c, rotation: DetailKit06.yaw(rng.float(0...6.28))))
                m.add(s)
            }
            y += 0.0165
        }
        let wallTop = y - 0.006
        m.add(Prim.tube([V3(lean.x * 0, 0.004, 0), V3(lean.x * 5, wallTop * 0.5, lean.y * 5), V3(lean.x * 10, wallTop, lean.y * 10)], radii: [0.034, 0.027, 0.02], sides: 10, seamTile: 0.03, material: "ground.mud:4A3A2A", capEnd: false))
        // Dark burrow hole: a dim disc just below the top rim.
        var hole = Surface(material: "ground.mud:1E1812")
        let hr: Float = 0.016
        let top = y - 0.03
        let c = hole.add(V3(lean.x * 10, top, lean.y * 10), .up, .zero)
        for k in 0..<12 {
            let a = Float(k) / 12 * 2 * .pi
            _ = hole.add(V3(cos(a) * hr + lean.x * 10, top, sin(a) * hr + lean.y * 10), .up, V2(cos(a), sin(a)) * hr)
        }
        for k in 0..<12 { hole.tri(c, 1 + c + UInt32((k + 1) % 12), 1 + c + UInt32(k)) }
        hole.recomputeNormals(weldSeams: false); hole.computeTangents()
        m.add(hole)
        groundAO(&m)
        return m
    }
}
