import simd
import Foundation

/// Raccoon front and hind hand prints in soft mud, 48 cm patch: palm pads, five fingers and claw dots.
public struct RaccoonTrack: RealAsset {
    public static let id = "raccoon-track"
    public static let summary = "Raccoon trail in soft mud: two front and two hind hand prints with five long fingers, palm pads and claw dots."
    public static let tags = ["nature", "ground", "river"]
    public static let budget = 16_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 0.8, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let a0 = rng.float(0...6.28), d0 = V2(cos(a0), sin(a0)), side = V2(-d0.y, d0.x)
        struct Paw { var c: V2; var dir: V2; var hind: Bool; var size: Float; var dep: Float }
        var paws: [Paw] = []
        for i in 0..<2 {
            let sgn: Float = (i % 2 == 0 ? 1 : -1)
            let base = d0 * (Float(i) * 0.15 - 0.07)
            // front paw and the hind paw that lands just ahead and across the body line
            paws.append(Paw(c: base + side * sgn * 0.034 + V2(rng.float(-0.006...0.006), rng.float(-0.006...0.006)), dir: DetailKit16.rot(d0, rng.float(-0.25...0.1) * sgn), hind: false, size: rng.float(0.92...1.08), dep: rng.float(0.8...1.1)))
            paws.append(Paw(c: base + d0 * 0.065 - side * sgn * 0.03 + V2(rng.float(-0.006...0.006), rng.float(-0.006...0.006)), dir: DetailKit16.rot(d0, rng.float(-0.2...0.2)), hind: true, size: rng.float(0.95...1.1), dep: rng.float(0.85...1.15)))
        }
        let toeSpread: [Float] = (0..<5).map { _ in rng.float(0.88...1.12) }
        let press: (V2) -> (Float, Float) = { q in
            var dep: Float = 0, berm: Float = 0
            func add(_ r: (Float, Float), _ k: Float) { dep = max(dep, r.0 * k); berm = max(berm, r.1 * k) }
            for p in paws {
                let s = p.size
                if p.hind {
                    add(DetailKit16.stamp(q, c: p.c - p.dir * 0.012 * s, dir: p.dir, len: 0.028 * s, wid: 0.0125 * s, berm: 1.5), p.dep * 0.85)
                } else {
                    add(DetailKit16.stamp(q, c: p.c, dir: p.dir, len: 0.0125 * s, wid: 0.0175 * s, berm: 1.5), p.dep)
                }
                for k in 0..<5 {
                    let spread: Float = p.hind ? 0.26 : 0.3
                    let a = (Float(k) - 2) * spread
                    let d = DetailKit16.rot(p.dir, a)
                    let mid = 1 - abs(Float(k) - 2) * 0.12
                    let base: Float = p.hind ? 0.04 : 0.03
                    let tc = p.c + d * (base * s * mid * toeSpread[k]) + (p.hind ? p.dir * 0.008 * s : .zero)
                    add(DetailKit16.stamp(q, c: tc, dir: d, len: 0.0125 * s * mid, wid: 0.0072 * s, berm: 1.7), p.dep * 0.95)
                    add(DetailKit16.stamp(q, c: tc + d * 0.0145 * s, dir: d, len: 0.0035, wid: 0.0022, berm: 1.5), p.dep * 1.1)
                }
            }
            return (dep, berm)
        }
        m.add(DetailKit16.mudDisc(seed: seed, radius: 0.22, rings: lod == 0 ? 60 : 22, sectors: lod == 0 ? 110 : 40, depth: 0.0085, press: press))
        groundAO(&m)
        return m
    }
}
