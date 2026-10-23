import simd
import Foundation

/// 15 to 25 white and rose quartz pebbles, 2 to 6 cm, smooth and glossy, loosely scattered.
public struct QuartzPebbles: RealAsset {
    public static let id = "quartz-pebbles"
    public static let summary = "Fifteen to twenty-five white and rose quartz pebbles of 2 to 6 cm with glassy highlights; 2 LODs."
    public static let tags = ["nature", "rock", "stone", "ground"]
    public static let budget = 2_300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.75, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit09.lods(seed: seed, name: Self.id, switchAt: 2) { lod, rng in
            var out: [Surface] = []
            let n = rng.int(15...25)
            let tints = ["F3F0E8", "ECE8DE", "E6C9C6", "F0D6D2", "FAF8F2", "D9A9A6"]
            var placed: [(V2, Float)] = []
            var tries = 0
            while placed.count < n && tries < 600 {
                tries += 1
                let big = rng.float() < 0.25
                let w = big ? rng.float(0.045...0.06) : rng.float(0.02...0.042)
                let p = rng.inDisc(radius: 0.12)
                if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + w) * 0.5 }) { continue }
                placed.append((p, w))
                let h = w * rng.float(0.45...0.7)
                let mat: MaterialKey = "rock.river-wet:" + tints[rng.int(0...5)]
                let b = DetailKit09.blob(V3(w / 2, h / 2, w * rng.float(0.32...0.5)), sub: lod == 0 ? 3 : 2, material: mat, rng: &rng, jitter: 0.1)
                out.append(DetailKit09.shift(b, V3(p.x, h / 2 - 0.002, p.y), yaw: rng.float(0...6.28)))
            }
            return out
        }
    }
}
