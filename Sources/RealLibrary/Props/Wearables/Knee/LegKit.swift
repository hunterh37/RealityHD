import simd
import Foundation

/// Shared helpers for the knee wearables. The invisible leg is a circular cylinder on the Y axis: thigh above the knee
/// (y > 0, radius 6.05 cm widening to 8.75 cm), calf and shin below (6.5 cm at the calf, 4.1 cm near the ankle).
/// Azimuth th = 0 faces front (+Z, kneecap), th = pi/2 is the outer side (+X, wearer's left), th = pi the back.
enum LegKit {
    typealias K = ChestKit

    static func R(_ y: Float) -> Float {
        if y >= 0 { return 0.0605 + 0.0270 * smoothstep(0, 0.22, y) }
        let t = -y
        return 0.0605 - 0.0020 * smoothstep(0, 0.06, t) + 0.0065 * smoothstep(0.05, 0.17, t) - 0.0235 * smoothstep(0.17, 0.42, t)
    }

    /// Point at azimuth `th`, height `y`, `off` metres outside the limb surface.
    static func P(_ th: Float, _ y: Float, _ off: Float = 0) -> V3 {
        let r = R(y) + off
        return V3(sin(th) * r, y, cos(th) * r)
    }

    static func nrm(_ p: V3) -> V3 {
        let h = V3(p.x, 0, p.z)
        return simd_length(h) > 1e-6 ? simd_normalize(h) : V3(0, 0, 1)
    }

    static func tangent(_ th: Float) -> V3 { V3(cos(th), 0, -sin(th)) }

    /// Closed ring path around the leg; `bump(th)` adds extra offset (straps rising over hinge bars).
    static func ring(y: Float, off: Float, count: Int, bump: ((Float) -> Float)? = nil) -> [V3] {
        (0..<count).map { let th = 2 * Float.pi * Float($0) / Float(count); return P(th, y, off + (bump?(th) ?? 0)) }
    }

    /// Double walled tube of fabric around the leg with an open top and bottom rim, rim heights varying with azimuth and an
    /// optional window (cells whose (th, y) centre satisfies `hole` are left out). Outer face `off + thick` above the limb.
    static func sleeve(cols: Int, rows: Int, top: (Float) -> Float, bot: (Float) -> Float, off: Float, thick: Float,
                       hole: ((Int, Int) -> Bool)? = nil, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let row = rows + 1
        func yAt(_ th: Float, _ j: Int) -> Float { let b = bot(th), t = top(th); return b + (t - b) * Float(j) / Float(rows) }
        for layer in 0..<2 {
            let o = off + (layer == 0 ? thick : 0)
            for i in 0...cols {
                let th = 2 * Float.pi * Float(i) / Float(cols)
                for j in 0...rows { let y = yAt(th, j); s.add(P(th, y, o), nrm(P(th, y, o)), V2(th * 0.075, y)) }
            }
        }
        let inner = UInt32((cols + 1) * row)
        func id(_ i: Int, _ j: Int) -> UInt32 { UInt32(i * row + j) }
        for i in 0..<cols { for j in 0..<rows {
            if let h = hole, h(i, j) { continue }
            s.quad(id(i, j), id(i + 1, j), id(i + 1, j + 1), id(i, j + 1))
            s.quad(inner + id(i, j), inner + id(i, j + 1), inner + id(i + 1, j + 1), inner + id(i + 1, j))
        }}
        for i in 0..<cols {
            s.quad(id(i, 0), inner + id(i, 0), inner + id(i + 1, 0), id(i + 1, 0))
            s.quad(id(i, rows), id(i + 1, rows), inner + id(i + 1, rows), inner + id(i, rows))
        }
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    /// Bends a flat part authored in local space (x across, y along the leg, z out of the surface) onto the leg: x becomes an
    /// arc length around azimuth `th0`, y stays, z is the offset above the limb.
    static func wrap(_ s: inout Surface, th0: Float, yc: Float, off: Float) {
        s.deform { p in
            let y = yc + p.y
            let th = th0 + p.x / (R(y) + off)
            return P(th, y, off + p.z)
        }
    }

    /// Soft stain: nested flat blobs, widest and palest first, laid on a surface at `p` with outward normal `n`.
    static func stain(_ m: inout Model, rng: inout SeededRNG, at p: V3, normal n: V3, size: Float, aspect: Float = 0.7, layers: [MaterialKey]) {
        let q = facing(n) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)
        for (i, mat) in layers.prefix(2).enumerated() {
            let k = 1 - Float(i) * 0.40
            m.add(Prim.superellipsoid(V3(size * k, 0.00035, size * k * aspect), exponent: 2.2, subdivisions: 3, material: mat),
                  Xform(translation: p - n * (0.00012 - 0.00008 * Float(i)), rotation: q))
        }
    }
}
