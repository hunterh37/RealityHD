import simd
import Foundation

/// Low brick garden wall: architectural facade customizer, Colonial Revival. Flemish bond brick on a stone
/// plinth, lime mortar joints, end piers with caps and a cast stone coping with a drip groove.
public struct LowBrickGardenWall: RealAsset {
    public static let id = "low-brick-garden-wall"
    public static let summary = "Low brick garden wall 2.4 m: Flemish bond brick on a stone plinth with end piers and a cast stone coping."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 3.4)

    /// Wall length in meters.
    public var length: Float = 2.37
    /// Brick wythe thickness (excluding coping overhang) in meters.
    public var thickness: Float = 0.19
    /// Coping material.
    public var coping: MaterialKey = "stone.cast-stone"
    /// Plinth material.
    public var plinth: MaterialKey = "stone.granite-curb"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, t = thickness
        let pierW: Float = 0.3, plinthH: Float = 0.03
        // Plinth with chamfered top.
        FA.box(&m, V3(L, plinthH, t + 0.02), V3(0, plinthH / 2, 0), plinth, r: 0.008)
        // Pier brickwork runs full wall height; wall panel between piers.
        let rows = 6
        let y0 = plinthH
        FE.brickRows(&m, rng: &rng, x0: -L / 2 + 0.01, x1: -L / 2 + pierW, y0: y0, rows: rows + 1, depth: t, flemish: false, flatBack: true)
        FE.brickRows(&m, rng: &rng, x0: L / 2 - pierW, x1: L / 2 - 0.01, y0: y0, rows: rows + 1, depth: t, flemish: false, flatBack: true)
        FE.brickRows(&m, rng: &rng, x0: -L / 2 + pierW, x1: L / 2 - pierW, y0: y0, rows: rows, depth: t - 0.008, flemish: true, flatBack: true)
        // End returns closed with header faces.
        for e: Float in [-1, 1] {
            let x = e * (L / 2 - 0.004)
            var y = y0 + 0.005
            for r in 0..<(rows + 1) {
                m.add(Prim.roundedBox(V3(0.008, 0.065, t - 0.016), radius: 0.0025, bevelSegments: 1, material: r % 2 == 0 ? "brick.unit-header" : "brick.unit-red"),
                      Xform(translation: V3(x, y + 0.0325, 0)))
                y += 0.075
            }
        }
        // Shadow-line course under the coping: one soldier course of headers set back 4 mm.
        let top = y0 + Float(rows) * 0.075 + 0.002
        // Coping: sloped weathered cap, drip kerf on the underside.
        let ch: Float = 0.07, cd = t + 0.03
        let prof: [V2] = [V2(-cd / 2, 0), V2(cd / 2, 0), V2(cd / 2, ch * 0.45), V2(0.02, ch), V2(-0.02, ch), V2(-cd / 2, ch * 0.45)]
        FA.run(&m, prof, length: L - 2 * pierW + 0.04, at: V3(0, top, 0), coping, bevel: 0.003)
        // Piers rise one course higher with a flat stone cap and a pyramid ball base.
        let pierTop = y0 + Float(rows + 1) * 0.075 + 0.002
        for e: Float in [-1, 1] {
            let cx = e * (L / 2 - pierW / 2)
            FA.box(&m, V3(pierW + 0.03, 0.04, cd + 0.01), V3(cx, pierTop + 0.02, 0), coping, r: 0.006)
            FA.box(&m, V3(pierW - 0.05, 0.015, t - 0.05), V3(cx, pierTop + 0.0475, 0), coping, r: 0.005)
        }
        // Mortar staining and a moss patch at the foot.
        for _ in 0..<4 {
            FE.patch(&m, V3(rng.float(-L / 2 + 0.2...L / 2 - 0.2), plinthH + 0.004, (rng.chance(0.5) ? 1 : -1) * (t / 2 + 0.006)), V3(rng.float(0.1...0.2), 0.03, 0.02))
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.1, floor: 0.6)
        return LODModel(m)
    }
}
