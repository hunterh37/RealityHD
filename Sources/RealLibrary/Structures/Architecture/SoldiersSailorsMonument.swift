import simd
import Foundation

/// Soldiers and Sailors Monument, Flagstaff Hill, Boston Common (Martin Milmore, 1877), 38 m: three granite
/// steps, a pedestal with four bronze relief panels and four seated bronze figures on corner buttresses,
/// a die and attic, a band of four standing figures at the column foot, a Roman Doric granite column and
/// the bronze America with flag and sword on top. Centered on X/Z, base at y = 0.
public struct SoldiersSailorsMonument: RealAsset {
    public static let id = "soldiers-sailors-monument"
    public static let summary = "Flagstaff Hill Civil War monument, 38 m: stepped granite base, pedestal with bronze reliefs and seated corner figures, Doric column, bronze America on top."
    public static let tags = ["structure", "architecture", "park", "outdoor", "stone", "metal", "ornament"]
    public static let budget = 30000
    public static let author = "hunterh37"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.0)

    /// Overall height to the top of the statue (m).
    public var height: Float = 38
    /// Width of the bottom step (m).
    public var baseWidth: Float = 11.5
    /// Column lower diameter (m).
    public var columnDiameter: Float = 2.0
    /// Granite material for steps, pedestal and column.
    public var granite: MaterialKey = "stone.cast-grey:A29E95"
    /// Fine-grained dressed granite for the column shaft.
    public var shaftStone: MaterialKey = "stone.limestone-sooted:ABA79F"
    /// Foot-worn granite for the steps.
    public var stepStone: MaterialKey = "stone.granite-curb:8E8B85"
    /// Bronze for the figures and reliefs.
    public var bronze: MaterialKey = "metal.bronze-cast:4A3B26"
    /// Weathered green bronze for the reliefs and the America statue.
    public var patina: MaterialKey = "metal.copper-patina:5E7F6C"
    /// Rain streak and soot strength on the granite.
    public var weathering: Float = 0.75
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let full = model(seed: seed, detail: true)
        let lite = model(seed: seed, detail: false)
        return LODModel(levels: [full, lite], switchDistances: [60])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let g = granite, k: Float = height / 38
        // Three granite steps.
        var y: Float = 0
        let stepH: Float = 0.45 * k
        for i in 0..<3 {
            let w = baseWidth - Float(i) * 1.2 * k
            m.add(Prim.roundedBox(V3(w, stepH, w), radius: 0.05, bevelSegments: 2, material: stepStone), Xform(translation: V3(0, y + stepH / 2, 0)))
            y += stepH
        }
        // Base block with a molded plinth.
        let bw: Float = 8.0 * k
        m.add(Prim.roundedBox(V3(bw, 0.3 * k, bw), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, y + 0.15 * k, 0)))
        y += 0.3 * k
        m.add(Prim.roundedBox(V3(bw - 0.3 * k, 0.6 * k, bw - 0.3 * k), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, y + 0.3 * k, 0)))
        y += 0.6 * k
        // Corner buttresses carrying the seated figures.
        let bs: Float = 1.9 * k, bh: Float = 1.6 * k, bc = bw / 2 - bs / 2 - 0.1 * k
        let figs: [(StatueKit.Attribute, Bool)] = [(.branch, false), (.tablet, false), (.sword, true), (.anchor, true)]
        for (i, (sx, sz)) in [(Float(1), Float(1)), (-1, 1), (-1, -1), (1, -1)].enumerated() {
            let c = V3(sx * bc, y, sz * bc)
            m.add(Prim.roundedBox(V3(bs, bh, bs), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: c + V3(0, bh / 2, 0)))
            m.add(Prim.roundedBox(V3(bs + 0.2 * k, 0.22 * k, bs + 0.2 * k), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: c + V3(0, bh + 0.11 * k, 0)))
            let yaw = atan2(sx, sz) * 180 / .pi
            seatedFigure(&m, at: c + V3(0, bh + 0.22 * k, 0) + V3(sx, 0, sz) * 0.08 * k, yaw: yaw, h: 2.9 * k, mat: bronze,
                             attribute: figs[i].0, helmet: figs[i].1, seed: seed &+ UInt64(i), detail: detail)
        }
        // Die with four bronze reliefs.
        let dw: Float = 5.0 * k, dh: Float = 3.2 * k
        m.add(Prim.roundedBox(V3(dw, dh, dw), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, y + dh / 2, 0)))
        for f in 0..<4 {
            let rot = simd_quatf(degrees: Float(f) * 90, axis: V3(0, 1, 0))
            relief(&m, center: V3(0, y + dh * 0.5, 0), d: dw / 2, rot: rot, w: 3.7 * k, h: 1.7 * k, rng: &rng, detail: detail)
        }
        y += dh
        // Cornice over the die: bed molding, corona with a drip, cyma cap.
        y = stack(&m, y: y, [(dw + 0.12 * k, 0.16 * k, 0.06), (dw + 0.45 * k, 0.22 * k, 0.1), (dw + 0.75 * k, 0.3 * k, 0.05), (dw + 0.5 * k, 0.16 * k, 0.07)], material: g)
        // Attic block with a lighter cornice.
        let aw: Float = 3.8 * k, ah: Float = 1.7 * k
        m.add(Prim.roundedBox(V3(aw, ah, aw), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, y + ah / 2, 0)))
        // Raised inscription panels on the attic faces.
        for f in 0..<4 {
            let rot = simd_quatf(degrees: Float(f) * 90, axis: V3(0, 1, 0))
            m.add(Prim.roundedBox(V3(aw * 0.7, ah * 0.55, 0.06), radius: 0.02, bevelSegments: 1, material: g),
                  Xform(translation: rot.act(V3(0, 0, aw / 2)) + V3(0, y + ah / 2, 0), rotation: rot))
        }
        y += ah
        y = stack(&m, y: y, [(aw + 0.1 * k, 0.12 * k, 0.05), (aw + 0.4 * k, 0.24 * k, 0.05), (aw + 0.2 * k, 0.12 * k, 0.05)], material: g)
        // Figure drum: a round core ringed by four standing figures (North, South, East, West).
        let coreR: Float = 1.05 * k, figH: Float = 2.5 * k
        m.add(Prim.cylinder(radius: 1.62 * k, height: 0.35 * k, bevel: 0.03, segments: 40, material: g), Xform(translation: V3(0, y, 0)))
        y += 0.35 * k
        m.add(Prim.cylinder(radius: coreR, height: figH, bevel: 0.02, segments: 32, material: g), Xform(translation: V3(0, y, 0)))
        for f in 0..<4 {
            let a = Float(f) * .pi / 2 + .pi / 4
            standingFigure(&m, at: V3(sin(a), 0, cos(a)) * (coreR + 0.16 * k) + V3(0, y, 0), yaw: a * 180 / .pi, h: figH * 0.96,
                           soldier: f % 2 == 0, detail: detail)
        }
        y += figH
        var dp = ArchProfile(V2(0, 0))
        dp.to(V2(1.55 * k, 0)); dp.ovolo(0.2 * k, 0.12 * k); dp.fillet(0.1 * k); dp.step(-0.1 * k); dp.to(V2(0, dp.end.y))
        m.add(ArchTrimKit.lathe(dp, segments: 32, material: g, maxSeg: 0.4), Xform(translation: V3(0, y, 0)))
        y += dp.end.y
        // Roman Doric column: torus base, plain granite shaft with entasis in drums, astragal, echinus, abacus.
        let r = columnDiameter / 2 * k
        m.add(Prim.roundedBox(V3(2.6 * r, 0.4 * k, 2.6 * r), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, y + 0.2 * k, 0)))
        y += 0.4 * k
        var b = ArchProfile(V2(0, y))
        b.to(V2(r * 1.2, y)); b.torus(r * 0.18); b.step(-r * 0.08); b.fillet(r * 0.05); b.cavetto(r * 0.06, -r * 0.06)
        let by = b.end.y
        b.to(V2(0, by))
        m.add(ArchTrimKit.lathe(b, segments: 32, material: g, maxSeg: 0.4))
        let statueH: Float = 3.3 * k, pedH: Float = 0.7 * k, capH: Float = 1.25 * k
        let reach = statueH * 1.72  // flag finial rises above the head
        let shaftTop = height - reach - pedH - capH
        let r1 = r * 0.84
        var sp = ArchProfile(V2(r, by - 0.01))
        let rows = 10
        for i in 1...rows {
            let t = Float(i) / Float(rows)
            let e = t < 0.33 ? 0 : pow((t - 0.33) / 0.67, 1.6)
            sp.push(V2(r + (r1 - r) * e, by + (shaftTop - by) * t), sharp: false)
        }
        m.add(ArchTrimKit.lathe(sp, segments: detail ? 40 : 24, material: shaftStone, seamTile: 2, maxSeg: 3))
        // Drum joints as shallow beads.
        if false {
            var jy = by + 1.6 * k
            while jy < shaftTop - 0.5 {
                let t = (jy - by) / (shaftTop - by)
                let rr = r + (r1 - r) * (t < 0.33 ? 0 : pow((t - 0.33) / 0.67, 1.6))
                m.add(Prim.torus(major: rr - 0.004, minor: 0.012, segments: 28, sides: 3, material: g), Xform(translation: V3(0, jy, 0)))
                jy += 1.6 * k
            }
        }
        var c = ArchProfile(V2(0, shaftTop))
        c.to(V2(r1, shaftTop)); c.bead(r * 0.06); c.step(-r * 0.03); c.fillet(r * 0.4)
        c.step(r * 0.06); c.fillet(r * 0.03); c.ovolo(r * 0.3, r * 0.24)
        let echTop = c.end.y
        c.to(V2(0, echTop))
        m.add(ArchTrimKit.lathe(c, segments: 32, material: g, maxSeg: 0.4))
        let abH = height - reach - pedH - echTop
        m.add(Prim.roundedBox(V3(r1 * 2.7, abH, r1 * 2.7), radius: 0.06, bevelSegments: 2, material: g), Xform(translation: V3(0, echTop + abH / 2, 0)))
        // Statue pedestal: a low drum and a bronze globe-capped base.
        let pedY = height - reach - pedH
        m.add(turned([(0, 0), (0.75 * k, 0), (0.75 * k, 0.12 * k), (0.62 * k, 0.2 * k), (0.6 * k, 0.55 * k), (0.7 * k, pedH), (0, pedH)], segments: 32, material: g),
              Xform(translation: V3(0, pedY, 0)))
        // America: robed, crowned with laurel, flag in her right hand, sword and laurel wreath in her left.
        StatueKit.standing(&m, at: V3(0, height - reach, 0), yaw: 0, h: statueH, mat: patina, right: .flag, left: .sword,
                           seed: seed &+ 99, detail: detail)
        _ = rng.float()
        ArchTrimKit.weather(&m, seed: seed, amount: weathering)
        groundAO(&m, height: 1.0, floor: 0.55)
        return ArchTrimKit.ground(m)
    }

    /// Square stepped molding: boxes of (width, height, edge radius) stacked from `y`. Returns the top y.
    func stack(_ m: inout Model, y: Float, _ tiers: [(Float, Float, Float)], material: MaterialKey) -> Float {
        var y = y
        for (w, h, r) in tiers {
            m.add(Prim.roundedBox(V3(w, h, w), radius: r, bevelSegments: 1, material: material), Xform(translation: V3(0, y + h / 2, 0)))
            y += h - 0.002
        }
        return y
    }

    /// Bronze relief panel: a frame and a crowd of half-round figures in procession.
    func relief(_ m: inout Model, center: V3, d: Float, rot: simd_quatf, w: Float, h: Float, rng: inout SeededRNG, detail: Bool) {
        let pl = patina
        m.add(Prim.roundedBox(V3(w, h, 0.08), radius: 0.02, bevelSegments: 1, material: pl), Xform(translation: center + rot.act(V3(0, 0, d)), rotation: rot))
        guard detail else { return }
        let n = 6
        for i in 0..<n {
            let x = -w / 2 + 0.3 + (w - 0.6) * (Float(i) + rng.float(-0.2...0.2)) / Float(n - 1)
            let fh = h * rng.float(0.6...0.75)
            let base = V3(x, -h / 2 + 0.12, d + 0.04)
            m.add(Prim.superellipsoid(V3(0.22, fh * 0.62, 0.12), exponent: 2.4, subdivisions: 2, material: pl),
                  Xform(translation: center + rot.act(base + V3(0, fh * 0.31, 0)), rotation: rot))
            m.add(Prim.superellipsoid(V3(0.13, 0.15, 0.1), exponent: 2, subdivisions: 2, material: pl),
                  Xform(translation: center + rot.act(base + V3(0, fh * 0.62 + 0.08, 0.01)), rotation: rot))
            if i % 3 == 1 {
                m.add(Prim.tube([center + rot.act(base + V3(0.12, fh * 0.4, 0.05)), center + rot.act(base + V3(0.2, fh * 1.1, 0.05))], radii: [0.015, 0.012], sides: 4, seamTile: 0.2, material: pl))
            }
        }
    }

    // MARK: Monument figures: articulated legs, arms, heads and kit, readable at monument scale.

    func limb(_ m: inout Model, _ pts: [V3], _ r0: Float, _ r1: Float, _ mat: MaterialKey) {
        let n = pts.count
        m.add(Prim.tube(pts, radii: (0..<n).map { r0 + (r1 - r0) * Float($0) / Float(n - 1) }, sides: 8, seamTile: 0.3, material: mat))
    }

    /// Seated allegorical figure on a block: legs bent at the knee under a lap drape, torso, mantle, head, arms, attribute.
    func seatedFigure(_ m: inout Model, at p: V3, yaw: Float, h: Float, mat: MaterialKey, attribute: StatueKit.Attribute,
                      helmet: Bool, seed: UInt64, detail: Bool) {
        var f = Model(name: "seated")
        let s = h / 1.85, sy = 0.5 * s
        f.add(Prim.roundedBox(V3(0.66, sy, 0.5) * s, radius: 0.03 * s, bevelSegments: 1, material: mat), Xform(translation: V3(0, sy / 2, -0.16 * s)))
        f.add(Prim.superellipsoid(V3(0.42, 0.22, 0.34) * s, exponent: 2.4, subdivisions: 3, material: mat), Xform(translation: V3(0, sy + 0.1 * s, -0.02 * s)))
        for side: Float in [-1, 1] {
            let hip = V3(side * 0.11 * s, sy + 0.1 * s, 0), knee = V3(side * 0.15 * s, sy + 0.12 * s, 0.46 * s)
            let ankle = V3(side * (0.16 + 0.04 * side) * s, 0.09 * s, (0.5 + 0.06 * side) * s)
            limb(&f, [hip, knee], 0.095 * s, 0.075 * s, mat)
            limb(&f, [knee, (knee + ankle) / 2 + V3(0, 0, 0.02 * s), ankle], 0.07 * s, 0.045 * s, mat)
            f.add(Prim.superellipsoid(V3(0.1, 0.08, 0.24) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: ankle + V3(0, -0.04 * s, 0.08 * s)))
        }
        // Drape across the lap, hanging between the knees.
        var drape = Prim.loft([Prim.ring(StatueKit.ellipse(0.27 * s, 0.05 * s, 10), y: sy + 0.2 * s, offset: V3(0, 0, 0.3 * s)),
                               Prim.ring(StatueKit.ellipse(0.24 * s, 0.05 * s, 10), y: sy + 0.08 * s, offset: V3(0, 0, 0.5 * s)),
                               Prim.ring(StatueKit.ellipse(0.2 * s, 0.05 * s, 10), y: 0.2 * s, offset: V3(0, 0, 0.56 * s))],
                              capStart: true, capEnd: true, material: mat)
        if detail { drape = StatueKit.folds(drape, seed: seed, depth: 0.012 * s, y0: 0.2 * s, y1: sy) }
        f.add(drape)
        // Torso, chest and mantle.
        f.add(Prim.superellipsoid(V3(0.36, 0.5, 0.23) * s, exponent: 2.3, subdivisions: 4, material: mat), Xform(translation: V3(0, sy + 0.42 * s, 0.0)))
        f.add(Prim.superellipsoid(V3(0.5, 0.16, 0.3) * s, exponent: 2.4, subdivisions: 3, material: mat), Xform(translation: V3(0, sy + 0.64 * s, -0.01 * s)))
        StatueKit.head(&f, c: V3(0, sy + 0.9 * s, 0.03 * s), s: s, mat: mat, helmet: helmet)
        for side: Float in [-1, 1] {
            let sh = V3(side * 0.24 * s, sy + 0.62 * s, 0)
            let holds = side > 0 && attribute != .none
            let elbow = V3(side * 0.3 * s, sy + 0.36 * s, holds ? 0.12 * s : 0.06 * s)
            let hand = holds ? V3(side * 0.26 * s, sy + 0.32 * s, 0.38 * s) : V3(side * 0.15 * s, sy + 0.22 * s, 0.42 * s)
            limb(&f, [sh, elbow], 0.07 * s, 0.055 * s, mat)
            limb(&f, [elbow, hand], 0.052 * s, 0.04 * s, mat)
            f.add(Prim.superellipsoid(V3(0.08, 0.1, 0.07) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: hand))
            if holds && detail { StatueKit.attribute(&f, attribute, hand: hand, s: s, mat: mat, side: side) }
        }
        m.add(f, Xform(translation: p, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))))
    }

    /// Standing Civil War soldier (frock coat, kepi, rifle at order arms) or sailor (pea jacket, flat cap, hands clasped).
    func standingFigure(_ m: inout Model, at p: V3, yaw: Float, h: Float, soldier: Bool, detail: Bool) {
        var f = Model(name: "standing")
        let s = h / 1.8, mat = bronze
        for side: Float in [-1, 1] {
            let hip = V3(side * 0.1 * s, 0.92 * s, 0), knee = V3(side * 0.11 * s, 0.5 * s, 0.02 * s), ankle = V3(side * 0.12 * s, 0.08 * s, 0)
            limb(&f, [hip, knee], 0.085 * s, 0.065 * s, mat)
            limb(&f, [knee, ankle], 0.062 * s, 0.05 * s, mat)
            f.add(Prim.superellipsoid(V3(0.11, 0.1, 0.27) * s, exponent: 2.4, subdivisions: 2, material: mat), Xform(translation: ankle + V3(0, -0.03 * s, 0.06 * s)))
        }
        // Coat: frock skirt to the knee for the soldier, short jacket for the sailor.
        let hem: Float = soldier ? 0.55 : 0.82
        f.add(Prim.loft([Prim.ring(StatueKit.ellipse(0.25 * s, 0.17 * s, 12), y: hem * s),
                         Prim.ring(StatueKit.ellipse(0.2 * s, 0.14 * s, 12), y: 1.0 * s),
                         Prim.ring(StatueKit.ellipse(0.23 * s, 0.15 * s, 12), y: 1.3 * s),
                         Prim.ring(StatueKit.ellipse(0.21 * s, 0.13 * s, 12), y: 1.45 * s),
                         Prim.ring(StatueKit.ellipse(0.07 * s, 0.06 * s, 12), y: 1.5 * s)], capStart: true, capEnd: true, material: mat))
        f.add(Prim.torus(major: 0.2 * s, minor: 0.02 * s, segments: 14, sides: 4, material: mat), Xform(translation: V3(0, 1.0 * s, 0), scale: V3(1, 1, 0.72)))
        f.add(Prim.superellipsoid(V3(0.5, 0.14, 0.28) * s, exponent: 2.6, subdivisions: 3, material: mat), Xform(translation: V3(0, 1.42 * s, 0)))
        let hc = V3(0, 1.66 * s, 0.01 * s)
        StatueKit.head(&f, c: hc, s: s, mat: mat, helmet: false)
        if soldier {
            // Kepi: tilted crown and visor.
            f.add(Prim.cylinder(radius: 0.1 * s, height: 0.13 * s, bevel: 0.01 * s, segments: 12, bevelSegments: 1, material: mat),
                  Xform(translation: hc + V3(0, 0.08 * s, -0.01 * s), rotation: simd_quatf(degrees: 10, axis: V3(1, 0, 0))))
        } else {
            f.add(Prim.cylinder(radius: 0.13 * s, height: 0.04 * s, bevel: 0.01 * s, segments: 14, bevelSegments: 1, material: mat), Xform(translation: hc + V3(0, 0.1 * s, 0)))
        }
        f.add(Prim.roundedBox(V3(0.16, 0.015, 0.08) * s, radius: 0.005 * s, bevelSegments: 1, material: mat), Xform(translation: hc + V3(0, 0.08 * s, 0.13 * s)))
        for side: Float in [-1, 1] {
            let sh = V3(side * 0.24 * s, 1.42 * s, 0)
            let elbow: V3, hand: V3
            if soldier && side > 0 { elbow = V3(0.3 * s, 1.12 * s, 0.03 * s); hand = V3(0.27 * s, 0.9 * s, 0.1 * s) }
            else if soldier { elbow = V3(-0.28 * s, 1.12 * s, 0.02 * s); hand = V3(-0.26 * s, 0.86 * s, 0.04 * s) }
            else { elbow = V3(side * 0.27 * s, 1.14 * s, 0.06 * s); hand = V3(side * 0.05 * s, 1.0 * s, 0.2 * s) }
            limb(&f, [sh, elbow], 0.065 * s, 0.052 * s, mat)
            limb(&f, [elbow, hand], 0.05 * s, 0.038 * s, mat)
            f.add(Prim.superellipsoid(V3(0.07, 0.09, 0.07) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: hand))
        }
        if soldier {
            // Rifle grounded beside the right foot, muzzle at the shoulder.
            limb(&f, [V3(0.3 * s, 0.04 * s, 0.12 * s), V3(0.3 * s, 0.45 * s, 0.12 * s)], 0.045 * s, 0.04 * s, mat)
            limb(&f, [V3(0.3 * s, 0.45 * s, 0.12 * s), V3(0.29 * s, 1.5 * s, 0.1 * s)], 0.02 * s, 0.016 * s, mat)
        } else if detail {
            // Coiled rope by the left foot.
            f.add(Prim.torus(major: 0.13 * s, minor: 0.035 * s, segments: 14, sides: 5, material: mat), Xform(translation: V3(-0.3 * s, 0.04 * s, 0.12 * s)))
        }
        m.add(f, Xform(translation: p, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))))
    }
}
