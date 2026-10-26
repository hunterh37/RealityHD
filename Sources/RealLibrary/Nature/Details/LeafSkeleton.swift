import simd
import Foundation

/// Leaf skeletons, 8 to 11 cm: three decayed leaves reduced to midrib, curving veins and a fine web, with torn margins.
public struct LeafSkeleton: RealAsset {
    public static let id = "leaf-skeleton"
    public static let summary = "Three decayed leaf skeletons, 8 to 11 cm, only veins left: midrib, curved side veins, fine web, torn margin; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.45)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed, switchAt: 2.5) { lod, rng in
            var all: [Surface] = []
            let tints = ["C8AE82", "B89868", "D4BC92"]
            let centers = [V2(-0.055, -0.05), V2(0.065, -0.01), V2(-0.01, 0.075)]
            for i in 0..<3 {
                let lobed = i == 1
                let phase = rng.float(0...6.28)
                var s = DetailKit21.LeafShape(len: rng.float(0.08...0.11), width: rng.float(0.045...0.062),
                    outline: { f in
                        let base = pow(sin(.pi * pow(f, 0.8)), 0.8)
                        return lobed ? base * (0.78 + 0.22 * cos(f * 25 + phase)) : base
                    })
                s.curl = rng.float(0.2...0.6); s.bow = rng.float(0.02...0.06); s.twist = rng.float(-0.25...0.25)
                s.wob = 0.0012; s.ph = V3(rng.float(0...6.28), rng.float(0...6.28), rng.float(0...6.28))
                let mat = MaterialKey("litter.dry:" + tints[i])
                var parts = DetailKit21.veins(s, pairs: lod == 0 ? 11 : 8, lift: 0.0008, rMid: 0.0009, rSec: 0.00055,
                                              tert: lod == 0 ? 5 : 0, segs: lod == 0 ? 5 : 3, margin: true, gaps: 0.25, rng: &rng, material: mat)
                // Petiole stub.
                parts.append(DetailKit21.tube([s.point(0.02, 0) + V3(0, 0.0008, 0), s.point(0, 0) + V3(-0.014, 0.001, 0.003)], r0: 0.0009, r1: 0.0006, material: mat))
                parts = DetailKit21.put(parts, yaw: rng.float(0...6.28), tilt: V2(rng.float(-0.06...0.06), rng.float(-0.06...0.06)), at: V3(centers[i].x, 0, centers[i].y))
                all += parts
            }
            DetailKit07.settle(&all, sink: 0.002, center: true)
            return DetailKit21.finish(Self.id, all, aoHeight: 0.01, floor: 0.7)
        }
    }
}
