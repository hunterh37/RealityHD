import simd

/// Shared helpers for whole-produce props (apple, citrus, tomato, avocado).
enum ProduceKit {
    /// Averages tangents of vertices that share a position (revolve and loft seams duplicate them for
    /// UVs), so normal-mapped skins shade without a meridian line.
    static func weldTangents(_ s: Surface) -> Surface {
        var o = s
        var groups: [SIMD3<Int32>: [Int]] = [:]
        for (i, p) in o.positions.enumerated() {
            let q = (p * 1e5).rounded(.toNearestOrAwayFromZero)
            groups[SIMD3<Int32>(Int32(q.x), Int32(q.y), Int32(q.z)), default: []].append(i)
        }
        for (_, g) in groups where g.count > 1 {
            var t = V3.zero
            for i in g { let v = o.tangents[i]; t += V3(v.x, v.y, v.z) }
            let w = o.tangents[g[0]].w
            for i in g {
                let n = o.normals[i]
                var tt = t - n * simd_dot(n, t)
                if simd_length_squared(tt) < 1e-12 { continue }
                tt = simd_normalize(tt)
                o.tangents[i] = V4(tt, w)
            }
        }
        return o
    }

    /// Averages baked occlusion over vertices that share a position. `bakeCavityAO` sees only one side
    /// of a UV seam per copy, which leaves a shading step along the seam; call after `groundAO`.
    static func weldAO(_ m: inout Model) {
        for si in m.surfaces.indices {
            var s = m.surfaces[si]
            guard s.occlusion.count == s.positions.count else { continue }
            var groups: [SIMD3<Int32>: [Int]] = [:]
            for (i, p) in s.positions.enumerated() {
                let q = (p * 1e5).rounded(.toNearestOrAwayFromZero)
                groups[SIMD3<Int32>(Int32(q.x), Int32(q.y), Int32(q.z)), default: []].append(i)
            }
            for (_, g) in groups where g.count > 1 {
                let a = g.reduce(Float(0)) { $0 + s.occlusion[$1] } / Float(g.count)
                for i in g { s.occlusion[i] = a }
            }
            m.surfaces[si] = s
        }
    }
}
