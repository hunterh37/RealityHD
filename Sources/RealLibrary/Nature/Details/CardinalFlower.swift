import simd
import Foundation

/// Cardinal flower, 70 cm: tall stem with lance leaves and a spike of scarlet two-lipped flowers, on a patch of wet mud.
public struct CardinalFlower: RealAsset {
    public static let id = "cardinal-flower"
    public static let summary = "Cardinal flower, 70 cm: tall stem with lance leaves and a spike of scarlet two-lipped flowers on wet mud; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage", "water"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit25.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            var m = Model(name: Self.id)
            let phase = rng.float(0...6.28)
            let yaw = rng.float(0...6.28)
            // Wet mud pad with a shallow puddle.
            m.add(DetailKit25.blob(V3(0, -0.012, 0), V3(0.16, 0.014, 0.13), sub: 2, material: "ground.mud"))
            m.add(DetailKit25.blob(V3(0.05, -0.0045, 0.03), V3(0.06, 0.006, 0.045), sub: 1, material: "water.pond"))
            let base = V3(-0.03, 0.0, -0.01)
            let path = DetailKit25.arc(base, h: rng.float(0.62...0.72), reach: rng.float(0.02...0.06), yaw: yaw, n: 10, droop: 0.05)
            m.add(PlantKit.stem(path, radius: 0.0035, tipRadius: 0.0012, sides: 5, weight: V2(0, 1.4), phase: phase, material: "plant.stem:6A5238"))
            // Basal rosette then stem leaves.
            for k in 0..<5 {
                m.add(DetailKit25.card(base, yaw: yaw + Float(k) * 1.26 + rng.float(-0.3...0.3), len: rng.float(0.1...0.15), wid: 0.025, lean: rng.float(1.0...1.3),
                                       curl: 0.5, belly: 0.5, fold: 0.15, weight: 0.5, segs: 3, tip: 0.05, material: "leaf.plain:3A6E2E"))
            }
            let nl = lod == 0 ? 14 : 9
            for i in 0..<nl {
                let t = 0.05 + 0.6 * Float(i) / Float(nl)
                let sz = (0.12 - 0.06 * t) * rng.float(0.85...1.1)
                m.add(DetailKit25.card(DetailKit25.at(path, t), yaw: yaw + Float(i) * 2.4 + rng.float(-0.3...0.3), len: sz, wid: sz * 0.2, lean: 0.9 + t * 0.5,
                                       curl: 0.35, belly: 0.45, fold: 0.2, weight: 0.8, segs: 3, tip: 0.05,
                                       material: MaterialKey("leaf.plain:\(DetailKit25.tint(&rng, ["3E7430", "35672A", "4A7F36"]))")))
            }
            // Flower spike: open flowers low, tight buds toward the tip.
            let nf = lod == 0 ? 20 : 12
            for f in 0..<nf {
                let t = 0.66 + 0.34 * Float(f) / Float(nf)
                let q = DetailKit25.at(path, t)
                let a = yaw + Float(f) * 2.4 + rng.float(-0.3...0.3)
                let open = 1 - Float(f) / Float(nf)
                let sz = (0.4 + 0.6 * open) * rng.float(0.85...1.1)
                let d = V3(cos(a), 0, sin(a))
                let pp = [q, q + d * 0.008 * sz + V3(0, 0.003, 0)]
                m.add(DetailKit25.wire(pp, r0: 0.0006, r1: 0.0005, sides: 3, material: "plant.stem:7A4A38", weight: 1))
                let c = pp.last!
                let red = DetailKit25.tint(&rng, ["D01818", "C41010", "E02424", "B80E14"])
                let mat = MaterialKey("flower.petal:\(red)")
                m.add(DetailKit25.blob(c + d * 0.004 * sz + V3(0, 0.002, 0), V3(0.0045, 0.0035, 0.0045) * sz, sub: 1, material: mat))
                if open > 0.25 {
                    // Upper lip: two small lobes. Lower lip: three spreading lobes.
                    let o = c + d * 0.009 * sz
                    for k in 0..<2 {
                        m.add(DetailKit25.card(o + V3(0, 0.002, 0), yaw: a + (Float(k) - 0.5) * 0.7, len: 0.012 * sz, wid: 0.0045 * sz, lean: 0.9, curl: 0.4,
                                               belly: 0.6, weight: 1, segs: 1, tip: 0.3, material: mat))
                    }
                    if lod == 0 {
                        for k in 0..<3 {
                            m.add(DetailKit25.card(o, yaw: a + (Float(k) - 1) * 0.55, len: 0.015 * sz, wid: 0.0055 * sz, lean: 1.7, curl: -0.3,
                                                   belly: 0.6, weight: 1, segs: 1, tip: 0.3, material: mat))
                        }
                    }
                }
            }
            return m
        }
    }
}
