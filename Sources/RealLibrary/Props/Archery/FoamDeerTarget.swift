import simd
import Foundation

/// 3D foam deer target: standing doe 3D archery target 1.05 m at the shoulder, tan molded foam, white throat and belly, faint vital-zone circle behind the front shoulder, hide-colored ears. Parts: body, head, ears, legs, tail, vital zone, arrow scuffs, base stakes.
public struct FoamDeerTarget: RealAsset {
    public static let id = "foam-deer-target"
    public static let summary = "3D foam whitetail deer target: molded closed-cell foam body, painted vital zone, scuffed from arrow hits."
    public static let tags = ["prop", "archery", "sports", "outdoor", "hunting"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x length, y height, z width). Nose faces +X.
    public var size = V3(1.25, 1.05, 0.45)
    /// Hide tint of the molded foam (sRGB hex).
    public var hide: UInt32 = 0x9C7A52
    /// Belly, throat and tail underside tint (sRGB hex).
    public var white: UInt32 = 0xE6E0D2
    /// Number of scuffed arrow holes on each flank.
    public var holes = 7
    public init() {}

    // Torso stations rump (t 0) to brisket (t 1): half width, dorsal, ventral (fractions of the fit
    // semi-axes 0.17 / 0.30 / 0.30) and centre lift (fraction of 0.6 m depth). Derived from the whitetail plan.
    static let stations: [(t: Float, w: Float, d: Float, v: Float, lift: Float)] = [
        (0.00, 0.30, 0.34, 0.40, 0.10), (0.06, 0.72, 0.74, 0.80, 0.08), (0.17, 0.98, 0.90, 0.92, 0.06),
        (0.30, 0.94, 0.82, 0.70, 0.05), (0.40, 0.88, 0.80, 0.74, 0.03), (0.52, 0.96, 0.84, 0.92, 0.01),
        (0.66, 1.00, 0.88, 1.04, 0.01), (0.78, 0.94, 1.00, 1.10, 0.04), (0.88, 0.82, 0.96, 1.06, 0.04),
        (0.96, 0.62, 0.78, 0.92, 0.02), (1.00, 0.36, 0.52, 0.62, 0.00)]
    static let tc = V3(0, 0.64, 0)
    static let ta = V3(0.52, 0.30, 0.17)
    /// Interpolated (halfWidth, dorsal, ventral, centreY) at asset x.
    static func torsoAt(_ x: Float) -> (Float, Float, Float, Float) {
        let t = min(1, max(0, (x + ta.x) / (2 * ta.x)))
        var j = stations.count - 1
        for (i, st) in stations.enumerated() where st.t >= t { j = i; break }
        let a = stations[max(0, j - 1)], b = stations[j]
        let k0 = (t - a.t) / max(1e-5, b.t - a.t), k = k0 * k0 * (3 - 2 * k0)
        func l(_ p: Float, _ q: Float) -> Float { p + (q - p) * k }
        let e: Float = 0.10, q = t < e ? (e - t) / e : (t > 1 - e ? (t - (1 - e)) / e : 0)
        let cap = sqrt(max(0.0, 1 - q * q)) * 0.995 + 0.005
        return (ta.z * l(a.w, b.w) * cap, ta.y * 0.90 * l(a.d, b.d) * cap, ta.y * 0.82 * l(a.v, b.v) * cap, tc.y + 0.6 * l(a.lift, b.lift))
    }
    static func torsoZ(_ x: Float, _ y: Float) -> Float {
        let (w, d, v, cy) = torsoAt(x)
        let e = (y - (cy + (d - v) / 2)) / ((d + v) / 2)
        return w * sqrt(max(0, 1 - e * e))
    }

    /// Loft of elliptical sections along a path: (center, half width in z, half extent in the path plane).
    func lofted(_ st: [(V3, Float, Float)], n: Int = 20, exponent: Float = 2, cap: Bool = true, material: MaterialKey) -> Surface {
        let rings: [[V3]] = st.indices.map { i in
            let c = st[i].0
            let fwd = simd_normalize(st[min(i + 1, st.count - 1)].0 - st[max(i - 1, 0)].0)
            let u = simd_normalize(simd_cross(V3(0, 0, 1), fwd))
            return (0..<n).map { k in
                let a = Float(k) / Float(n) * 2 * .pi
                let ca = cos(a), sa = sin(a)
                let p = exponent
                let x = (ca < 0 ? -1 : 1) * pow(abs(ca), 2 / p), y = (sa < 0 ? -1 : 1) * pow(abs(sa), 2 / p)
                return c + V3(0, 0, 1) * (st[i].1 * x) + u * (st[i].2 * y)
            }
        }
        return Prim.loft(rings, capStart: cap, capEnd: cap, material: material).flipped()
    }

    func hex(_ base: String, _ c: UInt32) -> MaterialKey { MaterialKey(base + ":" + String(c, radix: 16, uppercase: true)) }

    /// Flat disc or ring projected onto the torso flank (side = +1 / -1 for z).
    func flankDecal(inner: Float, outer: Float, at c: V2, side: Float, lift: Float, sx: Float = 1, sy: Float = 1, material: MaterialKey) -> Surface {
        var s = Prim.lathe([V2(inner, 0), V2((inner + outer) / 2, 0), V2(outer, 0)], segments: 14, material: material)
        s.deform { p in
            let x = c.x + p.x * sx, y = c.y - p.z * sy
            let z = Self.torsoZ(x, y) + lift
            return V3(x, y, side * z)
        }
        return side > 0 ? s.flipped() : s
    }

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: foam.eva-worn foam.eva paint.bow-camo plastic.grime.
        let skin = hex("foam.eva", hide)
        let worn = hex("foam.eva-worn", hide)
        let pale = hex("foam.eva", white)
        let dark = hex("foam.eva", 0x4A3A2A)
        let hoof = hex("foam.eva", 0x2A2420)
        let paint = hex("foam.eva", 0x7A5F3C)
        let id = Xform()

        // Torso: lofted from the whitetail section plan, deep chest, tucked waist, rounded rump.
        let ns = 44
        let tor: [(V3, Float, Float)] = (0..<ns).map { i in
            let x = -Self.ta.x + 2 * Self.ta.x * Float(i) / Float(ns - 1)
            let (w, d, v, cy) = Self.torsoAt(x)
            return (V3(x, cy + (d - v) / 2, 0), max(w, 0.02), (d + v) / 2)
        }
        m.add(lofted(tor, n: 28, exponent: 2.05, material: skin), id)

        // Neck: thick at the withers, tapering to the throat latch.
        let neck: [(V3, Float, Float)] = [(V3(0.22, 0.66, 0), 0.115, 0.17), (V3(0.31, 0.76, 0), 0.098, 0.135), (V3(0.39, 0.86, 0), 0.075, 0.100),
                                          (V3(0.45, 0.93, 0), 0.058, 0.074), (V3(0.48, 0.96, 0), 0.054, 0.066)]
        m.add(lofted(neck, n: 18, material: skin), id)
        // Wedge head: skull, long tapering face, muzzle.
        let head: [(V3, Float, Float)] = [(V3(0.45, 0.945, 0), 0.058, 0.072), (V3(0.50, 0.925, 0), 0.056, 0.066), (V3(0.55, 0.895, 0), 0.040, 0.050),
                                          (V3(0.595, 0.872, 0), 0.030, 0.038), (V3(0.622, 0.860, 0), 0.024, 0.030)]
        m.add(lofted(head, n: 16, material: skin), id)
        m.add(Prim.superellipsoid(V3(0.034, 0.024, 0.040), exponent: 2, subdivisions: 4, material: dark), Xform(translation: V3(0.612, 0.862, 0)))
        for s in [Float(1), -1] {
            m.add(Prim.superellipsoid(V3(0.024, 0.018, 0.010), exponent: 2, subdivisions: 4, material: dark), Xform(translation: V3(0.525, 0.945, s * 0.052)))
            let r = simd_quatf(angle: s * 0.55, axis: V3(1, 0, 0)) * simd_quatf(angle: -0.2, axis: V3(0, 0, 1))
            m.add(Prim.superellipsoid(V3(0.065, 0.18, 0.016), exponent: 2, subdivisions: 6, material: skin), Xform(translation: V3(0.425, 1.0, s * 0.10), rotation: r))
            m.add(Prim.superellipsoid(V3(0.040, 0.13, 0.006), exponent: 2, subdivisions: 5, material: pale), Xform(translation: V3(0.426, 0.995, s * 0.107), rotation: r))
        }
        // White throat patch.
        m.add(Prim.superellipsoid(V3(0.12, 0.07, 0.06), exponent: 2, subdivisions: 5, material: pale),
              Xform(translation: V3(0.47, 0.875, 0), rotation: simd_quatf(angle: -0.6, axis: V3(0, 0, 1))))

        // Tail: short wedge, white underside.
        m.add(Prim.superellipsoid(V3(0.06, 0.17, 0.08), exponent: 2, subdivisions: 6, material: skin),
              Xform(translation: V3(-0.55, 0.77, 0), rotation: simd_quatf(angle: 0.45, axis: V3(0, 0, 1))))
        m.add(Prim.superellipsoid(V3(0.03, 0.13, 0.07), exponent: 2, subdivisions: 5, material: pale),
              Xform(translation: V3(-0.575, 0.75, 0), rotation: simd_quatf(angle: 0.45, axis: V3(0, 0, 1))))

        // Legs: slim, tall, forelegs straight, hind legs with a hock.
        for z in [Float(0.085), -0.085] {
            let fore: [(V3, Float, Float)] = [(V3(0.30, 0.62, z), 0.052, 0.085), (V3(0.31, 0.46, z), 0.040, 0.060), (V3(0.315, 0.30, z), 0.020, 0.026),
                                              (V3(0.31, 0.18, z), 0.015, 0.020), (V3(0.31, 0.075, z), 0.014, 0.019), (V3(0.315, 0.035, z), 0.016, 0.022)]
            m.add(lofted(fore, n: 10, material: skin), id)
            let hind: [(V3, Float, Float)] = [(V3(-0.38, 0.62, z), 0.065, 0.13), (V3(-0.40, 0.46, z), 0.050, 0.085), (V3(-0.455, 0.31, z), 0.026, 0.040),
                                              (V3(-0.43, 0.24, z), 0.016, 0.026), (V3(-0.415, 0.12, z), 0.014, 0.018), (V3(-0.41, 0.075, z), 0.014, 0.018), (V3(-0.405, 0.035, z), 0.016, 0.022)]
            m.add(lofted(hind, n: 10, material: skin), id)
            for hx in [Float(0.318), -0.405] {
                m.add(Prim.superellipsoid(V3(0.05, 0.06, 0.036), exponent: 2.4, subdivisions: 5, material: hoof), Xform(translation: V3(hx, 0.035, z)))
            }
        }

        // Ground-stake base plate with two stake tabs.
        m.add(Prim.roundedBox(V3(0.90, 0.022, 0.44), radius: 0.006, bevelSegments: 2, material: "plastic.grime"), Xform(translation: V3(-0.05, 0.011, 0)))
        for sx in [Float(-0.50), 0.40] {
            m.add(Prim.roundedBox(V3(0.07, 0.018, 0.08), radius: 0.004, bevelSegments: 2, material: "plastic.grime"), Xform(translation: V3(sx, 0.009, 0)))
        }

        // Vital zone, faint paint ring and wash, both sides. Center x +0.12, y 0.66, radius 0.15.
        for s in [Float(1), -1] {
            m.add(flankDecal(inner: 0.0, outer: 0.15, at: V2(0.12, 0.66), side: s, lift: 0.007,
                             material: hex("foam.eva", 0xA48860)), id)
            m.add(flankDecal(inner: 0.138, outer: 0.15, at: V2(0.12, 0.66), side: s, lift: 0.0085, material: paint), id)
            m.add(flankDecal(inner: 0.0, outer: 0.022, at: V2(0.12, 0.66), side: s, lift: 0.0085, material: paint), id)
        }

        // Scuffed arrow holes: dark pits with a lighter torn rim.
        var hr = rng.fork(1)
        for s in [Float(1), -1] {
            for _ in 0..<holes {
                let a = hr.float(0...(2 * .pi)), r = hr.float(0...0.16) * (hr.chance(0.6) ? 0.9 : 1.7)
                let c = V2(0.12 + cos(a) * r, 0.66 + sin(a) * r * 0.9)
                let rad = hr.float(0.007...0.012)
                m.add(flankDecal(inner: 0, outer: rad * 2.1, at: c, side: s, lift: 0.0095, material: hex("foam.eva-worn", 0xC4A878)), id)
                m.add(flankDecal(inner: 0, outer: rad, at: c, side: s, lift: 0.011, material: hex("foam.eva", 0x15110E)), id)
            }
        }

        // Foam seams: spine and flank mold lines.
        func seam(_ pts: [V3]) {
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0016 }, sides: 6, seamTile: 0.05, material: dark), id)
        }
        seam((0...24).map { k in let x = -0.46 + 0.88 * Float(k) / 24; let t = Self.torsoAt(x); return V3(x, t.3 + t.1 - 0.001, 0) })
        for s in [Float(1), -1] {
            seam((0...24).map { k in let x = -0.46 + 0.92 * Float(k) / 24; let y: Float = 0.50; return V3(x, y, s * (Self.torsoZ(x, y) + 0.0008)) })
            seam((0...12).map { k in let y = 0.46 + 0.36 * Float(k) / 12; let x: Float = -0.30; return V3(x, y, s * (Self.torsoZ(x, y) + 0.0008)) })
        }

        groundAO(&m)
        return LODModel(m)
    }
}
