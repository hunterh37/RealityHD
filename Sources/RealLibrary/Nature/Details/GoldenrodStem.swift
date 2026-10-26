import simd
import Foundation

/// Goldenrod stem, 60 cm: upright stem of lance leaves ending in an arching plume of yellow florets.
public struct GoldenrodStem: RealAsset {
    public static let id = "goldenrod-stem"
    public static let summary = "Goldenrod stem, 60 cm: upright stem with lance leaves and an arching plume of yellow floret clusters; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit25.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            var m = Model(name: Self.id)
            let phase = rng.float(0...6.28)
            let yaw = rng.float(0...6.28)
            let base = V3(0, -0.004, 0)
            let path = DetailKit25.arc(base, h: rng.float(0.5...0.6), reach: rng.float(0.08...0.14), yaw: yaw, n: 10, droop: 0.12)
            m.add(PlantKit.stem(path, radius: 0.0032, tipRadius: 0.0012, sides: 5, weight: V2(0, 1.6), phase: phase, material: "plant.stem:6E8240"))
            let nl = lod == 0 ? 20 : 12
            for i in 0..<nl {
                let t = 0.03 + 0.7 * Float(i) / Float(nl)
                let q = DetailKit25.at(path, t)
                let sz = (0.11 - 0.07 * t) * rng.float(0.8...1.15)
                m.add(DetailKit25.card(q, yaw: yaw + Float(i) * 2.4 + rng.float(-0.3...0.3), len: sz, wid: sz * 0.17, lean: 0.8 + t * 0.4 + rng.float(-0.15...0.15),
                                       curl: rng.float(0.2...0.6), belly: 0.45, fold: 0.2, weight: 0.8, segs: 3, tip: 0.05,
                                       material: MaterialKey("leaf.plain:\(DetailKit25.tint(&rng, ["46792F", "3C6C28", "528436", "4C7A30"]))")))
            }
            // Plume: side branches in the upper 30 percent, each carrying floret clusters.
            let nb = lod == 0 ? 14 : 9
            for b in 0..<nb {
                let t = 0.72 + 0.28 * Float(b) / Float(nb)
                let q = DetailKit25.at(path, t)
                let by = yaw + Float(b) * 2.4 + rng.float(-0.4...0.4)
                let len = 0.065 * (1.05 - 0.6 * (t - 0.72) / 0.28) * rng.float(0.8...1.2)
                let bp = DetailKit25.arc(q, h: len * 0.5, reach: len, yaw: by, n: 3, droop: 0.5)
                m.add(DetailKit25.wire(bp, r0: 0.0009, r1: 0.0005, sides: 3, material: "plant.stem:7A8A44", weight: 1.2))
                let nf = lod == 0 ? rng.int(6...9) : 4
                for f in 0..<nf {
                    let u = 0.25 + 0.75 * Float(f) / Float(nf)
                    let c = DetailKit25.at(bp, u) + V3(rng.float(-0.003...0.003), rng.float(0.0...0.004), rng.float(-0.003...0.003))
                    let r = rng.float(0.0032...0.0048)
                    let tint = DetailKit25.tint(&rng, ["F2C418", "E8B80E", "F8D030", "DDAA10"])
                    m.add(DetailKit25.blob(c, V3(r, r * 0.8, r), sub: 1, material: MaterialKey("flower.petal:\(tint)")))
                    if lod == 0 && f % 2 == 0 {   // ray florets
                        for k in 0..<3 {
                            m.add(DetailKit25.card(c, yaw: Float(k) * 2.1 + rng.float(0...1), len: r * 1.6, wid: r * 0.5, lean: 1.0, curl: 0.2, belly: 0.5, weight: 1, segs: 1,
                                                   material: MaterialKey("flower.petal:\(tint)")))
                        }
                    }
                }
            }
            return m
        }
    }
}
