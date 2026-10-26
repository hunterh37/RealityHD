import simd
import Foundation

/// Beaux-Arts glazed terracotta cornice, 2.0 m run, 0.40 m tall, 0.35 m projection: four hollow-cast units with mortar
/// joints, each carrying an egg-and-dart ovolo bed mould, a dentil course, a fillet band, a coffered soffit with
/// rosettes, a plain corona with a drip, and a cyma recta sima. Eight scrolled modillion brackets with acanthus leaves
/// hang under the corona. Galvanized anchor straps tie the units at the top. The buff glaze is sooted and crazed, chipped
/// to red body on the arrises, with run-off streaks below the corona.
public struct TerracottaCorniceModillionRun: RealAsset {
    public static let id = "terracotta-cornice-modillion-run"
    public static let summary = "Beaux-Arts terracotta cornice run: crown moulding, corona, carved modillions with acanthus scrolls, dentils and an egg-and-dart bed moulding, in glazed terracotta units."
    public static let tags = ["prop", "architecture", "facade", "ornament", "trim", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 3, distance: 3.4)

    /// Run length (m).
    public var length: Float = 2.0
    /// Glazed buff surface.
    public var glaze: MaterialKey = "ceramic.bisque:D6C29C"
    /// Sooted glaze on top surfaces and recesses.
    public var soot: MaterialKey = "ceramic.bisque:7C705B"
    /// Red clay body exposed where the glaze is chipped.
    public var body: MaterialKey = "ceramic.terracotta"
    public var mortar: MaterialKey = "brick.mortar-grey"
    public var strap: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let prof: [V2] = [V2(0, 0), V2(0.062, 0), V2(0.074, 0.004), V2(0.080, 0.014), V2(0.079, 0.028), V2(0.070, 0.040), V2(0.062, 0.045),
                          V2(0.062, 0.088), V2(0.108, 0.088), V2(0.108, 0.100), V2(0.068, 0.100), V2(0.068, 0.205),
                          V2(0.286, 0.205), V2(0.286, 0.200), V2(0.300, 0.200), V2(0.304, 0.205), V2(0.304, 0.268), V2(0.292, 0.276), V2(0.280, 0.282),
                          V2(0.262, 0.290), V2(0.250, 0.305), V2(0.254, 0.325), V2(0.280, 0.345), V2(0.318, 0.362), V2(0.340, 0.378), V2(0.350, 0.392),
                          V2(0.350, 0.400), V2(0, 0.400)]
        let units = 4, ul = L / Float(units) - 0.006
        let xs: [Float] = (0..<units).map { -L / 2 + L / Float(units) * (Float($0) + 0.5) }
        for (i, x) in xs.enumerated() {
            FA.run(&m, prof, length: ul, at: V3(x, 0, 0), i % 2 == 0 ? glaze : "ceramic.bisque:CDB88F", bevel: 0.0022)
        }
        // Mortar joints, set back a touch from the glazed face.
        let shr = prof.map { V2($0.x * 0.985, $0.y * 0.985 + 0.003) }
        for j in 1..<units { FA.run(&m, shr, length: 0.012, at: V3(-L / 2 + L / Float(units) * Float(j), 0, 0), mortar, bevel: 0.0008) }

        // Egg-and-dart on the ovolo: eggs with shells and slim darts between them.
        let pe: Float = 0.0625
        for i in 0..<Int(L / pe) - 1 {
            let x = -L / 2 + pe * (Float(i) + 1.0)
            m.add(Prim.superellipsoid(V3(0.04, 0.034, 0.014), exponent: 2.3, subdivisions: 2, material: glaze), Xform(translation: V3(x, 0.022, 0.078)))
            FJ.slab(&m, V3(0.006, 0.026, 0.004), V3(x + pe / 2, 0.022, 0.0805), glaze)
            FJ.slab(&m, V3(0.040, 0.004, 0.005), V3(x, 0.0375, 0.071), soot)                       // shell lip
        }
        // Dentil course.
        for i in 0..<Int(L / 0.045) {
            let x = -L / 2 + 0.0225 + 0.045 * Float(i)
            FJ.slab(&m, V3(0.025, 0.036, 0.036), V3(x, 0.066, 0.080), glaze)
        }
        // Modillions: scrolled brackets with acanthus leaves, a volute and a bead.
        let mp: [V2] = Shape2D.rounded([V2(0.068, 0.205), V2(0.200, 0.205), V2(0.206, 0.189), V2(0.200, 0.172), V2(0.184, 0.152), V2(0.160, 0.134),
                                        V2(0.130, 0.118), V2(0.098, 0.109), V2(0.068, 0.106)], radius: 0.004, segments: 2)
        for k in 0..<8 {
            let x = -L / 2 + 0.125 + 0.25 * Float(k)
            FA.run(&m, mp, length: 0.054, at: V3(x, 0, 0), glaze, bevel: 0.0022)
            for e: Float in [-1, 1] {
                m.add(Prim.superellipsoid(V3(0.006, 0.05, 0.075), exponent: 2.4, subdivisions: 2, material: glaze),
                      Xform(translation: V3(x + e * 0.0285, 0.158, 0.130), rotation: FA.q(-28, FA.X)))
                m.add(Prim.superellipsoid(V3(0.006, 0.034, 0.05), exponent: 2.4, subdivisions: 1, material: glaze),
                      Xform(translation: V3(x + e * 0.0285, 0.185, 0.095), rotation: FA.q(-18, FA.X)))
            }
            m.add(Prim.torus(major: 0.021, minor: 0.0075, segments: 14, sides: 5, arc: 1.5 * .pi, material: glaze),
                  Xform(translation: V3(x, 0.168, 0.176), rotation: FA.q(90, FA.Z) * FA.q(rng.float(150...200), FA.Y)))
            FC.bead(&m, r: 0.0085, at: V3(x, 0.206, 0.192), glaze, sub: 3)
        }
        // Coffer rosettes in the soffit between brackets.
        for x in [-0.75, -0.25, 0.25, 0.75] as [Float] {
            m.add(Prim.cylinder(radius: 0.036, height: 0.01, bevel: 0.002, segments: 20, bevelSegments: 1, material: soot), Xform(translation: V3(x, 0.195, 0.18)))
            for p in 0..<8 {
                let a = Float(p) / 8 * 2 * .pi
                FC.bead(&m, r: 0.006, at: V3(x + cos(a) * 0.022, 0.193, 0.18 + sin(a) * 0.022), glaze, sub: 1)
            }
            FC.bead(&m, r: 0.009, at: V3(x, 0.192, 0.18), glaze, sub: 3)
        }
        // Galvanized anchor straps over the unit joints, riveted down.
        for j in 1..<units {
            let x = -L / 2 + L / Float(units) * Float(j)
            FA.box(&m, V3(0.034, 0.004, 0.2), V3(x, 0.402, 0.12), strap, r: 0.001)
            for dz: Float in [0.04, 0.12, 0.2] { rivet(&m, at: V3(x, 0.404, dz), normal: FA.Y, radius: 0.0045, segments: 6, material: "metal.screw-zinc") }
        }
        // Wear: soot on the upper faces and in recesses, run-off streaks and crazing on the corona, chips to red clay.
        for i in 0..<9 {
            let x = -0.92 + Float(i) * 0.23 + rng.float(-0.04...0.04)
            FJ.slab(&m, V3(rng.float(0.05...0.14), 0.0016, rng.float(0.05...0.13)), V3(x, 0.401, rng.float(0.1...0.3)), soot)
            FJ.streak(&m, x: x + rng.float(-0.03...0.03), top: 0.268, length: rng.float(0.04...0.065), width: rng.float(0.012...0.03), z: 0.304, soot)
        }
        for i in 0..<6 {
            let x = -0.9 + Float(i) * 0.36 + rng.float(-0.05...0.05)
            FJ.slab(&m, V3(rng.float(0.06...0.12), 0.0014, 0.0014), V3(x, 0.235 + rng.float(-0.03...0.03), 0.3052), "ceramic.bisque:5A5242", rot: FA.q(rng.float(-30...30), FA.Z))   // glaze crazing
        }
        for _ in 0..<9 { FJ.peel(&m, at: V3(rng.float(-0.95...0.95), rng.float(0.215...0.26), 0.3042), w: rng.float(0.025...0.075), h: rng.float(0.012...0.03), body, rng: &rng) }
        for _ in 0..<6 { FJ.peel(&m, at: V3(rng.float(-0.95...0.95), 0.094, 0.1085), w: rng.float(0.03...0.07), h: rng.float(0.008...0.012), soot, rng: &rng) }
        for i in 0..<14 { FJ.streak(&m, x: -0.95 + Float(i) * 0.145 + rng.float(-0.03...0.03), top: 0.088, length: rng.float(0.03...0.08), width: rng.float(0.01...0.026), z: 0.1082, soot) }
        FJ.chips(&m, spots: [V3(-0.82, 0.23, 0), V3(-0.18, 0.25, 0), V3(0.44, 0.24, 0), V3(0.86, 0.22, 0)], face: 0.3042, body, rng: &rng, each: 5)
        FJ.chips(&m, spots: [V3(-0.55, 0.066, 0), V3(0.3, 0.066, 0), V3(0.7, 0.066, 0)], face: 0.0985, body, rng: &rng, each: 3)
        for sx: Float in [-1, 1] { FJ.peel(&m, at: V3(sx * 0.99, 0.3, 0.35), w: 0.01, h: 0.01, body, rng: &rng) }
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
