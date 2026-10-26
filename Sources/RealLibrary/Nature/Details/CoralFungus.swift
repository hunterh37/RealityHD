import simd
import Foundation

/// Coral fungus (Ramaria) 9 cm tall: pale branched cluster rising from a short thick base, tips tinted pink-tan, with litter at the base.
public struct CoralFungus: RealAsset {
    public static let id = "coral-fungus"
    public static let summary = "Coral fungus about 9 cm tall: pale cream branching clusters from thick bases with tan tips, on forest duff with litter."
    public static let tags = ["nature", "fungus"]
    public static let budget = 13_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 0.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let ms = (0..<3).map { make(seed: seed, lod: $0) }
        return LODModel(levels: ms, switchDistances: [0.7, 1.8])
    }

    private func make(seed: UInt64, lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var parts: [Surface] = []
        m.add(DetailKit23.lobe(at: V3(0, 0.002, 0), radii: V3(0.065, 0.007, 0.055), sub: DetailKit23.q(5, lod), rng: &rng, jitter: 0.2, material: "ground.forest"))
        for i in 0..<9 {
            let a = rng.float(0...6.28), d = rng.float(0.01...0.06)
            m.add(DetailKit23.lobe(at: V3(cos(a) * d, 0.006, sin(a) * d), radii: V3(rng.float(0.01...0.02), 0.0012, rng.float(0.006...0.012)),
                                   q: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0)), sub: DetailKit23.q(3, lod), rng: &rng, material: i % 2 == 0 ? "litter.dry" : "leaf.oak:7A5A33"))
        }
        let clusters: [(V2, Float)] = [(V2(-0.012, 0.004), 1), (V2(0.016, -0.006), 0.8), (V2(0.002, 0.018), 0.62)]
        for (c, s) in clusters {
            let base = V3(c.x, -0.003, c.y)
            let stub = DetailKit23.tube([base, base + V3(0, 0.014 * s, 0)], r0: 0.011 * s, r1: 0.009 * s, sides: 8, material: "fungus.stalk:EFE4CE")
            parts.append(stub)
            let n = Int(5 + 2 * s)
            for k in 0..<n {
                let ang = Float(k) / Float(n) * 6.28 + rng.float(-0.4...0.4)
                let d = simd_normalize(V3(cos(ang) * rng.float(0.35...0.7), 1, sin(ang) * rng.float(0.35...0.7)))
                DetailKit23.coral(&parts, from: base + V3(0, 0.012 * s, 0), dir: d, len: 0.026 * s * rng.float(0.8...1.2), r: 0.0042 * s,
                                  depth: 3, rng: &rng, stem: "fungus.stalk:F1E6CF", tip: "fungus.stalk:E2C9A4", lod: lod)
            }
        }
        for s in parts { m.add(s) }
        groundAO(&m, height: 0.04, floor: 0.6)
        return m
    }
}
