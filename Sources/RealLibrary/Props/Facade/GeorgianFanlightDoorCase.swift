import simd
import Foundation

/// Georgian door case, 1.4 x 3.0 x 0.35 m, painted timber: six-panel door with bolection beads, brass hinges, letterbox,
/// knocker and kickplate; semicircular fanlight with radial and ring bars under a moulded archivolt and keystone;
/// reeded pilasters on plinths with Doric capitals; architrave, frieze, dentil cornice and a low triangular pediment
/// over two limestone steps. Wall plane at z = 0, piece projecting toward +Z.
public struct GeorgianFanlightDoorCase: RealAsset {
    public static let id = "georgian-fanlight-door-case"
    public static let summary = "Georgian door case, 1.4 x 3.0 m: six-panel door, semicircular fanlight, reeded pilasters, dentil cornice, pediment, stone steps."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 5.2)

    /// Painted case: pilasters, architrave, cornice and pediment.
    public var paint: MaterialKey = "wood.painted-exterior:E2DAC5"
    /// Door leaf paint.
    public var door: MaterialKey = "wood.painted-exterior:2B4A3B"
    /// Worn paint where boots and rain reach.
    public var worn: MaterialKey = "wood.trim-weathered"
    /// Step stone.
    public var stone: MaterialKey = "stone.limestone:C9BFA3"
    /// Door furniture.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let stepTop: Float = 0.15
        let spring: Float = 2.1, R: Float = 0.45

        // Two limestone steps with worn nosings.
        FA.box(&m, V3(1.4, 0.08, 0.35), V3(0, 0.04, 0.175), stone, r: 0.006)
        FA.box(&m, V3(1.12, 0.07, 0.27), V3(0, 0.115, 0.135), "stone.limestone:BFB598", r: 0.006)
        FA.box(&m, V3(1.12, 0.004, 0.012), V3(0, 0.15, 0.264), "stone.limestone:6F685A", r: 0.001)

        // Reeded pilasters on plinths with capitals.
        for s: Float in [-1, 1] {
            let x = s * 0.62
            FA.box(&m, V3(0.17, 0.12, 0.12), V3(x, stepTop + 0.06, 0.06), worn, r: 0.004)
            FA.box(&m, V3(0.15, 0.03, 0.11), V3(x, stepTop + 0.135, 0.055), paint, r: 0.003)
            FA.box(&m, V3(0.14, 2.2, 0.09), V3(x, 0.3 + 1.1 + 0.0, 0.045), paint, r: 0.004)
            for k in -1...1 {   // reeds: proud half-round beads
                FA.rod(&m, V3(x + Float(k) * 0.038, 0.32, 0.092), V3(x + Float(k) * 0.038, 2.48, 0.092), r: 0.013, paint, sides: 6)
            }
            FA.box(&m, V3(0.12, 0.02, 0.09), V3(x, 2.5, 0.045), paint, r: 0.003)
            let ech = [V2(-0.055, 0), V2(0.055, 0), V2(0.075, 0.05), V2(-0.075, 0.05)]
            m.add(Prim.extrude(FO.ccw(ech), depth: 0.1, bevel: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x, 2.51, 0.05)))
            FA.box(&m, V3(0.18, 0.05, 0.12), V3(x, 2.595, 0.06), paint, r: 0.004)
        }

        // Jamb architraves with a bead, transom bar over the door and the archivolt of the fanlight.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.09, spring - stepTop, 0.12), V3(s * 0.495, (spring + stepTop) / 2, 0.06), paint, r: 0.004)
            FA.rod(&m, V3(s * 0.452, stepTop, 0.123), V3(s * 0.452, spring, 0.123), r: 0.009, paint, sides: 6)
        }
        FA.box(&m, V3(1.0, 0.05, 0.12), V3(0, 2.075, 0.06), paint, r: 0.004)
        let arch: [V2] = [V2(0, 0), V2(0.12, 0), V2(0.12, 0.015), V2(0.14, 0.03), V2(0.14, 0.06), V2(0, 0.06)]
        let aPath = FC.archPath(width: R * 2, spring: 0, pointed: false, z: 0, steps: 24).map { V3($0.x, $0.y + spring, 0) }
        m.add(Prim.sweep(arch, along: aPath, up: V3(0, 0, 1), material: paint))
        // Keystone block.
        FA.box(&m, V3(0.1, 0.13, 0.15), V3(0, spring + R + 0.03, 0.075), paint, r: 0.004)

        // Fanlight: single glass sheet, radial bars from the hub, two ring bars.
        let outline = FC.archOutline(width: R * 2 - 0.02, spring: 0, pointed: false, steps: 24)
        m.add(Prim.extrude(outline, depth: 0.008, bevel: 0.0005, bevelSegments: 1, material: "glass.tinted"),
              Xform(translation: V3(0, spring + 0.025, 0.05)))
        for k in 1...7 {
            let a = Float(k) * .pi / 8
            FA.rod(&m, V3(0, spring + 0.025, 0.065), V3(cos(a) * (R - 0.01), spring + 0.025 + sin(a) * (R - 0.01), 0.065), r: 0.006, paint, sides: 6)
        }
        for r in [Float(0.17), 0.31] {
            let ring = FO.ellipse(c: V2(0, spring + 0.025), rx: r, ry: r, from: 2, to: 178, steps: 18, z: 0.067)
            FA.path(&m, ring, r: 0.0055, paint, sides: 6)
        }
        m.add(Prim.superellipsoid(V3(0.1, 0.05, 0.03), exponent: 2, subdivisions: 4, material: paint), Xform(translation: V3(0, spring + 0.04, 0.07)))
        // Fanlight frame inside the reveal.
        let fr = FC.archPath(width: R * 2 - 0.02, spring: 0, pointed: false, z: 0.062, steps: 24).map { V3($0.x, $0.y + spring + 0.025, $0.z) }
        FA.path(&m, fr, r: 0.012, paint, sides: 6)

        // Door leaf: slab, stiles and rails, six recessed panels with bead mouldings.
        let dTop: Float = 2.05
        let dH = dTop - stepTop
        FA.box(&m, V3(0.9, dH, 0.03), V3(0, stepTop + dH / 2, 0.06), door, r: 0.002)
        let stile: Float = 0.1
        FA.box(&m, V3(stile, dH, 0.045), V3(-0.4, stepTop + dH / 2, 0.0675), door, r: 0.003)
        FA.box(&m, V3(stile, dH, 0.045), V3(0.4, stepTop + dH / 2, 0.0675), door, r: 0.003)
        FA.box(&m, V3(0.08, dH, 0.045), V3(0, stepTop + dH / 2, 0.0675), door, r: 0.003)
        let rows: [(Float, Float)] = [(0.56, 0.42), (1.2, 0.70), (1.79, 0.32)]   // centre y, height
        FA.box(&m, V3(0.9, 0.2, 0.045), V3(0, stepTop + 0.1, 0.0675), "wood.painted-exterior:27422F", r: 0.003)
        let midRails: [Float] = [0.81, 1.59]
        for y in midRails {
            FA.box(&m, V3(0.9, 0.08, 0.045), V3(0, y, 0.0675), door, r: 0.003)
        }
        FA.box(&m, V3(0.9, 0.1, 0.045), V3(0, dTop - 0.05, 0.0675), door, r: 0.003)
        for (ri, (cy, h)) in rows.enumerated() {
            for s: Float in [-1, 1] {
                let cx = s * 0.19
                let w: Float = 0.3
                m.add(Prim.extrude(Shape2D.roundedRect(w, h, radius: 0.008), depth: 0.016, bevel: 0.003, bevelSegments: 1,
                                   material: ri == 0 ? "wood.painted-exterior:27422F" : door),
                      Xform(translation: V3(cx, cy, 0.083)))
                let loop: [V3] = [V3(cx - w / 2, cy - h / 2, 0.094), V3(cx + w / 2, cy - h / 2, 0.094), V3(cx + w / 2, cy + h / 2, 0.094),
                                  V3(cx - w / 2, cy + h / 2, 0.094), V3(cx - w / 2, cy - h / 2, 0.094)]
                FA.path(&m, loop, r: 0.005, door, sides: 6)
            }
        }
        // Brass hinges, letterbox, knocker, knob and escutcheon, kickplate.
        for y in [Float(0.45), 1.1, 1.75] {
            FA.box(&m, V3(0.07, 0.11, 0.005), V3(-0.42, y, 0.0935), brass, r: 0.0015)
            FA.rod(&m, V3(-0.452, y - 0.055, 0.095), V3(-0.452, y + 0.055, 0.095), r: 0.007, brass, sides: 8)
            for dy: Float in [-0.035, 0.035] { FC.bead(&m, r: 0.004, at: V3(-0.415, y + dy, 0.097), brass, sub: 2) }
        }
        FA.box(&m, V3(0.26, 0.06, 0.008), V3(0, 1.64, 0.0905), brass, r: 0.002)
        FA.box(&m, V3(0.2, 0.012, 0.004), V3(0, 1.64, 0.096), "metal.cast-iron", r: 0.001)
        FA.box(&m, V3(0.07, 0.12, 0.008), V3(0, 1.8, 0.0905), brass, r: 0.003)
        m.add(Prim.torus(major: 0.035, minor: 0.007, segments: 16, sides: 6, material: brass),
              Xform(translation: V3(0, 1.76, 0.108), rotation: FA.q(90, FA.X)))
        FC.bead(&m, r: 0.014, at: V3(0, 1.84, 0.1), brass, sub: 3)
        m.add(Prim.lathe([V2(0, 0), V2(0.03, 0), V2(0.03, 0.004), V2(0.012, 0.01), V2(0.012, 0.03), V2(0.028, 0.045), V2(0.026, 0.06), V2(0, 0.065)],
                         segments: 12, seamTile: 0.1, material: brass),
              Xform(translation: V3(0.34, 1.0, 0.094), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.025, 0.045, 0.004), V3(0.34, 0.9, 0.093), brass, r: 0.001)
        FA.box(&m, V3(0.78, 0.17, 0.006), V3(0, stepTop + 0.095, 0.0905), brass, r: 0.002)
        for dx: Float in [-0.35, 0.35] { for dy: Float in [0.03, 0.16] { FC.bead(&m, r: 0.004, at: V3(dx, stepTop + dy, 0.094), brass, sub: 2) } }
        // Scuffs on the kickplate and a flaking patch at the bottom of the left pilaster.
        FO.streak(&m, x: -0.2, top: stepTop + 0.15, w: 0.2, h: 0.03, z: 0.094, "metal.cast-iron")
        FO.streak(&m, x: -0.62, top: 0.7, w: 0.08, h: 0.38, z: 0.1045, worn)

        // Entablature: architrave, frieze with a patera, dentil cornice.
        let ent: [[V2]] = [
            [V2(0, 2.62), V2(0.14, 2.62), V2(0.14, 2.66), V2(0.16, 2.67), V2(0.16, 2.70), V2(0, 2.70)],
            [V2(0, 2.70), V2(0.15, 2.70), V2(0.15, 2.78), V2(0, 2.78)],
            [V2(0, 2.78), V2(0.145, 2.78), V2(0.145, 2.81), V2(0.17, 2.81), V2(0.17, 2.83), V2(0.30, 2.83), V2(0.30, 2.855),
             V2(0.27, 2.865), V2(0, 2.865)]
        ]
        for p in ent { FA.run(&m, p, length: 1.4, at: .zero, paint, bevel: 0.002) }
        FO.comb(&m, count: 17, pitch: 0.075, w: 0.04, h: 0.03, y0: 2.78, z0: 0.145, depth: 0.03, paint)
        FO.rosette(&m, at: V3(0, 2.74, 0.155), r: 0.032, petals: 6, paint)

        // Pediment: tympanum and two raking cornices.
        let tym = [V2(-0.69, 2.865), V2(0.69, 2.865), V2(0, 2.945)]
        m.add(Prim.extrude(FO.ccw(tym), depth: 0.18, bevel: 0.003, bevelSegments: 1, material: paint), Xform(translation: V3(0, 0, 0.09)))
        let rake: [V2] = [V2(0, 0), V2(0.27, 0), V2(0.30, 0.01), V2(0.30, 0.028), V2(0.27, 0.04), V2(0, 0.04)]
        let ang = atan2(Float(0.09), Float(0.7)) * 180 / .pi
        let len = sqrt(Float(0.7 * 0.7 + 0.09 * 0.09))
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(rake, depth: len, bevel: 0.002, bevelSegments: 1, material: paint),
                  Xform(translation: V3(s * 0.35, 2.865 + 0.045, 0), rotation: FA.q(-s * ang, FA.Z) * FA.q(-90, FA.Y)))
        }

        // Weathering on the cornice and pilaster faces: runs below the corona.
        for _ in 0..<6 {
            FO.streak(&m, x: rng.float(-0.6...0.6), top: 2.83, w: rng.float(0.015...0.04), h: rng.float(0.05...0.15), z: 0.148, "wood.trim-weathered")
        }

        groundAO(&m, height: 0.15, floor: 0.88)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
