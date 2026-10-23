import simd
import Foundation

/// Turkey-tail bracket fungi on a 30 cm weathered log section: 16 overlapping scalloped shelves in banded
/// browns, tans and greys with cream pore undersides, stacked in tiers. LOD1: fewer bands and columns.
public struct BracketFungus: RealAsset {
    public static let id = "bracket-fungus"
    public static let summary = "Stacked turkey-tail shelf fungi on a 30 cm weathered log section, banded brown and tan caps, cream pores; 2 LODs."
    public static let tags = ["nature", "fungus", "wood"]
    public static let budget = 4_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.7)

    public init() {}
    static let bands: [MaterialKey] = ["fungus.cap:3b2a22", "fungus.cap:8a6a4a", "fungus.cap:a89a82", "fungus.cap:5e5046",
                                       "fungus.cap:b4743c", "fungus.cap:e6dcc4"]

    public func build(seed: UInt64) -> LODModel {
        DetailKit04.lods { lod in
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let L: Float = 0.30, r: Float = 0.062, cy = r * 0.92
            let nx = lod == 0 ? 22 : 9, ns = lod == 0 ? 18 : 10
            let ns32 = UInt32(truncatingIfNeeded: seed)
            func radius(_ x: Float, _ a: Float) -> Float {
                let ridge = 0.035 * sin(7 * a + 3 * x * 10) + 0.025 * sin(13 * a - 2) + 0.05 * Noise.perlin(V3(x * 14, cos(a) * 2, sin(a) * 2), seed: ns32)
                return r * (1 + ridge) * (1 + 0.04 * x / L)
            }
            var rows: [[V3]] = [], uvs: [[V2]] = []
            for j in 0...nx {
                let x = -L / 2 + L * Float(j) / Float(nx)
                var row: [V3] = [], uv: [V2] = []
                for k in 0...ns {
                    let a = Float(k % ns) / Float(ns) * 2 * .pi
                    let R = radius(x, a)
                    row.append(V3(x, cy + R * cos(a), R * sin(a))); uv.append(V2(x, Float(k) / Float(ns) * 2 * .pi * r))
                }
                rows.append(row); uvs.append(uv)
            }
            var side = WoodParts.grid(rows, uvs: uvs, material: "wood.deadwood")
            DetailKit04.orient(&side, center: { V3($0.x, cy, 0) })
            m.add(side)
            for (j, nrm) in [(0, V3(-1, 0, 0)), (nx, V3(1, 0, 0))] {
                m.add(WoodParts.cap(Array(rows[j].dropLast()), normal: nrm, pith: V3(rows[j][0].x, cy, 0), e1: .up, e2: V3(0, 0, 1),
                                    radius: r, spin: rng.float(0...6), material: "wood.endgrain"))
            }
            // Clusters of tiered shelves: (x, side, elevation, tiers)
            let clusters: [(Float, Float, Float, Int)] = [(-0.09, 1, 0.55, 4), (0.05, 1, 0.3, 4), (0.11, -1, 0.5, 3), (-0.07, -1, 0.25, 3), (0.0, 1, 0.95, 2)]
            for (ci, c) in clusters.enumerated() {
                var cr = rng.fork(ci)
                for t in 0..<c.3 {
                    let el = c.2 - 0.2 * Float(t) + cr.float(-0.05...0.05)
                    let x = c.0 + cr.float(-0.02...0.02)
                    let R = radius(x, c.1 > 0 ? .pi / 2 - el : -.pi / 2 + el)
                    let P = V3(x, cy + R * sin(el), c.1 * R * cos(el))
                    let depth = 0.032 + 0.012 * Float(t) + cr.float(-0.006...0.008)
                    Self.shelf(&m, P: P, side: c.1, depth: depth, halfW: depth * cr.float(0.9...1.3), rng: &cr, lod: lod, offset: ci + t)
                }
            }
            groundAO(&m, height: 0.06, floor: 0.7)
            return m
        }
    }

    static func shelf(_ m: inout Model, P: V3, side: Float, depth: Float, halfW: Float, rng: inout SeededRNG, lod: Int, offset: Int) {
        let nb = lod == 0 ? 5 : 3, nc = lod == 0 ? 8 : 5
        let D = V3(0, 0.08, side).normalized
        let edge = (0...nc).map { k -> Float in let u = Float(k) / Float(nc) * 2 - 1; return depth * (1 - 0.32 * u * u) * rng.float(0.88...1.1) }
        let droop = depth * rng.float(0.15...0.4)
        func pt(_ s: Float, _ k: Int, top: Bool) -> V3 {
            let u = Float(k) / Float(nc) * 2 - 1
            let W = halfW * (0.25 + 0.75 * pow(s, 0.6))
            let th: Float = 0.0045 * pow(1 - s, 0.6) + 0.0006
            var p = P + V3(u * W, 0, 0) + D * (edge[k] * s - 0.008) - V3(0, droop * s * s, 0)
            p.y += top ? th : 0
            return p
        }
        var bottomRows: [[V3]] = [], buv: [[V2]] = []
        for i in 0...nb {
            let s = Float(i) / Float(nb)
            bottomRows.append((0...nc).map { pt(s, $0, top: false) }); buv.append((0...nc).map { V2(Float($0) * 0.01, s * depth) })
        }
        var pore = WoodParts.grid(bottomRows, uvs: buv, material: "fungus.gills:eadfc4")
        DetailKit04.orient(&pore, toward: V3(0, -1, 0)); m.add(pore)
        for b in 0..<nb {
            let rowsT = [b, b + 1].map { i -> [V3] in (0...nc).map { pt(Float(i) / Float(nb), $0, top: true) } }
            let uv = [b, b + 1].map { i in (0...nc).map { V2(Float($0) * 0.01 + Float(offset), Float(i) * 0.01) } }
            var s = WoodParts.grid(rowsT, uvs: uv, material: bands[(b + offset) % bands.count])
            DetailKit04.orient(&s, toward: .up); m.add(s)
        }
    }
}
