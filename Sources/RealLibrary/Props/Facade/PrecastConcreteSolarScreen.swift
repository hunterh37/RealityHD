import simd
import Foundation

/// Precast concrete solar screen: five by six pierced blocks (round opening, built from four chamfered
/// quadrant castings) laid in mortar joints on a plinth, capped with a cast coping, and tied with
/// galvanized plates and bolts. Algae and efflorescence stain the lower courses. Free-standing, z centered.
public struct PrecastConcreteSolarScreen: RealAsset {
    public static let id = "precast-concrete-solar-screen"
    public static let summary = "Mid-century precast concrete solar screen 2.0 x 2.4 m: pierced round-hole blocks in mortar joints, plinth, coping and steel ties."
    public static let tags = ["prop", "architecture", "facade", "concrete", "metal", "decor"]
    public static let budget = 14_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 4.6)

    /// Block columns and rows, block depth (m), opening radius (m).
    public var columns: Int = 5
    public var rows: Int = 6
    public var blockDepth: Float = 0.14
    public var opening: Float = 0.135
    public var block: MaterialKey = "concrete.rough"
    public var mortar: MaterialKey = "concrete.smooth"
    public var steel: MaterialKey = "metal.galvanized-aged"
    public init() {}

    /// Quadrant casting outline: corner at the origin, opening circle centred on (h, h).
    private func quadrant(_ h: Float, _ r: Float) -> [V2] {
        var pts = [V2(0, 0), V2(h, 0), V2(h, h - r)]
        for i in 1..<7 {
            let a = Float(i) / 7 * (.pi / 2)
            pts.append(V2(h - r * sin(a), h - r * cos(a)))
        }
        pts.append(V2(h - r, h))
        pts.append(V2(0, h))
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pxs: Float = 0.39, pys: Float = 0.38
        let W = Float(columns) * pxs, plinth: Float = 0.07, cap: Float = 0.05
        let d = blockDepth
        let bs: Float = 0.372
        let q = quadrant(bs / 2, opening)
        let totalH = plinth + Float(rows) * pys + cap
        // Plinth and coping.
        FA.box(&m, V3(W + 0.05, plinth, 0.15), V3(0, plinth / 2, 0), "stone.cast-stone", r: 0.006)
        FA.box(&m, V3(W + 0.05, cap, 0.15), V3(0, totalH - cap / 2, 0), "stone.cast-stone", r: 0.006)
        FA.box(&m, V3(W + 0.056, 0.008, 0.156), V3(0, totalH - cap + 0.004, 0), "stone.cast-stone", r: 0.002)
        // Mortar joints: thin bedding strips in the gaps between courses and columns (openings stay clear).
        for row in 0...rows {
            FA.box(&m, V3(W, 0.012, d - 0.03), V3(0, plinth + pys * Float(row), 0), mortar, r: 0.002)
        }
        for col in 0...columns {
            FA.box(&m, V3(0.014, Float(rows) * pys, d - 0.03), V3(-W / 2 + pxs * Float(col), plinth + Float(rows) * pys / 2, 0), mortar, r: 0.002)
        }
        for row in 0..<rows {
            for col in 0..<columns {
                let cx = -W / 2 + pxs * (Float(col) + 0.5)
                let cy = plinth + pys * (Float(row) + 0.5)
                let tone: MaterialKey = rng.pick([block, block, "concrete.rough:C4BEB0", "concrete.rough:B5AFA2", "concrete.smooth:C9C4B8"])
                for k in 0..<4 {
                    // One quadrant casting per corner, rotated about the block centre.
                    let corner = [V3(-bs / 2, -bs / 2, 0), V3(bs / 2, -bs / 2, 0), V3(bs / 2, bs / 2, 0), V3(-bs / 2, bs / 2, 0)][k]
                    m.add(Prim.extrude(q, depth: d, bevel: 0.0025, bevelSegments: 1, material: tone),
                          Xform(translation: V3(cx, cy, 0) + corner, rotation: FA.q(Float(k) * 90, FA.Z)))
                }
                // Algae creeping up the lowest course and efflorescence under the coping.
                if row == 0 && rng.chance(0.8) {
                    FA.box(&m, V3(rng.float(0.1...0.25), rng.float(0.05...0.12), 0.0008), V3(cx + rng.float(-0.1...0.1), plinth + 0.05, d / 2 + 0.0005), "concrete.river-algae", r: 0.0003)
                }
                if row == rows - 1 && rng.chance(0.5) {
                    FA.box(&m, V3(rng.float(0.01...0.03), rng.float(0.1...0.2), 0.0008), V3(cx + rng.float(-0.12...0.12), totalH - cap - 0.1, d / 2 + 0.0005), "concrete.smooth", r: 0.0003)
                }
            }
        }
        // Galvanized tie plates with bolts on the plinth and coping joints.
        for x in [-W / 2 + 0.06, 0, W / 2 - 0.06] as [Float] {
            for y in [plinth + 0.04, totalH - cap - 0.04] as [Float] {
                FA.box(&m, V3(0.09, 0.06, 0.004), V3(x, y, d / 2 + 0.002), steel, r: 0.0015)
                for e in [-1, 1] as [Float] { FA.cylZ(&m, r: 0.0065, h: 0.004, at: V3(x + e * 0.028, y, d / 2 + 0.003), "metal.bolt-bright", bevel: 0.001, segments: 6) }
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.15, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
