import simd
import Foundation

/// Split firewood wedge, 30 cm tall and about 22 cm across: bark rim, endgrain top and rough riven faces.
public struct SplitFirewoodRound: RealAsset {
    public static let id = "split-firewood-round"
    public static let summary = "Split firewood wedge, 30 cm tall and 22 cm across, with bark rim, endgrain top and rough riven faces."
    public static let tags = ["nature", "wood"]
    public static let budget = 450
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.8)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var bark = Surface(material: "bark.oak:8A7862"), wood = Surface(material: "wood.oak:C4A06E"), end = Surface(material: "wood.endgrain:C9A672")
        let R = rng.float(0.095...0.12), H = rng.float(0.27...0.32), span = rng.float(2.0...3.1), a0 = rng.float(0...(2 * .pi))
        let rad = DetailKit11.Harmonics(&rng, count: 3, lowest: 2)
        // ring of (position, top height, bulge, kind) points, CCW seen from above
        struct P { var p: V2; var h: Float; var bulge: Float; var bark: Bool }
        var ring: [P] = []
        let apex = V2(0, 0)
        func splitFace(_ a: V2, _ b: V2, n: Int) {
            for i in 0..<n {
                let t = Float(i) / Float(n)
                ring.append(P(p: a + (b - a) * t, h: H * rng.float(0.985...1.015) - 0.008 * sin(t * 3.14), bulge: i == 0 ? 0 : rng.float(-0.005...0.007), bark: false))
            }
        }
        var arc: [V2] = []
        let N = 16
        for i in 0...N {
            let a = a0 + span * Float(i) / Float(N)
            let r = R * (1 + 0.05 * rad(a))
            arc.append(V2(cos(a), sin(a)) * r)
        }
        splitFace(apex, arc[0], n: 6)
        for i in 0...N {
            ring.append(P(p: arc[i], h: H * rng.float(0.99...1.015), bulge: 0, bark: true))
        }
        splitFace(arc[N], apex, n: 6)
        // center on x/z
        var c = V2(0, 0)
        for r in ring { c += r.p }
        c /= Float(ring.count)
        for i in ring.indices { ring[i].p -= c }
        let rows = 4, cnt = ring.count
        func wallPoint(_ i: Int, _ j: Int) -> V3 {
            let r = ring[i % cnt], f = Float(j) / Float(rows)
            let prev = ring[(i + cnt - 1) % cnt].p, next = ring[(i + 1) % cnt].p
            let d = next - prev, out = simd_normalize(V2(d.y, -d.x))
            let b = r.bulge * sin(Float.pi * f) * 1.6
            let p = r.p + out * b
            return V3(p.x, r.h * f, p.y)
        }
        var pts: [V3] = []
        for i in 0...cnt { for j in 0...rows { pts.append(wallPoint(i, j)) } }
        for i in 0..<cnt {
            let isBark = ring[i].bark && ring[(i + 1) % cnt].bark
            var ids: [UInt32] = []
            for k in 0...1 { for j in 0...rows {
                let p = pts[(i + k) * (rows + 1) + j]
                let uv = V2((Float(i + k) * 0.03), p.y)
                if isBark { ids.append(bark.add(p, V3(0, 0, 1), uv)) } else { ids.append(wood.add(p, V3(0, 0, 1), V2(p.x + p.z, p.y))) }
            }}
            for j in 0..<rows {
                let b0 = ids[j], t0 = ids[j + 1], b1 = ids[rows + 1 + j], t1 = ids[rows + 2 + j]
                if isBark { bark.quad(b1, b0, t0, t1) } else { wood.quad(b1, b0, t0, t1) }
            }
        }
        // endgrain cap
        var mean = V3.zero
        for i in 0..<cnt { mean += pts[i * (rows + 1) + rows] }
        mean /= Float(cnt); mean.y += 0.004
        let ci = end.add(mean, V3(0, 1, 0), V2(0.5, 0.5))
        var ei: [UInt32] = []
        for i in 0..<cnt { let p = pts[i * (rows + 1) + rows]; ei.append(end.add(p, V3(0, 1, 0), V2(p.x * 4 + 0.5, p.z * 4 + 0.5))) }
        for i in 0..<cnt { end.tri(ci, ei[(i + 1) % cnt], ei[i]) }
        var ss = [bark, wood, end]
        for k in ss.indices { ss[k].recomputeNormals() }
        var m = Model(name: Self.id)
        for var s in ss { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
