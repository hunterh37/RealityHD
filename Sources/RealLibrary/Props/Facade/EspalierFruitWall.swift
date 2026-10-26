import simd
import Foundation

/// Espalier fruit wall: a half-brick garden wall in stretcher bond with a stone coping, three tiers of
/// horizontal apple cordons trained on galvanized wires and vine eyes, with spurs, leaves, apples and
/// raffia ties. Wall face at z = 0, tree projecting toward +Z.
public struct EspalierFruitWall: RealAsset {
    public static let id = "espalier-fruit-wall"
    public static let summary = "English garden espalier fruit wall 1.5 x 2.0 m: stretcher-bond brick wall with stone coping, wire-trained three-tier apple cordons, fruit and leaves."
    public static let tags = ["prop", "architecture", "facade", "brick", "plant", "garden"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 3.6)

    public var width: Float = 1.47
    /// Brick courses at 75 mm gauge.
    public var courses: Int = 26
    /// Heights of the three cordon tiers (m).
    public var tiers: [Float] = [0.52, 0.97, 1.42]
    public var wood: MaterialKey = "bark.maple"
    public var leaf: MaterialKey = "leaf.plain:46722F"
    public init() {}

    /// Branch from the trunk out to one side, rising slightly at the tip.
    private func cordon(_ y: Float, _ side: Float, _ z: Float, reach: Float) -> [V3] {
        var pts: [V3] = []
        for i in 0...10 {
            let t = Float(i) / 10
            pts.append(V3(side * (0.01 + reach * t), y - 0.045 * (1 - t) * (1 - t) * 0 + 0.07 * t * t - 0.012 * sin(t * 9), z + 0.004 * sin(t * 7)))
        }
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, j: Float = 0.01, bh: Float = 0.065, bl: Float = 0.215
        let gauge = bh + j, half = W / 2
        let reds: [MaterialKey] = ["brick.unit-red", "brick.unit-red", "brick.unit-red-dark", "brick.unit-red-dark", "brick.unit-red-light"]
        // Stretcher bond: every course offset by half a brick, closers at the reveals.
        for c in 0..<courses {
            let y0 = Float(c) * gauge + j / 2, y1 = y0 + bh
            var x = -half - (c % 2 == 0 ? 0 : (bl + j) / 2)
            var i = 0
            while x < half - 0.004 {
                var r = rng.fork(c * 40 + i)
                let a = max(x + j / 2, -half), b = min(x + bl + j / 2, half)
                if b - a > 0.03 {
                    var mat: MaterialKey = r.pick(reds)
                    if c < 3 && r.chance(0.4) { mat = "brick.unit-sooted" }
                    if c > 3 && c < 6 && r.chance(0.15) { mat = "brick.unit-efflorescent" }
                    FM.brick(&m, x0: a, x1: b, y0: y0, y1: y1, depth: 0.035, mat, rng: &r, chip: (c, i) == (9, 3))
                }
                x += bl + j; i += 1
            }
        }
        let h = Float(courses) * gauge
        FM.mortar(&m, w: W, h: h, recess: 0.004, back: 0.085, "brick.mortar-lime")
        // Stone coping with a drip overhang and a weathered upper face.
        FA.box(&m, V3(W + 0.03, 0.05, 0.13), V3(0, h + 0.025, -0.025), "stone.cap", r: 0.005)
        FA.box(&m, V3(W + 0.034, 0.008, 0.134), V3(0, h + 0.006, -0.025), "stone.cap", r: 0.002)
        FA.box(&m, V3(W * 0.5, 0.0008, 0.07), V3(0.2, h + 0.0504, -0.03), "moss.cushion", r: 0.0003)
        // Lichen and moss patches on the lower brickwork.
        for _ in 0..<6 {
            FA.box(&m, V3(rng.float(0.05...0.14), rng.float(0.04...0.09), 0.0007), V3(rng.float(-half + 0.1...half - 0.1), rng.float(0.08...0.5), 0.0012), "moss.cushion", r: 0.0003)
        }
        // Vine eyes and training wires at each tier, 0.12 m above the cordon line.
        let zw: Float = 0.032
        for y in tiers {
            let wy = y + 0.085
            FA.rod(&m, V3(-half + 0.05, wy, zw), V3(half - 0.05, wy, zw), r: 0.0016, "metal.galvanized-aged", sides: 5)
            for x in [-half + 0.05, -0.38, 0.38, half - 0.05] as [Float] {
                FA.cylZ(&m, r: 0.003, h: zw + 0.0, at: V3(x, wy, 0), "metal.galvanized-aged", bevel: 0.0006, segments: 6)
                m.add(Prim.torus(major: 0.0055, minor: 0.0016, segments: 8, sides: 4, material: "metal.galvanized-aged"),
                      Xform(translation: V3(x, wy, zw)))
            }
        }
        // Trunk and three tiers of paired cordons, trained down to a single central leader.
        var trunk: [V3] = []
        for i in 0...16 {
            let t = Float(i) / 16
            trunk.append(V3(0.004 * sin(t * 9), t * (tiers[2] + 0.27), 0.022 + 0.003 * sin(t * 6)))
        }
        m.add(Prim.tube(trunk, radii: trunk.indices.map { 0.017 - 0.010 * Float($0) / 16 }, sides: 8, seamTile: 0.2, material: wood, capEnd: true))
        // Graft union swelling near the base and a stake stub.
        FC.bead(&m, r: 0.019, at: V3(0, 0.12, 0.022), wood, sub: 3)
        let apples: [MaterialKey] = ["flower.petal:A62A20", "flower.petal:B8472A", "flower.petal:C9B94E"]
        for (ti, y) in tiers.enumerated() {
            for side in [-1, 1] as [Float] {
                let reach = ti == 2 ? 0.58 : 0.66 - Float(ti) * 0.03
                let pts = cordon(y, side, 0.022, reach: reach)
                m.add(Prim.tube(pts, radii: pts.indices.map { 0.011 - 0.0055 * Float($0) / 10 }, sides: 7, seamTile: 0.2, material: wood, capEnd: true))
                // Raffia ties to the wire and fruiting spurs with leaf pairs and apples.
                for k in 1...7 {
                    let p = pts[min(10, k + 1)]
                    if k % 2 == 0 {
                        FC.bead(&m, r: 0.0055, at: V3(p.x, p.y + 0.035, 0.03), "fabric.burlap", sub: 1)
                        FA.rod(&m, V3(p.x, p.y + 0.004, p.z), V3(p.x, p.y + 0.036, 0.03), r: 0.0012, "fabric.burlap", sides: 4)
                    }
                    let sdir: Float = rng.chance(0.5) ? 1 : -1
                    let tip = V3(p.x + rng.float(-0.015...0.015), p.y + sdir * rng.float(0.04...0.07), p.z + rng.float(0.008...0.016))
                    FA.rod(&m, p, tip, r: 0.0034, wood, sides: 5)
                    for li in 0..<2 where li == 0 || rng.chance(0.65) {
                        m.add(Prim.superellipsoid(V3(0.05, 0.075, 0.006) * rng.float(0.85...1.2), exponent: 2.4, subdivisions: 2, material: leaf),
                              Xform(translation: tip + V3(rng.float(-0.03...0.03), rng.float(-0.01...0.03), 0.004), rotation: FA.q(rng.float(0...360), FA.Z) * FA.q(rng.float(-25...25), FA.X)))
                    }
                    if k % 3 == 0 {
                        FC.bead(&m, r: 0.026, at: tip + V3(0.004, -0.04, 0.004), rng.pick(apples), sub: 3)
                        FA.rod(&m, tip, tip + V3(0.004, -0.018, 0.004), r: 0.0014, wood, sides: 4)
                    }
                }
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
