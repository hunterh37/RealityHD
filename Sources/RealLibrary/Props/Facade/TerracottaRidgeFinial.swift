import simd
import Foundation

/// Victorian terracotta ridge finial, 0.25 x 0.8 x 0.25 m: an angular ridge tile bedded in lime mortar, a lead-flashed collar, a
/// square moulded plinth with an iron cramp, a turned baluster stem with ring mouldings, a crown of eight curled acanthus leaves
/// around a bud and a spire with a ball tip. One leaf tip is broken off; moss and soot sit in the mouldings. Base on y = 0.
public struct TerracottaRidgeFinial: RealAsset {
    public static let id = "terracotta-ridge-finial"
    public static let summary = "Victorian terracotta ridge finial, 0.25 x 0.8 m: ridge-tile base, collar, baluster stem, acanthus crown, spire, mortar bed, weathering."
    public static let tags = ["prop", "architecture", "facade", "roof", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 1.7)

    /// Number of acanthus leaves in the crown.
    public var leaves: Int = 8
    /// Fired terracotta.
    public var clay: MaterialKey = "ceramic.terracotta"
    /// Lighter, sun-bleached clay for the crown.
    public var crown: MaterialKey = "ceramic.terracotta:C2704B"
    public var mortar: MaterialKey = "brick.mortar-lime"
    public var lead: MaterialKey = "concrete.smooth:6D7174"
    public var iron: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)

        // Angular ridge tile, 250 mm along the ridge (X), with a flat crown and a slight lip at the foot.
        let tile: [V2] = [V2(-0.108, 0), V2(0.108, 0), V2(0.108, 0.018), V2(0.08, 0.07), V2(-0.08, 0.07), V2(-0.108, 0.018)]
        m.add(Prim.extrude(tile, depth: 0.25, bevel: 0.004, bevelSegments: 1, material: clay), Xform(rotation: FA.q(90, FA.Y)))
        // Lime mortar bedding at both feet of the tile, slightly slumped.
        for s: Float in [-1, 1] {
            m.add(Prim.extrude([V2(0, 0), V2(0.018, 0), V2(0, 0.026)], depth: 0.25, bevel: 0.002, bevelSegments: 1, material: mortar),
                  Xform(translation: V3(0, 0, s * 0.107), rotation: FA.q(90, FA.Y) * (s > 0 ? FA.q(0, FA.Z) : FA.q(180, FA.Y))))
        }
        // Tile joint, cracked mortar line and moss at the feet.
        FA.box(&m, V3(0.004, 0.072, 0.216), V3(0.0, 0.035, 0), "ceramic.terracotta:7A3E26", r: 0.001)
        for s: Float in [-1, 1] {
            FO.slab(&m, 0.12, 0.012, 0.012, V3(rng.float(-0.04...0.04), 0.008, s * 0.112), "ceramic.terracotta:5E6B3A", bevel: 0.002)
        }

        // Lead flashing collar around the foot of the plinth.
        let top = tile.map { $0.y }.max() ?? 0.07
        m.add(Prim.lathe([V2(0.085, 0), V2(0.108, 0), V2(0.104, 0.008), V2(0.08, 0.028), V2(0.078, 0.034), V2(0.0, 0.034)], segments: 24, seamTile: 0.1, material: lead),
              Xform(translation: V3(0, top, 0)))

        // Square plinth: stepped base mould, die and projecting cap, as a loft of changing squares.
        let py = top + 0.03
        func sq(_ w: Float, _ y: Float) -> [V3] { Prim.ring(Shape2D.rounded(Shape2D.rect(w, w), radius: 0.004, segments: 1), y: y) }
        m.add(Prim.loft([sq(0.15, 0), sq(0.15, 0.012), sq(0.128, 0.018), sq(0.128, 0.07), sq(0.15, 0.078), sq(0.15, 0.09), sq(0.1, 0.094)],
                        capStart: true, capEnd: true, material: clay), Xform(translation: V3(0, py, 0)))
        let stemY = py + 0.094

        // Iron cramp straps with rivets on two faces of the die.
        for s: Float in [-1, 1] {
            FO.slab(&m, 0.026, 0.08, 0.006, V3(0, py + 0.045, s * 0.067), iron, bevel: 0.0015)
            rivet(&m, at: V3(0, py + 0.02, s * 0.0705), normal: V3(0, 0, s), radius: 0.006, segments: 6, material: iron)
            rivet(&m, at: V3(0, py + 0.07, s * 0.0705), normal: V3(0, 0, s), radius: 0.006, segments: 6, material: iron)
            FO.slab(&m, 0.012, 0.06, 0.002, V3(0.012, py + 0.0, s * 0.0725), "ceramic.terracotta:6B4A33", bevel: 0.0004)
        }

        // Turned baluster stem: ring, bell, swelling vase, neck and collar.
        let stem: [V2] = [V2(0, 0), V2(0.05, 0), V2(0.056, 0.008), V2(0.046, 0.018), V2(0.046, 0.026), V2(0.058, 0.034), V2(0.064, 0.05), V2(0.068, 0.09),
                          V2(0.062, 0.13), V2(0.048, 0.17), V2(0.034, 0.2), V2(0.03, 0.222), V2(0.038, 0.232), V2(0.04, 0.244), V2(0.03, 0.252), V2(0.036, 0.262),
                          V2(0.05, 0.268), V2(0.052, 0.282), V2(0.044, 0.29), V2(0.0, 0.29)]
        // Three tonal bands: damp-darkened foot, fired clay body, bleached neck (weathering baked into the parts).
        func slice(_ pts: [V2], _ y0: Float, _ y1: Float) -> [V2] {
            func at(_ y: Float) -> V2 {
                for i in 0..<(pts.count - 1) where (pts[i].y - y) * (pts[i + 1].y - y) <= 0 && pts[i].y != pts[i + 1].y {
                    let t = (y - pts[i].y) / (pts[i + 1].y - pts[i].y)
                    return V2(pts[i].x + (pts[i + 1].x - pts[i].x) * t, y)
                }
                return V2(0.05, y)
            }
            let mid = pts.filter { $0.y > y0 + 0.0005 && $0.y < y1 - 0.0005 && $0.x > 0 }
            return [V2(0, y0), at(y0)] + mid + [at(y1), V2(0, y1)]
        }
        let bands: [(Float, Float, MaterialKey)] = [(0, 0.1, "ceramic.terracotta:8A4E34"), (0.1, 0.2, clay), (0.2, 0.29, "ceramic.terracotta:B5683F")]
        for (a, b, mat) in bands {
            m.add(Prim.lathe(slice(stem, a, b), segments: 28, seamTile: 0.12, material: mat), Xform(translation: V3(0, stemY, 0)))
        }
        // Gadroon flutes on the swelling of the vase: eight raised ribs.
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi
            let pts: [V3] = (0...6).map { i in
                let t = Float(i) / 6
                let y = stemY + 0.04 + 0.1 * t
                let yr = y - stemY
                var r: Float = 0.064
                for j in 0..<(stem.count - 1) where (stem[j].y - yr) * (stem[j + 1].y - yr) <= 0 && stem[j].y != stem[j + 1].y {
                    r = stem[j].x + (stem[j + 1].x - stem[j].x) * (yr - stem[j].y) / (stem[j + 1].y - stem[j].y)
                }
                return V3((r + 0.0012) * cos(a), y, (r + 0.0012) * sin(a))
            }
            m.add(Prim.tube(pts, radii: [0.0035, 0.005, 0.0058, 0.0058, 0.005, 0.0035, 0.0015], sides: 5, seamTile: 0.1, material: clay, capEnd: true))
        }

        // Crown: eight acanthus leaves, each a lofted blade that widens, then curls outward at the tip.
        let cy = stemY + 0.29
        let widths: [Float] = [0.026, 0.044, 0.056, 0.05, 0.034, 0.014, 0.002]
        let offs: [Float] = [0, 0.002, 0.008, 0.02, 0.036, 0.056, 0.078]
        for k in 0..<leaves {
            let yaw = Float(k) / Float(leaves) * 360 + 11
            let broken = k == 3
            let nRing = broken ? 5 : 7
            var rings: [[V3]] = []
            for i in 0..<nRing {
                let t = Float(i) / 6
                let w = broken && i == nRing - 1 ? widths[i] * 0.7 : widths[i]
                rings.append(Prim.ring(Shape2D.superellipse(w, 0.016 - 0.01 * t, exponent: 2.6, segments: 12), y: t * 0.17, offset: V3(0, 0, -offs[i])))
            }
            let q = FA.q(yaw, FA.Y) * FA.q(rng.float(22...30), FA.X)
            m.add(Prim.loft(rings, capStart: true, capEnd: true, material: crown),
                  Xform(translation: V3(0, cy - 0.01, 0) + FA.q(yaw, FA.Y).act(V3(0, 0, 0.03)), rotation: q).jittered(&rng))
            // Midrib on the leaf: a thin tube following the blade.
            let rib = (0..<4).map { i -> V3 in
                let t = Float(i) / 3
                return V3(0, 0.012 + t * 0.12, 0.009 - offs[min(6, i * 2)] * 0.6)
            }
            m.add(Prim.tube(rib, radii: [0.0028, 0.0026, 0.0022, 0.0012], sides: 5, seamTile: 0.1, material: crown, capEnd: true),
                  Xform(translation: V3(0, cy - 0.01, 0) + FA.q(yaw, FA.Y).act(V3(0, 0, 0.03)), rotation: q))
        }
        // Bud core and spire with a ball tip.
        let bud: [V2] = [V2(0.026, 0), V2(0.028, 0.04), V2(0.026, 0.09), V2(0.022, 0.14), V2(0.016, 0.2), V2(0.011, 0.26), V2(0.009, 0.3)]
        m.add(Prim.lathe([V2(0, 0)] + bud.prefix(5) + [V2(0.016 + 0.0, 0.2), V2(0, 0.2)], segments: 18, seamTile: 0.1, material: crown), Xform(translation: V3(0, cy - 0.01, 0)))
        m.add(Prim.lathe([V2(0, 0.2), V2(0.016, 0.2), V2(0.011, 0.26), V2(0.009, 0.3), V2(0, 0.3)], segments: 18, seamTile: 0.1, material: "ceramic.terracotta:5E3626"),
              Xform(translation: V3(0, cy - 0.01, 0)))
        FC.bead(&m, r: 0.016, at: V3(0, cy - 0.01 + 0.31, 0), crown, sub: 4)

        // Weathering: soot in the leaf throats, lichen on the shoulder of the vase, chipped plinth corner, lime drip down the stem.
        func patch(_ yaw: Float, _ r: Float, _ y: Float, _ w: Float, _ h: Float, _ mat: MaterialKey) {
            let a = yaw * .pi / 180
            m.add(Prim.extrude(Shape2D.rect(w, h), depth: 0.0024, bevel: 0.0005, bevelSegments: 1, material: mat),
                  Xform(translation: V3(r * sin(a), y, r * cos(a)), rotation: FA.q(yaw, FA.Y)))
        }
        // Moss in the foot of the vase and on the plinth cap, soot streaks below the leaf tips, lime runs down the plinth die,
        // rust bleed from the cramp rivets.
        for k in 0..<10 {
            let yw = Float(k) * 37 + rng.float(0...25)
            patch(yw, 0.0615, stemY + rng.float(0.04...0.07), rng.float(0.018...0.036), rng.float(0.02...0.05), "ceramic.terracotta:5A6A3A")
        }
        for k in 0..<4 {
            patch(Float(k) * 90 + 20, 0.0752, py + 0.04 + rng.float(-0.01...0.01), rng.float(0.02...0.04), rng.float(0.04...0.07), k % 2 == 0 ? "brick.mortar-lime" : "ceramic.terracotta:5A3E30")
        }

        groundAO(&m, height: 0.06, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
