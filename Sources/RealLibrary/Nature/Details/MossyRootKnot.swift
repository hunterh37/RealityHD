import simd
import Foundation

/// Gnarled exposed root knot, ~50 cm: three twisting roots fused at a burl, thick moss on top and dry
/// leaves caught in the crooks.
public struct MossyRootKnot: RealAsset {
    public static let id = "mossy-root-knot"
    public static let summary = "Gnarled exposed root knot, 50 cm: three twisting roots around a burl with moss and leaf debris."
    public static let tags = ["nature", "wood", "plant", "ground"]
    public static let budget = 2_700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.8, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var out: [Surface] = []
        out.append(DetailKit09.soil(size: 0.6, seg: 18, material: "ground.forest", seed: seed, base: 0.012, bump: 0.01))
        let knot = V3(0, 0.05, 0)
        let burl = DetailKit09.blob(V3(0.065, 0.055, 0.06), sub: 5, material: "bark.oak", rng: &rng, jitter: 0.2)
        out.append(DetailKit09.shift(burl, knot, yaw: rng.float(0...6.28)))
        var moss: [Surface] = []
        let a0 = rng.float(0...6.28)
        for i in 0..<3 {
            let a = a0 + Float(i) * 2.1 + rng.float(-0.4...0.4)
            let L = rng.float(0.2...0.27), r0 = rng.float(0.035...0.05)
            let ph = rng.float(0...6.28), arch = rng.float(0.03...0.08)
            var path: [V3] = []
            for k in 0..<8 {
                let t = Float(k) / 7
                let rr = r0 * (1 - 0.75 * t)
                let ang = a + 0.5 * sin(t * 5 + ph) * t
                let d = 0.03 + L * t
                let y = rr * 0.45 + arch * sin(min(t * 1.6, 1) * 3.14) * (1 - t) - 0.008 * t * t + 0.03 * (1 - t)
                path.append(V3(cos(ang) * d, y, sin(ang) * d))
                if k > 0, k < 6, rng.chance(0.35) {
                    let b = DetailKit09.blob(V3(rr * 1.1, rr * 0.3, rr * 0.9) * rng.float(0.7...1.1), sub: 3,
                                             material: "moss.cushion", rng: &rng, jitter: 0.25)
                    moss.append(DetailKit09.shift(b, path[k] + V3(0, rr * 0.75, 0), yaw: rng.float(0...6.28)))
                }
            }
            out.append(DetailKit09.root(path, r0: r0, r1: r0 * 0.2, sides: 8, material: "bark.oak", rng: &rng))
        }
        for _ in 0..<2 {
            let b = DetailKit09.blob(V3(0.035, 0.015, 0.03), sub: 3, material: "moss.cushion", rng: &rng, jitter: 0.25)
            moss.append(DetailKit09.shift(b, knot + V3(rng.float(-0.03...0.03), 0.04, rng.float(-0.03...0.03)), yaw: rng.float(0...6.28)))
        }
        // Leaf debris
        var lm = Model(name: "leaves")
        for i in 0..<12 {
            let p = rng.inDisc(radius: 0.24)
            let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            var b = PlantKit.Blade()
            b.length = rng.float(0.04...0.08); b.width = b.length
            b.yaw = rng.float(0...6.28)
            let d = V3(cos(b.yaw), 0, sin(b.yaw))
            b.root = V3(p.x, 0.02 + Float(i) * 0.0008, p.y) - d * b.length / 2
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.35...1.55); b.curl = rng.float(-0.05...0.08); b.segments = 1
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
            b.weight = V2(0, 0); b.ao = V2(0.75, 0.9); b.upNormal = 0.2
            lm.add(PlantKit.blade(b, material: "litter.dry"))
        }
        PlantKit.finish(&lm)
        var m = DetailKit09.finish(Self.id, out + moss)
        m.add(lm)
        return LODModel(levels: [m], switchDistances: [])
    }
}
