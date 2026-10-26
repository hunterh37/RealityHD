import simd
import Foundation

/// 6 to 9 Christmas fern fronds, 30 to 45 cm: leathery dark evergreen lance fronds with eared leaflets on a scaly stipe. 2 LODs.
public struct ChristmasFern: RealAsset {
    public static let id = "christmas-fern"
    public static let summary = "Christmas fern, 40 cm: arching leathery dark green fronds with eared leaflets on scaly stipes; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit24.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            var m = Model(name: Self.id)
            let n = rng.int(6...9)
            for f in 0..<n {
                let a = Float(f) / Float(n) * 2 * .pi + rng.float(-0.35...0.35)
                let base = V3(cos(a) * 0.015, -0.003, sin(a) * 0.015)
                let h = rng.float(0.13...0.2), reach = rng.float(0.12...0.24)
                let path = DetailKit24.arc(base, h: h, reach: reach, yaw: a, n: 8, droop: 0.35)
                m.add(DetailKit24.wire(path, r0: 0.0028, r1: 0.001, sides: 4, material: "wood.deadwood:4A3820", weight: 3))
                let leaflets = lod == 0 ? rng.int(26...32) : rng.int(12...14)
                for j in 0..<leaflets {
                    let t = 0.22 + 0.78 * Float(j) / Float(leaflets)
                    let i = min(path.count - 2, Int(t * Float(path.count - 1)))
                    let q = path[i] + (path[i + 1] - path[i]) * (t * Float(path.count - 1) - Float(i))
                    let sz = 0.075 * (1 - 0.7 * pow(t, 2.2)) * rng.float(0.85...1.1)
                    let tint = ["2F5A26", "3A6A2C", "2A4F22"][rng.int(0...2)]
                    for side: Float in [-1, 1] {
                        m.add(DetailKit24.card(q, yaw: a + side * (1.35 + rng.float(-0.15...0.15)), len: sz, wid: sz * 0.34,
                                               lean: 1.15 + rng.float(-0.15...0.25), curl: 0.3, belly: 0.7, fold: 0.1, weight: 0.6,
                                               segs: lod == 0 ? 3 : 2, material: MaterialKey("fern.bracken:\(tint)")))
                    }
                }
                m.add(DetailKit24.card(path.last!, yaw: a, len: 0.04, wid: 0.01, lean: 1.0, curl: 0.4, belly: 0.7, fold: 0.1,
                                       weight: 0.7, segs: 2, material: "fern.bracken:2F5A26"))
            }
            DetailKit10.litter(&m, radius: 0.12, count: lod == 0 ? 3 : 1, rng: &rng)
            return m
        }
    }
}
