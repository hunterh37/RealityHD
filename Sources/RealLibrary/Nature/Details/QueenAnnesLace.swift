import simd
import Foundation

/// Queen Anne's lace, 55 cm: three stems with flat white umbels of tiny florets, one drawn into a brown seed cup.
public struct QueenAnnesLace: RealAsset {
    public static let id = "queen-annes-lace"
    public static let summary = "Queen Anne's lace, 55 cm: three stems with flat white umbels and cut leaves, one umbel curled into seed."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 7_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit25.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            var m = Model(name: Self.id)
            let phase = rng.float(0...6.28)
            for s in 0..<3 {
                let p = rng.inDisc(radius: 0.05)
                let base = V3(p.x, -0.003, p.y)
                let yaw = rng.float(0...6.28)
                let h = rng.float(0.38...0.52)
                let path = DetailKit25.arc(base, h: h, reach: rng.float(0.02...0.08), yaw: yaw, n: 6, droop: 0.05)
                m.add(PlantKit.stem(path, radius: 0.0022, tipRadius: 0.0011, sides: 4, weight: V2(0, 1.5), phase: phase, material: "plant.stem:7C9A4A"))
                // Finely cut leaves: fans of narrow cards at low nodes.
                for n in 0..<(s == 2 ? 3 : 4) {
                    let t = 0.08 + Float(n) * 0.17
                    let q = DetailKit25.at(path, t)
                    let ly = yaw + Float(n) * 2.4 + rng.float(-0.4...0.4)
                    let sz = 0.09 * (1.2 - t) * rng.float(0.8...1.1)
                    let cnt = lod == 0 ? 5 : 3
                    for k in 0..<cnt {
                        let off = (Float(k) / Float(cnt - 1) - 0.5) * 1.0
                        m.add(DetailKit25.card(q, yaw: ly + off, len: sz, wid: sz * 0.25, lean: 1.0 + rng.float(-0.2...0.3), curl: 0.4, belly: 0.5, fold: 0.2,
                                               weight: 0.9, segs: 3, material: MaterialKey("fern.lady:\(DetailKit25.tint(&rng, ["5B9440", "4F8638", "689E48"]))")))
                    }
                }
                let top = path.last!
                let seeding = s == 1
                let nr = lod == 0 ? rng.int(18...22) : 10
                let radius: Float = rng.float(0.05...0.065)
                // Bracts under the umbel.
                for k in 0..<5 {
                    m.add(DetailKit25.card(top, yaw: Float(k) * 1.26, len: 0.02, wid: 0.004, lean: 1.8, curl: 0.2, belly: 0.3, segs: 1, material: "leaf.plain:5F9244"))
                }
                for k in 0..<nr {
                    let a = Float(k) * 2.399 + rng.float(-0.2...0.2)     // golden angle spread
                    let r = radius * sqrt((Float(k) + 0.5) / Float(nr))
                    let dir = V3(cos(a), 0, sin(a))
                    let ray: [V3]
                    let end: V3
                    if seeding {
                        // Rays curl inward into a bird's-nest cup.
                        let rr = radius * 0.55 * (0.5 + 0.5 * sqrt(Float(k) / Float(nr)))
                        end = top + dir * rr + V3(0, 0.03 + rr * 0.3, 0)
                        ray = [top, top + dir * rr * 1.5 + V3(0, 0.012, 0), end]
                    } else {
                        let dome = 0.018 * (1 - (r / radius) * (r / radius))
                        end = top + dir * r + V3(0, 0.022 + dome, 0)
                        ray = [top, top + dir * r * 0.5 + V3(0, 0.014, 0), end]
                    }
                    m.add(DetailKit25.wire(ray, r0: 0.0004, r1: 0.0003, sides: 3, material: seeding ? "plant.stem:7A6A3A" : "plant.stem:A8B880", weight: 1))
                    // Tiny floret cluster (secondary umbel).
                    let fr = seeding ? 0.004 : rng.float(0.0065...0.0095)
                    let mat: MaterialKey = seeding ? MaterialKey("plant.stem:\(DetailKit25.tint(&rng, ["6E5A32", "7C6A40"]))")
                        : MaterialKey("flower.petal:\(DetailKit25.tint(&rng, ["FFFFFF", "F6F4EC", "FAF8F0"]))")
                    m.add(DetailKit25.blob(end + V3(0, 0.001, 0), V3(fr, fr * 0.45, fr), sub: 1, material: mat))
                }
                if !seeding {   // the single dark red floret at the centre
                    m.add(DetailKit25.blob(top + V3(0, 0.03, 0), V3(0.0025, 0.0015, 0.0025), material: "flower.petal:5A1428"))
                }
            }
            return m
        }
    }
}
