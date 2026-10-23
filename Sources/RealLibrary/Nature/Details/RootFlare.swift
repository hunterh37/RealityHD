import simd
import Foundation

/// Tree root flare, ~1 m across: a trunk base with 4 or 5 tapered roots that dive into forest soil, bark
/// texture and moss patches on the upper sides. 2 LODs.
public struct RootFlare: RealAsset {
    public static let id = "root-flare"
    public static let summary = "Tree root flare, 1 m: trunk base with four or five tapered roots diving into soil, bark and moss patches; 2 LODs."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 5_300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 1.0, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit09.lods(seed: seed, name: Self.id) { lod, rng in
            var out: [Surface] = []
            let sides = lod == 0 ? 14 : 7
            let bark: MaterialKey = "bark.oak"
            out.append(DetailKit09.soil(size: 1.3, seg: lod == 0 ? 26 : 12, material: "ground.forest", seed: seed, base: 0.016))
            // Trunk
            let lean = V2(rng.float(-0.02...0.02), rng.float(-0.02...0.02))
            let tp = (0..<8).map { i -> V3 in let t = Float(i) / 7; return V3(lean.x * t, -0.004 + 0.6 * t, lean.y * t) }
            let tr = (0..<8).map { i -> Float in let t = Float(i) / 7; return 0.155 + 0.07 * pow(1 - t, 2.5) }
            out.append(Prim.tube(tp, radii: tr, sides: sides + 2, seamTile: 0.2, material: bark))
            var moss: [Surface] = []
            let n = rng.int(4...5)
            let a0 = rng.float(0...6.28)
            for i in 0..<n {
                let a = a0 + Float(i) / Float(n) * 6.2832 + rng.float(-0.35...0.35)
                let L = rng.float(0.30...0.42), r0 = rng.float(0.09...0.125)
                let ph = rng.float(0...6.28)
                var path: [V3] = []
                let steps = 9
                for k in 0..<steps {
                    let t = Float(k) / Float(steps - 1)
                    let rr = r0 * (1 - 0.7 * pow(t, 1.3))
                    let ang = a + 0.25 * sin(t * 4 + ph) * t
                    let d = 0.10 + L * t
                    let y = 0.22 * pow(1 - t, 3) + 0.4 * rr - 0.03 * pow(t, 4)
                    path.append(V3(cos(ang) * d, max(y, -0.003), sin(ang) * d))
                    if lod == 0, k > 1, k < steps - 2, rng.chance(0.5) {
                        let b = DetailKit09.blob(V3(rr * 1.3, rr * 0.4, rr * 1.2) * rng.float(0.8...1.2), sub: 3,
                                                 material: "moss.cushion", rng: &rng, jitter: 0.25)
                        moss.append(DetailKit09.shift(b, path[k] + V3(rng.float(-0.01...0.01), rr * 0.8, rng.float(-0.01...0.01)), yaw: rng.float(0...6.28)))
                    }
                }
                out.append(DetailKit09.root(path, r0: r0, r1: r0 * 0.2, sides: sides, material: bark, rng: &rng))
            }
            if lod == 0 {
                for _ in 0..<3 {
                    let a = rng.float(0...6.28), y = rng.float(0.08...0.3)
                    let b = DetailKit09.blob(V3(0.05, 0.035, 0.04), sub: 3, material: "moss.cushion", rng: &rng, jitter: 0.25)
                    out.append(DetailKit09.shift(b, V3(cos(a) * 0.2, y, sin(a) * 0.2), yaw: -a))
                }
            }
            return out + moss
        }
    }
}
