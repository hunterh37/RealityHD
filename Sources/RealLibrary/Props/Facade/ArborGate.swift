import simd
import Foundation

/// Arbor gate: architectural facade customizer, Cottage. Parts: posts, arched top, lattice side panels, picket gate leaf, strap hinges, latch, post caps, cross rails.
public struct ArborGate: RealAsset {
    public static let id = "arbor-gate"
    public static let summary = "Cottage garden arbor with arched head, lattice sides and picket gate, painted cedar"
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 2.4, 0.6)
    public init() {}

    /// Painted cedar (cottage white).
    public var paint: MaterialKey = "wood.barn-white"
    /// Paint worn through to grey cedar at feet, rails and edges.
    public var worn: MaterialKey = "wood.trim-weathered"
    /// Bare weathered cedar under the paint failures.
    public var bare: MaterialKey = "wood.cedar-weathered"
    /// Hand-forged ironmongery.
    public var iron: MaterialKey = "metal.wrought-iron"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let px: Float = 0.55, pz: Float = 0.255, pw: Float = 0.09
        let spring: Float = 1.9, rise: Float = 0.45
        // Posts on small blocks, with chamfered caps.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, spring - 0.03, pw), V3(sx * px, (spring + 0.03) / 2, sz * pz), paint, r: 0.004)
            FA.box(&m, V3(pw + 0.012, 0.03, pw + 0.012), V3(sx * px, 0.015, sz * pz), worn, r: 0.003)
            FG.frustum(&m, w0: pw + 0.014, w1: 0.04, y0: spring, y1: spring + 0.045, at: V3(sx * px, 0, sz * pz), paint)
            FA.box(&m, V3(pw + 0.014, 0.012, pw + 0.014), V3(sx * px, spring - 0.006, sz * pz), paint, r: 0.003)
        } }
        // Front and back arch ribs (doubled) with a spandrel fillet each side.
        for sz in [-1, 1] as [Float] {
            FG.archBoard(&m, a: px, rise: rise, y0: spring, z: sz * pz, thick: 0.035, depth: 0.1, paint)
            FG.archBoard(&m, a: px - 0.02, rise: rise - 0.04, y0: spring - 0.03, z: sz * (pz - 0.03), thick: 0.025, depth: 0.05, worn, steps: 12)
            // Tie rail across the posts under the springing.
            FA.box(&m, V3(2 * px, 0.08, 0.04), V3(0, spring - 0.065, sz * pz), paint, r: 0.004)
        }
        // Top cross slats following the arch from front to back.
        let R = (px * px + rise * rise) / (2 * rise), cy = spring + rise - R, t0 = asin(px / R)
        for i in 0..<11 {
            let t = -t0 + 2 * t0 * (Float(i) + 0.5) / 11
            let c = V3(R * sin(t), cy + R * cos(t) + 0.064, 0)
            FA.box(&m, V3(0.035, 0.022, 2 * pz + 0.07), c, paint, r: 0.003, rot: FA.q(-t * 180 / .pi, FA.Z))
        }
        // Side lattice panels between the front and back posts, with rails and a mid stile.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.05, 0.07, 2 * pz), V3(sx * px, 1.79, 0), paint, r: 0.003)
            FA.box(&m, V3(0.05, 0.1, 2 * pz), V3(sx * px, 0.38, 0), paint, r: 0.003)
            FG.lattice(&m, x: sx * px - 0.012, z0: -pz + pw / 2, z1: pz - pw / 2, y0: 0.43, y1: 1.755, pitch: 0.1, lath: 0.016, paint)
            // Lattice frame beads.
            for z in [-1, 1] as [Float] { FA.box(&m, V3(0.032, 1.33, 0.02), V3(sx * px, 1.09, z * (pz - pw / 2 - 0.01)), paint, r: 0.003) }
        }
        // Picket gate hung inside the front posts: stiles, rails, brace and 11 pointed pickets.
        let gz: Float = pz - 0.02
        for x in [-0.46, 0.46] as [Float] { FA.box(&m, V3(0.06, 0.98, 0.03), V3(x, 0.62, gz), paint, r: 0.003) }
        for y in [0.24, 0.92] as [Float] { FA.box(&m, V3(0.92, 0.08, 0.026), V3(0, y, gz - 0.026), paint, r: 0.003) }
        FA.box(&m, V3(0.04, 1.0, 0.022), V3(0, 0.58, gz - 0.026), paint, r: 0.003, rot: FA.q(-50, FA.Z))
        let n = 11
        for k in 0..<n {
            var r = rng.fork(k)
            let x = -0.40 + 0.80 * Float(k) / Float(n - 1)
            FG.pointedPicket(&m, x: x, y: 0.12, w: 0.052, h: 0.94 + r.float(-0.004...0.004), tip: 0.045, z: gz + 0.011, thick: 0.02, paint)
        }
        // Strap hinges at the left stile and a thumb latch at the right.
        for y in [0.24, 0.92] as [Float] {
            FG.strapHinge(&m, at: V3(-0.49, y, gz + 0.03), length: 0.34, dirX: 1, w: 0.028, iron)
        }
        FA.box(&m, V3(0.06, 0.14, 0.01), V3(0.455, 0.7, gz + 0.02), iron, r: 0.003)
        FA.box(&m, V3(0.14, 0.014, 0.012), V3(0.40, 0.72, gz + 0.03), iron, r: 0.003, rot: FA.q(8, FA.Z))
        FC.bead(&m, r: 0.012, at: V3(0.46, 0.65, gz + 0.032), iron, sub: 2)
        // Wear: paint loss at the gate foot and the post bases, drip streaks under the arch.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            FG.slab(&m, V3(pw + 0.004, 0.18, 0.004), V3(sx * px, 0.12, sz * (pz + pw / 2 + 0.0015)), bare)
            FG.slab(&m, V3(0.004, 0.2, pw + 0.004), V3(sx * (px + pw / 2 + 0.0015), 0.14, sz * pz), bare)
        } }
        FG.slab(&m, V3(0.9, 0.06, 0.004), V3(0, 0.15, gz + 0.0225), bare)
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
