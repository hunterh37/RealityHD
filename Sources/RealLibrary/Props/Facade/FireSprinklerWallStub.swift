import simd
import Foundation

/// Wall sprinkler stub: architectural facade customizer, Commercial. Red-painted 1 in Schedule 40 riser on two
/// one-hole pipe straps, a grooved coupling with bolt pads, threaded end cap, long-radius elbow, hex bushing and
/// a standard-response sidewall sprinkler (frame arms, deflector, red glass bulb). Paint is scuffed to bare
/// steel on the strap contacts and rusty at the cap thread.
public struct FireSprinklerWallStub: RealAsset {
    public static let id = "fire-sprinkler-wall-stub"
    public static let summary = "Sidewall sprinkler on pipe stub, 0.3 m: red pipe, grooved coupling, frame, deflector and glass bulb."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, distance: 1.3)

    /// Pipe paint.
    public var paint: MaterialKey = "metal.fire-extinguisher-red"
    /// Bulb liquid, 68 C red.
    public var bulb: MaterialKey = "sign.red"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let steel: MaterialKey = "metal.steel", rust: MaterialKey = "metal.rust", grime: MaterialKey = "metal.rust-grime", chrome: MaterialKey = "metal.chrome"
        let pr: Float = 0.0167, pz: Float = 0.025, yTop: Float = 0.262, R: Float = 0.018
        // Riser pipe with a threaded, hex-bodied end cap at the foot.
        FSV.cyl(&m, V3(0, 0.024, pz), V3(0, yTop, pz), r: pr, paint, bevel: 0.0008, segments: 20)
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.0235), depth: 0.026, bevel: 0.0025, bevelSegments: 1, material: "metal.cast-iron"),
              Xform(translation: V3(0, 0.013, pz), rotation: FA.q(-90, FA.X)))
        FSV.cyl(&m, V3(0, 0.024, pz), V3(0, 0.032, pz), r: pr + 0.0015, rust, bevel: 0.0006, segments: 16)
        FSV.cyl(&m, V3(0, 0.0, pz), V3(0, 0.002, pz), r: 0.019, grime, bevel: 0.0005, segments: 12)
        // Pipe straps: collar loop, flat tail to a wall plate with two screws.
        for y: Float in [0.07, 0.205] {
            m.add(Prim.torus(major: pr + 0.0018, minor: 0.0018, segments: 18, sides: 5, material: steel), Xform(translation: V3(0, y, pz)))
            FA.box(&m, V3(0.04, 0.014, 0.0016), V3(0, y, 0.0165), steel, r: 0.0005)
            FA.box(&m, V3(0.048, 0.022, 0.004), V3(0, y, 0.002), steel, r: 0.001)
            for s: Float in [-1, 1] { FSV.screw(&m, at: V3(s * 0.017, y, 0.004), normal: FA.Z, r: 0.0034) }
        }
        // Grooved coupling: housing halves, gasket lips, two bolt pads with nuts, locating tongue.
        let cy: Float = 0.135
        m.add(Prim.lathe([V2(pr + 0.0006, cy - 0.027), V2(0.0235, cy - 0.027), V2(0.0255, cy - 0.022), V2(0.0255, cy + 0.022), V2(0.0235, cy + 0.027), V2(pr + 0.0006, cy + 0.027)],
                          segments: 20, seamTile: 0.2, material: "metal.painted:C3281C"), Xform(translation: V3(0, 0, pz)))
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.017, 0.044, 0.02), V3(s * 0.032, cy, pz), "metal.painted:C3281C", r: 0.0025)
            FSV.cyl(&m, V3(s * 0.027, cy + 0.011, pz), V3(s * 0.046, cy + 0.011, pz), r: 0.0033, steel, bevel: 0.0006, segments: 8)
            FSV.cyl(&m, V3(s * 0.027, cy - 0.011, pz), V3(s * 0.046, cy - 0.011, pz), r: 0.0033, steel, bevel: 0.0006, segments: 8)
            FSV.bolt(&m, at: V3(s * 0.0425, cy + 0.011, pz), normal: V3(s, 0, 0), size: 0.01, material: steel)
            FSV.bolt(&m, at: V3(s * 0.0425, cy - 0.011, pz), normal: V3(s, 0, 0), size: 0.01, material: steel)
        }
        // Yellow identification band on the pipe.
        FSV.cyl(&m, V3(0, 0.178, pz), V3(0, 0.19, pz), r: pr + 0.0006, "metal.signal-yellow", bevel: 0.0003, segments: 18)
        // Long-radius elbow turning the riser toward +Z.
        let arc: [V3] = (0...8).map { i in
            let t = Float(i) / 8 * (.pi / 2)
            return V3(0, yTop + R * sin(t), pz + R * (1 - cos(t)))
        }
        FA.path(&m, arc, r: pr + 0.0012, paint, sides: 16)
        let zN = pz + R, yN = yTop + R
        // Nipple and hex bushing, then the sprinkler body.
        FSV.cyl(&m, V3(0, yN, zN), V3(0, yN, zN + 0.018), r: pr, paint, bevel: 0.0008, segments: 16)
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.0225 / sqrt(3) * 1.15), depth: 0.012, bevel: 0.0015, bevelSegments: 1, material: chrome),
              Xform(translation: V3(0, yN, zN + 0.014), rotation: FA.q(0, FA.X)))
        let zB = zN + 0.02
        m.add(Prim.lathe([V2(0, 0), V2(0.0125, 0), V2(0.0125, 0.006), V2(0.0092, 0.01), V2(0.0092, 0.022), V2(0.0072, 0.024), V2(0, 0.024)],
                         segments: 14, seamTile: 0.1, material: "metal.brass"), Xform(translation: V3(0, yN, zB), rotation: facing(FA.Z)))
        // Frame arms and deflector.
        let zD = zB + 0.036
        for s: Float in [-1, 1] {
            FA.path(&m, [V3(s * 0.0092, yN, zB + 0.018), V3(s * 0.0108, yN, zB + 0.024), V3(s * 0.008, yN + 0.002, zB + 0.031), V3(s * 0.0028, yN + 0.002, zD - 0.002)], r: 0.0017, "metal.brass", sides: 6)
        }
        FA.box(&m, V3(0.0125, 0.0012, 0.0125), V3(0, yN + 0.0132, zB + 0.034), "metal.brass", r: 0.0003)
        m.add(Prim.cylinder(radius: 0.0165, height: 0.0016, bevel: 0.0004, segments: 18, bevelSegments: 1, material: chrome),
              Xform(translation: V3(0, yN, zD), rotation: facing(FA.Z)))
        FSV.cyl(&m, V3(0, yN, zD - 0.0016), V3(0, yN, zD + 0.003), r: 0.0042, "metal.brass", bevel: 0.0004, segments: 8)
        // Glass bulb with a thermal liquid tip and seat cup.
        FSV.cyl(&m, V3(0, yN, zB + 0.024), V3(0, yN, zD - 0.002), r: 0.0034, bulb, bevel: 0.0014, segments: 10)
        FC.bead(&m, r: 0.0012, at: V3(0, yN, zD - 0.002), "metal.brass")
        // Wear: scuffs, drips below the coupling and overspray tide marks.
        for _ in 0..<4 {
            let y = rng.float(0.04...0.23)
            FA.box(&m, V3(0.006, rng.float(0.004...0.012), 0.0006), V3(rng.float(-0.006...0.006), y, pz + pr + 0.0004), "metal.steel", r: 0.0002)
        }
        FSV.streak(&m, at: V3(0.012, 0.1, pz + pr + 0.0004), w: 0.004, h: 0.03, rust)
        // Ceiling-paint overspray flecks on the upper pipe and a chip on the coupling.
        for _ in 0..<9 {
            let a = rng.float(-0.9...0.9), y = rng.float(0.2...0.255)
            FA.box(&m, V3(rng.float(0.002...0.006), rng.float(0.002...0.005), 0.0006), V3((pr + 0.0003) * sin(a), y, pz + (pr + 0.0003) * cos(a)), "metal.painted:EDEBE4", r: 0.0003, rot: FA.q(a * 57.3, FA.Y))
        }
        FA.box(&m, V3(0.008, 0.005, 0.0006), V3(-0.011, cy + 0.005, pz + 0.0258), "metal.steel", r: 0.0002)
        return LODModel(FC.seatY(m))
    }
}
