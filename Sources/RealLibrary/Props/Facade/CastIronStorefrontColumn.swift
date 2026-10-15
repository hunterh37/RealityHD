import simd
import Foundation

/// Victorian Commercial cast-iron storefront column, 3.2 m, foundry-cast in the 1870s: square plinth,
/// torus and scotia base mouldings, a twelve-flute shaft with entasis between astragal beads, a bolted
/// mid-shaft joint flange, a two-row acanthus capital with corner volutes and a moulded abacus.
/// Dark green paint, rust blooming at the base and chipped on the lower shaft.
public struct CastIronStorefrontColumn: RealAsset {
    public static let id = "cast-iron-storefront-column"
    public static let summary = "Victorian cast-iron storefront column, 3.2 m: moulded plinth, fluted shaft with astragal rings, foliate capital, bolted flanges."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "decor"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.35)

    /// Overall height in meters.
    public var height: Float = 3.2
    /// Abacus and plinth width in meters.
    public var width: Float = 0.3
    /// Shaft radius at the base in meters.
    public var shaftRadius: Float = 0.098
    /// Painted surface.
    public var paint: MaterialKey = "metal.painted:2C4636"
    /// Bare cast iron at seams and flange faces.
    public var iron: MaterialKey = "metal.cast-iron"
    /// Corrosion at the base and in chips.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    private static func fluted(r: Float, flutes: Int, depth: Float, per: Int = 4) -> [V2] {
        var pts: [V2] = []
        for k in 0..<(flutes * per) {
            let a = Float(k) / Float(flutes * per) * 2 * .pi
            let u = Float(k % per) / Float(per)
            let rr = r - depth * sin(.pi * u)
            pts.append(V2(cos(a) * rr, sin(a) * rr))
        }
        return pts
    }

    private static func leaf(w: Float, h: Float) -> [V2] {
        let right: [V2] = [V2(0.28 * w, 0), V2(0.5 * w, 0.3 * h), V2(0.46 * w, 0.55 * h), V2(0.34 * w, 0.62 * h),
                           V2(0.4 * w, 0.78 * h), V2(0.2 * w, 0.86 * h), V2(0.08 * w, h)]
        let left = right.reversed().dropFirst().map { V2(-$0.x, $0.y) }
        return right + left + [V2(-0.28 * w, 0)]
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, R = shaftRadius
        let yBase: Float = 0.28, yShaft0: Float = 0.31, yShaft1: Float = 2.87, yCap: Float = 2.90

        // Plinth: square block with a chamfered, stepped top.
        FA.box(&m, V3(W, 0.09, W), V3(0, 0.045, 0), paint, r: 0.004)
        FA.box(&m, V3(W - 0.04, 0.05, W - 0.04), V3(0, 0.115, 0), paint, r: 0.004)
        // Base mouldings: lower torus, scotia, upper torus, fillet up to the shaft.
        let baseProfile: [V2] = [V2(0, 0.14), V2(0.128, 0.14), V2(0.136, 0.148), V2(0.14, 0.16), V2(0.136, 0.172), V2(0.12, 0.18),
                                 V2(0.105, 0.186), V2(R + 0.012, 0.19), V2(R + 0.02, 0.2), V2(0.118, 0.212), V2(0.126, 0.224),
                                 V2(0.128, 0.236), V2(0.122, 0.25), V2(0.108, 0.26), V2(R + 0.012, 0.268), V2(R + 0.004, yBase), V2(0, yBase)]
        m.add(turned(baseProfile.map { ($0.x, $0.y) }, segments: 36, material: paint, seamTile: 0.3))
        // Rust bloom skirt where water pools on the plinth.
        FA.box(&m, V3(W + 0.002, 0.012, W + 0.002), V3(0, 0.006, 0), rust, r: 0.003)
        // Astragal beads at both ends of the shaft.
        for y in [yBase + 0.012, yShaft1 + 0.014] {
            m.add(Prim.torus(major: R + 0.002, minor: 0.011, segments: 32, sides: 8, material: paint), Xform(translation: V3(0, y, 0)))
        }
        // Shaft: 12 flutes, entasis swelling a third of the way up, taper toward the capital.
        let rings: [[V3]] = (0...8).map { i in
            let t = Float(i) / 8
            let r = R * (1 - 0.1 * t) * (1 + 0.012 * sin(.pi * min(1, t * 1.4)))
            return Prim.ring(Self.fluted(r: r, flutes: 12, depth: 0.011), y: yShaft0 + (yShaft1 - yShaft0) * t)
        }
        m.add(Prim.loft(rings, capStart: true, capEnd: true, material: paint))
        // Bolted joint flange at mid-height (sections of the column cast in two lengths).
        let yJ: Float = 1.55
        let rJ = R * (1 - 0.1 * ((yJ - yShaft0) / (yShaft1 - yShaft0)))
        m.add(turned([(0, yJ - 0.02), (rJ + 0.026, yJ - 0.02), (rJ + 0.03, yJ - 0.015), (rJ + 0.03, yJ + 0.015), (rJ + 0.026, yJ + 0.02), (0, yJ + 0.02)],
                     segments: 32, material: paint, seamTile: 0.3))
        m.add(Prim.torus(major: rJ + 0.026, minor: 0.004, segments: 32, sides: 6, material: iron), Xform(translation: V3(0, yJ, 0)))
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi + .pi / 8
            hexBolt(&m, at: V3((rJ + 0.031) * cos(a), yJ, (rJ + 0.031) * sin(a)), normal: V3(cos(a), 0, sin(a)), size: 0.014, material: iron)
        }
        // Casting seams: thin raised lines down the plinth corners.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.rod(&m, V3(sx * W / 2, 0.012, sz * W / 2), V3(sx * W / 2, 0.088, sz * W / 2), r: 0.0018, iron, sides: 4)
        } }

        // Capital: neck ring, bell, two staggered rows of acanthus leaves, corner volutes, abacus.
        let bell: [V2] = [V2(0, yCap), V2(R * 0.9 + 0.008, yCap), V2(R * 0.9 + 0.012, yCap + 0.012), V2(R * 0.9 + 0.004, yCap + 0.025),
                          V2(0.1, yCap + 0.05), V2(0.112, yCap + 0.12), V2(0.12, yCap + 0.2), V2(0.124, yCap + 0.24), V2(0, yCap + 0.24)]
        m.add(turned(bell.map { ($0.x, $0.y) }, segments: 32, material: paint, seamTile: 0.3))
        for row in 0..<2 {
            let n = 8, rr: Float = row == 0 ? 0.093 : 0.098
            let w: Float = row == 0 ? 0.092 : 0.086, h: Float = row == 0 ? 0.15 : 0.19
            let y0 = yCap + (row == 0 ? 0.025 : 0.07)
            for k in 0..<n {
                let a = (Float(k) + (row == 0 ? 0 : 0.5)) / Float(n) * 2 * .pi + rng.float(-0.02...0.02)
                let yaw = FA.q(90 - a * 180 / .pi, FA.Y), tilt = FA.q(row == 0 ? 8 : 13, FA.X)
                m.add(Prim.extrude(Self.leaf(w: w, h: h * rng.float(0.96...1.04)), depth: 0.008, bevel: 0.0022, bevelSegments: 1, material: paint),
                      Xform(translation: V3(rr * cos(a), y0, rr * sin(a)), rotation: yaw * tilt))
                // Midrib standing proud of the leaf face.
                let tl = yaw * tilt
                let p0 = V3(rr * cos(a), y0, rr * sin(a)) + tl.act(V3(0, 0.01, 0.007)), p1 = V3(rr * cos(a), y0, rr * sin(a)) + tl.act(V3(0, h * 0.8, 0.007))
                FA.rod(&m, p0, p1, r: 0.0022, paint, sides: 4)
            }
        }
        // Volutes at the four abacus corners, each a tube spiral with a bead eye.
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            let dir = V3(cos(a), 0, sin(a)), side = V3(-sin(a), 0, cos(a))
            for s: Float in [-1, 1] {
                var pts: [V3] = []
                for j in 0...9 {
                    let t = Float(j) / 9, ang = t * 1.7 * .pi, rad = 0.03 * (1 - t * 0.65)
                    pts.append(dir * (0.108 + rad * sin(ang) * 0.4) + side * (s * (0.018 + rad * (1 - cos(ang)) * 0.6)) + V3(0, yCap + 0.2 - rad * cos(ang) * 0.9, 0))
                }
                FA.path(&m, pts, r: 0.0045, paint, sides: 6)
            }
        }
        // Abacus: concave-sided slab with ogee cap moulding.
        let yA = yCap + 0.24
        var abOutline: [V2] = []
        let hw = W / 2
        for i in 0..<4 {
            let rot = Float(i) * .pi / 2
            for j in 0...6 {
                let t = Float(j) / 6, x = -hw + W * t, z = hw - 0.02 * sin(.pi * t)
                abOutline.append(V2(x * cos(rot) - z * sin(rot), x * sin(rot) + z * cos(rot)))
            }
        }
        abOutline = Shape2D.deduped(abOutline)
        m.add(Prim.loft([Prim.ring(abOutline, y: yA - 0.02), Prim.ring(abOutline, y: yA + 0.045)], capStart: true, capEnd: true, material: paint))
        FA.box(&m, V3(W - 0.002, 0.022, W - 0.002), V3(0, yA + 0.056, 0), paint, r: 0.005)
        m.add(Prim.loft([Prim.ring(Shape2D.roundedRect(W - 0.03, W - 0.03, radius: 0.008), y: yA + 0.045),
                         Prim.ring(Shape2D.roundedRect(W - 0.008, W - 0.008, radius: 0.004), y: yA + 0.054)], material: paint))

        // Rust streaks running down from each flange bolt, bare iron chipped at the plinth corners.
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi + .pi / 8
            let rr = rJ + 0.002
            m.add(Prim.superellipsoid(V3(0.007, rng.float(0.05...0.12), 0.003), exponent: 2.4, subdivisions: 2, material: rust),
                  Xform(translation: V3(rr * cos(a), yJ - 0.07, rr * sin(a)), rotation: FA.q(90 - a * 180 / .pi, FA.Y)))
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.03, 0.02, 0.03), V3(sx * (W / 2 - 0.0155), 0.092, sz * (W / 2 - 0.0155)), iron, r: 0.004)
            FA.box(&m, V3(0.012, 0.03, 0.012), V3(sx * (W / 2 - 0.0085), 0.03, sz * (W / 2 - 0.0085)), rust, r: 0.003)
        } }
        // Story detail: paint chips down to rust on the shaft's lower flutes (street-side).
        for _ in 0..<14 {
            let a = rng.float(-0.9...0.9) + .pi / 2, y = rng.float(0.34...0.9)
            let rr = R * 0.98
            m.add(Prim.superellipsoid(V3(rng.float(0.014...0.03), rng.float(0.02...0.05), 0.003), exponent: 2.4, subdivisions: 2, material: rust),
                  Xform(translation: V3(rr * cos(a), y, rr * sin(a)), rotation: FA.q(90 - a * 180 / .pi, FA.Y)))
        }
        // Rust bloom creeping up the base mouldings and bare iron band where the flange paint wore through.
        for k in 0..<10 {
            let a = Float(k) / 10 * 2 * .pi + rng.float(-0.1...0.1)
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), rng.float(0.02...0.06), 0.004), exponent: 2.4, subdivisions: 2, material: rust),
                  Xform(translation: V3(0.138 * cos(a), rng.float(0.15...0.25), 0.138 * sin(a)), rotation: FA.q(90 - a * 180 / .pi, FA.Y)))
        }
        m.add(Prim.torus(major: rJ + 0.0305, minor: 0.0035, segments: 32, sides: 6, material: iron), Xform(translation: V3(0, yJ + 0.012, 0)))
        groundAO(&m, height: 0.3, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
