import simd
import Foundation

/// Split kindling, 10 sticks about 30 cm long and 2 to 3 cm wide, stacked in three crossing layers with pale riven faces and bark slivers.
public struct SplitKindling: RealAsset {
    public static let id = "split-kindling"
    public static let summary = "Split kindling, 10 sticks 30 cm long stacked in crossing layers, pale fresh faces with bark slivers and ragged ends."
    public static let tags = ["nature", "wood"]
    public static let budget = 2_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.6)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            let hi = lod == 0
            var parts: [Surface] = []
            let base = rng.float(-0.4...0.4)
            let layers: [(Int, Float, Float)] = [(5, 0, 0.0), (3, 1.5708, 0.03), (2, 0.2, 0.058)]
            for (n, yaw0, y0) in layers {
                for i in 0..<n {
                    let r = rng.float(0.010...0.016), len = rng.float(0.26...0.36)
                    let yaw = base + yaw0 + rng.float(-0.18...0.18)
                    let off = (Float(i) - Float(n - 1) / 2) * 0.03 + rng.float(-0.006...0.006)
                    let dir = V3(cos(yaw), rng.float(-0.03...0.05), sin(yaw))
                    let side = V3(-sin(yaw), 0, cos(yaw))
                    let c = side * off + V3(rng.float(-0.02...0.02), y0 + r + 0.004, rng.float(-0.02...0.02))
                    let a = c - dir * len / 2, b = c + dir * len / 2
                    let tint = String(format: "%02X%02X%02X", Int(rng.float(214...236)), Int(rng.float(186...206)), Int(rng.float(140...166)))
                    var st = DetailKit22.limb(&rng, from: a, to: b, r0: r, r1: r * rng.float(0.6...0.95), segs: hi ? 6 : 2, sides: hi ? 5 : 4,
                                              bend: 0.012, seam: 0.05, material: MaterialKey("wood.pine:" + tint))
                    st = st.transformed(Xform(translation: .zero))
                    parts.append(st)
                    // bark sliver along one edge
                    let o = simd_normalize(V3(rng.float(-1...1), 1, rng.float(-1...1))) * r * 0.85
                    parts.append(DetailKit22.limb(&rng, from: a + o + dir * len * 0.05, to: b + o - dir * len * rng.float(0.05...0.2), r0: r * 0.42, r1: r * 0.38,
                                                  segs: hi ? 4 : 1, sides: 3, bend: 0.01, seam: 0.05, material: "bark.pine:6B5640"))
                }
            }
            return DetailKit22.model(Self.id, parts)
        }
    }
}
