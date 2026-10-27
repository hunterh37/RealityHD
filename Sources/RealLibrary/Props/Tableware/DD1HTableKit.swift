import simd
import Foundation

/// Shared helpers for the DD1H everyday tableware props: height-field slabs (cloth, spoon, mats), surface decals and
/// closed rounded-rectangle rails.
enum DD1HTable {
    /// Closed shell between a bottom and a top height field. Rows run along Z from `z0` to `z1`; X spans +-`halfW(z)`.
    /// The top grid is full resolution, the underside uses every `bottomStride`-th sample. UVs are meters (x, z).
    static func slab(nx: Int, nz: Int, z0: Float, z1: Float, halfW: (Float) -> Float, bottomStride bs: Int = 1,
                     material: MaterialKey, bottom: (Float, Float) -> Float, top: (Float, Float) -> Float) -> Surface {
        var s = Surface(material: material)
        let row = UInt32(nx + 1)
        func zAt(_ j: Int) -> Float { z0 + (z1 - z0) * Float(j) / Float(nz) }
        func xAt(_ i: Int, _ z: Float) -> Float { (-1 + 2 * Float(i) / Float(nx)) * halfW(z) }
        for j in 0...nz { let z = zAt(j); for i in 0...nx { let x = xAt(i, z); s.add(V3(x, top(x, z), z), .up, V2(x, z)) } }
        for j in 0..<nz { for i in 0..<nx {
            let a = UInt32(j) * row + UInt32(i)
            s.quad(a, a + row, a + row + 1, a + 1)
        }}
        // Skirt vertices on the perimeter (exact bottom height under every top edge sample).
        var skirt: [Int: UInt32] = [:]
        func skirtIndex(_ i: Int, _ j: Int) -> UInt32 {
            let key = j * (nx + 1) + i
            if let v = skirt[key] { return v }
            let z = zAt(j), x = xAt(i, z)
            let v = s.add(V3(x, bottom(x, z), z), .up, V2(x, z))
            skirt[key] = v
            return v
        }
        func wall(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32, out: V3) {
            let n = simd_cross(s.positions[Int(b)] - s.positions[Int(a)], s.positions[Int(c)] - s.positions[Int(a)])
            if simd_dot(n, out) >= 0 { s.quad(a, b, c, d) } else { s.quad(a, d, c, b) }
        }
        func topIdx(_ i: Int, _ j: Int) -> UInt32 { UInt32(j) * row + UInt32(i) }
        for j in 0..<nz {
            wall(topIdx(0, j), topIdx(0, j + 1), skirtIndex(0, j + 1), skirtIndex(0, j), out: V3(-1, 0, 0))
            wall(topIdx(nx, j), topIdx(nx, j + 1), skirtIndex(nx, j + 1), skirtIndex(nx, j), out: V3(1, 0, 0))
        }
        for i in 0..<nx {
            wall(topIdx(i, 0), topIdx(i + 1, 0), skirtIndex(i + 1, 0), skirtIndex(i, 0), out: V3(0, 0, -1))
            wall(topIdx(i, nz), topIdx(i + 1, nz), skirtIndex(i + 1, nz), skirtIndex(i, nz), out: V3(0, 0, 1))
        }
        // Underside: coarse grid on every bs-th sample; perimeter samples reuse the skirt vertices.
        let cx = nx / bs, cz = nz / bs
        var under: [[UInt32]] = []
        for jj in 0...cz {
            var r: [UInt32] = []
            for ii in 0...cx {
                let i = ii * bs, j = jj * bs
                if i == 0 || i == nx || j == 0 || j == nz { r.append(skirtIndex(i, j)) }
                else { let z = zAt(j), x = xAt(i, z); r.append(s.add(V3(x, bottom(x, z), z), .up, V2(x, z))) }
            }
            under.append(r)
        }
        for jj in 0..<cz { for ii in 0..<cx { s.quad(under[jj][ii], under[jj + 1][ii], under[jj + 1][ii + 1], under[jj][ii + 1]) } }
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    /// Top-only height-field grid (for woven mats laid on a separate base). X spans +-`halfX`, Z spans +-`halfZ`.
    static func topGrid(nx: Int, nz: Int, halfX: Float, halfZ: Float, material: MaterialKey, region: ((Float, Float) -> Bool)? = nil, height: (Float, Float) -> Float) -> Surface {
        var s = Surface(material: material)
        let row = UInt32(nx + 1)
        for j in 0...nz { let z = -halfZ + 2 * halfZ * Float(j) / Float(nz)
            for i in 0...nx { let x = -halfX + 2 * halfX * Float(i) / Float(nx); s.add(V3(x, height(x, z), z), .up, V2(x, z)) } }
        for j in 0..<nz { for i in 0..<nx {
            if let r = region {
                let cx = -halfX + 2 * halfX * (Float(i) + 0.5) / Float(nx), cz = -halfZ + 2 * halfZ * (Float(j) + 0.5) / Float(nz)
                if !r(cx, cz) { continue }
            }
            let a = UInt32(j) * row + UInt32(i); s.quad(a, a + row, a + row + 1, a + 1)
        }}
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    /// Thin elliptical patch that follows a height field `lift` meters off it (stains, scuffs, worn spots).
    /// `up` false faces the patch downward (undersides).
    static func decal(center: V2, rx: Float, rz: Float, yaw: Float = 0, lift: Float = 0.0004, up: Bool = true, rings: Int = 3,
                      segments: Int = 18, material: MaterialKey, height: (Float, Float) -> Float) -> Surface {
        var s = Surface(material: material)
        let cs = cos(yaw), sn = sin(yaw)
        func pt(_ r: Float, _ a: Float) -> V3 {
            let lx = cos(a) * rx * r, lz = sin(a) * rz * r
            let x = center.x + lx * cs - lz * sn, z = center.y + lx * sn + lz * cs
            // Ragged outline so the patch does not read as a clean ellipse.
            return V3(x, height(x, z) + (up ? lift : -lift), z)
        }
        let c = s.add(pt(0, 0), .up, center)
        for k in 0..<rings { for i in 0..<segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            let wob = 1 + 0.07 * sin(a * 5 + Float(k) * 1.7) + 0.05 * cos(a * 2 + Float(k)) * Float(k + 1) / Float(rings)
            let p = pt(Float(k + 1) / Float(rings) * wob, a)
            s.add(p, .up, V2(p.x, p.z))
        }}
        func idx(_ k: Int, _ i: Int) -> UInt32 { 1 + UInt32(k * segments + (i % segments)) }
        for i in 0..<segments { s.tri(c, idx(0, i + 1), idx(0, i)) }
        for k in 0..<(rings - 1) { for i in 0..<segments { s.quad(idx(k, i), idx(k, i + 1), idx(k + 1, i + 1), idx(k + 1, i)) } }
        s.recomputeNormals(weldSeams: true)
        if let n = s.normals.first, (n.y < 0) == up { s = s.flipped() }
        s.computeTangents()
        return s
    }

    /// Thin ragged annulus (ring stain) between radii `r0` and `r1`, following a height field.
    static func ringDecal(center: V2, r0: Float, r1: Float, lift: Float = 0.0004, segments: Int = 56, material: MaterialKey,
                          height: (Float, Float) -> Float) -> Surface {
        var s = Surface(material: material)
        for k in 0..<2 { for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            let wob = 1 + 0.035 * sin(a * 3 + 1) + 0.02 * sin(a * 7)
            let r = (k == 0 ? r0 : r1) * wob + (k == 1 ? 0.0006 * sin(a * 5) : 0)
            let x = center.x + cos(a) * r, z = center.y + sin(a) * r
            s.add(V3(x, height(x, z) + lift, z), .up, V2(x, z))
        }}
        let row = UInt32(segments + 1)
        for i in 0..<segments { let a = UInt32(i); s.quad(a, a + 1, a + row + 1, a + row) }
        s.recomputeNormals(weldSeams: true)
        if let n = s.normals.first, n.y < 0 { s = s.flipped() }
        s.computeTangents()
        return s
    }

    /// Closed rounded-rectangle path in XZ at height `y`.
    static func railPath(w: Float, d: Float, radius: Float, y: Float, segments: Int = 5) -> [V3] {
        Shape2D.rounded(Shape2D.rect(w, d), radius: radius, segments: segments).map { V3($0.x, y, -$0.y) }
    }

    /// Hem roll: round bead of `r` along a closed path.
    static func bead(path: [V3], r: Float, sides: Int = 5, material: MaterialKey) -> Surface {
        Prim.sweep(Shape2D.circle(r, segments: sides), along: path, up: .up, closedPath: true, caps: false, material: material)
    }

    /// Upright wall of `h` x `t` meters along a closed path whose bottom sits at the path height.
    static func wall(path: [V3], h: Float, t: Float, radius: Float = 0.0008, material: MaterialKey) -> Surface {
        let prof = Shape2D.roundedRect(h, t, radius: radius, segments: 2).map { V2($0.x + h / 2, $0.y) }
        return Prim.sweep(prof, along: path, up: .up, closedPath: true, caps: false, material: material)
    }

    /// Perimeter of a slab grid following its heights, for beads and stitch rows. `inset` pulls the path inward.
    static func edgePath(halfX: Float, halfZ: Float, inset: Float, step: Float, lift: Float, height: (Float, Float) -> Float) -> [V3] {
        let a = halfX - inset, b = halfZ - inset
        var pts: [V2] = []
        func run(_ p: V2, _ q: V2) {
            let n = max(1, Int(simd_distance(p, q) / step))
            for k in 0..<n { pts.append(p + (q - p) * (Float(k) / Float(n))) }
        }
        run(V2(-a, -b), V2(a, -b)); run(V2(a, -b), V2(a, b)); run(V2(a, b), V2(-a, b)); run(V2(-a, b), V2(-a, -b))
        return pts.map { V3($0.x, height($0.x, $0.y) + lift, $0.y) }
    }
}
