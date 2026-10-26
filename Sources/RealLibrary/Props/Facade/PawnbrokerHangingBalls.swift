import simd
import Foundation

/// Pawnbroker's sign: three brass balls hung from a wrought iron bracket. The bracket has a bolted wall
/// plate, a scrolled arm with a diagonal brace, a drop rod and cross bar, and each ball hangs from an
/// eye ring on an S hook. Balls are two spun halves with a soldered seam band and a polished upper face.
public struct PawnbrokerHangingBalls: RealAsset {
    public static let id = "pawnbroker-hanging-balls"
    public static let summary = "Three brass balls on a wrought iron bracket 0.6 m: seamed spheres, scroll arm, hanger rings."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 10, distance: 1.2)

    /// Ball radius (m).
    public var ballRadius: Float = 0.08
    public var iron: MaterialKey = "metal.wrought-iron"
    public var brass: MaterialKey = "metal.brass-aged"
    public var polished: MaterialKey = "metal.brass"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r = ballRadius, armY: Float = 0.6, tipZ: Float = 0.33636
        // Wall plate with four bolts.
        FA.box(&m, V3(0.1, 0.3, 0.014), V3(0, armY - 0.07, 0.007), iron, r: 0.004)
        for (dx, dy) in [(-0.032, -0.11), (0.032, -0.11), (-0.032, 0.11), (0.032, 0.11)] as [(Float, Float)] {
            hexBolt(&m, at: V3(dx, armY - 0.07 + dy, 0.014), normal: FA.Z, size: 0.014, material: "metal.rust")
        }
        // Main arm with a forged end bulb, diagonal brace, and scroll under the arm.
        FA.rod(&m, V3(0, armY, 0.012), V3(0, armY, tipZ), r: 0.0125, iron, sides: 10)
        FA.ball(&m, r: 0.02, at: V3(0, armY, tipZ + 0.012), iron)
        FA.path(&m, FG.smooth([V3(0, armY - 0.22, 0.012), V3(0, armY - 0.17, 0.08), V3(0, armY - 0.08, 0.17), V3(0, armY - 0.01, 0.255)]), r: 0.0085, iron, sides: 8)
        FA.path(&m, FG.spiral(c: V3(0, armY - 0.06, 0.1), u: FA.Z, v: FA.Y, r0: 0.05, r1: 0.011, a0: 1.8, turns: 1.1, steps: 24), r: 0.0065, iron, sides: 6)
        // Drop rod, cross bar and two collars.
        let hz = tipZ - 0.02, barY = armY - 0.15
        FA.rod(&m, V3(0, armY, hz), V3(0, barY, hz), r: 0.0075, iron, sides: 8)
        FA.rod(&m, V3(-0.17, barY, hz), V3(0.17, barY, hz), r: 0.0085, iron, sides: 8)
        FA.ball(&m, r: 0.012, at: V3(-0.17, barY, hz), iron)
        FA.ball(&m, r: 0.012, at: V3(0.17, barY, hz), iron)
        // The three balls: lathe spheres with seam band, S hook and eye.
        let cy = barY - 0.06 - r
        var sphere: [V2] = []
        for k in 0...16 { let a = Float(k) / 16 * .pi; sphere.append(V2(sin(a) * r, -cos(a) * r)) }
        for (i, (x, y)) in [(-0.17 as Float, cy), (0.17 as Float, cy), (0 as Float, cy - 0.15)].enumerated() {
            let tilt = rng.float(-1.5...1.5)
            m.add(Prim.lathe(sphere, segments: 28, seamTile: 0.3, material: brass), Xform(translation: V3(x, y, hz), rotation: FA.q(tilt, FA.Z)))
            // Polished cap worn bright on the top, soldered seam band at the equator.
            m.add(Prim.lathe(sphere.filter { $0.y > r * 0.55 }, segments: 28, seamTile: 0.3, material: polished), Xform(translation: V3(x, y + 0.0008, hz), rotation: FA.q(tilt, FA.Z), scale: V3(1.004, 1.004, 1.004)))
            m.add(Prim.torus(major: r, minor: 0.0042, segments: 40, sides: 6, material: "metal.brass-aged"), Xform(translation: V3(x, y, hz)))
            m.add(Prim.torus(major: 0.012, minor: 0.0032, segments: 14, sides: 6, material: iron), Xform(translation: V3(x, y + r + 0.006, hz), rotation: FA.q(90, FA.X)))
            let top = i == 2 ? V3(0, barY - 0.01, hz) : V3(x, barY - 0.01, hz)
            FA.rod(&m, top, V3(x, y + r + 0.012, hz), r: 0.0032, iron, sides: 6)
            if i == 2 { m.add(Prim.torus(major: 0.01, minor: 0.003, segments: 12, sides: 6, material: iron), Xform(translation: V3(0, barY - 0.014, hz), rotation: FA.q(90, FA.X))) }
        }
        // Verdigris and rust stains where brass meets iron.
        for x: Float in [-0.17, 0.17] { FG.flat(&m, V3(0.012, 0.03, 0.0006), V3(x, barY - 0.03, hz + 0.0128), "paint.stucco:4A6B5C") }
        groundAO(&m, height: 0.1, floor: 0.92)
        return LODModel(FC.place(m))
    }
}
