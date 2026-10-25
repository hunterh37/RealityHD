import simd
import Foundation

/// Boston ivy corner: Collegiate Gothic external corner, 200 mm brick wall in running bond with Indiana limestone
/// long-and-short quoins every 225 mm, chamfered plinth water table, projecting string course with drip, and an
/// embattled parapet of two merlons on a coping band. Boston ivy (Parthenocissus tricuspidata) in autumn red and
/// orange climbs on woody vines, covering the lower and left of both faces and spilling over the string course.
public struct BostonIvyCorner: RealAsset {
    public static let id = "boston-ivy-corner"
    public static let summary = "Collegiate Gothic brick corner with limestone quoins, string course and merlons under autumn Boston ivy."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 3.0)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.8, 3.0, 0.8)
    public var bricks: [MaterialKey] = ["brick.unit-red", "brick.unit-red-dark", "brick.unit-red-light", "brick.unit-buff-dark", "brick.unit-sooted"]
    public var mortar: MaterialKey = "brick.mortar-lime"
    public var limestone: MaterialKey = "stone.limestone"
    public var sooted: MaterialKey = "stone.limestone-sooted"
    public var autumn: [MaterialKey] = ["leaf.maple-red", "leaf.japanese-maple", "leaf.maple", "leaf.maple-norway", "leaf.maple-fallen"]
    public var stem: MaterialKey = "bark.maple"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H: Float = 3.0, h: Float = 0.4, t: Float = 0.2, plinth: Float = 0.3, topBrick: Float = 2.76
        let group: Float = 0.225, pitch: Float = 0.075, bh: Float = pitch - 0.01
        func block(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ z0: Float, _ z1: Float, _ mat: MaterialKey, r: Float = 0.004) {
            FA.box(&m, V3(x1 - x0, y1 - y0, z1 - z0), V3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, r: r)
        }
        // Core: front arm (z 0.2 ... 0.4) and side arm (x 0.2 ... 0.4, z -0.4 ... 0.2), recessed mortar faces.
        block(-h, h - 0.006, plinth, topBrick, t, h - 0.006, mortar, r: 0.001)
        block(t, h - 0.006, plinth, topBrick, -h, t, mortar, r: 0.001)
        // End and inner faces in brick pattern.
        FC.slab(&m, V3(0.002, topBrick - plinth, h - t), V3(-h - 0.001, (plinth + topBrick) / 2, (t + h) / 2), "brick.red")
        FC.slab(&m, V3(h - t, topBrick - plinth, 0.002), V3((t + h) / 2, (plinth + topBrick) / 2, -h - 0.001), "brick.red")
        // Plinth water table: 300 mm limestone, chamfered top, projecting 30 mm all round the corner.
        let ch: [V2] = [V2(-0.03, 0), V2(0.43, 0), V2(0.43, plinth - 0.06), V2(0.41, plinth), V2(-0.03, plinth)]
        _ = ch
        block(-h - 0.03, h + 0.03, 0, plinth - 0.05, t - 0.03, h + 0.03, sooted)
        block(t - 0.03, h + 0.03, 0, plinth - 0.05, -h - 0.03, t - 0.03, sooted)
        block(-h - 0.015, h + 0.015, plinth - 0.05, plinth, t - 0.015, h + 0.015, limestone, r: 0.008)
        block(t - 0.015, h + 0.015, plinth - 0.05, plinth, -h - 0.015, t - 0.015, limestone, r: 0.008)
        // Quoins and brick courses in groups of three courses.
        let groups = Int((topBrick - plinth) / group)
        for g in 0..<groups {
            let y0 = plinth + Float(g) * group, y1 = y0 + group - 0.01
            let longFront = g % 2 == 0
            let lf: Float = longFront ? 0.45 : 0.225, ls: Float = longFront ? 0.225 : 0.45
            let tones: [MaterialKey] = [limestone, "stone.limestone:D2C8B3", "stone.limestone:BDB29B", sooted, "stone.limestone:C9BEA6"]
            let mat = tones[(g * 3 + Int(rng.float(0...1) * 2)) % tones.count]
            block(h - lf, h, y0, y1, t, h, mat)
            block(t, h, y0 + 0.001, y1 - 0.001, h - ls, t + (h - t) * 0, mat, r: 0.004)
            block(t, h, y0 + 0.001, y1 - 0.001, h - ls, h, mat, r: 0.004)
            for c in 0..<3 {
                let y = y0 + Float(c) * pitch + bh / 2 + 0.005
                // Front face bricks: stretchers 215, running bond offset per course, ending at the quoin edge.
                var x: Float = -h + (c % 2 == 0 ? 0 : 0.1075 - 0.1075) , first = true
                let offset: Float = (g + c) % 2 == 0 ? 0 : 0.1075
                x = -h
                while x < h - lf - 0.001 {
                    var bl: Float = 0.215
                    if first && offset > 0 { bl = offset; first = false }
                    first = false
                    if x + bl > h - lf { bl = h - lf - x }
                    if bl < 0.04 { x += bl + 0.01; continue }
                    let b = bricks[rng.chance(0.6) ? 0 : rng.int(1...(bricks.count - 1))]
                    m.add(Prim.extrude(Shape2D.rect(bl - 0.002, bh - 0.002), depth: 0.011, bevel: 0.0014, bevelSegments: 1, material: b),
                          Xform(translation: V3(x + bl / 2, y, h - 0.0055)))
                    x += bl + 0.01
                }
                // Side face bricks (z runs -h ... h - ls).
                var z: Float = -h
                var f2 = true
                while z < h - ls - 0.001 {
                    var bl: Float = 0.215
                    if f2 && offset > 0 { bl = offset }
                    f2 = false
                    if z + bl > h - ls { bl = h - ls - z }
                    if bl < 0.04 { z += bl + 0.01; continue }
                    let b = bricks[rng.chance(0.6) ? 0 : rng.int(1...(bricks.count - 1))]
                    m.add(Prim.extrude(Shape2D.rect(bl - 0.002, bh - 0.002), depth: 0.011, bevel: 0.0014, bevelSegments: 1, material: b),
                          Xform(translation: V3(h - 0.0055, y, z + bl / 2), rotation: FA.q(90, FA.Y)))
                    z += bl + 0.01
                }
            }
        }
        // String course at 1.5 m: 140 mm limestone band projecting 45 mm, weathered top, drip groove.
        let sc: Float = 1.5
        block(-h - 0.045, h + 0.045, sc, sc + 0.14, t - 0.045, h + 0.045, limestone, r: 0.012)
        block(t - 0.045, h + 0.045, sc, sc + 0.14, -h - 0.045, t - 0.045, limestone, r: 0.012)
        FC.slab(&m, V3(0.86, 0.008, 0.004), V3(-0.0, sc + 0.012, h + 0.046), "wood.charred")
        // Parapet: coping band at 2.76, 90 mm limestone projecting 40 mm, then two 180 mm merlons.
        block(-h - 0.04, h + 0.04, topBrick, topBrick + 0.09, t - 0.04, h + 0.04, limestone, r: 0.008)
        block(t - 0.04, h + 0.04, topBrick, topBrick + 0.09, -h - 0.04, t - 0.04, limestone, r: 0.008)
        for (cx, cz, w, d) in [(Float(0.05), Float(0.3), Float(0.22), Float(0.2)), (Float(0.3), Float(-0.1), Float(0.2), Float(0.22))] {
            block(cx - w / 2, cx + w / 2, topBrick + 0.09, H - 0.035, cz - d / 2, cz + d / 2, sooted, r: 0.006)
            block(cx - w / 2 - 0.01, cx + w / 2 + 0.01, H - 0.035, H, cz - d / 2 - 0.01, cz + d / 2 + 0.01, limestone, r: 0.01)
        }
        // Boston ivy: woody vines up both faces, leaf cards by coverage, autumn colours graded by height.
        func cover(_ u: Float, _ y: Float) -> Float {
            1.0 - 0.8 * u - 0.45 * pow(y / H, 1.3) + 0.15 * sin(u * 13 + y * 3) + 0.1 * sin(y * 9)
        }
        for k in 0..<7 {
            var pts: [V3] = []
            var x = -h + 0.1 + Float(k) * 0.1, y: Float = 0.1
            let reach = rng.float(1.2...2.7)
            while y < reach {
                pts.append(V3(x, y, h + 0.006 + rng.float(0...0.004)))
                x += rng.float(-0.04...0.06); y += 0.14
                x = max(-h + 0.04, min(h - 0.05, x))
            }
            if pts.count > 2 {
                let c = catmull(pts, per: 3)
                m.add(Prim.tube(c, radii: c.indices.map { 0.009 - 0.006 * Float($0) / Float(c.count) }, sides: 5, seamTile: 0.05, material: stem, capEnd: true))
            }
        }
        for _ in 0..<1700 {
            let face = rng.chance(0.55)
            let u = rng.float(0...1), y = rng.float(0.1...2.78)
            if rng.float() > cover(u, y) { continue }
            let w = rng.float(0.13...0.22)
            let mat = autumn[min(autumn.count - 1, Int(Float(autumn.count) * (0.6 * rng.float() + 0.4 * (y / H))))]
            if face {   // front face, x from -h + 0.1 to h - 0.05
                let x = -h + 0.09 + u * (2 * h - 0.14 - 0.0)
                FC.leafCard(&m, mat, at: V3(x, y - w / 2, h + 0.008 + rng.float(0...0.03)), width: w, height: w, spin: rng.float(-180...180), tilt: rng.float(-14...(-2)))
            } else {    // side face
                let z = -h + 0.09 + u * (2 * h - 0.14)
                FC.leafCard(&m, mat, at: V3(h + 0.008 + rng.float(0...0.03), y - w / 2, z), width: w, height: w, spin: rng.float(-180...180), tilt: rng.float(-14...(-2)), yaw: 90)
            }
        }
        // Tendrils hanging off the string course and coping.
        for k in 0..<10 {
            let x = rng.float(-h + 0.1...h)
            FC.leafCard(&m, autumn[k % 3], at: V3(x, sc + 0.02, h + 0.05), width: 0.12, height: rng.float(0.15...0.3), spin: 180 + rng.float(-30...30), tilt: rng.float(-10...(-2)))
        }
        // Wear: soot streaks below the string course, moss in the water-table joint, efflorescence.
        FC.slab(&m, V3(0.5, 0.02, 0.004), V3(-0.1, sc - 0.015, h + 0.003), "wood.charred")
        for _ in 0..<4 {
            m.add(Prim.superellipsoid(V3(rng.float(0.05...0.1), 0.014, 0.04), exponent: 2.2, subdivisions: 2, material: "moss.cushion"),
                  Xform(translation: V3(rng.float(-0.35...0.3), plinth + 0.008, h + 0.03)))
        }
        groundAO(&m, height: 0.4, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
