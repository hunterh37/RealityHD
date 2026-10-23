import simd
import Foundation

/// Pile of 6 to 10 flat, smooth river skipping stones, 4 to 9 cm across and 7 to 14 mm thick, stacked loosely
/// on a shore, each tilted a few degrees. 2 LODs.
public struct SkippingStones: RealAsset {
    public static let id = "skipping-stones"
    public static let summary = "Six to ten flat smooth river skipping stones, 4-9 cm, stacked loosely and tilted on a shore; 2 LODs."
    public static let tags = ["nature", "rock", "river"]
    public static let budget = 5_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.9, ground: false)

    public var count: ClosedRange<Int> = 6...10
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var placed: [(V2, Float, Float)] = []  // xz, radius, top
        let n = rng.int(count)
        let mats: [MaterialKey] = ["rock.river-wet", "rock.slate", "rock.river", "rock.cobble-wet"]
        let sizes = (0..<n).map { _ in rng.float(0.04...0.09) }.sorted(by: >)
        for (k, L) in sizes.enumerated() {
            let size = V3(L, rng.float(0.007...0.014), L * rng.float(0.7...0.9))
            let p = k == 0 ? V2.zero : rng.inDisc(radius: 0.035)
            var base: Float = 0
            for q in placed where simd_distance(q.0, p) < (q.1 + L * 0.5) * 0.8 { base = max(base, q.2) }
            let tilt = rng.float(0.03...0.2)
            let s = DetailKit05.stone(size: size, rng: &rng, sub: lod == 0 ? 6 : 3, e: 3.2, material: mats[rng.int(0...3)])
            let rot = DetailKit01.yawQuat(rng.float(0...(2 * .pi))) * simd_quatf(angle: tilt, axis: simd_normalize(V3(rng.float(-1...1), 0, rng.float(-1...1)) + V3(0.01, 0, 0)))
            let y = base + size.y * 0.5 + L * tilt * 0.4 - 0.0008
            m.add(s.transformed(Xform(translation: V3(p.x, max(y, size.y * 0.5 - 0.004), p.y), rotation: rot)))
            placed.append((p, L, y + size.y * 0.5 + L * tilt * 0.3))
        }
        groundAO(&m)
        return m
    }
}
