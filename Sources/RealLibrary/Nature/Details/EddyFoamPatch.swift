import simd
import Foundation

/// Slack eddy 50 cm across: dark water between muddy banks, a cream foam raft of many bubbles with a few leaf bits caught in it. 2 LODs.
public struct EddyFoamPatch: RealAsset {
    public static let id = "eddy-foam-patch"
    public static let summary = "Slack eddy 50 cm across with a cream raft of foam and bubbles, leaf bits and a twig on dark water; 2 LODs."
    public static let tags = ["nature", "water", "river"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 0.8)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50)
        m.add(GroundMesh.disc(material: "ground.river-silt", rings: 6, sectors: 36,
            outline: { 0.3 * (1 + 0.08 * sin($0 * 2 + ph)) },
            height: { p, t in 0.0035 * (1 - t) + 0.004 * smoothstep(0.7, 1, t) + DetailKit26.wobble(p.x, p.y, ph, 0.0005) }))
        var w = GroundMesh.disc(material: "water.pond", rings: 6, sectors: 36,
            outline: { 0.235 * (1 + 0.1 * sin($0 * 3 + ph)) }, height: { _, _ in 0.0045 })
        w.paintSplat { _ in 0 }
        m.add(w)
        // Foam raft: sheets of flat blobs plus bubbles, concentrated off-center.
        let fm: [MaterialKey] = ["water.fountain-foam:EFE6D2", "water.fountain-foam:E2D6BC", "water.fountain-foam:F6F1E4"]
        let c = V2(rng.float(-0.04...0.04), rng.float(-0.04...0.04))
        for _ in 0..<(lod == 0 ? 9 : 5) {
            let p = c + rng.inDisc(radius: 0.1)
            let r = rng.float(0.03...0.07)
            m.add(DetailKit10.blob(V3(p.x, 0.0055, p.y), V3(r, 0.003, r * rng.float(0.6...1)), rot: DetailKit06.yaw(rng.float(0...6)), sub: 2, material: fm[rng.int(0...2)]))
        }
        for k in 0..<(lod == 0 ? 6 : 3) {
            let off = c + rng.inDisc(radius: 0.11)
            for s in DetailKit26.bubbles(center: off, radius: rng.float(0.03...0.06), count: lod == 0 ? 22 : 10, y: 0.0055, rng: &rng, material: fm[k % 3]) { m.add(s) }
        }
        // Sparse bubbles away from the raft.
        for s in DetailKit26.bubbles(center: V2(0, 0), radius: 0.2, count: lod == 0 ? 25 : 10, y: 0.0045, rng: &rng, material: fm[2]) { m.add(s) }
        // Leaf bits and a twig.
        for _ in 0..<5 {
            let p = c + rng.inDisc(radius: 0.12)
            let r = rng.float(0.012...0.025)
            m.add(DetailKit10.blob(V3(p.x, 0.0055, p.y), V3(r, 0.0015, r * 0.55), rot: DetailKit06.yaw(rng.float(0...6)), sub: 1, material: rng.chance(0.5) ? "litter.dry" : "leaf.oak-dry"))
        }
        let a = rng.float(0...6.28)
        let t0 = V3(c.x - cos(a) * 0.07, 0.0058, c.y - sin(a) * 0.07), t1 = V3(c.x + cos(a) * 0.08, 0.0062, c.y + sin(a) * 0.08)
        let tw = Prim.tube([t0, (t0 + t1) / 2 + V3(0, 0.001, 0.006), t1], radii: [0.0035, 0.003, 0.0015], sides: 5, seamTile: 0.02, material: "wood.weathered")
        m.add(tw)
        groundAO(&m)
        return m
    }
}
