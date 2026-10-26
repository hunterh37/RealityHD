import simd
import Foundation

/// Georgian trade sign on twin wrought iron scroll brackets: each bracket is a bolted plate, a projecting
/// arm with a forged end ball, a diagonal brace and a C scroll. A head rail spans the arm tips and carries
/// a painted board on two S hooks, with a gilded moulded border and gilt lettering.
public struct ProjectingBracketSignScroll: RealAsset {
    public static let id = "projecting-bracket-sign-scroll"
    public static let summary = "Georgian trade sign on twin scroll iron brackets 0.9 m: rail, S-hooks, painted board with gilded border."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.2)

    /// Sign lines (A-Z, 0-9).
    public var lines = ["WINE", "MERCHANT"]
    public var iron: MaterialKey = "metal.wrought-iron"
    public var board: MaterialKey = "wood.painted-shaker-worn:24432F"
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ay: Float = 0.66, reach: Float = 0.47, bx: Float = 0.405
        for sx: Float in [-1, 1] {
            let x = sx * bx
            FA.box(&m, V3(0.075, 0.26, 0.012), V3(x, ay - 0.08, 0.006), iron, r: 0.003)
            for dy: Float in [-1, 1] { hexBolt(&m, at: V3(x, ay - 0.08 + dy * 0.1, 0.012), normal: FA.Z, size: 0.012, material: "metal.rust") }
            FA.rod(&m, V3(x, ay, 0.01), V3(x, ay, reach), r: 0.0105, iron, sides: 10)
            FA.ball(&m, r: 0.017, at: V3(x, ay, reach + 0.006), iron)
            FA.path(&m, FG.smooth([V3(x, ay - 0.2, 0.01), V3(x, ay - 0.15, 0.1), V3(x, ay - 0.07, 0.24), V3(x, ay - 0.008, 0.4)]), r: 0.0075, iron, sides: 8)
            FA.path(&m, FG.spiral(c: V3(x, ay - 0.075, 0.13), u: FA.Z, v: FA.Y, r0: 0.055, r1: 0.012, a0: 1.7, turns: 1.2, steps: 26), r: 0.006, iron, sides: 6)
            FA.path(&m, FG.spiral(c: V3(x, ay + 0.045, 0.22), u: FA.Z, v: FA.Y, r0: 0.04, r1: 0.01, a0: -1.57, turns: -0.9, steps: 20), r: 0.0055, iron, sides: 6)
        }
        // Head rail between the arm tips, with a rope of small collars.
        let rz = reach - 0.03
        FA.rod(&m, V3(-bx - 0.012, ay, rz), V3(bx + 0.012, ay, rz), r: 0.0085, iron, sides: 8)
        for x: Float in [-0.25, 0.25] {
            m.add(Prim.torus(major: 0.014, minor: 0.004, segments: 14, sides: 6, material: iron), Xform(translation: V3(x, ay - 0.016, rz), rotation: FA.q(90, FA.Z)))
            FA.rod(&m, V3(x, ay - 0.012, rz), V3(x, ay - 0.075, rz), r: 0.0035, iron, sides: 6)
        }
        // Painted board 0.7 x 0.38 x 0.035 with moulded gilt border and inner keyline.
        let bw: Float = 0.7, bh: Float = 0.53, py = ay - 0.075 - bh / 2 - 0.004, pz = rz
        FA.box(&m, V3(bw, bh, 0.035), V3(0, py, pz), board, r: 0.004)
        let fz = pz + 0.0175
        for (w, h, x, y) in [(bw, 0.03, 0.0, py + bh / 2 - 0.015), (bw, 0.03, 0.0, py - bh / 2 + 0.015), (0.03, bh - 0.06, -bw / 2 + 0.015, py), (0.03, bh - 0.06, bw / 2 - 0.015, py)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, 0.008), V3(x, y, fz + 0.002), gilt, r: 0.002)
        }
        FG.flat(&m, V3(bw - 0.09, 0.005, 0.0012), V3(0, py + bh / 2 - 0.045, fz + 0.0005), gilt)
        FG.flat(&m, V3(bw - 0.09, 0.005, 0.0012), V3(0, py - bh / 2 + 0.045, fz + 0.0005), gilt)
        FG.text(&m, lines[0], h: 0.11, stroke: 0.017, depth: 0.003, at: V3(0, py + 0.09, fz), gilt)
        FG.text(&m, lines[1], h: 0.068, stroke: 0.0105, depth: 0.003, at: V3(0, py - 0.085, fz), gilt)
        // Cracked paint at a board corner and drip stain from the lower rail.
        FG.flat(&m, V3(0.07, 0.04, 0.0006), V3(-0.28, py - 0.16, fz + 0.0003), "wood.painted-shaker-worn:101C15", rot: FA.q(rng.float(-20...20), FA.Z))
        FG.flat(&m, V3(0.006, 0.12, 0.0004), V3(0.26, py - 0.17, fz + 0.0003), "metal.rust-grime")
        groundAO(&m, height: 0.1, floor: 0.92)
        return LODModel(FC.place(m))
    }
}
