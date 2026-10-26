import simd
import Foundation

/// Stone mounting block: architectural facade customizer, Colonial. Tall two-step rock-faced monolith with
/// a dished top platform, a recessed inscription panel, an iron ring bolt and lichen.
public struct MountingBlockStone: RealAsset {
    public static let id = "mounting-block-stone"
    public static let summary = "Stone mounting block 0.8 m: tall two-step rock-faced monolith with a dished top platform, iron ring bolt and lichen."
    public static let tags = ["prop", "architecture", "facade", "stone", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 20, distance: 2.4)

    /// Stone for both steps.
    public var stone: MaterialKey = "stone.granite-curb"
    /// Ring bolt iron.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.775, D: Float = 0.47, t1: Float = 0.195, t2: Float = 0.195
        let uw: Float = 0.5, ud: Float = 0.34
        let uz = D / 2 - ud / 2 - 0.004
        // Lower step, cut from the same block as the platform (bedding joint line between).
        FE.rockBlock(&m, V3(W, t1 - 0.012, D), V3(0, (t1 - 0.012) / 2 + 0.008, 0), stone, seed: 11, amp: 0.018, margin: 0.03, r: 0.015, subs: 3)
        FA.box(&m, V3(W - 0.008, 0.016, D - 0.008), V3(0, t1 - 0.008, 0), stone, r: 0.01)
        FE.rockBlock(&m, V3(uw, t2 - 0.012, ud), V3(0, t1 + (t2 - 0.012) / 2 - 0.004, uz), stone, seed: 4, amp: 0.018, margin: 0.03, r: 0.015, subs: 2)
        FA.box(&m, V3(uw - 0.008, 0.016, ud - 0.008), V3(0, t1 + t2 - 0.012, uz), stone, r: 0.01)
        // Recessed inscription panel on the upper step front: chamfered frame with a sunk field.
        let py = t1 + t2 / 2 + 0.002, pz = uz - ud / 2 - 0.016
        FA.box(&m, V3(0.28, 0.1, 0.006), V3(0, py, pz), "stone.slate", r: 0.003)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.01, 0.1, 0.01), V3(e * 0.145, py, pz - 0.0035), stone, r: 0.003)
        }
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.3, 0.01, 0.01), V3(0, py + e * 0.055, pz - 0.0035), stone, r: 0.003)
        }
        // Carved line marks (worn letter bands) inside the panel.
        for r in 0..<3 {
            FA.box(&m, V3(0.18 - Float(r) * 0.04, 0.008, 0.004), V3(0, py + 0.025 - Float(r) * 0.025, pz - 0.0035), "stone.slate", r: 0.001)
        }
        // Tooled treads, worn dishes and weathering.
        for (ty, zf, w) in [(t1 + 0.0005, -D / 2 + 0.045, W - 0.1), (t1 + t2 + 0.0005, uz - ud / 2 + 0.045, uw - 0.1)] as [(Float, Float, Float)] {
            for g in 0..<4 {
                FA.box(&m, V3(w, 0.0016, 0.0035), V3(0, ty + 0.0004, zf + Float(g) * 0.012), "stone.slate", r: 0.0007)
            }
        }
        FE.stain(&m, V3(0.02, t1 + t2 + 0.0012, uz + 0.02), w: 0.3, d: 0.2, "stone.granite-paver", yaw: 8)
        FE.stain(&m, V3(-0.1, t1 + 0.0012, -0.09), w: 0.34, d: 0.12, "stone.granite-paver", yaw: -5)
        // Iron ring bolt in the lower step front: plate, eye and a hanging ring.
        let rz: Float = -D / 2 - 0.006, rx: Float = 0.24
        FA.box(&m, V3(0.07, 0.07, 0.008), V3(rx, 0.105, rz), iron, r: 0.003)
        m.add(Prim.torus(major: 0.034, minor: 0.0055, segments: 28, sides: 10, material: iron),
              Xform(translation: V3(rx, 0.082, rz - 0.012), rotation: FA.q(90, FA.X) * FA.q(10, FA.Y)))
        FA.cylZ(&m, r: 0.011, h: 0.014, at: V3(rx, 0.113, rz - 0.01), iron, bevel: 0.002, segments: 12)
        FE.stain(&m, V3(rx, 0.036, rz - 0.006), w: 0.045, d: 0.012, "metal.rust")
        // Lichen patches on the top and the weathered side, and a chipped arris.
        for _ in 0..<3 {
            FE.stain(&m, V3(rng.float(-0.3...0.3), t1 + 0.002, rng.float((-0.2)...(-0.05))), w: rng.float(0.04...0.09), d: rng.float(0.03...0.06), "moss.sedum-gold", yaw: rng.float(0...90))
        }
        FA.box(&m, V3(0.045, 0.04, 0.035), V3(W / 2 - 0.02, t1 - 0.018, -D / 2 + 0.015), "stone.granite-paver", r: 0.005, rot: FA.q(22, FA.Y))
        FA.box(&m, V3(0.04, 0.035, 0.03), V3(-uw / 2 + 0.02, t1 + t2 - 0.02 - 0.012, uz + ud / 2 - 0.012), "stone.granite-paver", r: 0.005, rot: FA.q(-30, FA.Y))
        m = FE.seat(m)
        groundAO(&m, height: 0.09, floor: 0.5)
        return LODModel(m)
    }
}
