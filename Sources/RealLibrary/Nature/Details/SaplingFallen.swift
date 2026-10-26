import simd
import Foundation

/// Dead sapling lying on the forest floor, 2 m long and 3 cm thick at the base, with forked twigs, a splayed root stub and dry leaf remnants.
public struct SaplingFallen: RealAsset {
    public static let id = "sapling-fallen"
    public static let summary = "Dead 2 m sapling lying on the ground, forked grey twigs, a splayed root stub and a few clinging dry leaves."
    public static let tags = ["nature", "wood", "plant"]
    public static let budget = 4_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 2.4)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 8) { lod, rng in
            let hi = lod == 0
            var parts: [Surface] = []
            var leaves = Model(name: "leaves")
            let wood = "wood.weathered:8C8378"
            let L: Float = 2.0, r0: Float = 0.016
            var trunk: [V3] = []
            let n = 10
            var z: Float = 0, zv: Float = 0
            for i in 0...n {
                let t = Float(i) / Float(n)
                zv += rng.float(-0.02...0.02); z += zv
                trunk.append(V3(-1 + t * L, r0 * (1 - 0.8 * t) + 0.006 + 0.012 * sin(t * 5 + 1) * (1 - t), z))
            }
            func at(_ t: Float) -> (V3, Float) {
                let f = t * Float(n), k = min(n - 1, Int(f)), u = f - Float(k)
                return (trunk[k] + (trunk[k + 1] - trunk[k]) * u, r0 * (1 - 0.8 * t))
            }
            let radii = (0...n).map { max(0.0025, r0 * (1 - 0.85 * Float($0) / Float(n))) * rng.float(0.95...1.05) }
            parts.append(Prim.tube(trunk, radii: radii, sides: hi ? 7 : 4, seamTile: 0.2, material: "bark.dead:807868", capEnd: true))
            // splayed root stub
            for _ in 0..<3 {
                let a = rng.float(-0.9...0.9), dn = V3(-0.7, 0, 0) + V3(0, 0.1, sin(a))
                let p0 = trunk[0] + V3(0.02, 0, 0)
                parts.append(DetailKit22.limb(&rng, from: p0, to: V3(p0.x - 0.12, 0.012, p0.z + sin(a) * 0.12) + dn * 0.03, r0: 0.011, r1: 0.003, segs: hi ? 3 : 1, sides: hi ? 5 : 3, bend: 0.1, material: "wood.deadwood:5E5246"))
            }
            // side branches with forks and leaf remnants
            var tw: [(V3, V3)] = []
            let nb = hi ? 9 : 6
            for i in 0..<nb {
                let t = 0.12 + 0.8 * (Float(i) + rng.float(0...0.7)) / Float(nb)
                let (p, r) = at(t)
                let s: Float = rng.chance(0.5) ? 1 : -1
                let len = rng.float(0.22...0.5) * (1.1 - t * 0.6)
                let dir = simd_normalize(V3(rng.float(0.3...0.9), rng.float(0.1...0.55), s * rng.float(0.6...1)))
                let e = V3(p.x + dir.x * len, max(0.01, p.y + dir.y * len * 0.6), p.z + dir.z * len)
                parts.append(DetailKit22.limb(&rng, from: p, to: e, r0: r * 0.55, r1: 0.0022, segs: hi ? 4 : 2, sides: hi ? 5 : 3, bend: 0.07, material: wood))
                tw.append((p + (e - p) * 0.55, e))
                for _ in 0..<(hi ? 2 : 1) {
                    let q = p + (e - p) * rng.float(0.35...0.7)
                    let d2 = simd_normalize(V3(rng.float(0.2...1), rng.float(0...0.5), s * rng.float(0.2...1.2) + rng.float(-0.8...0.8)))
                    let e2 = V3(q.x + d2.x * len * 0.45, max(0.008, q.y + d2.y * len * 0.3), q.z + d2.z * len * 0.45)
                    parts.append(DetailKit22.limb(&rng, from: q, to: e2, r0: r * 0.28 + 0.0012, r1: 0.0015, segs: hi ? 3 : 1, sides: hi ? 4 : 3, bend: 0.1, material: wood))
                    tw.append((q, e2))
                }
            }
            for (a, b) in tw where rng.chance(hi ? 0.8 : 0.5) {
                var bl = PlantKit.Blade()
                bl.length = rng.float(0.04...0.08); bl.width = bl.length * 0.6; bl.belly = 1.4
                bl.yaw = rng.float(0...6.28)
                bl.root = a + (b - a) * rng.float(0.2...1) + V3(0, 0.001, 0)
                bl.lean = rng.float(1.1...1.55); bl.curl = rng.float(-0.1...0.25); bl.segments = hi ? 2 : 1
                let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
                bl.u = V2(c.origin.x, c.origin.x + c.size.x); bl.v = V2(c.origin.y, c.origin.y + c.size.y)
                bl.weight = V2(0, 0.5); bl.ao = V2(0.75, 0.9); bl.upNormal = 0.2
                leaves.add(PlantKit.blade(bl, material: "litter.dry"))
            }
            var out = DetailKit22.model(Self.id, parts)
            PlantKit.finish(&leaves)
            out.add(leaves)
            return out
        }
    }
}
