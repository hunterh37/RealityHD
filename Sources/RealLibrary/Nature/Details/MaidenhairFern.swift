import simd
import Foundation

/// 5 to 7 maidenhair fern fronds, 25 to 35 cm: wiry black stems forking into arching rachises with fan-shaped pinnae. 2 LODs.
public struct MaidenhairFern: RealAsset {
    public static let id = "maidenhair-fern"
    public static let summary = "Maidenhair fern, 30 cm: wiry black stems arching into horseshoe fronds of small fan-shaped pinnae; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 0.7)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit24.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            var m = Model(name: Self.id)
            let stem: MaterialKey = "wood.charred:1A1210"
            for f in 0..<rng.int(5...7) {
                let a = Float(f) / 6 * 2 * .pi + rng.float(-0.5...0.5)
                let r = rng.float(0.01...0.05)
                let base = V3(cos(a) * r, -0.003, sin(a) * r)
                let h = rng.float(0.16...0.24)
                let yaw = a + rng.float(-0.6...0.6)
                let path = DetailKit24.arc(base, h: h, reach: rng.float(0.05...0.12), yaw: yaw, n: 6, droop: 0.15)
                m.add(DetailKit24.wire(path, r0: 0.0016, r1: 0.001, sides: 4, material: stem, weight: 3))
                // Rachises fork from the upper third.
                let top = path[4]
                let nr = rng.int(3...4)
                for k in 0..<nr {
                    let sy = yaw + (Float(k) / Float(max(1, nr - 1)) - 0.5) * 2.2 + rng.float(-0.15...0.15)
                    let len = rng.float(0.07...0.11)
                    let rp = DetailKit24.arc(top, h: len * 0.35, reach: len, yaw: sy, n: 4, droop: 0.3)
                    m.add(DetailKit24.wire(rp, r0: 0.0008, r1: 0.0005, sides: 3, material: stem, weight: 3))
                    let n = lod == 0 ? rng.int(8...10) : rng.int(4...5)
                    for j in 1...n {
                        let t = Float(j) / Float(n)
                        let i = min(rp.count - 1, Int(t * Float(rp.count - 1)))
                        let q = rp[i]
                        let sz = 0.02 * (1.1 - 0.5 * t) * rng.float(0.8...1.2)
                        for side: Float in [-1, 1] {
                            let tint = ["5E9A3C", "6BA848", "558C36"][rng.int(0...2)]
                            m.add(DetailKit24.card(q, yaw: sy + side * rng.float(1.1...1.7), len: sz, wid: sz * 1.1, lean: 1.2 + rng.float(-0.2...0.2),
                                                   curl: 0.3, belly: 0.9, fold: 0.04, weight: 0.7, segs: 2, material: MaterialKey("fern.lady:\(tint)")))
                        }
                        m.add(DetailKit24.card(q, yaw: sy + rng.float(-0.3...0.3), len: sz * 0.9, wid: sz, lean: 0.9, curl: 0.4,
                                               belly: 0.9, fold: 0.04, weight: 0.7, segs: 2, material: "fern.lady:62A040"))
                    }
                }
            }
            return m
        }
    }
}
