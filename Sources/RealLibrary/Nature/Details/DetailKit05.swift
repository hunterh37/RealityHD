import simd
import Foundation

/// Shared builders for details group 05 (river shore: shells, stones, wrack, cress).
enum DetailKit05 {
    /// Superellipsoid pebble centered at the origin with `size` full extents, lumpy and irregular.
    static func stone(size: V3, rng: inout SeededRNG, sub: Int, e: Float = 2.4, material: MaterialKey) -> Surface {
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        let amp = rng.float(0.03...0.07)
        let a = size / 2
        return Prim.cubeSphere(subdivisions: sub, material: material) { d in
            let k = pow(pow(abs(d.x / a.x), e) + pow(abs(d.y / a.y), e) + pow(abs(d.z / a.z), e), 1 / e)
            let w = 1 + amp * sin(d.x * 3 + ph[0]) * cos(d.z * 3 + ph[1]) + amp * 0.5 * sin(d.y * 4 + ph[2])
            return d / k * w
        }
    }

    /// One mussel valve, hinge at x = -L/2, dome up, rim on y = 0. Outer and nacre inner surfaces.
    static func shell(length L: Float, rng: inout SeededRNG, nu: Int, nv: Int, outer: MaterialKey, inner: MaterialKey) -> (Surface, Surface) {
        let W = L * rng.float(0.45...0.55), H = L * rng.float(0.16...0.22)
        let ph = rng.float(0...6.28), rings = Float(rng.int(14...22))
        var po: [V3] = [], pi_: [V3] = []
        for j in 0...nv { for i in 0...nu {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv) * 2 - 1
            let t = 0.1 + 0.88 * u
            let sw = pow(max(sin(.pi * t), 0), 0.55)
            let wv = W / 2 * sw * (1 + 0.04 * sin(u * 9 + ph))
            let bump = 1 + 0.5 * exp(-pow((u - 0.2) / 0.15, 2)) * (1 - v * v)
            let dome = pow(max(1 - v * v, 0), 0.8) * pow(max(sin(.pi * t), 0), 0.5) * bump
            let r = sqrt(pow(u - 0.12, 2) + pow(v * 0.4, 2))
            let rip = 0.0004 * sin(r * rings * 6) * dome
            let y = H * dome + rip
            let x = u * L - L / 2, z = v * wv
            po.append(V3(x, y, z))
            pi_.append(V3(x, y - 0.0016 * pow(max(1 - v * v, 0), 0.3) * pow(max(sin(.pi * t), 0), 0.3), z))
        } }
        func build(_ pts: [V3], _ mat: MaterialKey, flip: Bool) -> Surface {
            var s = Surface(material: mat)
            for (n, p) in pts.enumerated() {
                let i = n % (nu + 1), j = n / (nu + 1)
                _ = s.add(p, V3(0, flip ? -1 : 1, 0), V2(Float(i) / Float(nu) * L * 4, Float(j) / Float(nv) * W * 4))
            }
            let row = UInt32(nu + 1)
            for j in 0..<UInt32(nv) { for i in 0..<UInt32(nu) {
                let a = j * row + i
                if flip { s.quad(a, a + row, a + row + 1, a + 1) } else { s.quad(a, a + 1, a + row + 1, a + row) }
            } }
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            return s
        }
        // quad winding for the outer dome: normal up when viewed from above (z toward +v).
        return (build(po, outer, flip: false), build(pi_, inner, flip: true))
    }
}
