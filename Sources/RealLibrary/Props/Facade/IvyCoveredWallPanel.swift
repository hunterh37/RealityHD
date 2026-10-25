import simd
import Foundation

/// Ivy covered wall panel: a 215 mm brick wall in English bond (alternate stretcher and header courses, 10 mm lime
/// mortar joints struck flush, bricks proud of the mortar face), limestone plinth and saddleback coping in three
/// stones, a frost-spalled brick missing from the field, and common ivy (Hedera helix) rising from the lower left on
/// woody stems with leaf sprays covering about two thirds of the face.
public struct IvyCoveredWallPanel: RealAsset {
    public static let id = "ivy-covered-wall-panel"
    public static let summary = "English bond brick wall panel with limestone plinth and coping, one spalled brick and ivy over two thirds of the face."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.8)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.5, 2.4, 0.2)
    /// Brick colour mix.
    public var bricks: [MaterialKey] = ["brick.unit-red", "brick.unit-red-dark", "brick.unit-red-light", "brick.unit-buff-dark", "brick.unit-sooted"]
    public var mortar: MaterialKey = "brick.mortar-lime"
    public var stone: MaterialKey = "stone.limestone-sooted"
    public var leaf: MaterialKey = "leaf.privet"
    public var stem: MaterialKey = "bark.oak-dry"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.5, D: Float = 0.2, zf = D, plinthH: Float = 0.12, topY: Float = 2.34
        let courses = 29, pitch = (topY - plinthH) / Float(courses), bh = pitch - 0.01
        // Core slab (mortar face recessed 6 mm) and side/back brick-textured faces.
        FA.box(&m, V3(W, topY - plinthH, D - 0.006), V3(0, plinthH + (topY - plinthH) / 2, (D - 0.006) / 2), mortar, r: 0.001)
        FC.slab(&m, V3(W - 0.004, topY - plinthH, 0.002), V3(0, plinthH + (topY - plinthH) / 2, -0.001), "brick.red")
        for s: Float in [-1, 1] { FC.slab(&m, V3(0.002, topY - plinthH, D), V3(s * (W / 2 + 0.001), plinthH + (topY - plinthH) / 2, D / 2), "brick.red") }
        // English bond: even courses stretchers (215), odd courses headers (102.5) with a queen closer at each end.
        let missing = (course: 9, x: Float(0.34))
        for c in 0..<courses {
            let y = plinthH + 0.005 + Float(c) * pitch + bh / 2
            let header = c % 2 == 1
            let len: Float = header ? 0.1025 : 0.215
            var x: Float = -W / 2 + 0.0
            var k = 0
            var cur = header ? 0.0 : -0.1075   // stretcher courses start with a half bat offset
            _ = cur
            while x < W / 2 - 0.001 {
                var bl = len
                if x == -W / 2 && !header { bl = 0.1075 }
                if x + bl > W / 2 { bl = W / 2 - x }
                if bl < 0.03 { break }
                let cx = x + bl / 2
                let skip = c == missing.course && abs(cx - (-W / 2 + (missing.x + 0.75))) < 0.11
                if !skip {
                    let mat = bricks[rng.chance(0.62) ? 0 : rng.int(1...(bricks.count - 1))]
                    let o = Shape2D.rect(bl - 0.002, bh - 0.002)
                    m.add(Prim.extrude(o, depth: 0.011, bevel: 0.0014, bevelSegments: 1, material: mat),
                          Xform(translation: V3(cx + rng.float(-0.0008...0.0008), y, zf - 0.0055 + rng.float(-0.0008...0.0008))))
                }
                x += bl + 0.010
                k += 1
            }
        }
        // Spalled brick: the cavity shows the mortar bed and a shard of the broken brick.
        let sx = -W / 2 + missing.x + 0.75
        let sy = plinthH + 0.005 + Float(missing.course) * pitch
        FA.box(&m, V3(0.06, 0.03, 0.02), V3(sx - 0.06, sy + 0.015, zf - 0.04), "brick.unit-red-dark", r: 0.003, rot: FA.q(8, FA.Z))
        // Limestone plinth (projecting 20 mm, weathered top bevel) and saddleback coping in three stones.
        FA.run(&m, [V2(-0.01, 0), V2(0.22, 0), V2(0.22, 0.105), V2(0.2, 0.12), V2(-0.01, 0.12)], length: W + 0.04, at: V3(0, 0, 0), stone, bevel: 0.003)
        for i in 0..<3 {
            let w = (W + 0.04) / 3 - 0.004, cx = (Float(i) - 1) * ((W + 0.04) / 3)
            FA.run(&m, [V2(-0.02, topY), V2(0.22, topY), V2(0.22, topY + 0.035), V2(0.1, topY + 0.07), V2(-0.02, topY + 0.035)], length: w, at: V3(cx, 0, 0),
                   i == 1 ? "stone.limestone" : stone, bevel: 0.003)
        }
        // Drip throating under the coping (dark groove) and sooty runs below each joint.
        FC.slab(&m, V3(W, 0.005, 0.003), V3(0, topY - 0.004, zf + 0.0005), "wood.charred")
        // Ivy: woody stems climbing from the lower left with aerial rootlets, then leaf sprays by a coverage field.
        func cover(_ x: Float, _ y: Float) -> Float {
            let u = (x + W / 2) / W, v = y / 2.4
            return 1.05 - 0.75 * u - 0.55 * pow(v, 1.4) + 0.12 * sin(x * 9 + y * 5) + 0.1 * sin(y * 11 - x * 3)
        }
        for k in 0..<9 {
            var pts: [V3] = []
            var x = -W / 2 + 0.08 + Float(k) * 0.07, y: Float = 0.12
            let reach = rng.float(1.1...2.2) - Float(k) * 0.08
            while y < reach {
                pts.append(V3(x, y, zf + 0.004 + rng.float(0...0.003)))
                x += rng.float(-0.05...0.07); y += 0.12
                x = max(-W / 2 + 0.04, min(W / 2 - 0.04, x))
            }
            if pts.count > 2 {
                let c = catmull(pts, per: 3)
                m.add(Prim.tube(c, radii: c.indices.map { 0.0085 - 0.0055 * Float($0) / Float(c.count) }, sides: 5, seamTile: 0.05, material: stem, capEnd: true))
            }
        }
        for _ in 0..<1600 {
            let x = rng.float(-W / 2 + 0.07...W / 2 - 0.07), y = rng.float(0.1...2.3)
            if rng.float() > cover(x, y) { continue }
            let w = rng.float(0.1...0.17)
            FC.leafCard(&m, leaf, at: V3(x, y - w / 2, zf + 0.006 + rng.float(0...0.025)), width: w, height: w * rng.float(0.9...1.1), spin: rng.float(-180...180), tilt: rng.float(-14...(-2)))
        }
        // Ivy tendrils dropping from the coping edge and a few over the plinth.
        for _ in 0..<7 {
            let x = rng.float(-0.45...0.0)
            FC.leafCard(&m, leaf, at: V3(x, topY - 0.01, zf + 0.012), width: 0.1, height: rng.float(0.14...0.24), spin: 180 + rng.float(-30...30), tilt: rng.float(-10...(-2)))
        }
        // Wear: moss and splash grime on the plinth and first courses, efflorescence, lime-scale drips below the coping.
        FC.slab(&m, V3(W, 0.2, 0.002), V3(0, plinthH + 0.1, zf + 0.0045), "soil.potting")
        for _ in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.05...0.12), 0.014, 0.03), exponent: 2.2, subdivisions: 2, material: "moss.cushion"),
                  Xform(translation: V3(rng.float(-0.65...0.65), plinthH + 0.008, zf + 0.02)))
        }
        groundAO(&m, height: 0.3, floor: 0.65)
        return LODModel(FC.fit(m, size))
    }
}
