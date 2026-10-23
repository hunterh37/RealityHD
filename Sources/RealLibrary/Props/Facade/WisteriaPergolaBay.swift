import simd
import Foundation

/// Wisteria pergola bay: four moulded timber posts on sooted limestone plinths carrying a ring of beams
/// and cut rafters, scroll brackets under the beams, and old wisteria twining up two posts and along
/// the beams with leaf clusters and hanging racemes. Free-standing, bounds centered.
public struct WisteriaPergolaBay: RealAsset {
    public static let id = "wisteria-pergola-bay"
    public static let summary = "Victorian garden pergola bay 3.0 x 2.6 m: painted timber posts on stone plinths, scroll brackets, ring beams and rafters, twining wisteria with hanging racemes."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone", "plant", "garden"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 4.4)

    /// Post centre spacing (m), post section and beam top height.
    public var span: Float = 2.58
    public var post: Float = 0.11
    public var beamTop: Float = 2.46
    public var paint: MaterialKey = "wood.barn-white:E6E0CF"
    public var stone: MaterialKey = "stone.limestone-sooted"
    public var leaf: MaterialKey = "leaf.plain:456F2E"
    public var leafCount: Int = 150
    public var racemeCount: Int = 34
    public init() {}

    /// Scroll bracket profile (u along the beam, v up): concave underside from post to beam.
    private func bracket(_ s: Float) -> [V2] {
        var pts = [V2(0, 0), V2(s, 0), V2(s, -0.03)]
        let r = s - 0.03
        for i in 1..<8 {
            let a = (90 + Float(i) / 8 * 90) * .pi / 180
            pts.append(V2(s + r * cos(a), -s + r * sin(a)))
        }
        pts += [V2(0.03, -s), V2(0, -s)]
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h = span / 2, pw = post
        let bh: Float = 0.16, by0 = beamTop - bh      // ring beam underside
        let plinth: Float = 0.16
        let cx: [(Float, Float)] = [(-h, -h), (h, -h), (h, h), (-h, h)]
        // Posts: stone plinth, base and neck mouldings, chamfered shaft, capital.
        for (x, z) in cx {
            FA.box(&m, V3(0.2, plinth, 0.2), V3(x, plinth / 2, z), stone, r: 0.008)
            FA.box(&m, V3(0.215, 0.012, 0.215), V3(x, plinth + 0.002, z), stone, r: 0.004)
            FA.box(&m, V3(0.15, 0.07, 0.15), V3(x, plinth + 0.045, z), paint, r: 0.006)
            FA.box(&m, V3(pw, by0 - plinth - 0.01, pw), V3(x, (by0 + plinth) / 2, z), paint, r: 0.012)
            // Stopped chamfers read as a recessed lamb's-tongue panel on each face.
            for (dx, dz) in [(0, 1), (0, -1)] as [(Float, Float)] {
                FA.box(&m, V3(dx == 0 ? 0.05 : 0.004, 1.5, dz == 0 ? 0.05 : 0.004), V3(x + dx * pw / 2, 1.2, z + dz * pw / 2), paint, r: 0.0012)
            }
            FA.box(&m, V3(0.15, 0.03, 0.15), V3(x, by0 - 0.015, z), paint, r: 0.005)
            FA.box(&m, V3(0.13, 0.025, 0.13), V3(x, by0 - 0.05, z), paint, r: 0.005)
            // Peeling paint at the foot.
            FA.box(&m, V3(pw * 0.9, 0.3, 0.0008), V3(x, 0.38, z + pw / 2 + 0.0004), "wood.weathered", r: 0.0003)
        }
        // Ring beams on the posts.
        let L = span + 0.17
        for z in [-h, h] { FA.box(&m, V3(L, bh, 0.1), V3(0, by0 + bh / 2, z), paint, r: 0.006) }
        for x in [-h, h] { FA.box(&m, V3(0.1, bh, span - pw), V3(x, by0 + bh / 2, 0), paint, r: 0.006) }
        // Scroll brackets inward from every post along both beam directions.
        for (i, (x, z)) in cx.enumerated() {
            let sx: Float = x < 0 ? 1 : -1, sz: Float = z < 0 ? 1 : -1
            // Along X: extrude runs in Z.
            m.add(Prim.extrude(bracket(0.32), depth: 0.04, bevel: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x + sx * pw / 2, by0, z), rotation: FA.q(sx < 0 ? 180 : 0, FA.Y)))
            // Along Z: rotate the same profile a quarter turn.
            m.add(Prim.extrude(bracket(0.32), depth: 0.04, bevel: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x, by0, z + sz * pw / 2), rotation: FA.q(sz > 0 ? -90 : 90, FA.Y)))
            _ = i
        }
        // Rafters across the beams, ends cut with a bevel; battens above them.
        let nr = 9
        for i in 0..<nr {
            let x = -h + Float(i) * span / Float(nr - 1)
            FA.box(&m, V3(0.055, 0.1, span + 0.17), V3(x, beamTop + 0.05, 0), paint, r: 0.006)
        }
        // Wisteria: heavy twining trunks on the front-left and back-right posts, branching along the beams.
        var spots: [V3] = []
        for (px, pz, dir) in [(-h, -h, 1), (h, h, -1)] as [(Float, Float, Float)] {
            for strand in 0..<2 {
                var path: [V3] = []
                let ph = Float(strand) * .pi
                for i in 0...46 {
                    let t = Float(i) / 46
                    let a = ph + t * 11.5 * dir
                    let rr: Float = 0.088 + 0.012 * sin(t * 21)
                    path.append(V3(px + cos(a) * rr, 0.12 + t * (beamTop - 0.1), pz + sin(a) * rr))
                }
                m.add(Prim.tube(path, radii: path.indices.map { 0.026 - 0.012 * Float($0) / 46 }, sides: 6, seamTile: 0.2, material: "bark.willow", capEnd: true))
                spots += path.suffix(24)
                // Branches out along the beams toward the neighbouring posts, one each way.
                for alongX in [true, false] {
                    var br: [V3] = []
                    let off = (span - 0.2)
                    for i in 0...14 {
                        let t = Float(i) / 14
                        let wob = 0.03 * sin(t * 11 + Float(strand))
                        let side: Float = (strand == 0 ? 1 : -1) * 0.06
                        if alongX {
                            br.append(V3(px + (px < 0 ? 1 : -1) * off * t, beamTop + 0.012 + wob, pz + (pz < 0 ? -1 : 1) * side))
                        } else {
                            br.append(V3(px + (px < 0 ? -1 : 1) * side, beamTop + 0.012 + wob, pz + (pz < 0 ? 1 : -1) * off * t))
                        }
                    }
                    m.add(Prim.tube(br, radii: br.indices.map { 0.016 - 0.008 * Float($0) / 14 }, sides: 5, seamTile: 0.2, material: "bark.willow", capEnd: true))
                    spots += br
                }
            }
        }
        for _ in 0..<leafCount {
            let p = rng.pick(spots)
            m.add(Prim.superellipsoid(V3(0.12, 0.16, 0.008) * rng.float(0.8...1.3), exponent: 2.4, subdivisions: 1, material: leaf),
                  Xform(translation: p + V3(rng.float(-0.1...0.1), rng.float(-0.12...0.1), rng.float(-0.1...0.1)),
                        rotation: FA.q(rng.float(0...360), FA.Z) * FA.q(rng.float(-60...60), FA.X)))
        }
        // Hanging racemes: tapered strings of florets under the rafters near the vine.
        let purples: [MaterialKey] = ["flower.petal:8C6BB8", "flower.petal:A68BCB", "flower.petal:7658A3"]
        let anchors = spots.filter { $0.y > beamTop - 0.2 }
        for _ in 0..<racemeCount {
            let a = rng.pick(anchors)
            let len = rng.float(0.35...0.65)
            let top = V3(a.x + rng.float(-0.1...0.1), beamTop - 0.01, a.z + rng.float(-0.12...0.12))
            var pts: [V3] = []
            for k in 0...5 {
                let t = Float(k) / 5
                pts.append(top + V3(0.02 * sin(t * 4), -t * len, 0.015 * sin(t * 3 + 1)))
            }
            let tone = rng.pick(purples)
            m.add(Prim.tube(pts, radii: [0.04, 0.05, 0.042, 0.03, 0.016, 0.005], sides: 6, seamTile: 0.1, material: tone, capEnd: true))
            for k in 1...3 {
                let t = Float(k) / 5
                FC.bead(&m, r: 0.026 * (1 - t * 0.6), at: pts[k] + V3(rng.float(-0.02...0.02), 0, rng.float(-0.02...0.02)), tone, sub: 1)
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.15, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
