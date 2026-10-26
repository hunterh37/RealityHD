import simd
import Foundation

/// Lead roll ridge cap, Georgian: 3.0 m run, 120 mm high, 200 mm across. An oak ridge board with exposed end grain, a
/// 90 mm lead-covered roll (rolled ends), two 4 mm lead wings dressed 42 degrees down each pitch with a stepped welt at
/// each sheet lap, lead clips wrapped over the roll every 600 mm, copper nail rows along both wing edges, a lapped sheet
/// joint, and carbonate bloom with dark run-off streaks. Roof piece, sits on y = 0.
public struct LeadRollRidgeCap: RealAsset {
    public static let id = "lead-roll-ridge-cap"
    public static let summary = "Lead roll ridge cap, Georgian facade prop, 3.0 x 0.12 x 0.2 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 22, distance: 1.5)

    /// Run length in meters.
    public var length: Float = 3.0
    /// Lead sheet.
    public var lead: MaterialKey = "stone.slate"
    /// Ridge board timber.
    public var timber: MaterialKey = "wood.lumber-oak"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let rollR: Float = 0.045, rollY: Float = 0.075
        let wingAng: Float = 42, wingLen: Float = 0.086, wt: Float = 0.004
        // Ridge board (oak), proud of the lead at both ends so the end grain shows.
        FA.box(&m, V3(L + 0.02, 0.034, 0.07), V3(0, 0.017, 0), timber, r: 0.003)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.002, 0.03, 0.066), V3(e * (L / 2 + 0.0105), 0.017, 0), "wood.endgrain-weathered", r: 0.0006)
        }
        // Roll: lead over a timber core, ends dressed over.
        FA.cylX(&m, r: rollR, h: L, at: V3(-L / 2, rollY, 0), lead, bevel: 0.006, segments: 20)
        // Wings dressed down both pitches: P0 on the roll flank, P1 at the eave.
        let z0: Float = 0.036, y0: Float = 0.068, z1: Float = 0.092, y1: Float = 0.012
        let wl = simd_length(V2(z1 - z0, y0 - y1)), wa = atan2(y0 - y1, z1 - z0)
        let wdeg = wa * 180 / .pi
        func onWing(_ sgn: Float, _ u: Float, _ off: Float = 0) -> V3 {
            V3(0, y0 - u * sin(wa), sgn * (z0 + u * cos(wa))) + V3(0, cos(wa), sgn * sin(wa)) * off
        }
        func wnorm(_ sgn: Float) -> V3 { V3(0, cos(wa), sgn * sin(wa)) }
        for sgn: Float in [-1, 1] {
            FA.box(&m, V3(L - 0.02, wt, wl), onWing(sgn, wl / 2, wt / 2), lead, r: 0.0012, rot: FA.q(sgn * wdeg, FA.X))
            // Drip edge rolled under at the eave.
            FA.cylX(&m, r: 0.004, h: L - 0.02, at: V3(-L / 2 + 0.01, y1 + 0.001, sgn * (z1 - 0.001)), lead, bevel: 0.001, segments: 8)
        }
        // Welts: stepped sheet laps across wings and over the roll.
        let lapX: [Float] = [-0.9, 0.55]
        for lx in lapX {
            for sgn: Float in [-1, 1] {
                var p = onWing(sgn, wl / 2, wt + 0.0045); p.x = lx
                FA.box(&m, V3(0.016, 0.009, wl - 0.004), p, "metal.painted:6E7378", r: 0.0025, rot: FA.q(sgn * wdeg, FA.X))
            }
            m.add(Prim.torus(major: rollR + 0.002, minor: 0.0038, segments: 18, sides: 6, arc: .pi, material: "metal.painted:6E7378"),
                  Xform(translation: V3(lx, rollY, 0), rotation: FA.q(90, FA.X) * FA.q(-90, FA.Y)))
        }
        // Lead clips wrapped over the roll every 600 mm, nailed on both flanks.
        var x: Float = -1.2
        while x < L / 2 - 0.1 {
            FA.box(&m, V3(0.03, 0.0035, 0.05), V3(x, rollY + rollR + 0.0012, 0), "metal.painted:62676C", r: 0.001)
            for sgn: Float in [-1, 1] {
                var p = onWing(sgn, 0.032, wt + 0.0017); p.x = x
                FA.box(&m, V3(0.03, 0.0035, 0.05), p, "metal.painted:62676C", r: 0.001, rot: FA.q(sgn * wdeg, FA.X))
                var q = onWing(sgn, 0.052, wt + 0.0035); q.x = x
                rivet(&m, at: q, normal: wnorm(sgn), radius: 0.0032, segments: 8, material: "metal.copper")
            }
            x += 0.6
        }
        // Copper nail rows along the eave edge of each wing.
        x = -L / 2 + 0.08
        while x < L / 2 - 0.05 {
            for sgn: Float in [-1, 1] {
                var p = onWing(sgn, wl - 0.014, wt); p.x = x
                rivet(&m, at: p, normal: wnorm(sgn), radius: 0.0026, segments: 6, material: "metal.copper")
            }
            x += 0.12
        }
        // Weathering: carbonate bloom on the roll, dark run-off lines on the pitches, a bright repair patch.
        for _ in 0..<20 {
            FA.box(&m, V3(rng.float(0.1...0.4), 0.0012, rng.float(0.014...0.034)), V3(rng.float(-1.25...1.25), rollY + rollR * 0.985 + 0.0004, rng.float(-0.008...0.008)),
                   rng.chance(0.65) ? "stone.limestone" : "stone.limestone-sooted", r: 0.0003)
        }
        for _ in 0..<18 {
            let sgn: Float = rng.chance(0.5) ? -1 : 1
            var p = onWing(sgn, rng.float(0.03...0.07), wt + 0.0007); p.x = rng.float(-1.4...1.4)
            FA.box(&m, V3(rng.float(0.012...0.04), 0.0012, rng.float(0.03...0.06)), p, rng.chance(0.4) ? "wood.deadwood" : "stone.limestone",
                   r: 0.0003, rot: FA.q(sgn * wdeg, FA.X))
        }
        var rp = onWing(1, 0.05, wt + 0.0009); rp.x = 1.1
        FA.box(&m, V3(0.28, 0.0012, 0.045), rp, "metal.steel", r: 0.0006, rot: FA.q(wdeg, FA.X))
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
