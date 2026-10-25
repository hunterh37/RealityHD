import simd
import Foundation

/// White-tailed deer hoof prints in river mud, 60 cm patch: three cloven prints 7 cm long on a walking line.
public struct DeerTrack: RealAsset {
    public static let id = "deer-track"
    public static let summary = "White-tailed deer trail in wet mud: three cloven hoof prints 7 cm long with raised rims and dewclaw marks."
    public static let tags = ["nature", "ground", "river"]
    public static let budget = 16_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 1.0, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let a0 = rng.float(0...6.28), d0 = V2(cos(a0), sin(a0)), side = V2(-d0.y, d0.x)
        struct Hoof { var c: V2; var dir: V2; var size: Float; var dep: Float; var dew: Bool }
        var hooves: [Hoof] = []
        for i in 0..<3 {
            let lat: Float = (i % 2 == 0 ? 1 : -1) * rng.float(0.018...0.032)
            let c = d0 * (Float(i - 1) * rng.float(0.17...0.21)) + side * lat + V2(rng.float(-0.01...0.01), rng.float(-0.01...0.01))
            let ang = rng.float(-0.14...0.14) + (i % 2 == 0 ? 0.05 : -0.05)
            hooves.append(Hoof(c: c, dir: DetailKit16.rot(d0, ang), size: rng.float(0.9...1.08), dep: rng.float(0.75...1.15), dew: i == 1))
        }
        let sp = rng.float(0.2...0.5)
        let press: (V2) -> (Float, Float) = { q in
            var dep: Float = 0, berm: Float = 0
            for h in hooves {
                let hp = V2(-h.dir.y, h.dir.x)
                for s: Float in [-1, 1] {
                    let d = DetailKit16.rot(h.dir, s * 0.07 * (1 + sp))
                    let c = h.c + hp * s * 0.0125 * h.size
                    // wide rear lobe and narrow pointed tip
                    let (w1, b1) = DetailKit16.stamp(q, c: c, dir: d, len: 0.027 * h.size, wid: 0.0135 * h.size, berm: 1.5)
                    let (w2, b2) = DetailKit16.stamp(q, c: c + d * 0.027 * h.size, dir: d, len: 0.018 * h.size, wid: 0.0075 * h.size, berm: 1.6)
                    let w = max(w1, w2) * h.dep
                    dep = max(dep, w); berm = max(berm, max(b1, b2) * h.dep)
                }
                if h.dew {
                    for s: Float in [-1, 1] {
                        let (w, b) = DetailKit16.stamp(q, c: h.c - h.dir * 0.058 + hp * s * 0.028, dir: h.dir, len: 0.007, wid: 0.0045)
                        dep = max(dep, w * 0.5); berm = max(berm, b * 0.4)
                    }
                }
            }
            return (dep, berm)
        }
        m.add(DetailKit16.mudDisc(seed: seed, radius: 0.28, rings: lod == 0 ? 62 : 22, sectors: lod == 0 ? 112 : 40, depth: 0.011, press: press))
        groundAO(&m)
        return m
    }
}
