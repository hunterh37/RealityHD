import simd
import Foundation

/// Helpers for the 2 x 2 m facade ground tiles: scattered stones, perimeter edging with stakes and
/// screws, grass blades. Tiles are centered on X/Z with the base at y = 0.
enum GTK {
    /// Scatter `count` stones over `|x| < hx, |z| < hz`, resting on `surface(p)`, sunk ~35 %.
    static func stones(_ m: inout Model, _ rng: inout SeededRNG, count: Int, hx: Float, hz: Float,
                       size: ClosedRange<Float>, flat: ClosedRange<Float> = 0.45...0.7, keys: [MaterialKey],
                       subdivisions: Int = 1, exponent: Float = 2.4, sink: Float = 0.35, offset: V3 = .zero,
                       surface: (V2) -> Float, keep: (V2) -> Bool = { _ in true }) {
        var n = 0, tries = 0
        while n < count && tries < count * 4 {
            tries += 1
            var r = rng.fork(9000 + tries)
            let p = V2(r.float(-hx...hx), r.float(-hz...hz))
            guard keep(p) else { continue }
            n += 1
            let len = size.lowerBound + (size.upperBound - size.lowerBound) * pow(r.float(), 1.5)
            let sz = V3(len, len * r.float(flat), len * r.float(0.6...0.95))
            let ss = UInt32(truncatingIfNeeded: r.int(0...100_000))
            var s = Prim.superellipsoid(sz, exponent: exponent, subdivisions: subdivisions, material: keys[r.int(0...(keys.count - 1))]) { d in
                1 + 0.08 * Noise.fbm(d * 1.7, octaves: 2, seed: ss)
            }
            let off = V2(r.float(0...4), r.float(0...4))
            s.uvs = s.positions.map { V2($0.x + 0.6 * $0.y, $0.z - 0.6 * $0.y) + off }
            s.recomputeNormals(weldSeams: true)
            m.add(s, Xform(translation: offset + V3(p.x, surface(p) + sz.y * (0.5 - sink), p.y),
                           rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-15...15), axis: V3(1, 0, 0))))
        }
    }

    /// Perimeter edging boards (outside face flush with the tile edge), tops at `top`, with pointed
    /// stakes inside every ~0.6 m, each fixed by two screw heads through the board.
    static func edging(_ m: inout Model, _ rng: inout SeededRNG, w: Float, d: Float, top: Float, thick: Float,
                       board: MaterialKey, stake: MaterialKey, screw: MaterialKey) {
        let hx = w / 2, hz = d / 2
        for side in 0..<4 {
            var r = rng.fork(500 + side)
            let alongX = side < 2, s: Float = side % 2 == 0 ? -1 : 1
            let len = alongX ? w : d - 2 * thick
            let c = alongX ? V3(0, top / 2, s * (hz - thick / 2)) : V3(s * (hx - thick / 2), top / 2, 0)
            let yaw: Float = alongX ? 0 : 90
            let h = top - r.float(0...0.004)
            m.add(plank(len - 0.003, h, thick, bevel: 0.003, material: board),
                  Xform(translation: V3(c.x, h / 2, c.z), rotation: simd_quatf(degrees: yaw, axis: .up) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let n = max(2, Int(len / 0.6) + 1)
            for k in 0..<n {
                let t = (Float(k) + 0.5) / Float(n) - 0.5
                let u = t * len + r.float(-0.04...0.04)
                let inward: V3 = alongX ? V3(0, 0, -s) : V3(-s, 0, 0)
                let face = alongX ? V3(u, 0, s * (hz - thick)) : V3(s * (hx - thick), 0, u)
                let sc = face + inward * 0.0115
                let sh = top - 0.012 - r.float(0...0.01)
                m.add(Prim.roundedBox(V3(0.022, sh, 0.022), radius: 0.002, bevelSegments: 1, material: stake),
                      Xform(translation: V3(sc.x, sh / 2, sc.z), rotation: simd_quatf(degrees: yaw + r.float(-2...2), axis: .up)))
                let outFace = face - inward * thick
                rivet(&m, at: outFace + V3(0, sh * 0.6, 0), normal: -inward, radius: 0.0042, height: 0.0012, segments: 6, material: screw)
            }
        }
    }

    /// Grass blade as a 3-sided tapered tube from `base`, leaning toward `lean` (horizontal offset at tip).
    static func blade(_ base: V3, height: Float, lean: V3, width: Float = 0.0014, material: MaterialKey) -> Surface {
        Prim.tube([base, base + V3(0, height * 0.6, 0) + lean * 0.35, base + V3(0, height, 0) + lean],
                  radii: [width, width * 0.7, width * 0.12], sides: 3, seamTile: 0.02, material: material)
    }

    /// Two LODs: `full` (every loose stone and blade) and `lite` (base only), centered, base at y = 0, ground AO.
    static func finish(_ full: inout Model, _ lite: inout Model, ao: Float = 0.05, switchAt: Float = 6) -> LODModel {
        let b = full.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        for i in full.surfaces.indices { full.surfaces[i].positions = full.surfaces[i].positions.map { $0 + shift } }
        for i in lite.surfaces.indices { lite.surfaces[i].positions = lite.surfaces[i].positions.map { $0 + shift } }
        groundAO(&full, height: ao); groundAO(&lite, height: ao)
        return LODModel(levels: [full, lite], switchDistances: [switchAt])
    }

    /// Heightfield slab on a `nx` x `nz` grid (UVs in meters times `uvScale`): constant `edge` height at
    /// the border, walled by skirts down to y = 0, plus `bump` faded in over 6 cm.
    static func field(_ m: inout Model, w: Float, d: Float, edge: Float, nx: Int, nz: Int, _ mat: MaterialKey, uvScale: Float,
                      bump: (V2) -> Float) {
        var s = Surface(material: mat)
        let fall: Float = 0.06
        for j in 0...nz { for i in 0...nx {
            let p = V2(-w / 2 + w * Float(i) / Float(nx), -d / 2 + d * Float(j) / Float(nz))
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, e / fall))
            s.add(V3(p.x, edge + bump(p) * k * k * (3 - 2 * k), p.y), .up, V2(p.x, -p.y) * uvScale)
        }}
        let row = UInt32(nx + 1)
        for j in 0..<UInt32(nz) { for i in 0..<UInt32(nx) { let q = j * row + i; s.quad(q, q + row, q + row + 1, q + 1) } }
        s.recomputeNormals(weldSeams: true); s.computeTangents()
        m.add(s)
        for sd: Float in [-1, 1] {
            GK.box(&m, V3(sd * (w / 2 - 0.005), edge / 2, 0), V3(0.01, edge, d), mat, r: 0.001)
            GK.box(&m, V3(0, edge / 2, sd * (d / 2 - 0.005)), V3(w, edge, 0.01), mat, r: 0.001)
        }
    }

    /// Square-grid convenience.
    static func field(_ m: inout Model, w: Float, d: Float, edge: Float, segments: Int, _ mat: MaterialKey, uvScale: Float, bump: (V2) -> Float) {
        field(&m, w: w, d: d, edge: edge, nx: segments, nz: segments, mat, uvScale: uvScale, bump: bump)
    }

    /// Rescales UVs so one UV unit spans one meter of surface (median over the triangles).
    static func normalizeTexel(_ s: inout Surface) {
        var area: Float = 0, uv: Float = 0
        for t in stride(from: 0, to: s.indices.count, by: 3) {
            let a = Int(s.indices[t]), b = Int(s.indices[t + 1]), c = Int(s.indices[t + 2])
            area += simd_length(simd_cross(s.positions[b] - s.positions[a], s.positions[c] - s.positions[a])) / 2
            let d1 = s.uvs[b] - s.uvs[a], d2 = s.uvs[c] - s.uvs[a]
            uv += abs(d1.x * d2.y - d1.y * d2.x) / 2
        }
        guard area > 1e-12, uv > 1e-12 else { return }
        let k = sqrt(area / uv)
        s.uvs = s.uvs.map { $0 * k }
    }
}
