import simd
import Foundation

/// Industrial exterior spiral stair, 1.6 m diameter, 2.0 m rise: a 160 mm steel pipe column on a bolted base plate over a grout
/// pad, ten galvanized wedge treads (rib-plate top, welded stiffener rim, radial channel bracket) stacked on spacer sleeves with
/// weld beads, a 130 degree landing, pipe balusters with welded foot flanges, a safety-yellow helical handrail with a mid rail
/// and ball end caps. Zinc dulled to white rust, rust at the weld seams and tread nosings, one new bright replacement tread
/// and a painted replacement baluster.
public struct MetalSpiralStairExterior: RealAsset {
    public static let id = "metal-spiral-stair-exterior"
    public static let summary = "Exterior spiral stair, 1.6 m diameter, 3.0 m high: pipe column, galvanized wedge treads, landing, yellow helical handrail."
    public static let tags = ["prop", "architecture", "facade", "metal", "urban"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 5.6)

    /// Number of risers up to the landing level.
    public var risers = 11
    /// Landing height in meters.
    public var rise: Float = 2.0
    /// Weathered galvanized steel for treads, column and balusters.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Safety-yellow handrail paint.
    public var rail: MaterialKey = "metal.painted:D2A820"
    /// Rust at welds and nosings.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [7])
    }

    /// World point at radius r, angle a (degrees, counter-clockwise seen from above), height y.
    static func P(_ r: Float, _ a: Float, _ y: Float) -> V3 {
        let t = a * .pi / 180
        return V3(r * cos(t), y, -r * sin(t))
    }

    /// Plan-view sector outline in the (x, z) plane written as (x, y) for an extrude that is then stood flat.
    static func sector(_ r0: Float, _ r1: Float, _ a0: Float, _ a1: Float, n: Int) -> [V2] {
        var o: [V2] = []
        for k in 0...n { let a = (a0 + (a1 - a0) * Float(k) / Float(n)) * .pi / 180; o.append(V2(r1 * cos(a), -r1 * sin(a))) }
        for k in 0...max(2, n / 3) { let a = (a1 + (a0 - a1) * Float(k) / Float(max(2, n / 3))) * .pi / 180; o.append(V2(r0 * cos(a), -r0 * sin(a))) }
        return Shape2D.deduped(o)
    }

    /// Flat plate from a plan outline, top face at y.
    func plate(_ m: inout Model, _ outline: [V2], top y: Float, thick: Float, _ mat: MaterialKey, bevel: Float = 0.002) {
        m.add(Prim.extrude(outline, depth: thick, bevel: bevel, bevelSegments: 1, material: mat),
              Xform(translation: V3(0, y - thick / 2, 0), rotation: FA.q(90, FA.X)))
    }

    /// Light bevelled beam: rectangle extruded, oriented along +X then rotated about Y by `deg`.
    func beam(_ m: inout Model, _ len: Float, _ h: Float, _ w: Float, at c: V3, deg: Float, _ mat: MaterialKey) {
        m.add(Prim.extrude([V2(-len / 2, -h / 2), V2(len / 2, -h / 2), V2(len / 2, h / 2), V2(-len / 2, h / 2)], depth: w, bevel: 0.002, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: FA.q(deg, FA.Y)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ri = rise / Float(risers)
        let step: Float = 24, half: Float = 13.5
        let r0: Float = 0.082, r1: Float = 0.80, rb: Float = 0.778
        let nT = risers - 1                                    // wedge treads; tread index `risers - 1` is the landing
        let landA0 = Float(nT) * step - half + 1, landA1: Float = Float(nT) * step + 130
        let tt: Float = 0.010                                   // tread plate thickness
        let replaced = 6
        func yTop(_ a: Float) -> Float { min(rise, (a / step + 1) * ri) }
        // Base: grout pad, plate with anchor bolts and nuts, column pipe, top cap.
        m.add(Prim.cylinder(radius: 0.26, height: 0.03, bevel: 0.004, segments: lite ? 12 : 20, bevelSegments: 1, material: "stone.cast-stone"), Xform(translation: .zero))
        m.add(Prim.cylinder(radius: 0.21, height: 0.016, bevel: 0.002, segments: lite ? 12 : 20, bevelSegments: 1, material: zinc), Xform(translation: V3(0, 0.03, 0)))
        let colTop: Float = rise + 0.13
        m.add(Prim.cylinder(radius: 0.0805, height: colTop - 0.046, bevel: 0.0015, segments: lite ? 12 : 18, bevelSegments: 1, material: zinc), Xform(translation: V3(0, 0.046, 0)))
        m.add(Prim.cylinder(radius: 0.09, height: 0.012, bevel: 0.002, segments: lite ? 12 : 18, bevelSegments: 1, material: zinc), Xform(translation: V3(0, colTop, 0)))
        if !lite {
            for k in 0..<6 {
                let a = Float(k) * 60 + 30
                let p = Self.P(0.17, a, 0.046)
                m.add(Prim.cylinder(radius: 0.011, height: 0.026, bevel: 0.002, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: p))
                m.add(Prim.cylinder(radius: 0.02, height: 0.01, bevel: 0.0015, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: p - V3(0, 0, 0) + V3(0, 0.0, 0)))
            }
            // Gusset ribs welded between column and base plate.
            for k in 0..<4 {
                let a = Float(k) * 90 + 45
                beam(&m, 0.1, 0.07, 0.012, at: Self.P(0.125, a, 0.085), deg: a, zinc)
            }
        }
        // Treads.
        for i in 0..<nT {
            let a = Float(i) * step, y = Float(i + 1) * ri
            let mat: MaterialKey = i == replaced ? "metal.galvanized" : zinc
            let out = Self.sector(r0 + 0.004, r1, a - half, a + half, n: lite ? 4 : 6)
            plate(&m, out, top: y, thick: tt, mat)
            // Welded stiffener rim under the outer edge, and nosing lip.
            if !lite {
                plate(&m, Self.sector(r1 - 0.026, r1, a - half, a + half, n: 4), top: y - tt, thick: 0.03, mat, bevel: 0.0015)
                // Radial channel bracket and the spacer sleeve it welds to.
                beam(&m, r1 - r0 - 0.05, 0.045, 0.034, at: Self.P((r1 + r0) / 2 - 0.02, a, y - tt - 0.0225), deg: a, zinc)
            }
            if !lite {
                // Raised anti-slip ribs, radial, either side of the tread centre line.
                for k in 0..<2 {
                    let aa = a + (Float(k) - 0.5) * 11
                    m.add(Prim.extrude([V2(-0.25, -0.008), V2(0.25, -0.008), V2(0.25, 0.008), V2(-0.25, 0.008)], depth: 0.004, bevel: 0.0005, bevelSegments: 1, material: mat),
                          Xform(translation: Self.P(0.47, aa, y + 0.002), rotation: FA.q(aa, FA.Y) * FA.q(90, FA.X)))
                }
            }
            m.add(Prim.cylinder(radius: 0.0905, height: ri - tt - 0.002, bevel: 0.0015, segments: lite ? 8 : 10, bevelSegments: 1, material: zinc), Xform(translation: V3(0, y - ri + 0.001, 0)))
            if !lite { m.add(Prim.torus(major: 0.0905, minor: 0.0042, segments: 10, sides: 4, material: rust), Xform(translation: V3(0, y - tt - 0.001, 0))) }
        }
        // Landing: wide sector plate on a heavier rim with two radial beams.
        plate(&m, Self.sector(r0 + 0.004, r1, landA0, landA1, n: lite ? 8 : 14), top: rise, thick: 0.012, zinc)
        plate(&m, Self.sector(r1 - 0.03, r1, landA0, landA1, n: lite ? 6 : 8), top: rise - 0.012, thick: 0.05, zinc, bevel: 0.002)
        if !lite {
            for a in [landA0 + 6, (landA0 + landA1) / 2, landA1 - 6] {
                beam(&m, r1 - r0 - 0.05, 0.07, 0.04, at: Self.P((r1 + r0) / 2, a, rise - 0.012 - 0.035), deg: a, zinc)
            }
            for k in 0..<5 {
                let aa = landA0 + 12 + Float(k) * (landA1 - landA0 - 24) / 4
                m.add(Prim.extrude([V2(-0.28, -0.007), V2(0.28, -0.007), V2(0.28, 0.007), V2(-0.28, 0.007)], depth: 0.0035, bevel: 0.0004, bevelSegments: 1, material: zinc),
                      Xform(translation: Self.P(0.46, aa, rise + 0.0018), rotation: FA.q(aa, FA.Y) * FA.q(90, FA.X)))
            }
        }
        // Balusters: two per tread on the outer edge and a post at each landing end, pipe with welded foot flange.
        var baluA: [Float] = []
        for i in 0..<nT { baluA += [Float(i) * step - 5, Float(i) * step + 5] }
        let landStart = landA0 + 4
        var a = landStart
        while a < landA1 - 2 { baluA.append(a); a += 14 }
        baluA.append(landA1 - 3)
        let railH: Float = 0.965
        for (k, ang) in baluA.enumerated() {
            let base = ang >= landA0 ? rise : yTop(max(0, ang))
            let topY = (ang >= landA0 ? rise : yTop(max(0, ang))) + railH - 0.02
            let isPost = ang >= landA1 - 4
            let mat: MaterialKey = k == 7 ? "metal.painted:1E2A3A" : zinc
            let rad: Float = isPost ? 0.0155 : 0.0085
            m.add(Prim.tube([Self.P(rb, ang, base), Self.P(rb, ang, topY)], radii: [rad, rad], sides: lite ? 4 : 6, seamTile: 0.15, material: mat, capEnd: true))
            if !lite {
                m.add(Prim.cylinder(radius: rad * 2.0, height: 0.006, bevel: 0.0012, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: Self.P(rb, ang, base)))
            }
        }
        // Helical handrail (yellow), mid rail, and ball ends. Rail follows the treads, then runs level around the landing.
        func railPts(_ off: Float, _ rr: Float) -> [V3] {
            var pts: [V3] = []
            var t: Float = -5
            while t < Float(nT - 1) * step + 12 { pts.append(Self.P(rr, t, yTop(max(0, t)) + off)); t += 8 }
            var t2 = landA0 + 4
            pts.append(Self.P(rr, t2, rise + off))
            while t2 < landA1 - 3 { t2 += 9; pts.append(Self.P(rr, min(t2, landA1 - 3), rise + off)) }
            return pts
        }
        let hp = railPts(railH, rb)
        // Repainted in sections: three yellows, with sleeve joints between them.
        let cuts = [0, hp.count / 3, 2 * hp.count / 3, hp.count - 1]
        let yellows: [MaterialKey] = [rail, "metal.painted:BE931A", "metal.painted:E0BC30"]
        for k in 0..<3 {
            let seg = Array(hp[cuts[k]...cuts[k + 1]])
            m.add(Prim.tube(seg, radii: Array(repeating: 0.0215, count: seg.count), sides: lite ? 8 : 10, seamTile: 0.15, material: yellows[k], capEnd: true))
        }
        if !lite {
            for k in 1..<3 { m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.05), exponent: 2, subdivisions: 3, material: "metal.painted:1B1B1D"), Xform(translation: hp[cuts[k]])) }
            let mp = railPts(railH * 0.5, rb)
            m.add(Prim.tube(mp, radii: Array(repeating: 0.0125, count: mp.count), sides: 6, seamTile: 0.15, material: zinc, capEnd: true))
            for p in [hp.first!, hp.last!] { m.add(Prim.superellipsoid(V3(0.053, 0.053, 0.053), exponent: 2, subdivisions: 4, material: rail), Xform(translation: p)) }
            // Rust bleed at the foot of the column and under the base plate.
            m.add(Prim.cylinder(radius: 0.212, height: 0.003, bevel: 0.001, segments: 16, bevelSegments: 1, material: rust), Xform(translation: V3(0, 0.0295, 0)))
            m.add(Prim.cylinder(radius: 0.083, height: 0.07, bevel: 0.002, segments: 14, bevelSegments: 1, material: rust), Xform(translation: V3(0, 0.046, 0)))
            // Rust blooms on tread tops at the outer nosing and around the bolts, runs below the rims, flaking at weld seams.
            func bloom(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let t = Float(j) / 8 * 2 * .pi; poly.append(V2(cx + cos(t) * rx * rng.float(0.55...1.1), cz + sin(t) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for i in 0..<nT {
                let aa = Float(i) * step, y = Float(i + 1) * ri
                for _ in 0..<2 {
                    let ang = aa + rng.float(-8...8)
                    let c = Self.P(rng.float(0.6...0.77), ang, 0)
                    bloom(c.x, c.z, rng.float(0.03...0.08), rng.float(0.02...0.05), y: y + 0.0006, rng.chance(0.65) ? rust : "metal.galvanized")
                }
                // Rust run down the column collar and under the rim.
                let ang = aa + rng.float(-6...6)
                FA.box(&m, V3(0.01, 0.0012, 0.045), Self.P(r1 - 0.012, ang, y - 0.01), rust, r: 0.0003, rot: FA.q(ang, FA.Y))
            }
            for _ in 0..<7 {
                let ang = rng.float(landA0 + 8...landA1 - 8)
                let c = Self.P(rng.float(0.55...0.78), ang, 0)
                bloom(c.x, c.z, rng.float(0.04...0.12), rng.float(0.03...0.06), y: rise + 0.0066, rng.chance(0.65) ? rust : "metal.galvanized")
            }
            // Paint chips on the handrail: rust spots where hands land.
            for _ in 0..<7 {
                let i = rng.int(0...(hp.count - 2))
                let p = (hp[i] + hp[i + 1]) / 2
                m.add(Prim.superellipsoid(V3(0.024, 0.008, 0.024), exponent: 2, subdivisions: 2, material: rust), Xform(translation: p + V3(0, 0.0185, 0)))
            }
        }
        groundAO(&m, height: 0.2, floor: 0.75)
        return FC.place(m)
    }
}
