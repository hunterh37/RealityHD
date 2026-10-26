import simd
import Foundation

/// 35 cm mat of partridge berry: creeping wiry vines rooting at nodes, paired round dark leaves with pale midribs,
/// 8 to 12 bright red berries. 2 LODs.
public struct PartridgeBerry: RealAsset {
    public static let id = "partridge-berry"
    public static let summary = "Partridge berry vine, 35 cm: creeping stems with paired round dark leaves and red berries; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 0.7)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit24.lods(SeededRNG(seed: seed), dist: 3) { lod, rng in
            var m = Model(name: Self.id)
            var berries = 0
            for v in 0..<rng.int(4...5) {
                var yaw = Float(v) / 4.5 * 2 * .pi + rng.float(-0.4...0.4)
                var p = V3(rng.float(-0.02...0.02), 0.003, rng.float(-0.02...0.02))
                var pts = [p]
                let nodes = rng.int(9...12)
                var nodePts: [(V3, Float)] = []
                for _ in 0..<nodes {
                    yaw += rng.float(-0.4...0.4)
                    p += V3(cos(yaw), 0, sin(yaw)) * rng.float(0.012...0.018)
                    p.y = 0.003 + rng.float(0...0.004)
                    if length(V2(p.x, p.z)) > 0.17 { break }
                    pts.append(p); nodePts.append((p, yaw))
                }
                if pts.count < 2 { continue }
                m.add(DetailKit24.wire(pts, r0: 0.0011, r1: 0.0007, sides: 3, material: "plant.stem:5A4630", weight: 0))
                for (q, y) in nodePts {
                    let sz = rng.float(0.018...0.027)
                    for side: Float in [-1, 1] {
                        let tint = ["3F8A3C", "4A9A42", "357A34"][rng.int(0...2)]
                        let cell = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
                        _ = cell
                        m.add(DetailKit24.card(q + V3(0, 0.001, 0), yaw: y + side * (1.5 + rng.float(-0.3...0.3)), len: sz, wid: sz * 0.95,
                                               lean: 1.35 + rng.float(-0.2...0.25), curl: rng.float(-0.1...0.3), belly: 0.8, fold: 0.12,
                                               weight: 0.3, segs: 2, material: MaterialKey("leaf.rose:\(tint)")))
                    }
                    if berries < 12 && rng.float(0...1) < 0.2 {
                        berries += 1
                        let b = q + V3(rng.float(-0.005...0.005), 0.005, rng.float(-0.005...0.005))
                        m.add(DetailKit24.blob(b, V3(0.0052, 0.0048, 0.0052), sub: lod == 0 ? 2 : 1, material: "flower.petal:C0202A"))
                        m.add(DetailKit24.blob(b + V3(0, 0.0045, 0), V3(0.0012, 0.0008, 0.0012), sub: 1, material: "plant.stem:3A2418"))
                    }
                }
            }
            DetailKit10.litter(&m, radius: 0.15, count: lod == 0 ? 4 : 2, rng: &rng)
            return m
        }
    }
}
