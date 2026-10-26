import simd
import Foundation

/// Early English Gothic triple lancet window, 1.8 x 2.8 x 0.3 m: three acute lancets (taller centre) in a coursed
/// ashlar wall, each with a chamfered arch ring, a nook-shaft roll order on turned bases and capitals, a hood mould
/// ending in label stops, leaded glazing with iron saddle bars and copper ties, a string course and a drip sill.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct LancetTripleWindow: RealAsset {
    public static let id = "lancet-triple-window"
    public static let summary = "Early English Gothic triple lancet window, 1.8 m: three pointed lights, nook shafts, hood moulds, label stops, leaded glass, sill."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 5.2)

    /// Ashlar and arch stone.
    public var stone: MaterialKey = "stone.limestone:CDC3A8"
    /// Sooted stone for sills, bases and joints.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Wrought iron saddle bars.
    public var iron: MaterialKey = "metal.wrought-iron:2B2A27"
    /// Lead cames.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let tones: [MaterialKey] = [stone, "stone.limestone:C0B496", "stone.limestone:D2C9AF", "stone.limestone:C7BC9F"]
        let sillTop: Float = 0.2, wallTop: Float = 2.68, wallD: Float = 0.22

        // Lights: centre x, half width, arc radius, springing height.
        let lights: [(Float, Float, Float, Float)] = [(-0.5, 0.17, 0.5, 1.7), (0, 0.21, 0.6, 1.95), (0.5, 0.17, 0.5, 1.7)]

        // Ashlar piers: two outer and two between the lights, in six courses with staggered joint tone.
        let piers: [(Float, Float)] = [(-0.785, 0.23), (-0.27, 0.12), (0.27, 0.12), (0.785, 0.23)]
        let nC = 6
        let ch = (wallTop - sillTop) / Float(nC)
        for (pi, (x, w)) in piers.enumerated() {
            for k in 0..<nC {
                FA.box(&m, V3(w - 0.004, ch - 0.005, wallD), V3(x, sillTop + ch * (Float(k) + 0.5), wallD / 2), tones[(k * 3 + pi) % 4], r: 0.003)
            }
        }
        // Spandrels above each arch: polygon between the arch and the string course.
        for (i, (cx, hw, R, sp)) in lights.enumerated() {
            var pts = FO.lancetArc(hw: hw, R: R, spring: sp, cx: cx).map { V2($0.x, $0.y) }
            pts += [V2(cx - hw, wallTop), V2(cx + hw, wallTop)]
            m.add(Prim.extrude(FO.ccw(Shape2D.deduped(pts)), depth: wallD, bevel: 0.003, bevelSegments: 1, material: tones[(i + 1) % 4]),
                  Xform(translation: V3(0, 0, wallD / 2)))
            // Coursing joints across the spandrel.
            var y = sp + 0.28
            while y < wallTop - 0.05 {
                FA.box(&m, V3(hw * 2, 0.004, 0.003), V3(cx, y, wallD + 0.0005), soot, r: 0.0008)
                y += 0.28
            }
        }

        for (i, (cx, hw, R, sp)) in lights.enumerated() {
            let apex = FO.lancetApex(hw: hw, R: R, spring: sp)
            // Glass and leading, recessed in the reveal.
            let outline = FO.lancetOutline(hw: hw - 0.01, R: R, spring: sp, steps: 14)
            m.add(Prim.extrude(outline, depth: 0.008, bevel: 0.0005, bevelSegments: 1, material: "glass.tinted"),
                  Xform(translation: V3(cx, sillTop + 0.005, 0.07)))
            let top = apex - 0.04
            for k in 0..<5 {   // saddle bars with copper ties
                let y = sillTop + 0.35 + Float(k) * 0.3
                if y > sp + 0.2 { break }
                FA.box(&m, V3(hw * 2 - 0.01, 0.013, 0.012), V3(cx, y, 0.085), iron, r: 0.002)
                for s: Float in [-1, 1] { FC.bead(&m, r: 0.006, at: V3(cx + s * (hw - 0.03), y, 0.093), "metal.copper-patina", sub: 2) }
            }
            for k in 1...2 {   // vertical cames
                let x = cx - hw + 2 * hw * Float(k) / 3
                FA.box(&m, V3(0.007, top - sillTop, 0.007), V3(x, (top + sillTop) / 2 + 0.003, 0.084), lead, r: 0.001)
            }
            // Central stanchion in the arch head: one came up the axis and a lead roundel.
            FA.box(&m, V3(0.007, apex - sp, 0.007), V3(cx, (apex + sp) / 2 - 0.02, 0.084), lead, r: 0.001)
            FA.rod(&m, V3(cx - hw + 0.015, sp + 0.07, 0.085), V3(cx + hw - 0.015, sp + 0.07, 0.085), r: 0.004, lead, sides: 6)

            // Nook shafts at each jamb: base, shaft, capital (turned), then the roll moulding springing from the capitals.
            for s: Float in [-1, 1] {
                let x = cx + s * hw
                let base: [V2] = [V2(0, 0), V2(0.036, 0), V2(0.036, 0.02), V2(0.028, 0.03), V2(0.024, 0.05), V2(0, 0.05)]
                m.add(Prim.lathe(base, segments: 10, seamTile: 0.1, material: soot), Xform(translation: V3(x, sillTop, 0.185)))
                FA.rod(&m, V3(x, sillTop + 0.05, 0.185), V3(x, sp - 0.07, 0.185), r: 0.022, tones[(i + 2) % 4], sides: 10)
                let cap: [V2] = [V2(0, 0), V2(0.026, 0), V2(0.03, 0.02), V2(0.04, 0.04), V2(0.042, 0.065), V2(0, 0.065)]
                m.add(Prim.lathe(cap, segments: 10, seamTile: 0.1, material: tones[(i + 1) % 4]), Xform(translation: V3(x, sp - 0.07, 0.185)))
                // Label stop: small carved boss at the end of the hood mould.
                m.add(Prim.superellipsoid(V3(0.075, 0.075, 0.05), exponent: 2.4, subdivisions: 4, material: tones[(i + 3) % 4]),
                      Xform(translation: V3(x + s * 0.11, sp - 0.02, 0.19)))
            }
            let roll = FO.lancetArc(hw: hw, R: R, spring: sp, delta: 0, cx: cx, z: 0.185, steps: 9)
            FA.path(&m, roll, r: 0.022, tones[(i + 1) % 4], sides: 8)
            // Chamfered arch ring outside the roll.
            let ring: [V2] = [V2(0, 0), V2(0.2, 0), V2(0.2, 0.01), V2(0.23, 0.045), V2(0.23, 0.075), V2(0, 0.075)]
            let ringPath = FO.lancetArc(hw: hw, R: R, spring: sp, delta: 0.03, cx: cx, z: 0, steps: 9)
            m.add(Prim.sweep(ring, along: ringPath, up: V3(0, 0, 1), material: tones[i % 4]))
            // Hood mould with a drip.
            let hood: [V2] = [V2(0.1, 0), V2(0.26, 0), V2(0.3, 0.014), V2(0.3, 0.036), V2(0.27, 0.05), V2(0.1, 0.05)]
            let hoodPath = FO.lancetArc(hw: hw, R: R, spring: sp, delta: 0.11, cx: cx, z: 0, steps: 9)
            m.add(Prim.sweep(hood, along: hoodPath, up: V3(0, 0, 1), material: tones[(i + 2) % 4]))
        }

        // String course along the top with a drip, sill slab with sloped top and drip groove.
        let str: [V2] = [V2(0, wallTop), V2(0.24, wallTop), V2(0.24, wallTop + 0.02), V2(0.3, wallTop + 0.045), V2(0.3, wallTop + 0.1), V2(0.26, wallTop + 0.12), V2(0, wallTop + 0.12)]
        FA.run(&m, str, length: 1.8, at: .zero, stone, bevel: 0.002)
        let sill: [V2] = [V2(0, 0), V2(0.26, 0), V2(0.26, 0.016), V2(0.3, 0.016), V2(0.3, 0.05), V2(0.2, sillTop), V2(0, sillTop)]
        FA.run(&m, sill, length: 1.8, at: .zero, soot, bevel: 0.002)
        for cx: Float in [-0.5, 0, 0.5] {
            FA.box(&m, V3(0.34, 0.003, 0.18), V3(cx, sillTop + 0.001, 0.1), "stone.limestone:5E5849", r: 0.001)
        }

        // Weathering: soot runs from the hood moulds and sill, lime wash streaks on the spandrels.
        for _ in 0..<14 {
            let x = rng.float(-0.85...0.85)
            FO.streak(&m, x: x, top: rng.float(1.4...2.6), w: rng.float(0.02...0.05), h: rng.float(0.1...0.35), z: wallD, "stone.limestone:6F685A")
        }
        for s: Float in [-1, 1] {
            FO.streak(&m, x: s * 0.27, top: 2.2, w: 0.05, h: 1.6, z: wallD, "stone.limestone:827A68")
            FO.streak(&m, x: s * 0.79, top: 1.9, w: 0.07, h: 1.2, z: wallD, "stone.limestone:766F5E")
            FO.streak(&m, x: s * 0.5, top: sillTop + 0.35, w: 0.3, h: 0.1, z: 0.19, "stone.limestone:5E5849")
        }
        FO.streak(&m, x: 0, top: sillTop + 0.35, w: 0.38, h: 0.1, z: 0.19, "stone.limestone:5E5849")

        groundAO(&m, height: 0.2, floor: 0.88)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
