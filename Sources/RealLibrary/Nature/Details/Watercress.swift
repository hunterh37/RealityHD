import simd
import Foundation

/// Watercress patch, 50 cm across, growing in shallow flowing water: 16 creeping hollow stems rooted in silt,
/// each with 5 to 8 pinnate leaves of 3 to 7 round leaflets, big terminal leaflet. 2 LODs.
public struct Watercress: RealAsset {
    public static let id = "watercress"
    public static let summary = "Watercress patch, 50 cm, in shallow flow: creeping stems with pinnate leaves of round leaflets on silt; 2 LODs."
    public static let tags = ["nature", "plant", "water", "river"]
    public static let budget = 6_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.8)

    public var sprigs = 24
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var silt = DetailKit05.stone(size: V3(0.52, 0.016, 0.42), rng: &rng, sub: lod == 0 ? 6 : 3, e: 2.2, material: "ground.river-silt:7A6A52")
        silt = silt.transformed(Xform(translation: V3(0, 0.003, 0)))
        m.add(silt)
        var stems = Surface(material: "plant.stem")
        var leaves = Surface(material: "leaf.plain:2F6B28")
        let cell = (origin: V2(0, 0), size: V2(1, 1))
        for _ in 0..<sprigs {
            let p = rng.inDisc(radius: 0.2)
            let yaw = rng.float(0...(2 * .pi))
            let len = rng.float(0.15...0.26)
            let pts = PlantKit.arc(from: V3(p.x, 0.012, p.y), height: len, yaw: yaw, lean: rng.float(0.9...1.35), bend: rng.float(-0.3...0.5), count: 6)
            stems.append(PlantKit.stem(pts, radius: 0.0016, tipRadius: 0.001, sides: lod == 0 ? 4 : 3, weight: V2(0.1, 0.6), phase: rng.float(0...6.28)))
            for k in 1..<pts.count {
                let side: Float = k % 2 == 0 ? 1 : -1
                let dir = simd_normalize(pts[k] - pts[k - 1])
                let out = simd_normalize(simd_cross(dir, V3(0, 1, 0))) * side
                let scale = 1 - 0.45 * Float(k) / 6
                var base = pts[k]
                let petLen = 0.02 * scale
                let tipDir = simd_normalize(out + V3(0, 0.6, 0) + dir * 0.4)
                let leafN = lod == 0 ? rng.int(1...3) : min(1, rng.int(1...3))  // lateral pairs
                let phase = rng.float(0...6.28)
                for j in 0...leafN {
                    let q = base + tipDir * petLen * Float(j) * 0.9
                    for sgn: Float in [1, -1] where j < leafN {
                        let lat = simd_normalize(simd_cross(tipDir, V3(0, 1, 0))) * sgn * 0.012 * scale
                        leaves.append(PlantKit.disc(center: q + lat, normal: V3(0, 1, 0) + rng.unitVector() * 0.25, radius: 0.012 * scale * rng.float(0.8...1.1), cup: 0.12, rim: lod == 0 ? 7 : 4, cell: cell, spin: rng.float(0...6.28), weight: 0.5, phase: phase, ao: 0.85, material: "leaf.plain:2F6B28"))
                    }
                    if j == leafN {
                        leaves.append(PlantKit.disc(center: q + tipDir * 0.01 * scale, normal: V3(0, 1, 0) + rng.unitVector() * 0.25, radius: 0.018 * scale * rng.float(0.85...1.1), cup: 0.15, rim: lod == 0 ? 8 : 4, cell: cell, spin: rng.float(0...6.28), weight: 0.6, phase: phase, ao: 0.9, material: "leaf.plain:2F6B28"))
                    }
                }
                base = pts[k]
                stems.append(PlantKit.stem([pts[k], pts[k] + tipDir * petLen * Float(leafN + 1) * 0.9], radius: 0.0008, sides: 3, weight: V2(0.4, 0.6), phase: phase))
            }
        }
        stems.computeTangents(); leaves.computeTangents()
        m.add(stems); m.add(leaves)
        groundAO(&m)
        return m
    }
}
