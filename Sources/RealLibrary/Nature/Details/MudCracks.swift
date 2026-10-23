import simd
import Foundation

/// Dried cracked mud, ~80 cm: a Voronoi pattern of polygon plates with curled, lifted edges and dark gaps.
public struct MudCracks: RealAsset {
    public static let id = "mud-cracks"
    public static let summary = "Dried cracked mud, 80 cm: polygon plates with curled lifted edges separated by dark gaps."
    public static let tags = ["nature", "ground"]
    public static let budget = 1_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 1.0, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let half: Float = 0.4
        let cols = 6, rows = 6
        var seeds: [V2] = []
        let cs = 2 * half / Float(cols)
        for i in 0..<cols { for j in 0..<rows {
            seeds.append(V2(-half + (Float(i) + rng.float(0.1...0.9)) * cs, -half + (Float(j) + rng.float(0.1...0.9)) * cs))
        } }
        var floor = Surface(material: "ground.mud:2A1E15")
        var top = Surface(material: "ground.mud:B09878")
        var walls = Surface(material: "ground.mud:5A4632")
        func tri(_ s: inout Surface, _ a: V3, _ b: V3, _ c: V3, up: V3?, _ ua: V2, _ ub: V2, _ uc: V2) {
            var n = simd_cross(b - a, c - a)
            var (b, c, ub, uc) = (b, c, ub, uc)
            if let u = up, simd_dot(n, u) < 0 { swap(&b, &c); swap(&ub, &uc); n = -n }
            let nn = simd_length(n) > 0 ? simd_normalize(n) : V3(0, 1, 0)
            let i0 = s.add(a, nn, ua), i1 = s.add(b, nn, ub), i2 = s.add(c, nn, uc)
            s.tri(i0, i1, i2)
        }
        let fl: Float = 0.0
        tri(&floor, V3(-half, fl - 0.004, -half), V3(half, fl - 0.004, -half), V3(half, fl - 0.004, half), up: V3(0, 1, 0), V2(0, 0), V2(1, 0), V2(1, 1))
        tri(&floor, V3(-half, fl - 0.004, -half), V3(half, fl - 0.004, half), V3(-half, fl - 0.004, half), up: V3(0, 1, 0), V2(0, 0), V2(1, 1), V2(0, 1))
        for (si, c) in seeds.enumerated() {
            var poly: [V2] = [V2(-half, -half), V2(half, -half), V2(half, half), V2(-half, half)]
            for (oi, o) in seeds.enumerated() where oi != si {
                let mid = (c + o) / 2, nrm = simd_normalize(c - o)
                var next: [V2] = []
                for k in 0..<poly.count {
                    let p = poly[k], q = poly[(k + 1) % poly.count]
                    let dp = simd_dot(p - mid, nrm), dq = simd_dot(q - mid, nrm)
                    if dp >= 0 { next.append(p) }
                    if (dp >= 0) != (dq >= 0) { next.append(p + (q - p) * (dp / (dp - dq))) }
                }
                poly = next
                if poly.count < 3 { break }
            }
            if poly.count < 3 { continue }
            let cen = poly.reduce(V2.zero, +) / Float(poly.count)
            let gap = rng.float(0.004...0.007)
            let thick = rng.float(0.012...0.02)
            let curl = rng.chance(0.3) ? rng.float(0.012...0.03) : rng.float(0.002...0.008)
            let tilt = V2(rng.float(-0.03...0.03), rng.float(-0.03...0.03))
            let R = poly.map { simd_length($0 - cen) }.max() ?? 0.05
            func pt(_ p: V2, _ k: Float) -> V3 {
                let d = p - cen
                let rr = simd_length(d)
                let edgeX = (rr / max(R, 0.001))
                let y = thick + curl * pow(edgeX, 3) * k + simd_dot(tilt, d) + 0.002 * sin(p.x * 80 + p.y * 60)
                return V3(p.x, max(y, 0.004), p.y)
            }
            // Inset vertices to open the gap.
            let edge = poly.map { p -> V2 in let d = p - cen; let l = simd_length(d); return l > gap ? cen + d * ((l - gap) / l) : p }
            let mid = edge.map { cen + ($0 - cen) * 0.55 }
            let n = edge.count
            let up = V3(0, 1, 0)
            func uv(_ p: V2) -> V2 { p * 1.6 }
            for k in 0..<n {
                let k2 = (k + 1) % n
                let cp = V3(cen.x, thick + simd_dot(tilt, V2.zero), cen.y)
                tri(&top, cp, pt(mid[k], 1), pt(mid[k2], 1), up: up, uv(cen), uv(mid[k]), uv(mid[k2]))
                tri(&top, pt(mid[k], 1), pt(edge[k], 1), pt(edge[k2], 1), up: up, uv(mid[k]), uv(edge[k]), uv(edge[k2]))
                tri(&top, pt(mid[k], 1), pt(edge[k2], 1), pt(mid[k2], 1), up: up, uv(mid[k]), uv(edge[k2]), uv(mid[k2]))
                // Wall down to the floor.
                let a = pt(edge[k], 1), b = pt(edge[k2], 1)
                let a0 = V3(a.x, -0.004, a.z), b0 = V3(b.x, -0.004, b.z)
                let outward = V3(((edge[k] + edge[k2]) / 2 - cen).x, 0, ((edge[k] + edge[k2]) / 2 - cen).y)
                tri(&walls, a, b, b0, up: outward, V2(0, a.y), V2(0.05, b.y), V2(0.05, 0))
                tri(&walls, a, b0, a0, up: outward, V2(0, a.y), V2(0.05, 0), V2(0, 0))
            }
        }
        var m = Model(name: Self.id)
        top.recomputeNormals(); for var s in [floor, top, walls] { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
