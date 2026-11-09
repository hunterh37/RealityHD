import simd
import Foundation

/// Shared helpers for the wrist wearables. The invisible wrist is an ellipse around the Y axis (59 mm wide in X, 45 mm deep
/// in Z, 17 cm circumference) at the origin; the hand hangs below (-Y). Azimuth ph = 0 is the back of the wrist (+Z, faces front),
/// ph = pi/2 is the outer side (+X).
enum WristKit {
    typealias K = ChestKit
    static let a: Float = 0.031, b: Float = 0.0225

    static func N(_ ph: Float) -> V3 { simd_normalize(V3(sin(ph) / a, 0, cos(ph) / b)) }
    static func T(_ ph: Float) -> V3 { simd_normalize(V3(a * cos(ph), 0, -b * sin(ph))) }
    /// Point on the wrist ellipse at azimuth `ph`, height `y`, `off` metres outside the skin.
    static func P(_ ph: Float, _ y: Float, _ off: Float = 0) -> V3 { V3(a * sin(ph), y, b * cos(ph)) + N(ph) * off }
    /// Local X = tangent, Y = outward normal.
    static func onSurface(_ ph: Float) -> simd_quatf { K.basis(T(ph), N(ph)) }

    /// Rotation taking watch-local axes (dial up +Y, 12 o'clock -Z, 3 o'clock +X) to the worn pose
    /// (dial toward +Z, 12 toward +X, crown toward the hand at -Y).
    static let watchRot = simd_quatf(simd_float3x3(columns: (V3(0, -1, 0), V3(0, 0, 1), V3(-1, 0, 0))))

    /// Path from lug tip (x = +x0) round the back of the wrist to the other lug tip (x = -x0). The path leaves the case at
    /// height `tipZ` and settles onto the skin.
    static func strapPath(x0: Float, tipZ: Float, y: Float, off: Float, count: Int, spread: Float = 0.0115) -> [V3] {
        let p0 = asin(min(0.98, x0 / (a + off)))
        let base = P(p0, y, off).z
        return (0..<count).map { i in
            let ph = p0 + (2 * Float.pi - 2 * p0) * Float(i) / Float(count - 1)
            var p = P(ph, y, off)
            p.z += (tipZ - base) * (1 - smoothstep(x0, x0 + spread, abs(p.x))) * (p.z > 0 ? 1 : 0)
            return p
        }
    }

    static func lengths(_ pts: [V3]) -> [Float] {
        var c: [Float] = [0]
        for i in 1..<pts.count { c.append(c[i - 1] + simd_distance(pts[i], pts[i - 1])) }
        return c
    }

    /// Point, tangent and outward normal (in the XZ plane) at arc length `s` along `pts`.
    static func at(_ pts: [V3], _ cum: [Float], _ s: Float) -> (p: V3, t: V3, n: V3) {
        var lo = 0, hi = cum.count - 1
        while hi - lo > 1 { let mid = (lo + hi) / 2; if cum[mid] <= s { lo = mid } else { hi = mid } }
        let f = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
        let p = lerp(pts[lo], pts[hi], f)
        let t = simd_normalize(pts[min(hi + 1, pts.count - 1)] - pts[max(lo - 1, 0)])
        return (p, t, simd_normalize(simd_cross(t, V3(0, 1, 0))))
    }

    /// Flat shaded box with six faces, UVs in metres. For ticks, plates and slots.
    static func box(_ size: V3, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let h = size / 2
        let faces: [(V3, V3, V3)] = [(V3(1, 0, 0), V3(0, 1, 0), V3(0, 0, 1)), (V3(-1, 0, 0), V3(0, 0, 1), V3(0, 1, 0)),
                                     (V3(0, 1, 0), V3(0, 0, 1), V3(1, 0, 0)), (V3(0, -1, 0), V3(1, 0, 0), V3(0, 0, 1)),
                                     (V3(0, 0, 1), V3(1, 0, 0), V3(0, 1, 0)), (V3(0, 0, -1), V3(0, 1, 0), V3(1, 0, 0))]
        for (n, u, v) in faces {
            let c = n * V3(h.x, h.y, h.z), uu = u * V3(h.x, h.y, h.z), vv = v * V3(h.x, h.y, h.z)
            let i0 = s.add(c - uu - vv, n, V2(-simd_length(uu), -simd_length(vv)))
            let i1 = s.add(c + uu - vv, n, V2(simd_length(uu), -simd_length(vv)))
            let i2 = s.add(c + uu + vv, n, V2(simd_length(uu), simd_length(vv)))
            let i3 = s.add(c - uu + vv, n, V2(-simd_length(uu), simd_length(vv)))
            if simd_dot(simd_cross(u, v), n) > 0 { s.quad(i0, i1, i2, i3) } else { s.quad(i0, i3, i2, i1) }
        }
        s.computeTangents()
        return s
    }

    /// Flat shaded plate (size x thick y x length z) with a 45 degree chamfer on the four top edges. Cheap links and clasp plates.
    static func chamfer(_ size: V3, _ c: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let h = size / 2, c = min(c, h.x * 0.9, h.y * 0.9, h.z * 0.9)
        func face(_ pts: [V3], _ n: V3) {
            var idx: [UInt32] = []
            for p in pts { idx.append(s.add(p, n, V2(p.x + p.z * 0.31, p.y + p.z * 0.57))) }
            let nn = simd_cross(pts[1] - pts[0], pts[2] - pts[0])
            if simd_dot(nn, n) >= 0 { s.quad(idx[0], idx[1], idx[2], idx[3]) } else { s.quad(idx[0], idx[3], idx[2], idx[1]) }
        }
        let t = V3(h.x - c, h.y, h.z - c)
        face([V3(-t.x, h.y, -t.z), V3(-t.x, h.y, t.z), V3(t.x, h.y, t.z), V3(t.x, h.y, -t.z)], V3(0, 1, 0))
        face([V3(-h.x, -h.y, -h.z), V3(h.x, -h.y, -h.z), V3(h.x, -h.y, h.z), V3(-h.x, -h.y, h.z)], V3(0, -1, 0))
        let hy = h.y - c
        // Chamfers (+X, -X, +Z, -Z) then vertical sides.
        face([V3(h.x, hy, -h.z + c), V3(h.x, hy, h.z - c), V3(t.x, h.y, t.z), V3(t.x, h.y, -t.z)], simd_normalize(V3(1, 1, 0)))
        face([V3(-h.x, hy, h.z - c), V3(-h.x, hy, -h.z + c), V3(-t.x, h.y, -t.z), V3(-t.x, h.y, t.z)], simd_normalize(V3(-1, 1, 0)))
        face([V3(h.x - c, hy, h.z), V3(-h.x + c, hy, h.z), V3(-t.x, h.y, t.z), V3(t.x, h.y, t.z)], simd_normalize(V3(0, 1, 1)))
        face([V3(-h.x + c, hy, -h.z), V3(h.x - c, hy, -h.z), V3(t.x, h.y, -t.z), V3(-t.x, h.y, -t.z)], simd_normalize(V3(0, 1, -1)))
        face([V3(h.x, -h.y, h.z), V3(h.x, -h.y, -h.z), V3(h.x, hy, -h.z), V3(h.x, hy, h.z)], V3(1, 0, 0))
        face([V3(-h.x, -h.y, -h.z), V3(-h.x, -h.y, h.z), V3(-h.x, hy, h.z), V3(-h.x, hy, -h.z)], V3(-1, 0, 0))
        face([V3(-h.x, -h.y, h.z), V3(h.x, -h.y, h.z), V3(h.x, hy, h.z), V3(-h.x, hy, h.z)], V3(0, 0, 1))
        face([V3(h.x, -h.y, -h.z), V3(-h.x, -h.y, -h.z), V3(-h.x, hy, -h.z), V3(h.x, hy, -h.z)], V3(0, 0, -1))
        s.computeTangents()
        return s
    }

    /// Parametric grid surface, f(u, v) with u, v in 0...1 (pass 1 at both ends for closed loops). UVs in metres from edge arc lengths.
    static func grid(_ cu: Int, _ cv: Int, flip: Bool = false, material: MaterialKey, _ f: (Float, Float) -> V3) -> Surface {
        var s = Surface(material: material)
        var pos: [[V3]] = []
        for i in 0...cu { pos.append((0...cv).map { f(Float(i) / Float(cu), Float($0) / Float(cv)) }) }
        var ua: [Float] = [0], va: [Float] = [0]
        for i in 1...cu { ua.append(ua[i - 1] + simd_distance(pos[i][0], pos[i - 1][0])) }
        for j in 1...cv { va.append(va[j - 1] + simd_distance(pos[0][j], pos[0][j - 1])) }
        for i in 0...cu { for j in 0...cv { _ = s.add(pos[i][j], .up, V2(ua[i], va[j])) } }
        let row = UInt32(cv + 1)
        for i in 0..<cu { for j in 0..<cv {
            let a0 = UInt32(i) * row + UInt32(j)
            if flip { s.quad(a0, a0 + row, a0 + row + 1, a0 + 1) } else { s.quad(a0, a0 + 1, a0 + row + 1, a0 + row) }
        }}
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }
}
