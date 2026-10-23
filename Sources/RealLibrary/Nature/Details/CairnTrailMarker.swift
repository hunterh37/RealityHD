import simd
import Foundation

/// Hiker's cairn trail marker, ~40 cm tall: six flat stones of mixed granite, slate and limestone stacked
/// off-axis, a few chips of gravel at the base, one mossy cap.
public struct CairnTrailMarker: RealAsset {
    public static let id = "cairn-trail-marker"
    public static let summary = "Hiker's cairn, ~40 cm tall: six flattened granite, slate and limestone stones stacked off-axis with gravel at the foot."
    public static let tags = ["nature", "rock", "stone", "ground"]
    public static let budget = 3600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        func make(n: Int, gravelN: Int) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let mats: [MaterialKey] = ["rock.granite-weathered", "rock.slate", "rock.limestone", "rock.granite-weathered", "rock.slate", "rock.mossy"]
            var parts: [MaterialKey: Surface] = [:]
            func put(_ s: Surface) { var cur = parts[s.material] ?? Surface(material: s.material); cur.append(s); parts[s.material] = cur }
            var top: Float = 0, off = V2(0, 0)
            let widths: [Float] = [0.30, 0.26, 0.21, 0.17, 0.12, 0.08]
            for i in 0..<6 {
                let w = widths[i] * rng.float(0.88...1.12), d = w * rng.float(0.7...0.95), t = rng.float(0.05...0.085) * (i == 5 ? 0.8 : 1)
                off += V2(rng.float(-0.025...0.025), rng.float(-0.025...0.025))
                let cy = top + t * 0.5 * 0.75 - 0.004
                put(DetailKit19.stone(V3(w, t, d), at: V3(off.x, cy, off.y), yaw: rng.float(0...6.28),
                                      tilt: V3(rng.float(-0.07...0.07), 0, rng.float(-0.07...0.07)), n: n, material: mats[i], rng: &rng))
                top = cy + t * 0.5 * 0.75 - 0.004
            }
            for k in 0..<gravelN {
                let a = rng.float(0...6.28), r = rng.float(0.15...0.26)
                let s = rng.float(0.012...0.03)
                put(DetailKit19.stone(V3(s * 1.4, s * 0.8, s), at: V3(cos(a) * r, s * 0.3, sin(a) * r), yaw: rng.float(0...6.28), tilt: .zero,
                                      n: 2, lump: 0.15, material: k % 3 == 0 ? "rock.slate" : "ground.gravel", rng: &rng))
            }
            for k in parts.keys.sorted(by: { $0 < $1 }) { var s = parts[k]!; s.computeTangents(); m.add(s) }
            groundAO(&m, height: 0.2)
            return m
        }
        return LODModel(levels: [make(n: 6, gravelN: 9), make(n: 3, gravelN: 5)], switchDistances: [6])
    }
}
