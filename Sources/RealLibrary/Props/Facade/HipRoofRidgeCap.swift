import simd
import Foundation

/// Hip roof ridge cap: American Traditional asphalt shingle roof, 3.0 m of ridge on a 12:12 pitch. Bent
/// ridge shingles lap along the apex over two courses of tabbed field shingles on black underlayment and
/// OSB sheathing, with a galvanized drip edge, white fascia, a sloped rake board and a lapped-siding gable
/// end. Exposed cap nails with sealant, granule loss, tar streaks and lichen weather the surface.
public struct HipRoofRidgeCap: RealAsset {
    public static let id = "hip-roof-ridge-cap"
    public static let summary = "Hip roof ridge cap, 3.0 m: lapped bent ridge shingles over asphalt field shingles, drip edge, fascia and rake board."
    public static let tags = ["prop", "architecture", "facade", "roofline", "trim"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 2.0)

    /// Ridge length in meters.
    public var length: Float = 3.0
    /// Horizontal run from ridge to eave in meters.
    public var run: Float = 0.113
    /// Weathered charcoal shingle color (sRGB hex tint).
    public var shingle: MaterialKey = "roofing.shingle-granule:3A3835"
    /// Trim and fascia paint.
    public var trim: MaterialKey = "wood.painted-exterior:8E9C8A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let th: Float = 45 * .pi / 180, sn = sin(th), cs = cos(th)
        let R = run, yE: Float = 0.16
        let L = R / cs
        let half = length / 2
        // Point on the roof plane: s side (+1 front, -1 back), x along the ridge, t up-slope from the eave, h normal.
        func P(_ s: Float, _ x: Float, _ t: Float, _ h: Float = 0) -> V3 {
            V3(x, yE + t * sn + h * cs, s * (R - t * cs + h * sn))
        }
        func slab(_ s: Float, _ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey, r: Float = 0.0012) {
            FA.box(&m, size, P(s, x, t, h), mat, r: r, rot: FA.q(s * 45, FA.X))
        }
        func decal(_ s: Float, _ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey) {
            RK.plate(&m, size, P(s, x, t, h), mat, rot: FA.q(s * 45, FA.X))
        }
        let tints: [MaterialKey] = ["roofing.shingle-granule:7C766E", "roofing.shingle-granule:978F84", "roofing.shingle-granule:6A655E", "roofing.shingle-granule:8A8277", "roofing.shingle-granule:847E75", "roofing.shingle-granule:5C5751"]

        // Gable end panels with lapped siding and white rake boards at both ends.
        let gable: [V2] = [V2(-(R + 0.004), 0), V2(R + 0.004, 0), V2(R + 0.004, yE - 0.006), V2(0, yE + R - 0.014), V2(-(R + 0.004), yE - 0.006)]
        for e: Float in [-1, 1] {
            let gx = e * (half - 0.012)
            FA.run(&m, gable, length: 0.02, at: V3(gx, 0, 0), "wood.plywood-osb", bevel: 0.001)
            // Lapped siding boards on the outer face, 0.045 m exposure.
            for k in 0..<5 {
                let y = 0.03 + Float(k) * 0.045
                let w = min(R + 0.004, (yE + R - 0.014 - y) ) - 0.004
                FA.box(&m, V3(0.008, 0.044, 2 * max(0.02, min(R, w)) - 0.004), V3(e * (half - 0.0015), y + 0.0, 0), trim, r: 0.0012)
            }
            for s: Float in [-1, 1] {
                slab(s, V3(0.02, 0.07, L + 0.03), x: e * (half + 0.002), t: L / 2 + 0.01, h: -0.021, trim, r: 0.002)
            }
        }
        // Fascia boards, drip edge and the subfascia behind them.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(length, yE - 0.004, 0.019), V3(0, (yE - 0.004) / 2, s * (R + 0.0095 + 0.004)), trim, r: 0.0025)
            FA.box(&m, V3(length - 0.03, 0.004, 0.028), V3(0, yE - 0.0095, s * (R + 0.0095 + 0.004)), "wood.cedar-weathered", r: 0.001)
            // Drip edge: horizontal leaf over the deck and a hanging leg over the fascia.
            slab(s, V3(length, 0.0016, 0.03), x: 0, t: 0.002, h: 0.0035, "metal.painted:55595B", r: 0.0006)
            FA.box(&m, V3(length, 0.026, 0.0016), V3(0, yE - 0.011, s * (R + 0.021)), "metal.painted:55595B", r: 0.0006)
            // Sheathing and underlayment, full length.
            slab(s, V3(length - 0.016, 0.012, L + 0.01), x: 0, t: L / 2, h: -0.006 - 0.002, "wood.plywood-osb", r: 0.0008)
            slab(s, V3(length - 0.018, 0.0018, L + 0.006), x: 0, t: L / 2, h: -0.002 + 0.0006, "roofing.shingle-granule:1E1E20", r: 0.0004)
            // Sheathing plank seams every 1.22 m, and nail dimples along a panel line.
            for sx: Float in [-1.22, 0, 1.22] {
                decal(s, V3(0.002, 0.0012, L), x: sx * 0.5 + 0.2, t: L / 2, h: -0.0015, "roofing.shingle-granule:101012")
            }
        }

        // Bed mould under the drip edge (quarter round profile), scarf joints with caulk lines, and a row of nail heads.
        let mould: [V2] = [V2(0, 0), V2(0.016, 0), V2(0.0155, 0.003), V2(0.013, 0.0075), V2(0.0085, 0.0115), V2(0.0035, 0.0145), V2(0, 0.016)]
        for s: Float in [-1, 1] {
            let zf = s * (R + 0.0095 + 0.004 + 0.0095)
            // Profile x goes out from the fascia face; flip it on the back side.
            let prof = s > 0 ? mould : mould.map { V2(-$0.x, $0.y) }.reversed() as [V2]
            FA.run(&m, prof, length: length - 0.02, at: V3(0, yE - 0.05, zf), trim, bevel: 0.0005)
            for jx: Float in [-0.62, 0.71] {
                RK.plate(&m, V3(0.0035, yE - 0.016, 0.0008), V3(jx, (yE - 0.004) / 2, zf + s * 0.0004), "wood.deadwood")
            }
            var nr = rng.fork(900 + Int(s + 2))
            var x = -half + 0.06
            while x < half - 0.05 {
                for yy: Float in [0.034, 0.1] {
                    RK.plate(&m, V3(0.0055, 0.0055, 0.0012), V3(x, yy + nr.float(-0.0015...0.0015), zf + s * 0.0004), "metal.cast-iron")
                }
                x += nr.float(0.28...0.34)
            }
        }
        // Field shingles: two courses per side, 0.333 m tabs, staggered half a tab, with butt gaps and a slot at each tab edge.
        let tabW: Float = 0.333
        let nT = Int(ceil(length / tabW)) + 1
        let courses: [(Float, Float)] = [(-0.014, 0.0), (0.056, 0.0032)]
        for s: Float in [-1, 1] {
            for (ci, (t0, lift)) in courses.enumerated() {
                let tLen: Float = 0.103
                for k in 0..<nT {
                    var r = rng.fork(Int(s + 2) * 100 + ci * 30 + k)
                    let x0 = -half + (Float(k) - 0.5 * Float(ci) - 0.35) * tabW
                    let xa = max(x0, -half + 0.006), xb = min(x0 + tabW - 0.004, half - 0.006)
                    if xb - xa < 0.02 { continue }
                    let mat = r.pick(tints)
                    slab(s, V3(xb - xa, 0.0032, tLen), x: (xa + xb) / 2, t: t0 + tLen / 2, h: 0.0021 + lift, mat, r: 0.0009)
                    // Slots: two cutouts per 3-tab shingle (dark underlayment shows) every third of the tab.
                    for sl in 1...2 {
                        let sx = x0 + tabW * Float(sl) / 3
                        if sx > -half + 0.01 && sx < half - 0.01 {
                            decal(s, V3(0.0042, 0.0004, 0.045), x: sx, t: t0 + 0.0225, h: 0.0042 + lift, "roofing.shingle-granule:151517")
                        }
                    }
                    // Granule loss: pale worn patch near the lower edge, and tar-dark streak.
                    if r.chance(0.4) && xb - xa > 0.12 {
                        decal(s, V3(r.float(0.03...0.08), 0.0004, r.float(0.01...0.025)), x: r.float(xa + 0.05...xb - 0.05), t: t0 + r.float(0.01...0.06),
                              h: 0.0043 + lift, r.chance(0.5) ? "roofing.shingle-granule:5C5852" : "roofing.shingle-granule:26262A")
                    }
                }
            }
            // Lichen clusters (many small blotches in grey-green and ochre) and tar drip streaks from the cap line.
            let lichen: [MaterialKey] = ["roofing.shingle-granule:7A8466", "roofing.shingle-granule:5E6A4C", "roofing.shingle-granule:A2A585", "roofing.shingle-granule:8C7F54"]
            for _ in 0..<6 {
                let cx = rng.float(-half + 0.1...half - 0.1), ct = rng.float(0.01...0.1)
                for _ in 0..<7 {
                    let tt = ct + rng.float(-0.02...0.02)
                    decal(s, V3(rng.float(0.006...0.022), 0.0005, rng.float(0.005...0.014)), x: cx + rng.float(-0.04...0.04), t: tt,
                          h: 0.0052 + (tt > 0.056 ? 0.0032 : 0) + rng.float(0...0.0003), rng.pick(lichen))
                }
            }
            for _ in 0..<7 {
                let tt = rng.float(0.07...0.11), len = rng.float(0.03...0.06)
                decal(s, V3(rng.float(0.003...0.007), 0.0005, len), x: rng.float(-half + 0.1...half - 0.1), t: tt, h: 0.0072, "roofing.shingle-granule:1A1918")
            }
        }

        // Ridge cap: bent shingles 0.3 m long on a 0.127 m exposure, running from -x, each lifted slightly over the last.
        let capLeg: Float = 0.068            // horizontal leg run each side
        let yA = yE + R + 0.0066             // apex of the field shingle surface
        func capProfile(_ lift: Float, _ th: Float) -> [V2] {
            let rr: Float = 0.016
            var outer: [V2] = []
            for zv in [-capLeg, -0.04, -0.022, -0.011, 0, 0.011, 0.022, 0.04, capLeg] as [Float] {
                outer.append(V2(zv, yA + lift - sqrt(zv * zv + rr * rr) + rr))
            }
            let inner = outer.map { V2($0.x, $0.y - th) }
            return Shape2D.deduped(outer + inner.reversed())
        }
        let exposure: Float = 0.127, capLen: Float = 0.30
        let nC = Int(ceil((length - capLen) / exposure)) + 1
        for i in 0..<nC {
            var r = rng.fork(500 + i)
            let x0 = -half + Float(i) * exposure
            let x1 = min(x0 + capLen, half - 0.004)
            let lift = Float(i % 3) * 0.0022 + 0.0006
            let mat = r.pick(tints)
            FA.run(&m, capProfile(lift, 0.0065), length: x1 - x0, at: V3((x0 + x1) / 2, 0, 0), mat, bevel: 0.0007)
            // Clipped lower corners: cap tail trimmed at 45 degrees where the next cap laps it.
            if r.chance(0.6) {
                RK.plate(&m, V3(0.01, 0.0009, 0.022), V3(x0 + 0.1, yA + lift - capLeg + 0.0003, 0), "roofing.shingle-granule:5C5852")
            }
        }
        // Exposed nail pairs with sealant dabs on the last cap, two per leg.
        let xN = half - 0.045
        for s: Float in [-1, 1] {
            for dx: Float in [-0.075, 0.0, 0.07] {
                let z = s * 0.052, y = yA + 0.0006 + Float(((nC - 1) % 3)) * 0.0022 - 0.052 + 0.0046
                m.add(Prim.superellipsoid(V3(0.0095, 0.0032, 0.0095), exponent: 2, subdivisions: 3, material: "roofing.shingle-granule:101012"), Xform(translation: V3(xN + dx, y, z), rotation: FA.q(s * 45, FA.X)))
                m.add(Prim.cylinder(radius: 0.0035, height: 0.0012, bevel: 0.0005, segments: 10, bevelSegments: 1, material: "metal.painted:55595B"),
                      Xform(translation: V3(xN + dx, y + 0.0014, z + s * 0.0014), rotation: FA.q(s * 45, FA.X)))
            }
        }
        // Roofing cement bead sealing the cap ends, and a tar smear along the apex.
        for e: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.016, 0.01, 0.15), exponent: 2, subdivisions: 4, material: "roofing.shingle-granule:151517"), Xform(translation: V3(e * (half - 0.004), yA - 0.01, 0), rotation: .identity))
        }
        // Rain streaks and soot on the white fascia and gable siding.
        for s: Float in [-1, 1] {
            for _ in 0..<6 {
                let x = rng.float(-half + 0.1...half - 0.1), h = rng.float(0.05...0.11)
                RK.plate(&m, V3(rng.float(0.012...0.03), h, 0.0006), V3(x, yE - 0.012 - h / 2, s * (R + 0.0095 + 0.004 + 0.0102)), "wood.deadwood")
            }
        }
        // Chipped paint at a fascia end where the rake board meets it.
        FA.box(&m, V3(0.012, 0.016, 0.0007), V3(-half + 0.03, 0.02, R + 0.0095 + 0.004 + 0.0102), "wood.pine-aged", r: 0.0002)
        FA.box(&m, V3(0.01, 0.012, 0.0007), V3(half - 0.2, 0.05, -(R + 0.0095 + 0.004 + 0.0102)), "wood.pine-aged", r: 0.0002)

        groundAO(&m, height: 0.08, floor: 0.85)
        return LODModel(m)
    }
}
