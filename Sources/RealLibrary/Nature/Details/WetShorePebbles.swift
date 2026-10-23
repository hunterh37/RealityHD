import simd
import Foundation

/// Waterline strip of wet pebbles on dark sand, 60 x 30 cm: 45 glossy river pebbles 1 to 4 cm, denser and
/// larger toward the water edge, half sunk in damp sand. 2 LODs.
public struct WetShorePebbles: RealAsset {
    public static let id = "wet-shore-pebbles"
    public static let summary = "Waterline strip of glossy wet pebbles, 1-4 cm, half sunk in dark damp sand, 60 cm long; 2 LODs."
    public static let tags = ["nature", "rock", "water", "river"]
    public static let budget = 9_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.75)

    public var count = 50
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let size = V2(0.6, 0.3)
        let ph = rng.float(0...6.28)
        let sand = Prim.terrain(size: size, segments: lod == 0 ? 14 : 5, material: "ground.sand:6E5F4D") { p in
            0.0025 + 0.0015 * sin(p.x * 23 + ph) * cos(p.y * 17 + ph) - 0.002 * (p.y / 0.15)
        }
        m.add(sand)
        let mats: [MaterialKey] = ["rock.river-wet", "rock.cobble-wet", "rock.slate", "rock.river-wet", "rock.algae-wet"]
        var placed: [(V2, Float)] = []
        var tries = 0
        while placed.count < count && tries < count * 40 {
            tries += 1
            let x = rng.float(-0.29...0.29)
            // z toward +0.15 is the water edge: bias pebbles there.
            let z = 0.15 - 0.3 * pow(rng.float(), 1.6)
            let d = rng.float(0.012...0.04) * (0.7 + 0.5 * (z + 0.15) / 0.3)
            let p = V2(x, z)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + d) * 0.5 }) { continue }
            placed.append((p, d))
            let h = min(d * rng.float(0.45...0.7), 0.02)
            let s = DetailKit05.stone(size: V3(d, h, d * rng.float(0.65...0.9)), rng: &rng, sub: lod == 0 ? (d > 0.025 ? 4 : 3) : 2, e: 2.3, material: mats[rng.int(0...4)])
            let rot = DetailKit01.yawQuat(rng.float(0...(2 * .pi)))
            m.add(s.transformed(Xform(translation: V3(p.x, h * 0.5 * 0.55, p.y), rotation: rot)))
        }
        groundAO(&m)
        return m
    }
}
