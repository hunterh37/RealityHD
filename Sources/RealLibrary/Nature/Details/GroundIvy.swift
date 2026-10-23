import simd
import Foundation

/// Ground ivy (Glechoma), 40 cm mat: creeping square runners rooted at nodes with opposite pairs of round scalloped leaves and a few violet flowers.
public struct GroundIvy: RealAsset {
    public static let id = "ground-ivy"
    public static let summary = "Ground ivy mat, 40 cm: creeping runners with opposite round scalloped leaves and a few violet flowers; 2 LODs."
    public static let tags = ["nature", "ground", "plant", "foliage"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.8, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let greens = ["5E8F38", "4F8030", "6B9A40", "3F7028"]
        let runners = rng.int(7...9)
        for r in 0..<runners {
            let yaw = Float(r) / Float(runners) * 6.28 + rng.float(-0.3...0.3)
            let len = rng.float(0.13...0.2)
            let nodes = rng.int(6...8)
            var p = V3(rng.float(-0.02...0.02), 0.003, rng.float(-0.02...0.02))
            var h = yaw
            var pts = [p]
            for n in 1...nodes {
                h += rng.float(-0.35...0.35)
                p += V3(cos(h), rng.float(-0.0003...0.0008), sin(h)) * (len / Float(nodes))
                p.y = max(0.002, p.y)
                pts.append(p)
            }
            let st = PlantKit.stem(pts, radius: 0.0009, tipRadius: 0.0006, sides: 4, weight: V2(0, 0.1), phase: phase, material: "plant.stem:7A6A48")
            m0.add(st); m1.add(st)
            for (i, q) in pts.enumerated() where i >= 1 {
                let tang = simd_normalize(q - pts[i - 1])
                let ly = atan2(tang.z, tang.x)
                let size = rng.float(0.022...0.034) * (1.05 - 0.4 * Float(i) / Float(nodes))
                for s in [-1, 1] as [Float] {
                    let a = ly + s * rng.float(1.2...1.9)
                    let l = DetailKit03.leaf(root: q + V3(0, 0.001, 0), yaw: a, length: size, width: size * 0.95, lean: rng.float(1.2...1.5),
                                             curl: rng.float(-0.1...0.25), fold: -0.12, belly: 0.8, tip: 0.02, segments: 5, weight: 0.3,
                                             phase: phase, material: MaterialKey("flower.petal:" + greens[rng.int(0...3)]))
                    m0.add(l)
                    if (i + (s > 0 ? 1 : 0)) % 2 == 0 { m1.add(l) }
                }
            }
            if rng.chance(0.4) {
                let q = pts[rng.int(2...nodes)]
                let fl = PlantKit.disc(center: q + V3(0, 0.012, 0), normal: V3(0.2, 1, 0.1), radius: 0.0055, cup: 0.35, rim: 6,
                                       cell: PlantKit.cell(6, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.6, phase: phase, material: "flower.petal:8E6CC8")
                m0.add(fl); m1.add(fl)
            }
        }
        groundAO(&m0, height: 0.03, floor: 0.6); groundAO(&m1, height: 0.03, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
