import simd
import Foundation

/// Colonial Revival carriage coach lamp, 0.5 m: round back plate with brass screws, a wrought C-scroll bracket
/// arm, base cup, tapered four-pane lantern with muntins and corner posts, glowing bulb, domed cap with vent
/// and ball finial. Black powder-coated iron, brass trim, rain-streaked below the cap.
public struct CarriageCoachLamp: RealAsset {
    public static let id = "carriage-coach-lamp"
    public static let summary = "Colonial Revival carriage coach lamp, 0.5 m: wall plate, short arm, tapered glass lantern with muntins, cap and finial."
    public static let tags = ["prop", "architecture", "facade", "light", "metal", "trim"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 0.9)

    /// Powder-coated iron.
    public var iron: MaterialKey = "metal.powdercoat:141416"
    /// Weathered paint on the cap, which takes the rain.
    public var capPaint: MaterialKey = "metal.painted:141416"
    /// Brass screws, collars and finial.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Lantern panes.
    public var glass: MaterialKey = "glass.pane"
    /// Bulb.
    public var bulb: MaterialKey = "emissive.warm"
    /// Rust bleeding from the screws.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zc: Float = 0.172          // lantern axis out from the wall
        let plateY: Float = 0.115
        let y0: Float = 0.145, y1: Float = 0.385, h0: Float = 0.056, h1: Float = 0.095
        let dy: Float = y1 - 0.36      // cap rides on the taller body

        // Back plate: domed disc with a raised rim ring, four brass screws and a rust tear under the lowest.
        m.add(Prim.lathe([V2(0, 0.012), V2(0.07, 0.012), V2(0.074, 0.009), V2(0.074, 0.003), V2(0.071, 0), V2(0, 0)], segments: 40, material: iron),
              Xform(translation: V3(0, plateY, 0), rotation: FA.q(90, FA.X)))
        m.add(Prim.torus(major: 0.062, minor: 0.0035, segments: 40, sides: 8, material: iron),
              Xform(translation: V3(0, plateY, 0.013), rotation: FA.q(90, FA.X)))
        FA.cylZ(&m, r: 0.024, h: 0.01, at: V3(0, plateY, 0.012), iron, bevel: 0.003, segments: 24)
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            let p = V3(0.05 * cos(a), plateY + 0.05 * sin(a), 0.0125)
            FA.cylZ(&m, r: 0.0058, h: 0.003, at: p, brass, bevel: 0.0012, segments: 12)
            FA.box(&m, V3(0.0016, 0.007, 0.0012), p + V3(0, 0, 0.0034), iron, r: 0.0004, rot: FA.q(rng.float(-40...40), FA.Z))
        }
        m.add(Prim.superellipsoid(V3(0.007, rng.float(0.03...0.045), 0.0016), exponent: 2.4, subdivisions: 2, material: rust),
              Xform(translation: V3(0.035, plateY - 0.05, 0.0135)))
        // Arm: round bar from the boss into the base cup, braced by a C-scroll that curls out and up under it.
        let armY: Float = 0.108
        FA.rod(&m, V3(0, plateY, 0.018), V3(0, armY, zc - 0.02), r: 0.0085, iron, sides: 12)
        let cs = catmull([V3(0, 0.07, 0.016), V3(0, 0.045, 0.045), V3(0, 0.032, 0.09), V3(0, 0.05, 0.128), V3(0, 0.082, 0.138), V3(0, 0.09, 0.122)], per: 6)
        m.add(Prim.tube(cs, radii: cs.indices.map { 0.0062 - 0.0027 * Float($0) / Float(cs.count - 1) }, sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        FC.bead(&m, r: 0.0062, at: cs.last!, iron, sub: 3)
        FA.cylZ(&m, r: 0.013, h: 0.012, at: V3(0, plateY, 0.018), brass, bevel: 0.002, segments: 16)
        // Base cup: inverted cone with a brass rim band.
        let cupY = y0 - 0.052
        m.add(turned([(0, cupY), (0.03, cupY), (0.034, cupY + 0.004), (0.045, cupY + 0.026), (0.058, cupY + 0.044), (0.058, cupY + 0.052), (0, cupY + 0.052)],
                     segments: 28, material: iron), Xform(translation: V3(0, 0, zc)))
        m.add(Prim.torus(major: 0.056, minor: 0.0028, segments: 28, sides: 6, material: brass), Xform(translation: V3(0, y0 - 0.004, zc)))
        // Lantern body.
        FC.lantern(&m, c: V3(0, 0, zc), y0: y0, y1: y1, h0: h0, h1: h1, post: 0.0045, frame: iron, glass: glass, muntins: true, rng: &rng)
        // Bulb on a brass socket.
        m.add(Prim.cylinder(radius: 0.013, height: 0.024, bevel: 0.002, segments: 14, bevelSegments: 1, material: brass), Xform(translation: V3(0, y0 + 0.004, zc)))
        m.add(Prim.superellipsoid(V3(0.04, 0.062, 0.04), exponent: 2, subdivisions: 6, material: bulb), Xform(translation: V3(0, y0 + 0.058, zc)))
        // Cap: eave plate stepping up through a bell to the vent neck, rounded-square rings.
        let steps: [(Float, Float, Float)] = [(0.0, 0.214, 0.012), (0.008, 0.22, 0.012), (0.014, 0.214, 0.01), (0.026, 0.184, 0.012),
                                              (0.042, 0.14, 0.014), (0.058, 0.1, 0.016), (0.07, 0.07, 0.018), (0.076, 0.052, 0.02)]
        let capRings = steps.map { Prim.ring(Shape2D.roundedRect($0.1, $0.1, radius: $0.2, segments: 3), y: y1 + $0.0, offset: V3(0, 0, zc)) }
        m.add(Prim.loft(capRings, capStart: false, capEnd: true, material: capPaint))
        m.add(Prim.loft([Prim.ring(Shape2D.roundedRect(0.214, 0.214, radius: 0.012, segments: 3), y: y1, offset: V3(0, 0, zc)),
                         Prim.ring(Shape2D.roundedRect(0.17, 0.17, radius: 0.012, segments: 3), y: y1, offset: V3(0, 0, zc))], material: iron).flipped())
        // Brass cap band and vent chimney with a rain cap.
        m.add(Prim.torus(major: 0.048, minor: 0.0028, segments: 24, sides: 6, material: brass), Xform(translation: V3(0, y1 + 0.04, zc)))
        m.add(turned([(0, 0.436 + dy), (0.022, 0.436 + dy), (0.022, 0.452 + dy), (0.034, 0.456 + dy), (0.034, 0.462 + dy), (0.022, 0.466 + dy), (0, 0.466 + dy)],
                     segments: 24, material: brass), Xform(translation: V3(0, 0, zc)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            FA.box(&m, V3(0.004, 0.012, 0.004), V3(0.026 * cos(a), 0.445 + dy, zc + 0.026 * sin(a)), brass, r: 0.001)
        }
        // Ball finial on a short stem.
        FA.rod(&m, V3(0, 0.466 + dy, zc), V3(0, 0.485 + dy, zc), r: 0.004, brass, sides: 8)
        FA.ball(&m, r: 0.0125, at: V3(0, 0.49 + dy, zc), brass)
        m.add(Prim.cylinder(radius: 0.0025, height: 0.008, bevel: 0.001, segments: 8, material: brass), Xform(translation: V3(0, 0.496 + dy, zc)))
        // Weathering: rust tears below the base cup rim and under the scroll tip.
        for k in 0..<3 {
            let a = Float(k) * 2.1 + 0.4
            m.add(Prim.superellipsoid(V3(0.005, rng.float(0.014...0.026), 0.0015), exponent: 2.4, subdivisions: 2, material: rust),
                  Xform(translation: V3(0.049 * cos(a), cupY + 0.03, zc + 0.049 * sin(a)), rotation: FA.q(90 - a * 180 / .pi, FA.Y)))
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
