import simd
import Foundation

/// 35 cm patch of sphagnum moss: pale green hummocks with red-tinged heads and fine capitulum tips. 2 LODs.
public struct SphagnumPatch: RealAsset {
    public static let id = "sphagnum-patch"
    public static let summary = "Sphagnum moss patch, 35 cm: pale green hummocks with red-tinted heads and fine shoot tips; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 5_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.7)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit24.lods(SeededRNG(seed: seed), dist: 3) { lod, rng in
            var m = Model(name: Self.id)
            m.add(DetailKit24.blob(V3(0, 0, 0), V3(0.15, 0.003, 0.14), sub: 2, material: "moss.cushion:A5BC68"))
            let tints = ["B9C77A", "A5BC68", "C9D08A", "D8B070", "B8584A", "9DB45E"]
            for i in 0..<(lod == 0 ? 60 : 24) {
                let p = rng.inDisc(radius: 0.15)
                let r = rng.float(0.018...0.034)
                let red = rng.float(0...1) < 0.25
                let tint = red ? tints[rng.int(3...4)] : tints[rng.int(0...2)]
                let ry = rng.float(0.008...0.016)
                m.add(DetailKit24.blob(V3(p.x, ry - 0.003, p.y), V3(r, ry, r * rng.float(0.8...1.2)),
                                       sub: lod == 0 ? 2 : 1, material: MaterialKey("moss.cushion:\(tint)")))
                _ = i
            }
            for _ in 0..<(lod == 0 ? 450 : 120) {
                let p = rng.inDisc(radius: 0.15)
                let h = 0.012 * (1 - length(p) / 0.2)
                let red = rng.float(0...1) < 0.2
                let tint = red ? "B0584A" : tints[rng.int(0...5)]
                let blade = DetailKit24.card(V3(p.x, 0.008 + max(0, h), p.y), yaw: rng.float(0...6.28), len: rng.float(0.02...0.035),
                                       wid: 0.006, lean: rng.float(0.2...1.1), curl: rng.float(0.2...0.7), belly: 0, fold: 0,
                                       weight: 0.4, segs: 1, material: MaterialKey("moss.cushion:\(tint)"), metric: true)
                m.add(blade)
            }
            return m
        }
    }
}
