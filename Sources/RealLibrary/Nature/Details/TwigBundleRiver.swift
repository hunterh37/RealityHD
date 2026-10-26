import simd
import Foundation

/// Flood-stacked twig bundle, 40 cm long: 40 grey twigs and a few thicker sticks lodged together, with silt and leaf bits caught between them.
public struct TwigBundleRiver: RealAsset {
    public static let id = "twig-bundle-river"
    public static let summary = "Flood-stacked bundle of 40 grey twigs lodged together, 40 cm long, with forks, silt smears and caught leaf bits."
    public static let tags = ["nature", "wood", "river"]
    public static let budget = 3_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            let hi = lod == 0
            var parts: [Surface] = []
            var leaves = Model(name: "leaves")
            let n = hi ? 40 : 22
            let flow = rng.float(-0.2...0.2)
            for i in 0..<n {
                let thick = i < 3
                let r = thick ? rng.float(0.007...0.011) : rng.float(0.0018...0.005)
                let len = thick ? rng.float(0.30...0.42) : rng.float(0.16...0.40)
                let cz = rng.float(-0.045...0.045), layer = max(0, 1 - abs(cz) / 0.06)
                let cy = r + layer * rng.float(0...0.045)
                let yaw = flow + rng.float(-0.4...0.4)
                let dir = simd_normalize(V3(cos(yaw), rng.float(-0.12...0.14), sin(yaw)))
                let c = V3(rng.float(-0.05...0.05), cy, cz)
                let a = c - dir * len / 2, b = c + dir * len / 2
                let g = Int(rng.float(80...120))
                let mat = MaterialKey(String(format: "bark.dead:%02X%02X%02X", g, g - 8, g - 20))
                parts.append(DetailKit22.limb(&rng, from: V3(a.x, max(a.y, 0.002 + r), a.z), to: V3(b.x, max(b.y, 0.002 + r), b.z), r0: r, r1: r * rng.float(0.35...0.7),
                                              segs: hi ? 4 : 2, sides: hi ? 5 : 3, bend: 0.03, seam: 0.4, material: mat))
                if hi && rng.chance(0.3) {
                    let q = a + (b - a) * rng.float(0.3...0.6)
                    let e = q + simd_normalize(dir + V3(rng.float(-0.6...0.6), rng.float(0...0.4), rng.float(-0.6...0.6))) * len * 0.3
                    parts.append(DetailKit22.limb(&rng, from: q, to: V3(e.x, max(e.y, 0.004), e.z), r0: r * 0.6, r1: 0.0012, segs: 3, sides: 4, bend: 0.1, seam: 0.4, material: mat))
                }
            }
            for _ in 0..<(hi ? 14 : 5) {
                let p = V3(rng.float(-0.17...0.17), 0, rng.float(-0.05...0.05))
                let g = Int(rng.float(105...140))
                parts.append(DetailKit22.chunk(V3(p.x, rng.float(0.003...0.02), p.z), u: V3(rng.float(-1...1), 0, rng.float(-1...1)), n: simd_normalize(V3(rng.float(-0.3...0.3), 1, rng.float(-0.3...0.3))),
                                               len: rng.float(0.02...0.05), wid: rng.float(0.015...0.035), th: 0.004, material: MaterialKey(String(format: "ground.mud:%02X%02X%02X", g, g - 12, g - 28))))
            }
            for _ in 0..<(hi ? 7 : 0) {
                var bl = PlantKit.Blade()
                bl.length = rng.float(0.03...0.06); bl.width = bl.length; bl.yaw = rng.float(0...6.28)
                bl.root = V3(rng.float(-0.12...0.12), rng.float(0.006...0.03), rng.float(-0.04...0.04))
                bl.constantWidth = true; bl.tipWidth = 1; bl.lean = rng.float(1.2...1.56); bl.curl = 0.05; bl.segments = 1
                let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
                bl.u = V2(c.origin.x, c.origin.x + c.size.x); bl.v = V2(c.origin.y, c.origin.y + c.size.y)
                bl.weight = V2(0, 0); bl.ao = V2(0.75, 0.9); bl.upNormal = 0.2
                leaves.add(PlantKit.blade(bl, material: "litter.dry"))
            }
            var out = DetailKit22.model(Self.id, parts)
            PlantKit.finish(&leaves)
            out.add(leaves)
            return out
        }
    }
}
