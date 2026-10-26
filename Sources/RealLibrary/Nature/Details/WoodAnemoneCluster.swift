import simd
import Foundation

/// Wood anemone cluster, 20 cm: white six-petal flowers on thin stems over whorls of cut leaves.
public struct WoodAnemoneCluster: RealAsset {
    public static let id = "wood-anemone-cluster"
    public static let summary = "Wood anemone cluster, 20 cm: white six-petal flowers over whorled, deeply cut leaves; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 4_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit25.lods(SeededRNG(seed: seed), dist: 3) { lod, rng in
            var m = Model(name: Self.id)
            let phase = rng.float(0...6.28)
            for i in 0..<rng.int(6...8) {
                let p = rng.inDisc(radius: 0.09)
                let base = V3(p.x, -0.003, p.y)
                let yaw = rng.float(0...6.28)
                let h = rng.float(0.09...0.17)
                let path = DetailKit25.arc(base, h: h, reach: rng.float(0.005...0.03), yaw: yaw, n: 4, droop: 0.1)
                m.add(PlantKit.stem(path, radius: 0.0007, tipRadius: 0.0005, weight: V2(0, 0.9), phase: phase, material: "plant.stem:8A6A58"))
                // Whorl of three compound leaves below the flower, each with 3 cut lobes.
                let w = DetailKit25.at(path, 0.62)
                for k in 0..<3 {
                    let ly = yaw + Float(k) * 2.094 + rng.float(-0.3...0.3)
                    let s = rng.float(0.03...0.045)
                    let lobes = lod == 0 ? 3 : 1
                    for j in 0..<lobes {
                        let off = Float(j - lobes / 2) * 0.5
                        m.add(DetailKit25.card(w, yaw: ly + off, len: s * (j == lobes / 2 ? 1 : 0.75), wid: s * 0.35, lean: 1.15 + rng.float(-0.15...0.2),
                                               curl: 0.3, belly: 0.5, fold: 0.1, weight: 0.6,
                                               material: MaterialKey("leaf.plain:\(DetailKit25.tint(&rng, ["3C7A32", "4A8A38", "356E2C"]))")))
                    }
                }
                if i % 3 == 0 {
                    let by = rng.float(0...6.28)
                    m.add(DetailKit25.card(V3(base.x, -0.003, base.z), yaw: by, len: 0.05, wid: 0.03, lean: 0.9, curl: 0.4, belly: 0.6, material: "leaf.plain:3F7C34"))
                }
                // Flower: 6 tepals around a yellow stamen boss, facing slightly sideways.
                let top = path.last!
                let tilt = rng.float(-0.35...0.35)
                let np = rng.int(6...7)
                for k in 0..<np {
                    let a = Float(k) / Float(np) * 6.283 + rng.float(-0.15...0.15)
                    let sz = rng.float(0.012...0.016)
                    m.add(DetailKit25.card(top + V3(0, 0.001, 0), yaw: a, len: sz, wid: sz * 0.55, lean: 1.3 + tilt * cos(a - yaw) * 0.5, curl: 0.2,
                                           belly: 0.7, weight: 0.9, tip: 0.5,
                                           material: MaterialKey("flower.petal:\(DetailKit25.tint(&rng, ["F8F6F2", "FFFFFF", "F2E8EE"]))")))
                }
                m.add(DetailKit25.blob(top + V3(0, 0.002, 0), V3(0.0045, 0.003, 0.0045), sub: 1, material: "flower.petal:E4C13A"))
                if lod == 0 && i % 2 == 0 {   // bud nodding on a short side stem
                    let bp = DetailKit25.arc(DetailKit25.at(path, 0.7), h: 0.02, reach: 0.02, yaw: yaw + 1.5, n: 2, droop: 0.9)
                    m.add(PlantKit.stem(bp, radius: 0.0005, tipRadius: 0.0004, weight: V2(0, 0.9), phase: phase, material: "plant.stem:8A6A58"))
                    m.add(DetailKit25.blob(bp.last! + V3(0, -0.004, 0), V3(0.0035, 0.006, 0.0035), material: "flower.petal:E8D8E0"))
                }
            }
            return m
        }
    }
}
