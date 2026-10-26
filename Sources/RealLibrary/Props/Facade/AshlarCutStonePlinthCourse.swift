import simd
import Foundation

/// Ashlar cut stone plinth course, Georgian: a 3.0 m run of dressed limestone blocks (250 mm courses,
/// 3 mm raked joints, chamfered arrises) on a roll-moulded base, capped with a sloped water table in
/// three stones with a drip. Stain, a chipped arris and a lead-plugged cramp hole give it age.
public struct AshlarCutStonePlinthCourse: RealAsset {
    public static let id = "ashlar-cut-stone-plinth-course"
    public static let summary = "Ashlar cut stone plinth course, 3.0 m: dressed blocks, raked joints, roll base, sloped water table with drip."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 3.6)

    /// Overall run length in meters.
    public var length: Float = 3.0
    /// Block face material.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted block material for the weathered stones.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Water table cap material.
    public var cap: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, face: Float = 0.27, joint: Float = 0.003
        // Roll-moulded base (x out from the wall, y up): splayed foot, torus roll, fillet.
        let base: [V2] = [V2(0, 0), V2(0.292, 0), V2(0.296, 0.006), V2(0.296, 0.018), V2(0.288, 0.03), V2(0.28, 0.038),
                          V2(0.274, 0.044), V2(0.272, 0.05), V2(0, 0.05)]
        let bj = 4, bl = (L - Float(bj - 1) * joint) / Float(bj)
        for k in 0..<bj {
            FA.run(&m, base, length: bl, at: V3(-L / 2 + bl / 2 + Float(k) * (bl + joint), 0, 0), k == 1 ? sooted : stone, bevel: 0.0015)
        }
        // Dressed blocks: one course, random stretcher lengths, joints raked back.
        var widths: [Float] = []
        var rest = L
        while rest > 0.3 {
            let w = min(rest, rng.float(0.52...0.84))
            widths.append(rest - w < 0.3 ? rest : w)
            rest -= widths.last!
        }
        var x = -L / 2
        for (i, w) in widths.enumerated() {
            var r = rng.fork(i)
            let bw = w - joint
            let mat: MaterialKey = r.chance(0.3) ? sooted : stone
            FA.box(&m, V3(bw, 0.25 - joint, face - 0.012), V3(x + w / 2, 0.05 + 0.125, (face - 0.012) / 2), mat, r: 0.0035)
            // Dressed face panel, 1.5 mm proud of the chamfered arris.
            FA.box(&m, V3(bw - 0.03, 0.22, 0.004), V3(x + w / 2, 0.175, face - 0.012 + 0.001), mat, r: 0.001)
            // Weathering streak under the water table (rain wash).
            if r.chance(0.5) {
                FA.box(&m, V3(r.float(0.04...0.1), 0.12, 0.002), V3(x + w / 2 + r.float(-0.15...0.15), 0.215, face - 0.0075), sooted, r: 0.0005)
            }
            x += w
        }
        // Raked joint backing (dark mortar line) behind the blocks.
        FA.box(&m, V3(L, 0.25, 0.01), V3(0, 0.175, 0.005), "stone.sandstone", r: 0.001)
        // Water table: sloped wash, throated drip, in three stones with butt joints.
        let table: [V2] = [V2(0, 0.30), V2(0.30, 0.30), V2(0.30, 0.322), V2(0.292, 0.332), V2(0.284, 0.332), V2(0.284, 0.345),
                           V2(0.30, 0.352), V2(0.30, 0.375), V2(0.27, 0.46), V2(0.27, 0.50), V2(0, 0.50)]
        let cl = (L - 2 * joint) / 3
        for k in 0..<3 {
            FA.run(&m, table, length: cl, at: V3(-L / 2 + cl / 2 + Float(k) * (cl + joint), 0, 0), k == 1 ? sooted : cap, bevel: 0.0018)
        }
        // Lead-plugged cramp hole and a chipped arris on the cap's nose.
        FA.cylZ(&m, r: 0.011, h: 0.003, at: V3(0.62, 0.48, 0.27), "metal.galvanized-aged", bevel: 0.0008, segments: 14)
        FA.cylZ(&m, r: 0.011, h: 0.003, at: V3(-0.9, 0.48, 0.27), "metal.galvanized-aged", bevel: 0.0008, segments: 14)
        FA.box(&m, V3(0.05, 0.018, 0.012), V3(-0.42, 0.372, 0.297), sooted, r: 0.003, rot: FA.q(14, FA.Z))
        groundAO(&m, height: 0.1, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
