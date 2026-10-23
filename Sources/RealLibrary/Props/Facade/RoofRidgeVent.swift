import simd
import Foundation

/// Roof ridge vent: American Traditional asphalt roof at 6:12, 3.0 m of ridge with a slotted black polymer
/// baffle vent over an open ridge slot. The right half is finished with lapped cap shingles and exposed
/// nails; the left half shows the bare vent with its louver slots, nailing line, spacer ribs and end plug.
/// Tabbed field shingles lie on OSB and underlayment, with white fascia, drip edge and gable end at each end.
/// UV chalking on the polymer, lichen, granule loss and rain streaks weather it.
public struct RoofRidgeVent: RealAsset {
    public static let id = "roof-ridge-vent"
    public static let summary = "Roof ridge vent, 3.0 m: baffled vent strip with end caps, nailing slots and ridge cap shingles on an asphalt roof."
    public static let tags = ["prop", "architecture", "facade", "roofline", "trim"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 2.0)

    /// Ridge length in meters.
    public var length: Float = 3.0
    /// Horizontal run from ridge to eave in meters.
    public var run: Float = 0.136
    /// Fraction of the ridge (from the right end) finished with cap shingles.
    public var capped: Float = 0.5
    /// Trim and fascia paint.
    public var trim: MaterialKey = "wood.painted-exterior:8E9C8A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let tn: Float = 0.5                       // 6:12 pitch
        let th = atan(tn), sn = sin(th), cs = cos(th)
        let deg = th * 180 / .pi
        let R = run, yE: Float = 0.093
        let L = R / cs
        let half = length / 2
        let yDeck = yE + R * tn                    // deck plane at the ridge
        func P(_ s: Float, _ x: Float, _ t: Float, _ h: Float = 0) -> V3 {
            V3(x, yE + t * sn + h * cs, s * (R - t * cs + h * sn))
        }
        func slab(_ s: Float, _ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey, r: Float = 0.0012) {
            FA.box(&m, size, P(s, x, t, h), mat, r: r, rot: FA.q(s * deg, FA.X))
        }
        func decal(_ s: Float, _ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey) {
            RK.plate(&m, size, P(s, x, t, h), mat, rot: FA.q(s * deg, FA.X))
        }
        let sh = "roofing.shingle-granule:"
        let tints: [MaterialKey] = [sh + "7C766E", sh + "978F84", sh + "6A655E", sh + "8A8277", sh + "847E75", sh + "5C5751"]
        let rakeBoard = R + 0.004

        // Gable end panels, lapped siding and sloped rake boards.
        let gable: [V2] = [V2(-(R + 0.004), 0), V2(R + 0.004, 0), V2(R + 0.004, yE - 0.006), V2(0, yDeck - 0.014), V2(-(R + 0.004), yE - 0.006)]
        for e: Float in [-1, 1] {
            FA.run(&m, gable, length: 0.02, at: V3(e * (half - 0.012), 0, 0), "wood.plywood-osb", bevel: 0.001)
            for k in 0..<3 {
                let y = 0.03 + Float(k) * 0.045
                let w = max(0.02, min(R, (yDeck - 0.014 - y) / tn))
                FA.box(&m, V3(0.008, 0.044, 2 * w - 0.004), V3(e * (half - 0.0015), y, 0), trim, r: 0.0012)
            }
            for s: Float in [-1, 1] {
                slab(s, V3(0.02, 0.06, L + 0.03), x: e * (half + 0.002), t: L / 2 + 0.01, h: -0.0205, trim, r: 0.002)
            }
        }
        _ = rakeBoard
        // Fascia, bed mould, drip edge, sheathing with a ridge slot, underlayment.
        let slotT = (R - 0.02) / cs                // sheathing stops 20 mm from the ridge
        let mould: [V2] = [V2(0, 0), V2(0.016, 0), V2(0.0155, 0.003), V2(0.013, 0.0075), V2(0.0085, 0.0115), V2(0.0035, 0.0145), V2(0, 0.016)]
        for s: Float in [-1, 1] {
            let zf = s * (R + 0.0095 + 0.004 + 0.0095)
            FA.box(&m, V3(length, yE - 0.004, 0.019), V3(0, (yE - 0.004) / 2, s * (R + 0.0135)), trim, r: 0.0025)
            FA.box(&m, V3(length - 0.03, 0.004, 0.028), V3(0, yE - 0.0095, s * (R + 0.0135)), "wood.cedar-weathered", r: 0.001)
            let prof = s > 0 ? mould : mould.map { V2(-$0.x, $0.y) }.reversed() as [V2]
            FA.run(&m, prof, length: length - 0.02, at: V3(0, yE - 0.05, zf), trim, bevel: 0.0005)
            for jx: Float in [-0.62, 0.71] {
                RK.plate(&m, V3(0.0035, yE - 0.016, 0.0008), V3(jx, (yE - 0.004) / 2, zf + s * 0.0004), "wood.deadwood")
            }
            var nr = rng.fork(900 + Int(s + 2))
            var x = -half + 0.06
            while x < half - 0.05 {
                for yy: Float in [0.05] {
                    RK.plate(&m, V3(0.0055, 0.0055, 0.0012), V3(x, yy + nr.float(-0.0015...0.0015), zf + s * 0.0004), "metal.cast-iron")
                }
                x += nr.float(0.28...0.34)
            }
            slab(s, V3(length, 0.0016, 0.03), x: 0, t: 0.002, h: 0.0035, "metal.painted:55595B", r: 0.0006)
            FA.box(&m, V3(length, 0.026, 0.0016), V3(0, yE - 0.011, s * (R + 0.021)), "metal.painted:55595B", r: 0.0006)
            slab(s, V3(length - 0.016, 0.012, slotT + 0.01), x: 0, t: slotT / 2, h: -0.008, "wood.plywood-osb", r: 0.0008)
            slab(s, V3(length - 0.018, 0.0018, slotT + 0.006), x: 0, t: slotT / 2, h: -0.0014, sh + "1E1E20", r: 0.0004)
            // Sheathing seams and the dark open slot.
            decal(s, V3(0.002, 0.0012, slotT), x: 0.2, t: slotT / 2, h: -0.0012, sh + "101012")
        }
        // Dark void in the ridge slot between the two sheathing edges.
        RK.plate(&m, V3(length - 0.02, 0.0016, 0.04), V3(0, yDeck - 0.012, 0), sh + "0A0A0B")

        // Field shingles, two courses per side.
        let tabW: Float = 0.333
        let nT = Int(ceil(length / tabW)) + 1
        let courses: [(Float, Float, Float)] = [(-0.014, 0.0, 0.06), (0.036, 0.0032, 0.09)]
        for s: Float in [-1, 1] {
            for (ci, (t0, lift, tLen)) in courses.enumerated() {
                for k in 0..<nT {
                    var r = rng.fork(Int(s + 2) * 100 + ci * 30 + k)
                    let x0 = -half + (Float(k) - 0.5 * Float(ci) - 0.35) * tabW
                    let xa = max(x0, -half + 0.006), xb = min(x0 + tabW - 0.004, half - 0.006)
                    if xb - xa < 0.02 { continue }
                    slab(s, V3(xb - xa, 0.0032, tLen), x: (xa + xb) / 2, t: t0 + tLen / 2, h: 0.0021 + lift, r.pick(tints), r: 0.0009)
                    for sl in 1...1 {
                        let sx = x0 + tabW * Float(sl) / 2
                        if sx > -half + 0.01 && sx < half - 0.01 {
                            decal(s, V3(0.0042, 0.0004, 0.04), x: sx, t: t0 + 0.02, h: 0.0042 + lift, sh + "151517")
                        }
                    }
                    if r.chance(0.4) && xb - xa > 0.12 {
                        decal(s, V3(r.float(0.03...0.08), 0.0004, r.float(0.01...0.02)), x: r.float(xa + 0.05...xb - 0.05), t: t0 + r.float(0.005...0.04),
                              h: 0.0043 + lift, r.chance(0.5) ? sh + "5C5852" : sh + "26262A")
                    }
                }
            }
            let lichen: [MaterialKey] = [sh + "7A8466", sh + "5E6A4C", sh + "A2A585", sh + "8C7F54"]
            for _ in 0..<3 {
                let cx = rng.float(-half + 0.1...half - 0.1), ct = rng.float(0.0...0.05)
                for _ in 0..<6 {
                    let tt = ct + rng.float(-0.012...0.012)
                    decal(s, V3(rng.float(0.006...0.022), 0.0005, rng.float(0.005...0.012)), x: cx + rng.float(-0.04...0.04), t: tt,
                          h: 0.0052 + (tt > 0.036 ? 0.0032 : 0) + rng.float(0...0.0003), rng.pick(lichen))
                }
            }
        }

        // Vent body: polymer wedge following the roof, 0.18 m wide, drooping to a thin lip at each edge.
        let vw: Float = 0.09
        let yShingle = yDeck + 0.0062
        func yRoof(_ z: Float) -> Float { yShingle - abs(z) * tn }
        func hv(_ z: Float) -> Float {
            let u = 1 - min(abs(z), vw) / vw
            return 0.005 + 0.019 * (u * u * (3 - 2 * u))
        }
        let zs: [Float] = [-vw, -0.075, -0.06, -0.045, -0.03, -0.015, 0, 0.015, 0.03, 0.045, 0.06, 0.075, vw]
        func ventTop(_ z: Float) -> Float { yRoof(z) + hv(z) }
        func ventProfile(inset: Float = 0) -> [V2] {
            let top = zs.map { V2($0, ventTop($0) - inset) }
            let bot = zs.map { V2($0, max(yRoof($0), yDeck - 0.004) - (abs($0) < 0.02 ? 0.0 : 0)) }
            return Shape2D.deduped(top + bot.reversed())
        }
        let vx0: Float = -half + 0.026, vx1: Float = half - 0.026
        FA.run(&m, ventProfile(), length: vx1 - vx0, at: V3((vx0 + vx1) / 2, 0, 0), "plastic.black", bevel: 0.0009)
        // End plugs: ribbed closures slightly proud of the body at both ends.
        for e: Float in [-1, 1] {
            FA.run(&m, ventProfile(inset: -0.0014), length: 0.012, at: V3(e * (half - 0.032), 0, 0), "plastic.pom", bevel: 0.0007)
        }
        // Louver slots in rows with webs every 0.1 m, spacer ribs between the rows, nailing line recess.
        func topSlope(_ z: Float) -> Float { atan2(-(ventTop(z + 0.004) - ventTop(z - 0.004)), 0.008) }
        for s: Float in [-1, 1] {
            for zr: Float in [0.036, 0.066] {
                let z = s * zr
                let ang = -atan2(ventTop(z + 0.004) - ventTop(z - 0.004), 0.008)
                var x = vx0 + 0.04
                while x < vx1 - 0.1 {
                    let slotL: Float = 0.085
                    RK.plate(&m, V3(slotL, 0.0006, 0.0075), V3(x + slotL / 2, ventTop(z) + 0.0004, z), sh + "070708",
                             rot: FA.q(ang * 180 / .pi, FA.X))
                    x += 0.1
                }
                _ = topSlope
            }
            // Raised spacer rib between louver rows and a nailing guide line near the ridge.
            for zr: Float in [0.051] {
                let z = s * zr
                let ang = -atan2(ventTop(z + 0.004) - ventTop(z - 0.004), 0.008)
                RK.plate(&m, V3(vx1 - vx0 - 0.08, 0.0012, 0.003), V3((vx0 + vx1) / 2, ventTop(z) + 0.0006, z), "plastic.black", rot: FA.q(ang * 180 / .pi, FA.X))
            }
            let zg = s * 0.016
            let ang = -atan2(ventTop(zg + 0.004) - ventTop(zg - 0.004), 0.008)
            RK.plate(&m, V3(vx1 - vx0 - 0.04, 0.0008, 0.004), V3((vx0 + vx1) / 2, ventTop(zg) + 0.0004, zg), "plastic.medical-grey-worn", rot: FA.q(ang * 180 / .pi, FA.X))
        }
        // UV chalking: pale weathered patches on the bare vent.
        for _ in 0..<9 {
            let s: Float = rng.chance(0.5) ? 1 : -1
            let zr = rng.float(0.02...0.08), z = s * zr
            let ang = -atan2(ventTop(z + 0.004) - ventTop(z - 0.004), 0.008)
            RK.plate(&m, V3(rng.float(0.02...0.07), 0.0005, rng.float(0.006...0.016)), V3(rng.float(vx0 + 0.05...0.0), ventTop(z) + 0.0007, z),
                     "plastic.medical-grey-worn", rot: FA.q(ang * 180 / .pi, FA.X))
        }
        // Long ring-shank nails through the nailing line on the bare half, with a spare ready on the vent.
        var xn = vx0 + 0.12
        while xn < 0.0 {
            for s: Float in [-1, 1] {
                let z = s * 0.016
                let ang = -atan2(ventTop(z + 0.004) - ventTop(z - 0.004), 0.008)
                m.add(Prim.cylinder(radius: 0.0034, height: 0.0014, bevel: 0.0005, segments: 8, bevelSegments: 1, material: "metal.painted:55595B"),
                      Xform(translation: V3(xn, ventTop(z) + 0.0016, z), rotation: FA.q(ang * 180 / .pi, FA.X)))
            }
            xn += 0.28
        }

        // Cap shingles over the right part of the vent: legs follow the vent contour then the roof out to 0.105 m.
        let capLeg: Float = 0.105
        func capTop(_ z: Float) -> Float {
            let a = abs(z)
            if a <= vw { return ventTop(z) + 0.0035 }
            return yRoof(z) + 0.0035 + 0.0015 * (1 - (a - vw) / (capLeg - vw))
        }
        func capProfile(_ lift: Float, _ th: Float) -> [V2] {
            var zz: [Float] = [-capLeg, -0.09, -0.075, -0.06, -0.045, -0.03, -0.015, 0, 0.015, 0.03, 0.045, 0.06, 0.075, 0.09, capLeg]
            zz = zz.map { $0 }
            let outer = zz.map { V2($0, capTop($0) + lift) }
            let inner = outer.map { V2($0.x, $0.y - th) }
            return Shape2D.deduped(outer + inner.reversed())
        }
        let exposure: Float = 0.127, capLen: Float = 0.30
        let capStart: Float = half * (1 - 2 * capped) - half + half        // x where the first cap begins
        let xStart = half - capped * length
        _ = capStart
        let nC = Int(ceil((half - 0.004 - xStart - capLen) / exposure)) + 1
        let tintsCap: [MaterialKey] = tints
        for i in 0..<nC {
            var r = rng.fork(500 + i)
            let x0 = xStart + Float(i) * exposure
            let x1 = min(x0 + capLen, half - 0.004)
            if x1 - x0 < 0.05 { continue }
            let lift = Float(i % 3) * 0.0022 + 0.0006
            FA.run(&m, capProfile(lift, 0.0062), length: x1 - x0, at: V3((x0 + x1) / 2, 0, 0), r.pick(tintsCap), bevel: 0.0007)
            if r.chance(0.6) {
                RK.plate(&m, V3(0.01, 0.0009, 0.02), V3(x0 + 0.1, capTop(0.099) + lift, 0.099), sh + "5C5852", rot: FA.q(-deg, FA.X))
            }
        }
        // Exposed cap nails with sealant on the last cap, and tar beads at the cap ends.
        let xN = half - 0.05
        for s: Float in [-1, 1] {
            for dx: Float in [-0.075, 0.0, 0.07] {
                let z = s * 0.072
                let ang = -atan2(capTop(z + 0.004) - capTop(z - 0.004), 0.008)
                let y = capTop(z) + Float((nC - 1) % 3) * 0.0022 + 0.0006
                m.add(Prim.superellipsoid(V3(0.0095, 0.0032, 0.0095), exponent: 2, subdivisions: 3, material: sh + "101012"), Xform(translation: V3(xN + dx, y, z), rotation: FA.q(ang * 180 / .pi, FA.X)))
                m.add(Prim.cylinder(radius: 0.0035, height: 0.0012, bevel: 0.0005, segments: 10, bevelSegments: 1, material: "metal.painted:55595B"),
                      Xform(translation: V3(xN + dx, y + 0.0014, z), rotation: FA.q(ang * 180 / .pi, FA.X)))
            }
        }
        m.add(Prim.superellipsoid(V3(0.016, 0.01, 0.15), exponent: 2, subdivisions: 4, material: sh + "151517"), Xform(translation: V3(xStart + 0.004, ventTop(0) - 0.004, 0)))
        // Rain streaks on the fascia and a chipped paint spot.
        for s: Float in [-1, 1] {
            for _ in 0..<3 {
                let x = rng.float(-half + 0.1...half - 0.1), h = rng.float(0.04...0.08)
                RK.plate(&m, V3(rng.float(0.012...0.03), h, 0.0006), V3(x, yE - 0.012 - h / 2, s * (R + 0.0135 + 0.0102)), "wood.deadwood")
            }
        }
        RK.plate(&m, V3(0.012, 0.016, 0.0007), V3(-half + 0.03, 0.02, R + 0.0135 + 0.0102), "wood.pine-aged")

        groundAO(&m, height: 0.08, floor: 0.85)
        return LODModel(m)
    }
}
