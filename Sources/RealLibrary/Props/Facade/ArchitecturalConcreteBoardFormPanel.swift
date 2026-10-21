import simd
import Foundation

/// Brutalist board-formed concrete panel, 1.5 x 3.0 m: 150 mm rough-sawn board impressions with
/// grain, cupping and grout fins at the board seams, a recessed lift joint at mid height, 20 mm
/// chamfered arrises, a 2 x 4 grid of form-tie cones with recessed grout plugs, and rain streaks
/// running down from the ties plus splash-back staining near grade.
public struct ArchitecturalConcreteBoardFormPanel: RealAsset {
    public static let id = "architectural-concrete-board-form-panel"
    public static let summary = "Board-formed architectural concrete panel, 1.5 x 3.0 m: 150 mm timber board impressions, form-tie cones, chamfered edges and lift-joint weathering."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 3.4)

    /// Panel width in meters.
    public var width: Float = 1.5
    /// Panel height in meters.
    public var height: Float = 3.0
    /// Panel thickness in meters.
    public var depth: Float = 0.25
    /// Board width in meters.
    public var board: Float = 0.15
    /// Concrete.
    public var concrete: MaterialKey = "concrete.rough:8C877E"
    /// Streak and splash staining.
    public var stain: MaterialKey = "concrete.rough:7A756D"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, D = depth, ch: Float = 0.02
        let fz = D - 0.006
        // Body: chamfered section extruded up the height.
        let sect: [V2] = [V2(-W / 2, 0), V2(W / 2, 0), V2(W / 2, fz - ch), V2(W / 2 - ch, fz), V2(-W / 2 + ch, fz), V2(-W / 2, fz - ch)]
        m.add(Prim.extrude(sect, depth: H, bevel: 0.006, bevelSegments: 2, material: concrete),
              Xform(translation: V3(0, H / 2, 0), rotation: FA.q(90, FA.X)))
        // Board impressions: one sheet per board, offset, cupped, with sawn grain along X.
        let boards = Int(H / board)
        let liftY = H / 2
        let bw = W - 2 * ch - 0.004
        for b in 0..<boards {
            let y = board * (Float(b) + 0.5)
            if abs(y - liftY) < board * 0.5 { continue }
            let off = rng.float(-0.003...0.003), sd = Float(b) * 3.1
            FCL.grid(&m, w: bw, h: board - 0.004, nx: 48, ny: 5, at: V3(0, y, fz + off), concrete) { px, py in
                let v = py / (board / 2)
                let cup = -0.0025 * (1 - v * v)
                let grain = 0.0014 * Noise.fbm(V3(px * 3 + sd, py * 90, sd), octaves: 3)
                let knot = max(0, 0.6 - simd_length(V2((px - 0.3 * sin(sd)) * 12, py * 30))) * 0.0015
                return cup + grain + knot
            }
            // Grout fin at the seam above.
            if b < boards - 1 {
                FCL.cube(&m, V3(bw, 0.005, 0.006), V3(0, board * Float(b + 1), fz + 0.001), "concrete.rough:A39E92")
            }
        }
        // Lift joint: recessed rustication strip at mid height.
        FA.box(&m, V3(W - 0.01, board - 0.02, 0.01), V3(0, liftY, fz - 0.003), "concrete.smooth:5A5853", r: 0.004)
        // Form-tie cones with recessed grout plugs.
        for tx in [-0.45, 0.45] as [Float] {
            for ty in [0.45, 1.2, 2.0, 2.65] as [Float] {
                let c = V3(tx, ty, fz + 0.0015)
                // Cone recess (shadowed annulus) around a slightly sunken grout plug.
                FA.cylZ(&m, r: 0.028, h: 0.004, at: V3(tx, ty, fz - 0.0005), "concrete.smooth:4A4844", bevel: 0.0015, segments: 18)
                FA.cylZ(&m, r: 0.018, h: 0.003, at: V3(tx, ty, fz + 0.0002), "concrete.smooth:8E8B86", bevel: 0.001, segments: 14)
                _ = c
                // Rain streak running down from the tie hole.
                let sl = min(rng.float(0.25...0.6), ty - 0.1)
                FCL.grid(&m, w: 0.035, h: sl, nx: 1, ny: 4, at: V3(tx + rng.float(-0.004...0.004), ty - 0.03 - sl / 2, fz + 0.0019), stain, ao: false) { _, _ in 0 }
            }
        }
        // Splash-back staining near grade.
        FCL.grid(&m, w: bw, h: 0.28, nx: 24, ny: 2, at: V3(0, 0.16, fz + 0.0021), stain, ao: false) { px, py in
            py > 0.1 + 0.03 * Noise.perlin(V3(px * 8, 0, 1)) ? -0.004 : 0
        }
        groundAO(&m, height: 0.2, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
