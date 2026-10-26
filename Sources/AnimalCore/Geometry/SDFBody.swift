import Foundation
import simd
import RealCore

public enum SDFRegion: Int, Sendable { case body, head, muzzle, limb }

/// Fur chart: a local frame that unwraps the surface near one primitive into the coat atlas. u is the angle
/// around `axis` measured from `ref` (0 at `ref`, 0.5 on the opposite side; both flanks share the left half of
/// the atlas, which the coat programs mirror), v runs along `axis` toward the hair root, so strands lie with
/// their tips toward lower v. One atlas unit spans about one half-circumference of the region.
struct SDFChart {
    var origin: V3, axis: V3, ref: V3, side: V3
    var vScale: Float, v0: Float
    var region: SDFRegion

    init(origin: V3, axis: V3, ref: V3, vScale: Float, v0: Float, region: SDFRegion) {
        self.origin = origin; self.axis = simd_normalize(axis)
        var r = ref - self.axis * simd_dot(ref, self.axis)
        if simd_length(r) < 1e-5 { r = self.axis.anyPerpendicular }
        self.ref = simd_normalize(r)
        side = simd_cross(self.axis, self.ref)
        self.vScale = vScale; self.v0 = v0; self.region = region
    }

    func uv(_ p: V3) -> V2 {
        let l = p - origin
        let y = simd_dot(l, axis)
        let q = l - axis * y
        let ang = atan2(abs(simd_dot(q, side)), simd_dot(q, ref))
        return V2(0.5 * ang / .pi, v0 + y * vScale)
    }
}

/// One shape of the field. `blend` is the smooth-union radius used when this shape joins the shapes before it.
struct SDFPrim {
    enum Kind {
        case cone(a: V3, b: V3, ra: Float, rb: Float)
        case ellipsoid(c: V3, r: V3, q: simd_quatf)
    }
    var kind: Kind
    var joint: String
    var chart: Int
    var blend: Float
    var lo: V3 = .zero, hi: V3 = .zero

    init(_ kind: Kind, joint: String, chart: Int, blend: Float) {
        self.kind = kind; self.joint = joint; self.chart = chart; self.blend = blend
        switch kind {
        case .cone(let a, let b, let ra, let rb):
            let m = max(ra, rb)
            lo = simd_min(a, b) - V3(repeating: m); hi = simd_max(a, b) + V3(repeating: m)
        case .ellipsoid(let c, let r, _):
            let m = max(r.x, max(r.y, r.z))
            lo = c - V3(repeating: m); hi = c + V3(repeating: m)
        }
    }

    func distance(_ p: V3) -> Float {
        switch kind {
        case .cone(let a, let b, let r1, let r2):
            let ba = b - a, l2 = simd_dot(ba, ba), rr = r1 - r2, a2 = l2 - rr * rr, il2 = 1 / l2
            // One end sphere swallows the other (radii differ by more than the length): the cone is that sphere.
            if a2 <= 1e-9 || l2 < 1e-12 { return rr >= 0 ? simd_length(p - a) - r1 : simd_length(p - b) - r2 }
            let pa = p - a, y = simd_dot(pa, ba), z = y - l2
            let x2 = simd_length_squared(pa * l2 - ba * y), y2 = y * y * l2, z2 = z * z * l2
            let k = (rr < 0 ? -1 : 1) * rr * rr * x2
            if (z < 0 ? -1 : 1) * a2 * z2 > k { return (x2 + z2).squareRoot() * il2 - r2 }
            if (y < 0 ? -1 : 1) * a2 * y2 < k { return (x2 + y2).squareRoot() * il2 - r1 }
            return ((x2 * a2 * il2).squareRoot() + y * rr) * il2 - r1
        case .ellipsoid(let c, let r, let q):
            let l = q.inverse.act(p - c)
            let k0 = simd_length(l / r), k1 = simd_length(l / (r * r))
            return k1 < 1e-8 ? -min(r.x, min(r.y, r.z)) : k0 * (k0 - 1) / k1
        }
    }

    /// Lower bound on the distance from `p` (distance to the bounding box).
    func bound(_ p: V3) -> Float {
        let d = simd_max(simd_max(lo - p, p - hi), .zero)
        return simd_length(d)
    }
}

/// Smooth union of primitives meshed with surface nets into one watertight surface per fur region.
/// Normals are field gradients, skin weights come from a soft-min over the primitive distances grouped by joint.
struct SDFBody {
    var prims: [SDFPrim] = []
    var charts: [SDFChart] = []

    mutating func chart(_ c: SDFChart) -> Int { charts.append(c); return charts.count - 1 }
    mutating func add(_ k: SDFPrim.Kind, joint: String, chart: Int, blend: Float) { prims.append(SDFPrim(k, joint: joint, chart: chart, blend: blend)) }
    mutating func cone(_ a: V3, _ b: V3, _ ra: Float, _ rb: Float, joint: String, chart: Int, blend: Float) {
        add(.cone(a: a, b: b, ra: ra, rb: rb), joint: joint, chart: chart, blend: blend)
    }
    /// Ellipsoid with radii `r` along `x`, `y` and `z` (axes need not be exactly orthogonal).
    mutating func ellipsoid(_ c: V3, _ r: V3, x: V3, y: V3, joint: String, chart: Int, blend: Float) {
        let xn = simd_normalize(x)
        var yn = y - xn * simd_dot(y, xn); yn = simd_normalize(yn)
        let zn = simd_cross(xn, yn)
        add(.ellipsoid(c: c, r: r, q: simd_quatf(simd_float3x3(columns: (xn, yn, zn)))), joint: joint, chart: chart, blend: blend)
    }

    func field(_ p: V3) -> Float {
        var acc = Float.greatestFiniteMagnitude
        for s in prims {
            if acc < 1e5, s.bound(p) - acc > s.blend { continue }
            let d = s.distance(p)
            if acc > 1e5 { acc = d; continue }
            let h = max(s.blend - abs(acc - d), 0)
            acc = min(acc, d) - h * h * 0.25 / max(s.blend, 1e-6)
        }
        return acc
    }

    func gradient(_ p: V3, _ e: Float) -> V3 {
        V3(field(p + V3(e, 0, 0)) - field(p - V3(e, 0, 0)),
           field(p + V3(0, e, 0)) - field(p - V3(0, e, 0)),
           field(p + V3(0, 0, e)) - field(p - V3(0, 0, e))) / (2 * e)
    }

    /// Meshes the zero level set on a grid of `cell` meters. `materials` gives the fur material for each region.
    /// `jointIndex` maps a joint name to its skeleton index. One surface per region, vertices unshared across charts.
    func mesh(cell: Float, tau: Float, materials: [SDFRegion: MaterialKey], jointIndex: (String) -> Int) -> [Surface] {
        guard !prims.isEmpty else { return [] }
        var lo = prims[0].lo, hi = prims[0].hi
        for s in prims { lo = simd_min(lo, s.lo); hi = simd_max(hi, s.hi) }
        lo -= V3(repeating: 2 * cell); hi += V3(repeating: 2 * cell)
        let nx = Int(ceil((hi.x - lo.x) / cell)), ny = Int(ceil((hi.y - lo.y) / cell)), nz = Int(ceil((hi.z - lo.z) / cell))
        let sx = nx + 1, sy = ny + 1, sz = nz + 1
        var f = [Float](repeating: 0, count: sx * sy * sz)
        @inline(__always) func gi(_ i: Int, _ j: Int, _ k: Int) -> Int { (k * sy + j) * sx + i }
        for k in 0..<sz { for j in 0..<sy { for i in 0..<sx {
            f[gi(i, j, k)] = field(lo + V3(Float(i), Float(j), Float(k)) * cell)
        }}}
        // One vertex per cell that straddles the surface.
        var vid = [Int32](repeating: -1, count: nx * ny * nz)
        var pos: [V3] = []
        let corner: [(Int, Int, Int)] = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0), (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 1, 1)]
        let edges: [(Int, Int)] = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
        for k in 0..<nz { for j in 0..<ny { for i in 0..<nx {
            var d = [Float](repeating: 0, count: 8)
            var mask = 0
            for c in 0..<8 { d[c] = f[gi(i + corner[c].0, j + corner[c].1, k + corner[c].2)]; if d[c] < 0 { mask |= 1 << c } }
            if mask == 0 || mask == 255 { continue }
            var sum = V3.zero, n: Float = 0
            for (a, b) in edges where (d[a] < 0) != (d[b] < 0) {
                let t = d[a] / (d[a] - d[b])
                let pa = V3(Float(corner[a].0), Float(corner[a].1), Float(corner[a].2)), pb = V3(Float(corner[b].0), Float(corner[b].1), Float(corner[b].2))
                sum += lerp(pa, pb, t); n += 1
            }
            let local = sum / n
            vid[(k * ny + j) * nx + i] = Int32(pos.count)
            pos.append(lo + (V3(Float(i), Float(j), Float(k)) + local) * cell)
        }}}
        // Project onto the surface with two Newton steps along the gradient.
        for i in pos.indices {
            for _ in 0..<2 {
                let d = field(pos[i]), g = gradient(pos[i], cell * 0.25)
                let l2 = simd_length_squared(g)
                if l2 < 1e-10 { break }
                let step = g * (d / l2)
                let m = simd_length(step)
                pos[i] -= m > cell ? step * (cell / m) : step
            }
        }
        var tris: [(UInt32, UInt32, UInt32)] = []
        func cellVertex(_ i: Int, _ j: Int, _ k: Int) -> UInt32? {
            guard i >= 0, j >= 0, k >= 0, i < nx, j < ny, k < nz else { return nil }
            let v = vid[(k * ny + j) * nx + i]
            return v < 0 ? nil : UInt32(v)
        }
        // One quad per grid edge that crosses the surface, from the four cells around the edge.
        for k in 0..<sz { for j in 0..<sy { for i in 0..<sx {
            let d0 = f[gi(i, j, k)]
            for axis in 0..<3 {
                let (ii, jj, kk) = (i + (axis == 0 ? 1 : 0), j + (axis == 1 ? 1 : 0), k + (axis == 2 ? 1 : 0))
                guard ii < sx, jj < sy, kk < sz else { continue }
                let d1 = f[gi(ii, jj, kk)]
                guard (d0 < 0) != (d1 < 0) else { continue }
                let cells: [(Int, Int, Int)]
                switch axis {
                case 0: cells = [(i, j - 1, k - 1), (i, j, k - 1), (i, j, k), (i, j - 1, k)]
                case 1: cells = [(i - 1, j, k - 1), (i - 1, j, k), (i, j, k), (i, j, k - 1)]
                default: cells = [(i - 1, j - 1, k), (i, j - 1, k), (i, j, k), (i - 1, j, k)]
                }
                let q = cells.compactMap { cellVertex($0.0, $0.1, $0.2) }
                guard q.count == 4 else { continue }
                // Orient outward: the geometric normal should follow the field gradient.
                let n = simd_cross(pos[Int(q[1])] - pos[Int(q[0])], pos[Int(q[2])] - pos[Int(q[0])])
                let g = V3(axis == 0 ? 1 : 0, axis == 1 ? 1 : 0, axis == 2 ? 1 : 0) * (d1 - d0)
                // Split along the shorter diagonal so a bent quad never folds into a flipped pair.
                let useA = simd_distance(pos[Int(q[0])], pos[Int(q[2])]) <= simd_distance(pos[Int(q[1])], pos[Int(q[3])])
                let t0: [(UInt32, UInt32, UInt32)] = useA ? [(q[0], q[1], q[2]), (q[0], q[2], q[3])] : [(q[0], q[1], q[3]), (q[1], q[2], q[3])]
                if simd_dot(n, g) >= 0 { tris += t0 } else { tris += t0.map { ($0.0, $0.2, $0.1) } }
            }
        }}}
        // Per-vertex primary chart and joint weights.
        let eps = cell * 0.35
        var normal = [V3](repeating: .zero, count: pos.count)
        var primary = [Int](repeating: 0, count: pos.count)
        var infl = [SkinInfluence](repeating: SkinInfluence(joints: .zero, weights: SIMD4(1, 0, 0, 0)), count: pos.count)
        let jointIdx = Dictionary(uniqueKeysWithValues: Set(prims.map(\.joint)).map { ($0, jointIndex($0)) })
        for i in pos.indices {
            let g = gradient(pos[i], eps)
            normal[i] = simd_length(g) > 1e-8 ? simd_normalize(g) : V3(0, 1, 0)
            let ds = prims.map { $0.distance(pos[i]) }
            let dmin = ds.filter { $0.isFinite }.min() ?? 0
            primary[i] = prims[ds.firstIndex(of: dmin) ?? 0].chart
            var byJoint: [Int: Float] = [:]
            for (s, d) in zip(prims, ds) where d.isFinite { byJoint[jointIdx[s.joint]!, default: 0] += exp(-(d - dmin) / tau) }
            let top = byJoint.sorted { $0.value > $1.value }.prefix(4)
            let sum = top.reduce(0) { $0 + $1.value }
            var J = SIMD4<UInt16>(repeating: 0), W = SIMD4<Float>(repeating: 0)
            for (n, e) in top.enumerated() { J[n] = UInt16(e.key); W[n] = e.value / sum }
            infl[i] = SkinInfluence(joints: J, weights: W)
        }
        // Triangles take the chart of their lowest-distance vertex so a triangle never mixes two unwraps.
        var out: [SDFRegion: Surface] = [:]
        for (a0, b0, c0) in tris {
            var (a, b, c) = (a0, b0, c0)
            // A bent quad can wind against its neighbours; the field normals decide which way is out.
            let gn = simd_cross(pos[Int(b)] - pos[Int(a)], pos[Int(c)] - pos[Int(a)])
            if simd_dot(gn, normal[Int(a)] + normal[Int(b)] + normal[Int(c)]) < 0 { swap(&b, &c) }
            let ia = Int(a), ib = Int(b), ic = Int(c)
            let ch = charts[primary[ia]]
            var s = out[ch.region] ?? Surface(material: materials[ch.region] ?? "")
            var uvs = [ch.uv(pos[ia]), ch.uv(pos[ib]), ch.uv(pos[ic])]
            let shift = floor(min(uvs[0].y, min(uvs[1].y, uvs[2].y)))
            for k in 0..<3 { uvs[k].y -= shift }
            // Collapsed triangles (two vertices projected onto the same point) have no tangent frame and light as NaN.
            let area = simd_length(simd_cross(pos[ib] - pos[ia], pos[ic] - pos[ia]))
            let uvDet = (uvs[1].x - uvs[0].x) * (uvs[2].y - uvs[0].y) - (uvs[2].x - uvs[0].x) * (uvs[1].y - uvs[0].y)
            if area < cell * cell * 1e-4 || abs(uvDet) < 1e-9 { continue }
            let base = UInt32(s.vertexCount)
            for (k, v) in [ia, ib, ic].enumerated() {
                s.add(pos[v], normal[v], uvs[k])
                s.skinWeights.append(infl[v])
            }
            s.tri(base, base + 1, base + 2)
            out[ch.region] = s
        }
        return [SDFRegion.body, .head, .muzzle, .limb].compactMap { r in
            guard var s = out[r], !s.isEmpty else { return nil }
            s.computeTangents()
            return s
        }
    }
}
