import simd
import Foundation

/// Two detached oak acorn cups, about 2.4 cm across: one lying open side up showing the hollow, one tipped on its side, both with ridged scale rows.
public struct AcornCapPair: RealAsset {
    public static let id = "acorn-cap-pair"
    public static let summary = "Pair of empty oak acorn cups, 2.4 cm, scaly ridged husks, one open side up and one on its side."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 1_300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.17, ground: false)

    public init() {}

    private func cup(_ rng: inout SeededRNG, scale s: Float) -> Surface {
        let ph1 = rng.float(0...6.28), ph2 = rng.float(0...6.28)
        let outer: [(Float, Float)] = [(0, 0), (0.004, 0.0008), (0.0072, 0.0028), (0.0094, 0.0050), (0.0108, 0.0074), (0.0116, 0.0098), (0.0119, 0.0122), (0.0113, 0.0146)]
        var prof: [V2] = []
        for (i, p) in outer.enumerated() {
            let ridge: Float = i > 1 && i % 2 == 1 ? 0.0006 : 0
            prof.append(V2((p.0 + ridge) * s, p.1 * s * rng.float(0.97...1.03)))
        }
        let inner: [(Float, Float)] = [(0.0105, 0.0150), (0.0100, 0.0126), (0.0088, 0.0096), (0.0066, 0.0068), (0.0036, 0.0049), (0, 0.0044)]
        for p in inner { prof.append(V2(p.0 * s, p.1 * s)) }
        var surf = Prim.lathe(prof, segments: 20, material: "bark.oak:7A6240")
        for i in surf.positions.indices {
            let p = surf.positions[i]
            let a = atan2(p.z, p.x)
            let f = 1 + 0.07 * sin(a * 2 + ph1) + 0.035 * sin(a * 5 + ph2)
            surf.positions[i] = V3(p.x * f, p.y * (1 + 0.04 * sin(a * 3 + ph2)), p.z * f)
        }
        return surf
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var all = Surface(material: "bark.oak:7A6240")
        let a = cup(&rng, scale: rng.float(0.95...1.1)), b = cup(&rng, scale: rng.float(0.85...1.0))
        let q1 = simd_quatf(angle: rng.float(0.1...0.35), axis: V3(1, 0, 0)) * simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0))
        let q2 = simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0)) * simd_quatf(angle: rng.float(1.75...2.15), axis: V3(0, 0, 1))
        all.append(DetailKit20.place(a, q: q1, at: V2(-0.016, rng.float(-0.004...0.004)), sink: 0.0005))
        all.append(DetailKit20.place(b, q: q2, at: V2(0.017, rng.float(-0.006...0.006)), sink: 0.0005))
        all.computeTangents()
        m.add(all)
        groundAO(&m, height: 0.02, floor: 0.55)
        return LODModel(levels: [m], switchDistances: [])
    }
}
