import simd
import Foundation

/// Bluebell sprig, 35 cm: arching stems with nodding blue bells, strap leaves at the base.
public struct BluebellSprig: RealAsset {
    public static let id = "bluebell-sprig"
    public static let summary = "Bluebell sprig, 35 cm: arching stems hung with nodding blue bells over long strap leaves; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 4_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.8)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit25.lods(SeededRNG(seed: seed), dist: 3.5) { lod, rng in
            var m = Model(name: Self.id)
            let phase = rng.float(0...6.28)
            for i in 0..<rng.int(3...4) {
                let p = rng.inDisc(radius: 0.035)
                let base = V3(p.x, -0.003, p.y)
                let yaw = rng.float(0...6.28)
                for _ in 0..<rng.int(4...5) {
                    m.add(DetailKit25.card(base, yaw: yaw + rng.float(-1.4...1.4), len: rng.float(0.18...0.28), wid: rng.float(0.011...0.016),
                                           lean: rng.float(0.5...0.9), curl: rng.float(0.8...1.3), belly: 0.3, fold: 0.25, weight: 0.5, segs: 4,
                                           tip: 0.15, material: MaterialKey("leaf.plain:\(DetailKit25.tint(&rng, ["3E7F34", "4A8C3A", "366F2C"]))")))
                }
                let h = rng.float(0.22...0.3)
                let path = DetailKit25.arc(base, h: h, reach: rng.float(0.09...0.15), yaw: yaw, n: 8, droop: 0.35)
                m.add(PlantKit.stem(path, radius: 0.0016, tipRadius: 0.0007, sides: 4, weight: V2(0, 1.2), phase: phase, material: "plant.stem:7FA050"))
                let nb = rng.int(6...9)
                let right = V3(-sin(yaw), 0, cos(yaw))
                for j in 0..<nb {
                    let t = 0.45 + 0.55 * Float(j) / Float(nb)
                    let q = DetailKit25.at(path, t)
                    let side: Float = j % 2 == 0 ? 1 : -1
                    let sz = (1.05 - 0.4 * Float(j) / Float(nb)) * rng.float(0.85...1.1)
                    // Pedicel arcs out then down; bell hangs at its end.
                    let out = right * side * 0.014 * sz
                    let pp = [q, q + out * 0.6 + V3(0, 0.006, 0), q + out + V3(0, 0.003, 0)]
                    m.add(PlantKit.stem(pp, radius: 0.0004, tipRadius: 0.0003, sides: 3, weight: V2(0, 1), phase: phase, material: "plant.stem:6C8F8A"))
                    let c = pp.last!
                    let tint = DetailKit25.tint(&rng, ["5A5FC8", "4C54BE", "6A6AD0", "4A4FB0"])
                    let bell = DetailKit25.blob(c + V3(0, -0.008 * sz, 0), V3(0.0036, 0.0085, 0.0036) * sz, sub: 1, material: MaterialKey("flower.petal:\(tint)"))
                    m.add(bell)
                    if lod == 0 {
                        for k in 0..<6 {
                            let a = Float(k) / 6 * 6.283 + rng.float(-0.2...0.2)
                            m.add(DetailKit25.card(c + V3(0, -0.015 * sz, 0), yaw: a, len: 0.0075 * sz, wid: 0.0032 * sz, lean: 2.1, curl: -0.7,
                                                   belly: 0.5, weight: 1.2, segs: 1, tip: 0.3, material: MaterialKey("flower.petal:\(tint)")))
                        }
                    }
                }
                if i == 0 {   // unopened buds at the tip
                    let tip = path.last!
                    for k in 0..<3 {
                        m.add(DetailKit25.blob(tip + V3(rng.float(-0.002...0.002), 0.003 + Float(k) * 0.004, rng.float(-0.002...0.002)), V3(0.0024, 0.0045, 0.0024), material: "flower.petal:7E86C0"))
                    }
                }
            }
            return m
        }
    }
}
