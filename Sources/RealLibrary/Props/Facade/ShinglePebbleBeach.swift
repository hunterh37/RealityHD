import simd
import Foundation

/// Shingle beach tile, 2 x 2 m: a bank of wave-sorted flint and chert pebbles over a gravel bed,
/// with a low storm berm crest, larger cobbles in the swash cusps, scattered sand-and-grit fines,
/// a few dried wrack strands and a bleached driftwood stick.
public struct ShinglePebbleBeach: RealAsset {
    public static let id = "shingle-pebble-beach"
    public static let summary = "Shingle beach tile 2 x 2 m: graded flint and granite pebbles on a gravel bed with a berm crest and driftwood."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Bed height at the border (m).
    public var base: Float = 0.07
    /// Number of surface pebbles.
    public var pebbles: Int = 620
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func bump(_ p: V2) -> Float {
            let berm = 0.03 * exp(-pow((p.y + 0.1 + 0.08 * sin(p.x * 2.4)) / 0.35, 2))
            return berm + 0.01 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 3, seed: sd)
        }
        func hgt(_ p: V2) -> Float { LGK.height(p, w: w, d: d, edge: base, bump) }
        let mats: [MaterialKey] = ["rock.river", "rock.granite-weathered", "rock.river:8A8378", "rock.sandstone:B8A68A",
                                   "rock.basalt:4C4A48", "rock.river:C9C2B4", "rock.granite:9A8F86"]
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: base, segments: 36, "ground.pebble-beach", bump: bump)
        for i in 0..<pebbles {
            var r = rng.fork(i)
            let p = V2(r.float(-0.97...0.97), r.float(-0.97...0.97))
            // Bigger cobbles sort to the berm crest.
            let crest = exp(-pow((p.y + 0.1) / 0.3, 2))
            let s = r.float(0.018...0.038) * (1 + 0.8 * crest * r.float(0...1)) * (r.chance(0.04) ? 1.8 : 1)
            LGK.pebble(&m, at: V3(p.x, hgt(p) - s * 0.3, p.y), size: s, flat: r.float(0.4...0.7), mats[r.int(0...mats.count - 1)], rng: &r, sub: s > 0.045 ? 2 : 1)
        }
        // Dried wrack and a driftwood stick lodged on the berm.
        var r = rng.fork(9000)
        let a = V2(r.float(-0.5...(-0.2)), -0.1), b = V2(r.float(0.2...0.5), 0.05)
        let mid = (a + b) / 2, len = simd_length(b - a), yaw = atan2(b.y - a.y, b.x - a.x)
        m.add(Prim.roundedBox(V3(len, 0.035, 0.04), radius: 0.016, bevelSegments: 3, material: "wood.weathered:B4AA98"),
              Xform(translation: V3(mid.x, hgt(mid) + 0.035, mid.y), rotation: simd_quatf(angle: -yaw, axis: .up) * simd_quatf(degrees: 4, axis: V3(1, 0, 0))))
        for i in 0..<10 {
            var q = rng.fork(9100 + i)
            let p = V2(q.float(-0.85...0.85), q.float(-0.4...0.2))
            m.add(Prim.roundedBox(V3(q.float(0.05...0.1), 0.004, 0.012), radius: 0.0018, bevelSegments: 1, material: "moss.cushion:2E2A1C"),
                  Xform(translation: V3(p.x, hgt(p) + 0.025, p.y), rotation: simd_quatf(degrees: q.float(0...360), axis: .up)))
        }
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: base + 0.015, segments: 24, "ground.pebble-beach", bump: bump)
        return LGK.finish(&m, lite: lite, ao: 0.03)
    }
}
