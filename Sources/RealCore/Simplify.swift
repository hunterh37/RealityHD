import simd

/// Quadric-error mesh simplification by half-edge collapse: a vertex merges into a neighbour and keeps
/// that neighbour's attributes unchanged, so UVs, tangents, wind weights and AO need no interpolation.
/// Open-edge vertices and vertices sharing a position with another vertex (UV or normal seams) stay
/// fixed, so silhouettes and texture seams do not crack.
public enum Simplify {
    /// Collapses until `target` triangles remain or the next collapse would move the surface by more than
    /// `maxError` meters (quadric distance).
    public static func surface(_ s: Surface, target: Int, maxError: Float) -> Surface {
        let vc = s.positions.count, tc = s.indices.count / 3
        guard tc > target, vc > 3 else { return s }
        var tris: [SIMD3<Int>] = []
        tris.reserveCapacity(tc)
        for t in 0..<tc {
            let i0 = Int(s.indices[t * 3]), i1 = Int(s.indices[t * 3 + 1]), i2 = Int(s.indices[t * 3 + 2])
            tris.append(SIMD3<Int>(i0, i1, i2))
        }
        var alive = [Bool](repeating: true, count: tc)
        var faces = [[Int]](repeating: [], count: vc)
        for (t, f) in tris.enumerated() { faces[f.x].append(t); faces[f.y].append(t); faces[f.z].append(t) }

        // Locked: on an open edge, or sharing a position with another vertex.
        var locked = [Bool](repeating: false, count: vc)
        var edgeUse: [UInt64: Int] = [:]
        func key(_ a: Int, _ b: Int) -> UInt64 { UInt64(min(a, b)) << 32 | UInt64(max(a, b)) }
        for f in tris { edgeUse[key(f.x, f.y), default: 0] += 1; edgeUse[key(f.y, f.z), default: 0] += 1; edgeUse[key(f.z, f.x), default: 0] += 1 }
        for (k, n) in edgeUse where n != 2 { locked[Int(k >> 32)] = true; locked[Int(k & 0xffff_ffff)] = true }
        var seen: [SIMD3<Float>: Int] = [:]
        for (i, p) in s.positions.enumerated() {
            if let j = seen[p] { locked[i] = true; locked[j] = true } else { seen[p] = i }
        }

        // Plane quadrics, area weighted.
        var q = [Quadric](repeating: Quadric(), count: vc)
        for f in tris {
            let pa: SIMD3<Float> = s.positions[f.x], pb: SIMD3<Float> = s.positions[f.y], pc: SIMD3<Float> = s.positions[f.z]
            let n: SIMD3<Float> = simd_cross(pb - pa, pc - pa)
            let len: Float = simd_length(n)
            guard len > 1e-12 else { continue }
            let un: SIMD3<Float> = n / len
            let pq = Quadric(normal: un, d: -simd_dot(un, pa), weight: len / 2)
            q[f.x] += pq; q[f.y] += pq; q[f.z] += pq
        }

        func neighbours(_ v: Int) -> Set<Int> {
            var out = Set<Int>()
            for t in faces[v] where alive[t] { let f = tris[t]; out.insert(f.x); out.insert(f.y); out.insert(f.z) }
            out.remove(v); return out
        }
        func cost(_ u: Int, _ v: Int) -> Float { (q[u] + q[v]).error(s.positions[v]) }

        var heap = MinHeap()
        var stamp = [Int](repeating: 0, count: vc)
        func push(_ u: Int) {
            guard !locked[u] else { return }
            stamp[u] += 1
            var best: (Float, Int)? = nil
            for v in neighbours(u) { let c = cost(u, v); if best == nil || c < best!.0 { best = (c, v) } }
            if let b = best { heap.push(.init(cost: b.0, u: u, v: b.1, stamp: stamp[u])) }
        }
        for u in 0..<vc { push(u) }

        var remaining = tc
        let limit = maxError * maxError
        var removed = [Bool](repeating: false, count: vc)
        while remaining > target, let e = heap.pop() {
            guard e.cost <= limit else { break }
            let u = e.u, v = e.v
            guard !removed[u], !removed[v], e.stamp == stamp[u] else { continue }
            // Reject flips and slivers among faces that survive the collapse.
            let pv = s.positions[v]
            var ok = true
            for t in faces[u] where alive[t] {
                let f = tris[t]
                if f.x == v || f.y == v || f.z == v { continue }
                let p = [f.x, f.y, f.z].map { s.positions[$0] }
                let np = [f.x, f.y, f.z].map { $0 == u ? pv : s.positions[$0] }
                let n0 = simd_cross(p[1] - p[0], p[2] - p[0]), n1 = simd_cross(np[1] - np[0], np[2] - np[0])
                let l0 = simd_length(n0), l1 = simd_length(n1)
                if l1 < 1e-12 || simd_dot(n0, n1) < 0.3 * l0 * l1 { ok = false; break }
            }
            guard ok else { stamp[u] += 1; continue }
            for t in faces[u] where alive[t] {
                var f = tris[t]
                if f.x == v || f.y == v || f.z == v { alive[t] = false; remaining -= 1; continue }
                if f.x == u { f.x = v }; if f.y == u { f.y = v }; if f.z == u { f.z = v }
                tris[t] = f; faces[v].append(t)
            }
            removed[u] = true
            q[v] += q[u]
            faces[v] = faces[v].filter { alive[$0] }
            push(v)
            for n in neighbours(v) { push(n) }
        }

        // Compact.
        var out = Surface(material: s.material)
        var remap = [Int](repeating: -1, count: vc)
        let hasT = s.tangents.count == vc, hasE = s.extra.count == vc, hasO = s.occlusion.count == vc, hasS = s.splat.count == vc
        func emit(_ i: Int) -> UInt32 {
            if remap[i] < 0 {
                remap[i] = out.positions.count
                out.positions.append(s.positions[i]); out.normals.append(s.normals[i]); out.uvs.append(s.uvs[i])
                if hasT { out.tangents.append(s.tangents[i]) }
                if hasE { out.extra.append(s.extra[i]) }
                if hasO { out.occlusion.append(s.occlusion[i]) }
                if hasS { out.splat.append(s.splat[i]) }
            }
            return UInt32(remap[i])
        }
        for (t, f) in tris.enumerated() where alive[t] && f.x != f.y && f.y != f.z && f.x != f.z {
            out.indices.append(emit(f.x)); out.indices.append(emit(f.y)); out.indices.append(emit(f.z))
        }
        return out
    }

    /// Every surface reduced to `ratio` of its triangles within `maxError` meters.
    public static func model(_ m: Model, ratio: Float, maxError: Float) -> Model {
        var out = Model(name: m.name)
        for s in m.surfaces {
            let r = surface(s, target: max(4, Int(Float(s.triangleCount) * ratio)), maxError: maxError)
            if !r.isEmpty { out.surfaces.append(r) }
        }
        return out
    }
}

public extension LODModel {
    /// A single-level model of `minTriangles` or more gets two simplified levels (about 45 % and 18 % of
    /// LOD0, error bounded by 0.4 % and 1.2 % of the bounds diagonal). Switch distances scale with size so
    /// each level's error stays under about one pixel at Vision Pro angular resolution. Levels that save
    /// under 20 % are dropped.
    func withAutoLevels(minTriangles: Int = 1500) -> LODModel {
        guard levels.count == 1, let m = levels.first, m.triangleCount >= minTriangles else { return self }
        let b = m.bounds, diag = simd_length(b.max - b.min)
        guard diag > 0 else { return self }
        var out = [m], dist: [Float] = []
        var last = m.triangleCount
        // (ratio, error as fraction of diag). Error e is under ~1 px (0.02 deg) past e / tan(0.02 deg) = e * 2900.
        for (ratio, frac) in [(Float(0.45), Float(0.004)), (0.18, 0.012)] {
            let err = diag * frac
            let lvl = Simplify.model(out.last!, ratio: ratio * Float(m.triangleCount) / Float(last), maxError: err)
            guard Float(lvl.triangleCount) < Float(last) * 0.8 else { break }
            out.append(lvl); dist.append(max(6, err * 2900)); last = lvl.triangleCount
        }
        return out.count == 1 ? self : LODModel(levels: out, switchDistances: dist)
    }
}

struct Quadric {
    var a = simd_float4x4()
    init() {}
    init(normal n: SIMD3<Float>, d: Float, weight w: Float) {
        let p = SIMD4<Float>(n, d)
        a = simd_float4x4(p * p.x * w, p * p.y * w, p * p.z * w, p * p.w * w)
    }
    static func + (l: Quadric, r: Quadric) -> Quadric { var o = l; o.a = l.a + r.a; return o }
    static func += (l: inout Quadric, r: Quadric) { l.a = l.a + r.a }
    func error(_ p: SIMD3<Float>) -> Float {
        let v = SIMD4<Float>(p, 1)
        // Quadric weight is area; divide by total weight to get mean squared distance.
        let w = max(1e-12, a[0][0] + a[1][1] + a[2][2])
        return max(0, simd_dot(v, a * v)) / w
    }
}

struct MinHeap {
    struct Item { var cost: Float; var u: Int; var v: Int; var stamp: Int }
    private var items: [Item] = []
    mutating func push(_ x: Item) {
        items.append(x); var i = items.count - 1
        while i > 0 { let p = (i - 1) / 2; if items[p].cost <= items[i].cost { break }; items.swapAt(p, i); i = p }
    }
    mutating func pop() -> Item? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last; var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1; var m = i
                if l < items.count && items[l].cost < items[m].cost { m = l }
                if r < items.count && items[r].cost < items[m].cost { m = r }
                if m == i { break }; items.swapAt(m, i); i = m
            }
        }
        return top
    }
}
