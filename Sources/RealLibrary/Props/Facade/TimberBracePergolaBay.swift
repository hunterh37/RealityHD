import simd
import Foundation

/// Timber brace pergola bay, Craftsman: a 3.0 m square free-standing bay of four 140 mm oak posts on
/// granite piers with iron post bases, paired knee braces pegged into the posts, 120 x 220 mm front and
/// back beams with angle-cut ends, rafters with rounded tails, cross slats and through-bolt washers.
/// End grain checks, weathered post feet and rust at the bolts.
public struct TimberBracePergolaBay: RealAsset {
    public static let id = "timber-brace-pergola-bay"
    public static let summary = "Timber brace pergola bay, 3.0 m: four posts on piers, knee braces, beams, tailed rafters, slats, bolts."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 8.0)

    /// Posts, beams and braces.
    public var oak: MaterialKey = "wood.lumber-oak"
    /// Rafters and slats.
    public var cedar: MaterialKey = "wood.cedar"
    /// Post feet and end checks.
    public var aged: MaterialKey = "wood.deadwood"
    /// Pier stone.
    public var pier: MaterialKey = "stone.granite-paver"
    /// Straps, bases and bolts.
    public var iron: MaterialKey = "metal.iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pc: Float = 1.30              // post centre offset in X and Z
        let pw: Float = 0.18, pierH: Float = 0.2
        let yb: Float = 2.18, bd: Float = 0.22   // beam bottom and depth
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let x = sx * pc, z = sz * pc
            // Tapered granite pier with an iron post base.
            m.add(Prim.extrude([V2(-0.2, 0), V2(0.2, 0), V2(0.16, pierH), V2(-0.16, pierH)], depth: 0.4, bevel: 0.006, bevelSegments: 1, material: pier),
                  Xform(translation: V3(x, 0, z)))
            FA.box(&m, V3(0.21, 0.012, 0.21), V3(x, pierH + 0.006, z), iron, r: 0.002)
            for k: Float in [-1, 1] {
                FA.box(&m, V3(0.01, 0.1, 0.21), V3(x + k * 0.105, pierH + 0.05, z), iron, r: 0.0015)
                FA.cylX(&m, r: 0.006, h: 0.014, at: V3(x + k * 0.105, pierH + 0.07, z), iron, bevel: 0.001, segments: 8)
            }
            // Post: weathered foot, oak shaft, with a shallow chamfered top.
            FA.box(&m, V3(pw, 0.35, pw), V3(x, pierH + 0.012 + 0.175, z), aged, r: 0.006)
            FA.box(&m, V3(pw, yb - pierH - 0.012 - 0.35, pw), V3(x, (yb + pierH + 0.012 + 0.35) / 2, z), oak, r: 0.006)
            // Knee braces in the beam plane, both directions, pegged at each end.
            let dir: Float = -sx            // toward the middle of the beam
            FA.box(&m, V3(0.72, 0.13, 0.11), V3(x + dir * 0.26, yb - 0.26, z), oak, r: 0.004, rot: FA.q(dir * 45, FA.Z))
            FA.cylZ(&m, r: 0.016, h: 0.19, at: V3(x + dir * 0.03, yb - 0.5, z - 0.095), "wood.walnut", bevel: 0.002, segments: 10)
            FA.cylZ(&m, r: 0.016, h: 0.19, at: V3(x + dir * 0.5, yb - 0.04, z - 0.095), "wood.walnut", bevel: 0.002, segments: 10)
            // Side braces toward the middle of the side girt (Z direction).
            let dz: Float = -sz
            FA.box(&m, V3(0.11, 0.13, 0.72), V3(x, yb - 0.26, z + dz * 0.26), oak, r: 0.004, rot: FA.q(-dz * 45, FA.X))
        } }
        // Girts along Z at the rail height tie front to back; lower rail at 0.95 m.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.12, 0.14, 2 * pc - pw), V3(sx * pc, 0.95, 0), oak, r: 0.004)
        }
        // Front and back beams with angle-cut tails.
        let tail: [V2] = [V2(-1.5, 0), V2(1.5, 0), V2(1.5, bd * 0.55), V2(1.43, bd), V2(-1.43, bd), V2(-1.5, bd * 0.55)]
        for sz: Float in [-1, 1] {
            m.add(Prim.extrude(tail, depth: 0.12, bevel: 0.004, bevelSegments: 1, material: oak),
                  Xform(translation: V3(0, yb, sz * pc)))
            // Through-bolts at each post: washer and nut on the beam face.
            for sx: Float in [-1, 1] {
                FA.cylZ(&m, r: 0.022, h: 0.004, at: V3(sx * pc, yb + 0.11, sz * pc + sz * 0.06), iron, bevel: 0.0008, segments: 14)
                FA.cylZ(&m, r: 0.012, h: 0.012, at: V3(sx * pc, yb + 0.11, sz * pc + sz * 0.064), iron, bevel: 0.001, segments: 6)
                FJ.slab(&m, V3(0.0045, 0.05, 0.002), V3(sx * pc + 0.03 * sx, yb + 0.11 - 0.07, sz * pc + sz * 0.062), "metal.rust")
            }
            // Long seasoning checks along the beam face and silvered upper edge.
            for k in 0..<4 {
                FJ.slab(&m, V3(rng.float(0.3...0.7), 0.003, 0.003), V3(rng.float(-1.0...1.0), yb + rng.float(0.05...0.17), sz * pc + sz * 0.0605), aged)
            }
            FJ.slab(&m, V3(2.95, 0.03, 0.002), V3(0, yb + bd - 0.015, sz * pc + sz * 0.0605), "wood.weathered")
            // End-grain check.
            FJ.slab(&m, V3(0.002, 0.12, 0.003), V3(-1.499 * 1, yb + bd * 0.4, sz * pc + sz * 0.059), aged)
        }
        // Rafters along Z with shaped tails, resting on the beams.
        let ry = yb + bd
        let nr = 8
        for i in 0..<nr {
            var r = rng.fork(i)
            let x = -1.5 + 0.09 + Float(i) * (3.0 - 0.18) / Float(nr - 1)
            let rt: [V2] = [V2(-1.5, 0), V2(1.5, 0), V2(1.5, 0.08), V2(1.46, 0.14), V2(-1.46, 0.14), V2(-1.5, 0.08)]
            m.add(Prim.extrude(rt, depth: 0.07, bevel: 0.003, bevelSegments: 1, material: r.chance(0.4) ? "wood.weathered" : cedar),
                  Xform(translation: V3(x, ry, 0), rotation: FA.q(90, FA.Y)))
            // Housing bolt at each beam crossing.
            for sz: Float in [-1, 1] {
                FA.cylX(&m, r: 0.006, h: 0.004, at: V3(x, ry + 0.06, sz * pc), iron, bevel: 0.0006, segments: 6)
            }
        }
        // Cross slats along X on top.
        let sy = ry + 0.14
        let ns = 11
        for i in 0..<ns {
            let z = -1.5 + 0.03 + Float(i) * (3.0 - 0.06) / Float(ns - 1)
            FA.box(&m, V3(3.0, 0.055, 0.05), V3(0, sy + 0.0275, z), i % 3 == 1 ? "wood.weathered" : cedar, r: 0.003)
        }
        groundAO(&m, height: 0.4, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
