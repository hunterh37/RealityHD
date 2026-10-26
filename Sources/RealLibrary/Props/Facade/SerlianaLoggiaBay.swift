import simd
import Foundation

/// Renaissance Serliana loggia bay, 3.0 x 3.0 x 0.4 m: a round-arched centre opening between two lintelled side
/// openings, carried on four coursed Tuscan piers (plinth, base, shaft, necking, echinus, abacus). Nine wedge
/// voussoirs with keystone, ashlar spandrels with marble roundels, turned marble balustrades under a moulded rail,
/// and a three-fascia entablature with a dentil band and a cyma cornice.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct SerlianaLoggiaBay: RealAsset {
    public static let id = "serliana-loggia-bay"
    public static let summary = "Renaissance Serliana loggia bay, 3.0 m: centre arch and two lintelled openings on four Tuscan piers, voussoirs, roundels, balustrades, entablature."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 5.4)

    /// Clear half width of the central arched opening in meters.
    public var archRadius: Float = 0.45
    /// Springing line height (top of the impost) in meters.
    public var spring: Float = 1.8
    /// Ashlar and entablature stone.
    public var stone: MaterialKey = "stone.limestone:CFC4A8"
    /// Contrasting stone for imposts, voussoirs and keystone.
    public var accent: MaterialKey = "stone.sandstone"
    /// Sooted stone for joints and backing.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Balusters and roundels.
    public var marble: MaterialKey = "stone.marble-honed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ra = archRadius, sp = spring
        let tones: [MaterialKey] = [stone, "stone.limestone:C4B99C", "stone.limestone:D3CAB0", "stone.limestone:CABFA3"]
        let pierD: Float = 0.3

        // Piers: x centre, width. Inner piers carry the arch, outer piers close the bay.
        let piers: [(Float, Float)] = [(-1.4, 0.2), (-0.6, 0.3), (0.6, 0.3), (1.4, 0.2)]
        for (pi, (x, w)) in piers.enumerated() {
            // Plinth and base moulding.
            FA.box(&m, V3(w + 0.02, 0.12, pierD + 0.04), V3(x, 0.06, (pierD + 0.04) / 2), soot, r: 0.004)
            FA.box(&m, V3(w + 0.02, 0.05, pierD + 0.015), V3(x, 0.145, (pierD + 0.015) / 2), tones[pi % 4], r: 0.004)
            FA.box(&m, V3(w + 0.01, 0.02, pierD + 0.01), V3(x, 0.18, (pierD + 0.01) / 2), tones[(pi + 1) % 4], r: 0.003)
            // Shaft in five ashlar courses with joint gaps.
            let shaftTop = sp - 0.15, shaftBot: Float = 0.19
            let nC = 5
            let ch = (shaftTop - shaftBot) / Float(nC)
            for k in 0..<nC {
                FA.box(&m, V3(w, ch - 0.006, pierD), V3(x, shaftBot + ch * (Float(k) + 0.5), pierD / 2), tones[(k * 3 + pi) % 4], r: 0.003)
            }
            // Capital: necking, echinus (flared), abacus.
            FA.box(&m, V3(w - 0.025, 0.02, pierD - 0.025), V3(x, shaftTop + 0.01, pierD / 2), tones[(pi + 2) % 4], r: 0.003)
            let ech = [V2(-(w - 0.025) / 2, 0), V2((w - 0.025) / 2, 0), V2((w + 0.03) / 2, 0.06), V2(-(w + 0.03) / 2, 0.06)]
            m.add(Prim.extrude(FO.ccw(ech), depth: pierD - 0.01, bevel: 0.003, bevelSegments: 1, material: accent),
                  Xform(translation: V3(x, shaftTop + 0.02, pierD / 2)))
            FA.box(&m, V3(w + 0.07, 0.06, pierD + 0.04), V3(x, sp - 0.03, (pierD + 0.04) / 2), accent, r: 0.004)
            // Iron cramp at the abacus joint.
            FA.box(&m, V3(0.05, 0.012, 0.008), V3(x, sp - 0.062, pierD + 0.022), "metal.wrought-iron:2B2A27", r: 0.002)
        }

        // Ashlar spandrel panels over the side openings: three courses, roundel in each.
        for s: Float in [-1, 1] {
            for k in 0..<3 {
                let h: Float = 0.2
                FA.box(&m, V3(0.75 - 0.005, h - 0.005, 0.22), V3(s * 1.125, sp + 0.02 + h * (Float(k) + 0.5), 0.11), tones[(k * 2 + (s > 0 ? 1 : 0)) % 4], r: 0.003)
            }
            // Lintel over the side opening: three flat voussoir-like blocks with a moulded cap.
            let lx = s * 1.025
            for j in 0..<3 {
                let w: Float = 0.58 / 3
                let dx = (Float(j) - 1) * w
                FA.box(&m, V3(w - 0.005, 0.12, 0.3), V3(lx + dx, sp + 0.06 - 0.12 + 0.12, 0.15), j == 1 ? accent : tones[(j * 2) % 4], r: 0.004)
            }
            // Marble roundel with a moulded ring in the spandrel.
            let rc = V3(s * 1.025, sp + 0.35, 0.22)
            FA.cylZ(&m, r: 0.15, h: 0.02, at: rc, marble, bevel: 0.003, segments: 28)
            m.add(Prim.torus(major: 0.17, minor: 0.012, segments: 24, sides: 5, material: accent),
                  Xform(translation: rc + V3(0, 0, 0.012), rotation: FA.q(90, FA.X)))
            FO.rosette(&m, at: rc + V3(0, 0, 0.022), r: 0.07, petals: 6, accent)
        }
        // Central spandrels: ashlar fill between the voussoir ring and the entablature (polygon with the arc cut).
        for s: Float in [-1, 1] {
            var pts: [V2] = []
            for i in 0...10 {
                let a = Float(i) / 10 * (.pi / 2)
                pts.append(V2(s * ra * cos(a), sp + ra * sin(a)))
            }
            pts += [V2(0, sp + 0.6), V2(s * 0.75, sp + 0.6), V2(s * 0.75, sp)]
            m.add(Prim.extrude(FO.ccw(Shape2D.deduped(pts)), depth: 0.2, bevel: 0.003, bevelSegments: 1, material: soot),
                  Xform(translation: V3(0, 0, 0.1)))
        }
        // Wedge voussoirs and keystone.
        FO.voussoirs(&m, c: V2(0, sp), rIn: ra, rOut: ra + 0.13, from: 0, to: 180, count: 9, z0: 0, depth: 0.3, gap: 0.005, bevel: 0.003) { i in
            i == 4 ? accent : tones[(i * 5 + 1) % 4]
        }
        m.add(Prim.extrude([V2(-0.05, sp + ra), V2(0.05, sp + ra), V2(0.075, sp + ra + 0.17), V2(-0.075, sp + ra + 0.17)],
                           depth: 0.05, bevel: 0.004, bevelSegments: 1, material: accent), Xform(translation: V3(0, 0, 0.325)))
        FO.rosette(&m, at: V3(0, sp + ra + 0.085, 0.352), r: 0.04, petals: 6, accent)
        let archFillet = FC.archPath(width: ra * 2 + 0.002, spring: sp, pointed: false, z: 0.302, steps: 20).dropFirst().dropLast()
        FA.path(&m, Array(archFillet), r: 0.008, soot, sides: 6)

        // Impost mouldings over the inner piers (the arch springs from them).
        let imp: [V2] = [V2(0, sp), V2(0.325, sp), V2(0.325, sp + 0.012), V2(0.345, sp + 0.03), V2(0.345, sp + 0.05), V2(0, sp + 0.05)]
        for s: Float in [-1, 1] {
            FA.run(&m, imp, length: 0.39, at: V3(s * 0.6, 0, 0), accent, bevel: 0.002)
        }

        // Balustrades in the three openings: base rail, turned marble balusters, moulded handrail.
        let spans: [(Float, Float)] = [(-1.3, -0.75), (-0.45, 0.45), (0.75, 1.3)]
        for (x0, x1) in spans {
            let w = x1 - x0, cx = (x0 + x1) / 2
            FA.box(&m, V3(w + 0.01, 0.08, 0.17), V3(cx, 0.17, 0.15), tones[1], r: 0.004)
            let rail: [V2] = [V2(0, 0.85), V2(0.19, 0.85), V2(0.2, 0.86), V2(0.2, 0.89), V2(0.17, 0.905), V2(0.04, 0.905), V2(0.0, 0.9)]
            FA.run(&m, rail, length: w + 0.01, at: V3(cx, 0, 0.05), tones[2], bevel: 0.003)
            let nB = Int(w / 0.15)
            let pitch = w / Float(nB)
            for i in 0..<nB {
                FO.baluster(&m, at: V3(x0 + pitch * (Float(i) + 0.5), 0.21, 0.15), h: 0.64, r: 0.034, marble)
            }
        }

        // Entablature: architrave (two fasciae), plain Tuscan frieze, dentil band, cyma cornice.
        let ent: [[V2]] = [
            [V2(0, 2.4), V2(0.31, 2.4), V2(0.31, 2.46), V2(0.325, 2.465), V2(0.325, 2.52), V2(0, 2.52)],
            [V2(0, 2.52), V2(0.29, 2.52), V2(0.29, 2.74), V2(0, 2.74)],
            [V2(0, 2.74), V2(0.3, 2.74), V2(0.3, 2.77), V2(0.33, 2.8), V2(0.33, 2.83), V2(0.4, 2.83), V2(0.4, 2.89),
             V2(0.385, 2.915), V2(0.34, 2.94), V2(0.3, 2.975), V2(0.26, 3.0), V2(0, 3.0)]
        ]
        for (i, p) in ent.enumerated() {
            FA.run(&m, Shape2D.deduped(p), length: 3.0, at: .zero, i == 1 ? tones[0] : stone, bevel: 0.002)
            _ = i
        }
        FO.comb(&m, count: 40, pitch: 0.075, w: 0.04, h: 0.045, y0: 2.765, z0: 0.3, depth: 0.04, tones[2])
        // Frieze joint (mid-span) and a lead-sealed cornice joint.
        FA.box(&m, V3(0.004, 0.22, 0.003), V3(0.55, 2.63, 0.2915), soot, r: 0.0008)
        FA.box(&m, V3(0.004, 0.22, 0.003), V3(-0.8, 2.63, 0.2915), soot, r: 0.0008)

        // Weathering: soot runs under the cornice and from the roundel rims, a damp patch at the plinth.
        for _ in 0..<12 {
            let x = rng.float(-1.4...1.4)
            FO.streak(&m, x: x, top: 2.74, w: rng.float(0.03...0.07), h: rng.float(0.1...0.24), z: 0.2915, "stone.limestone:6F685A")
        }
        for s: Float in [-1, 1] {
            FO.streak(&m, x: s * 1.025, top: sp + 0.2, w: 0.04, h: 0.16, z: 0.2415, "stone.limestone:7E7766")
            FA.box(&m, V3(0.3, 0.14, 0.002), V3(s * 0.6, 0.07, pierD + 0.0215), "stone.limestone:6A6454", r: 0.001)
        }

        groundAO(&m, height: 0.12, floor: 0.88)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
