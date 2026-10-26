import simd
import Foundation

/// Beaux-Arts acanthus leaf corbel, 0.5 m tall: a carved S-scroll console in limestone under a cyma and
/// abacus, three tiers of layered acanthus lobes following the scroll, side volutes and a pendant
/// acorn. One lobe is broken off and the abacus is sooted. Wall plane at z = 0.
public struct AcanthusLeafCorbel: RealAsset {
    public static let id = "acanthus-leaf-corbel"
    public static let summary = "Beaux-Arts acanthus corbel, 0.5 m tall: carved limestone S-scroll bracket with layered acanthus leaves, abacus-capped top, wall plate and a chipped lower tip."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 42, elevation: 12, distance: 1.5)

    /// Console body stone.
    public var body: MaterialKey = "stone.cast-stone"
    /// Carved leaves.
    public var leaf: MaterialKey = "stone.limestone"
    /// Sooted abacus and soffit.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    public init() {}

    /// Outer scroll curve from the pendant tip (z out, y up).
    static let curve: [V2] = [V2(0.04, 0.085), V2(0.085, 0.12), V2(0.13, 0.19), V2(0.18, 0.28), V2(0.235, 0.37), V2(0.275, 0.435)]

    func point(_ t: Float) -> (p: V2, d: V2) {
        let c = Self.curve
        let f = t * Float(c.count - 1), i = min(Int(f), c.count - 2), u = f - Float(i)
        let p0 = c[max(i - 1, 0)], p1 = c[i], p2 = c[i + 1], p3 = c[min(i + 2, c.count - 1)]
        func cr(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
            0.5 * ((2 * b) + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u * u + (-a + 3 * b - 3 * c + d) * u * u * u)
        }
        func dcr(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
            0.5 * ((-a + c) + 2 * (2 * a - 5 * b + 4 * c - d) * u + 3 * (-a + 3 * b - 3 * c + d) * u * u)
        }
        let p = V2(cr(p0.x, p1.x, p2.x, p3.x), cr(p0.y, p1.y, p2.y, p3.y))
        let d = simd_normalize(V2(dcr(p0.x, p1.x, p2.x, p3.x), dcr(p0.y, p1.y, p2.y, p3.y)))
        return (p, d)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Wall plate behind the console.
        FA.box(&m, V3(0.2, 0.37, 0.02), V3(0, 0.255, 0.01), body, r: 0.004)
        // Console body: dense outline from the curve, wall side straight.
        var outline: [V2] = [V2(0.0, 0.07)]
        for i in 0...24 { let q = point(Float(i) / 24).p; outline.append(V2(q.x - 0.012, q.y - 0.004)) }
        outline += [V2(0.255, 0.445), V2(0.0, 0.445)]
        FA.side(&m, Shape2D.deduped(outline), thick: 0.17, at: .zero, body, bevel: 0.004)
        // Soffit chamfer pieces and fillets along both arrises of the console.
        for s: Float in [-1, 1] {
            let path = (0...12).map { i -> V3 in let q = point(Float(i) / 12).p; return V3(s * 0.085, q.y - 0.004, q.x - 0.012) }
            FA.path(&m, path, r: 0.0065, body, sides: 8)
        }
        // Cyma under the abacus and the abacus slab with a thin fillet.
        var cyma: [V2] = [V2(0.0, 0.44), V2(0.2, 0.44)]
        cyma += FL.ogee(from: V2(0.2, 0.44), to: V2(0.285, 0.47), steps: 6)
        cyma += [V2(0.285, 0.472), V2(0.0, 0.472)]
        FA.side(&m, cyma, thick: 0.25, at: .zero, sooted, bevel: 0.002)
        FA.box(&m, V3(0.3, 0.03, 0.3), V3(0, 0.485, 0.15), sooted, r: 0.004)
        FA.box(&m, V3(0.292, 0.006, 0.292), V3(0, 0.4695, 0.146), sooted, r: 0.002)
        // Acanthus: three tiers, each a fan of pointed lobes laid on the scroll with a second, lifted fan
        // over the gaps; tips pitch outward and every lobe carries a raised midrib.
        func lobe(base: V3, theta: Float, fan: Float, pitch: Float, w: Float, l: Float, lift: Float, _ mat: MaterialKey, _ nrm: V2) {
            let outline = Shape2D.superellipse(w, l, exponent: 1.7, segments: 18).map { $0 + V2(0, l / 2) }
            let q = FA.q(theta * 180 / .pi, FA.X) * FA.q(fan, FA.Z) * FA.q(pitch, FA.X)
            let at = base + V3(0, nrm.y * lift, nrm.x * lift)
            m.add(Prim.extrude(outline, depth: 0.012, bevel: 0.0025, bevelSegments: 1, material: mat), Xform(translation: at, rotation: q))
            m.add(Prim.tube([V3(0, 0.01, 0.0075), V3(0, l * 0.9, 0.0075)], radii: [0.0035, 0.0012], sides: 5, seamTile: 0.1, material: mat, capEnd: true),
                  Xform(translation: at, rotation: q))
        }
        let tiers: [(t: Float, l: Float, w: Float)] = [(0.08, 0.095, 0.052), (0.38, 0.105, 0.054), (0.66, 0.1, 0.054)]
        for (ti, tier) in tiers.enumerated() {
            let (p, d) = point(tier.t)
            let theta = atan2(d.x, d.y)
            let nrm = V2(d.y, -d.x)
            for k in 0..<5 {
                let f = Float(k) - 2
                let broken = ti == 0 && k == 4
                let l = tier.l * (1 - 0.1 * abs(f))
                let base = V3(f * 0.03, p.y, p.x)
                lobe(base: base, theta: theta, fan: -f * 9, pitch: 8 + abs(f) * 3, w: tier.w, l: broken ? l * 0.55 : l, lift: 0.002, broken ? body : leaf, nrm)
                if broken {
                    m.add(Prim.superellipsoid(V3(0.03, 0.012, 0.012), exponent: 2, subdivisions: 3, material: "stone.limestone"),
                          Xform(translation: base + V3(0, d.y * l * 0.5 + nrm.y * 0.012, d.x * l * 0.5 + nrm.x * 0.012), rotation: FA.q(theta * 180 / .pi, FA.X)))
                }
            }
            for k in 0..<4 {
                let f = Float(k) - 1.5
                let base = V3(f * 0.036, p.y + d.y * 0.045, p.x + d.x * 0.045)
                lobe(base: base, theta: theta, fan: -f * 8, pitch: 20, w: tier.w * 0.85, l: tier.l * 0.8, lift: 0.011, leaf, nrm)
            }
        }
        // Side volutes: a spiral bead rolling in on each flank with a central eye, inside a raised disc.
        for s: Float in [-1, 1] {
            let cx = s * 0.0875, cy: Float = 0.18, cz: Float = 0.095
            FA.cylX(&m, r: 0.052, h: 0.006, at: V3(cx + s * 0.002, cy, cz), body, bevel: 0.002, segments: 22)
            let spiral = (0...56).map { i -> V3 in
                let a = Float(i) / 56 * 11.5
                let r = 0.005 + 0.0039 * a
                return V3(cx + s * 0.007, cy + r * sin(a * s), cz + r * cos(a * s))
            }
            FA.path(&m, spiral, r: 0.0052, leaf, sides: 6)
            m.add(Prim.superellipsoid(V3(0.016, 0.016, 0.016), exponent: 2, subdivisions: 4, material: leaf), Xform(translation: V3(cx + s * 0.008, cy, cz)))
        }
        // Pendant acorn at the foot.
        m.add(Prim.lathe([V2(0.0, 0.0), V2(0.018, 0.012), V2(0.026, 0.035), V2(0.02, 0.06), V2(0.03, 0.068), V2(0.0, 0.07)], segments: 14, material: leaf),
              Xform(translation: V3(0, 0.0, 0.04)))
        // Wear: rain streaks on the flanks, moss and a spalled corner on the abacus.
        for s: Float in [-1, 1] {
            for (z, y, h) in [(0.05, 0.35, 0.11), (0.1, 0.33, 0.14), (0.15, 0.37, 0.08)] as [(Float, Float, Float)] {
                FA.box(&m, V3(0.003, h, 0.011), V3(s * 0.0865, y, z), "stone.limestone-sooted", r: 0.001)
            }
        }
        m.add(Prim.superellipsoid(V3(0.07, 0.014, 0.05), exponent: 2.4, subdivisions: 5, material: "moss.cushion"), Xform(translation: V3(0.09, 0.5, 0.24)))
        FA.box(&m, V3(0.04, 0.012, 0.03), V3(-0.13, 0.494, 0.285), "stone.limestone", r: 0.003, rot: FA.q(-14, FA.Y))
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
