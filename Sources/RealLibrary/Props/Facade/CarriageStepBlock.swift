import simd
import Foundation

/// Carriage step block: architectural facade customizer, Colonial. Two-tier cut stone monolith with
/// rock-faced sides, chiselled draft margins, tooled treads, a worn dip, an iron ring bolt and moss at the base.
public struct CarriageStepBlock: RealAsset {
    public static let id = "carriage-step-block"
    public static let summary = "Carriage step block 0.8 m: two-tier cut stone monolith with rock-faced sides, chiselled margins, a worn tread dip and an iron ring bolt."
    public static let tags = ["prop", "architecture", "facade", "stone", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 2.2)

    /// Stone for both tiers.
    public var stone: MaterialKey = "stone.brownstone"
    /// Ring bolt iron.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.775, D: Float = 0.465, t1: Float = 0.146, t2: Float = 0.146
        // Lower tier and a smaller upper tier at the back, cut from one block (hairline bedding joint).
        FE.rockBlock(&m, V3(W, t1 - 0.012, D), V3(0, (t1 - 0.012) / 2 + 0.008, 0), stone, seed: 2, amp: 0.022, margin: 0.03, r: 0.012, subs: 3)
        FA.box(&m, V3(W - 0.008, 0.016, D - 0.008), V3(0, t1 - 0.008, 0), stone, r: 0.008)
        let uw: Float = 0.5, ud: Float = 0.3
        FE.rockBlock(&m, V3(uw, t2 - 0.012, ud), V3(0, t1 + (t2 - 0.012) / 2 - 0.004, D / 2 - ud / 2 - 0.004), stone, seed: 7, amp: 0.02, margin: 0.03, r: 0.012, subs: 2)
        FA.box(&m, V3(uw - 0.008, 0.016, ud - 0.008), V3(0, t1 + t2 - 0.012, D / 2 - ud / 2 - 0.004), stone, r: 0.008)
        // Tooled treads: a tight band of parallel boaster chisel marks near the front edge of each tread.
        for (ty, zf, w) in [(t1 + 0.0005, -D / 2 + 0.045, W - 0.1), (t1 + t2 - 0.004 + 0.0005 + 0.004, D / 2 - ud - 0.004 + 0.045, uw - 0.1)] as [(Float, Float, Float)] {
            for g in 0..<5 {
                FA.box(&m, V3(w, 0.0016, 0.0035), V3(0, ty + 0.0004, zf + Float(g) * 0.012), "stone.slate", r: 0.0007)
            }
        }
        // Worn dish in the upper tread and in the lower tread front.
        FE.stain(&m, V3(0, t1 + t2 + 0.0005, D / 2 - ud / 2), w: 0.28, d: 0.17, "stone.brownstone-sooted", yaw: 4)
        FE.stain(&m, V3(0.12, t1 + 0.0012, -0.1), w: 0.3, d: 0.1, "stone.brownstone-sooted", yaw: -6)
        // Iron ring bolt in the front face of the lower tier: plate, eye and ring.
        let rz: Float = -D / 2 - 0.006, rx: Float = -0.24
        FA.box(&m, V3(0.07, 0.07, 0.008), V3(rx, 0.07, rz), iron, r: 0.003)
        m.add(Prim.torus(major: 0.031, minor: 0.0052, segments: 28, sides: 10, material: iron),
              Xform(translation: V3(rx, 0.052, rz - 0.012), rotation: FA.q(90, FA.X) * FA.q(10, FA.Y)))
        FA.cylZ(&m, r: 0.011, h: 0.014, at: V3(rx, 0.082, rz - 0.01), iron, bevel: 0.002, segments: 12)
        // Rust bleed under the ring plate, moss at the base, chipped arris.
        FE.stain(&m, V3(rx, 0.014, rz - 0.006), w: 0.04, d: 0.012, "metal.rust")
        FA.box(&m, V3(0.045, 0.035, 0.035), V3(W / 2 - 0.02, t1 - 0.015, -D / 2 + 0.015), "stone.sandstone", r: 0.005, rot: FA.q(22, FA.Y))
        FA.box(&m, V3(0.04, 0.03, 0.03), V3(-uw / 2 + 0.02, t1 + t2 - 0.015 - 0.012, D / 2 - ud + 0.01), "stone.sandstone", r: 0.005, rot: FA.q(-30, FA.Y))
        m = FE.seat(m)
        groundAO(&m, height: 0.09, floor: 0.5)
        return LODModel(m)
    }
}
