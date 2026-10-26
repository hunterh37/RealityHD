import simd
import Foundation

/// Neoclassical dentil cornice run, 2.0 x 0.4 x 0.35 m, painted timber: frieze board with an astragal, a dentil course at 60 mm
/// pitch over a shadow board, ovolo with egg beads, corona with drip groove, cyma recta crown and a fascia. Scarf joint at
/// 0.4 m, galvanized nail heads with rust runs, end blocks, flaking paint under the corona.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct DentilCorniceRun: RealAsset {
    public static let id = "dentil-cornice-run"
    public static let summary = "Neoclassical dentil cornice run, 2.0 m: frieze, 60 mm dentils, egg-and-dart ovolo, corona with drip, cyma crown, fascia, scarf joint."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 3, distance: 2.7)

    /// Length of the run in meters.
    public var length: Float = 2.0
    /// Dentil pitch in meters.
    public var dentilPitch: Float = 0.06
    /// Painted cornice.
    public var paint: MaterialKey = "wood.barn-white:E4DDC8"
    /// Flaking, grey weathered timber showing through.
    public var worn: MaterialKey = "wood.trim-weathered"
    /// Fasteners.
    public var nails: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let alt: [MaterialKey] = [paint, "wood.painted-exterior:E6E0D0", "wood.painted-exterior:DAD3C0"]

        // Frieze board with an astragal at the top.
        FA.run(&m, [V2(0, 0), V2(0.03, 0), V2(0.03, 0.085), V2(0.042, 0.088), V2(0.042, 0.1), V2(0, 0.1)], length: L, paint, bevel: 0.002)
        // Dentils on a dark shadow board.
        FA.box(&m, V3(L - 0.04, 0.05, 0.004), V3(0, 0.125, 0.032), worn, r: 0.001)
        let n = Int((L - 0.06) / dentilPitch)
        FO7.comb(&m, count: n, pitch: dentilPitch, w: 0.036, h: 0.05, bar: 0.005, y0: 0.1, z0: 0.03, depth: 0.045, paint)
        // Corner blocks closing the dentil course at the ends.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.035, 0.05, 0.05), V3(s * (L / 2 - 0.0175), 0.125, 0.055), paint, r: 0.003)
        }
        // Ovolo (quarter-round) bed mould with egg beads.
        var ovolo: [V2] = [V2(0, 0.15), V2(0.07, 0.15)]
        for i in 1...6 {
            let a = Float(i) / 6 * (.pi / 2)
            ovolo.append(V2(0.07 + 0.03 * sin(a), 0.15 + 0.03 * (1 - cos(a))))
        }
        ovolo += [V2(0.1, 0.182), V2(0, 0.182)]
        FA.run(&m, Shape2D.deduped(ovolo), length: L, at: .zero, paint, bevel: 0.002)
        let nE = Int((L - 0.08) / 0.06)
        for i in 0..<nE {
            let x = -Float(nE - 1) * 0.06 / 2 + Float(i) * 0.06
            m.add(Prim.superellipsoid(V3(0.028, 0.032, 0.02), exponent: 2, subdivisions: 2, material: alt[i % 3]),
                  Xform(translation: V3(x, 0.168, 0.0925)))
        }
        // Corona with a drip groove under the nose.
        let corona: [V2] = [V2(0, 0.182), V2(0.25, 0.182), V2(0.255, 0.188), V2(0.27, 0.188), V2(0.275, 0.182), V2(0.31, 0.182),
                            V2(0.315, 0.19), V2(0.315, 0.245), V2(0.29, 0.255), V2(0, 0.255)]
        FA.run(&m, corona, length: L, at: .zero, paint, bevel: 0.002)
        // Cyma recta crown and fascia.
        var crown: [V2] = [V2(0, 0.255), V2(0.22, 0.255)]
        crown += FL.ogee(from: V2(0.22, 0.255), to: V2(0.34, 0.345), steps: 10)
        crown += [V2(0.35, 0.35), V2(0.35, 0.395), V2(0.34, 0.4), V2(0, 0.4)]
        FA.run(&m, Shape2D.deduped(crown), length: L, at: .zero, paint, bevel: 0.002)

        // Scarf joint and a butt joint: dark gaps through each face.
        for (x, w) in [(Float(-0.4), Float(0.004)), (0.62, 0.003)] {
            FA.box(&m, V3(w, 0.098, 0.002), V3(x, 0.05, 0.0305), worn, r: 0.0004)
            FA.box(&m, V3(w, 0.055, 0.002), V3(x, 0.2175, 0.3155 - 0.001), worn, r: 0.0004)
            FA.box(&m, V3(w, 0.055, 0.002), V3(x, 0.3725, 0.35), worn, r: 0.0004)
        }
        // Galvanized nail heads on the fascia and frieze with rust runs below.
        for i in 0..<8 {
            let x = -0.875 + Float(i) * 0.25 + rng.float(-0.01...0.01)
            FC.bead(&m, r: 0.0035, at: V3(x, 0.375, 0.3505), nails, sub: 2)
            FC.bead(&m, r: 0.0035, at: V3(x + 0.02, 0.045, 0.0305), nails, sub: 2)
            FO7.streak(&m, x: x, top: 0.372, w: 0.004, h: rng.float(0.02...0.05), z: 0.35, "metal.rust")
        }
        // Flaking paint on the frieze and the corona front, grime in the groove.
        for _ in 0..<7 {
            let x = rng.float(-0.9...0.9)
            FO7.streak(&m, x: x, top: rng.float(0.05...0.095), w: rng.float(0.03...0.08), h: rng.float(0.02...0.05), z: 0.03, worn)
            FA.box(&m, V3(rng.float(0.03...0.08), rng.float(0.015...0.03), 0.002), V3(rng.float(-0.9...0.9), 0.22, 0.3155), worn, r: 0.0005)
        }
        for _ in 0..<5 {
            FA.box(&m, V3(rng.float(0.02...0.05), rng.float(0.02...0.04), 0.002), V3(rng.float(-0.9...0.9), 0.37, 0.3505), worn, r: 0.0005)
        }

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
