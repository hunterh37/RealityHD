import simd
import Foundation

/// Helpers for the pediment and hood props (fourth facade batch). Same frame as `FA`: wall plane at z = 0,
/// piece projecting toward +Z.
enum FP {
    /// Classical cornice profile (x out from the wall, y up): bed mould, drip, corona with a hawksbill
    /// soffit, cyma recta and a top fillet. `d` is the projection, `h` the height.
    static func cornice(d: Float, h: Float) -> [V2] {
        [V2(0, 0), V2(0.74 * d, 0), V2(0.74 * d, 0.07 * h), V2(0.86 * d, 0.07 * h), V2(0.86 * d, 0.12 * h),
         V2(d, 0.16 * h), V2(d, 0.42 * h), V2(0.94 * d, 0.47 * h), V2(0.80 * d, 0.50 * h), V2(0.74 * d, 0.60 * h),
         V2(0.77 * d, 0.72 * h), V2(0.84 * d, 0.82 * h), V2(0.84 * d, h), V2(0, h)]
    }

    /// Cross-section for a raking or curved moulding, centred on the path (x along Z, y in the path plane).
    static func raking(d: Float, h: Float) -> [V2] {
        [V2(-0.50 * d, -0.50 * h), V2(0.30 * d, -0.50 * h), V2(0.30 * d, -0.40 * h), V2(0.50 * d, -0.34 * h),
         V2(0.50 * d, -0.04 * h), V2(0.40 * d, 0.0), V2(0.18 * d, 0.06 * h), V2(0.10 * d, 0.22 * h),
         V2(0.16 * d, 0.38 * h), V2(0.10 * d, 0.50 * h), V2(-0.50 * d, 0.50 * h)]
    }

    /// Archivolt section: two stepped fasciae and a cyma crown (x along Z from the back, y radial, outer face at +y).
    static func archivolt(d: Float, h: Float) -> [V2] {
        [V2(-0.50 * d, -0.50 * h), V2(0.50 * d, -0.50 * h), V2(0.50 * d, -0.40 * h), V2(0.34 * d, -0.40 * h), V2(0.34 * d, -0.04 * h),
         V2(0.50 * d, 0.0), V2(0.50 * d, 0.14 * h), V2(0.22 * d, 0.2 * h), V2(0.22 * d, 0.36 * h),
         V2(0.36 * d, 0.42 * h), V2(0.30 * d, 0.5 * h), V2(-0.50 * d, 0.50 * h)]
    }

    /// Moulding swept along a planar (x, y) path at depth `z`.
    static func sweepMould(_ m: inout Model, _ pts: [V2], z: Float, d: Float, h: Float, _ mat: MaterialKey) {
        let path = pts.map { V3($0.x, $0.y, z) }
        m.add(Prim.sweep(raking(d: d, h: h), along: path, up: FA.Z, material: mat))
    }

    /// Row of dentil blocks along a straight line or a slope. `skip` drops one block (a chipped dentil).
    static func dentils(_ m: inout Model, from a: V2, to b: V2, z: Float, size: V3, pitch: Float, _ mat: MaterialKey, skip: Int = -1) {
        let dv = b - a
        let len = simd_length(dv)
        let n = max(1, Int(len / pitch))
        let ang = atan2(dv.y, dv.x) * 180 / .pi
        for i in 0..<n where i != skip {
            let t = (Float(i) + 0.5) / Float(n)
            let p = a + dv * t
            FA.box(&m, size, V3(p.x, p.y, z), mat, r: 0.0015, rot: FA.q(ang, FA.Z))
        }
    }

    /// Flat entablature on y = `y0`: two-fascia architrave, plain frieze, optional dentil band, cornice.
    /// Returns the top y.
    @discardableResult
    static func entablature(_ m: inout Model, width W: Float, y0: Float, depth D: Float, height H: Float, dentil: Bool,
                            _ mat: MaterialKey, shadow: MaterialKey, skipDentil: Int = -1) -> Float {
        let A = 0.30 * H, F = 0.27 * H, T = dentil ? 0.13 * H : 0, C = H - A - F - T
        var y = y0
        FA.box(&m, V3(W - 0.02, A * 0.55, 0.46 * D), V3(0, y + A * 0.275, 0.23 * D), mat, r: 0.003)
        FA.box(&m, V3(W - 0.02, A * 0.45, 0.52 * D), V3(0, y + A * 0.55 + A * 0.225, 0.26 * D), mat, r: 0.003)
        FA.box(&m, V3(W - 0.02, 0.006, 0.55 * D), V3(0, y + A - 0.003, 0.275 * D), shadow, r: 0.002)
        y += A
        FA.box(&m, V3(W - 0.04, F, 0.50 * D), V3(0, y + F / 2, 0.25 * D), shadow, r: 0.003)
        y += F
        if dentil {
            FA.box(&m, V3(W - 0.02, T, 0.55 * D), V3(0, y + T / 2, 0.275 * D), mat, r: 0.002)
            dentils(&m, from: V2(-W / 2 + 0.07, y + T / 2), to: V2(W / 2 - 0.07, y + T / 2), z: 0.60 * D,
                    size: V3(0.026, T * 0.9, 0.09 * D), pitch: 0.048, shadow, skip: skipDentil)
            y += T
        }
        FA.run(&m, cornice(d: D, h: C), length: W, at: V3(0, y, 0), mat, bevel: 0.002)
        return y + C
    }

    /// Carved rosette: a dished disc with a ring of petals and a raised boss.
    static func rosette(_ m: inout Model, at c: V3, r: Float, petals: Int = 8, _ mat: MaterialKey, boss: MaterialKey) {
        FA.cylZ(&m, r: r, h: 0.012, at: c, mat, bevel: 0.0015, segments: 24)
        for i in 0..<petals {
            let a = Float(i) / Float(petals) * 2 * .pi
            m.add(Prim.superellipsoid(V3(r * 0.5, r * 0.22, 0.016), exponent: 2, subdivisions: 3, material: mat),
                  Xform(translation: c + V3(cos(a), sin(a), 0) * (r * 0.58) + V3(0, 0, 0.012), rotation: FA.q(a * 180 / .pi, FA.Z)))
        }
        FA.cylZ(&m, r: r * 0.26, h: 0.010, at: c + V3(0, 0, 0.012), boss, bevel: 0.0015, segments: 16)
        FC.bead(&m, r: r * 0.12, at: c + V3(0, 0, 0.026), boss)
    }

    /// Screw head (brass) on a face at z.
    static func screw(_ m: inout Model, at c: V3, _ mat: MaterialKey) {
        FA.cylZ(&m, r: 0.006, h: 0.004, at: c, mat, bevel: 0.0008, segments: 10)
    }
}
