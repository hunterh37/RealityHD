import simd
import Foundation

/// Alpine chalet balcony board, 2.4 m long, 1.0 m high, 30 mm deep: twelve sawn vertical boards (pointed tops, scalloped
/// bottoms) carry alternating heart and pine tree openings with a diamond opening above and below each; a top and a
/// bottom rail sit in front, two end stiles with pyramid caps close the run. Screw heads bleed rust, one board is a pale
/// replacement, the others are dark larch silvered by sun with split checks, rain streaks and lichen along the foot.
public struct ChaletCutworkBalconyBoard: RealAsset {
    public static let id = "chalet-cutwork-balcony-board"
    public static let summary = "Alpine chalet cutwork balcony board, 2.4 m: twelve sawn boards with heart and pine openings, rails and end stiles."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 3.2)

    /// Overall width in meters.
    public var width: Float = 2.4
    /// Number of boards.
    public var boards: Int = 12
    /// Board stain.
    public var stain: MaterialKey = "wood.oak:55402C"
    /// Rails and stiles.
    public var trim: MaterialKey = "wood.oak:765839"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    // MARK: Shapes

    static func heart(_ c: V2, w: Float, steps: Int) -> [V2] {
        var pts: [V2] = []
        for i in 0..<steps {
            let t = Float(i) / Float(steps) * 2 * .pi
            let x = 16 * pow(sin(t), 3)
            let y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
            pts.append(V2(c.x + x / 32 * w, c.y + (y + 2.5) / 32 * w))
        }
        return Shape2D.area(pts) >= 0 ? pts : pts.reversed()
    }

    static func pine(_ c: V2, s: Float) -> [V2] {
        let p: [(Float, Float)] = [(-0.008, -0.065), (0.008, -0.065), (0.008, -0.04), (0.05, -0.04), (0.025, -0.005), (0.04, -0.005), (0.015, 0.03), (0.028, 0.03),
                                   (0, 0.07), (-0.028, 0.03), (-0.015, 0.03), (-0.04, -0.005), (-0.025, -0.005), (-0.05, -0.04), (-0.008, -0.04)]
        let pts = p.map { V2(c.x + $0.0 * s, c.y + $0.1 * s) }
        return Shape2D.area(pts) >= 0 ? pts : pts.reversed()
    }

    static func diamond(_ c: V2, w: Float, h: Float) -> [V2] {
        [V2(c.x, c.y - h / 2), V2(c.x + w / 2, c.y), V2(c.x, c.y + h / 2), V2(c.x - w / 2, c.y)]
    }

    /// Joins CCW holes to the left edge of `outer` with zero-width bridges so one extrusion carries the openings.
    static func withHoles(_ outer: [V2], holes: [[V2]], leftX: Float) -> [V2] {
        var poly = outer
        for h in holes {
            let hole = Array(h.reversed())   // clockwise
            let li = hole.indices.min { hole[$0].x < hole[$1].x }!
            let ordered = Array(hole[li...] + hole[..<li])
            let y = ordered[0].y
            var at = -1
            for i in 0..<poly.count {
                let a = poly[i], b = poly[(i + 1) % poly.count]
                if abs(a.x - leftX) < 1e-6 && abs(b.x - leftX) < 1e-6 && ((a.y >= y && b.y <= y) || (a.y <= y && b.y >= y)) { at = i; break }
            }
            guard at >= 0 else { continue }
            let p = V2(leftX, y)
            poly.insert(contentsOf: [p] + ordered + [ordered[0], p], at: at + 1)
        }
        return poly
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, stileW: Float = 0.07
        let nB = boards
        let innerW = width - 2 * stileW
        let bw = innerW / Float(nB)
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
            if r <= 0.0006 {
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }
        let tints: [MaterialKey] = [stain, "wood.oak:634A32", "wood.oak:46341F", "wood.oak:6E5339", "wood.oak:5A4430", "wood.oak:7A5F44"]

        for i in 0..<nB {
            let cx = -innerW / 2 + (Float(i) + 0.5) * bw
            let w = bw - 0.005
            let nS = lite ? 5 : 9
            var holes: [[V2]] = []
            let motifY: Float = 0.50
            holes.append(Self.diamond(V2(0, 0.745), w: min(0.075, w * 0.5), h: 0.075))
            holes.append(i % 2 == 0 ? Self.heart(V2(0, motifY - 0.005), w: min(0.125, w * 0.68), steps: lite ? 14 : 28) : Self.pine(V2(0, motifY), s: min(1.55, w / 0.1 * 0.8) * 1.0))
            holes.append(Self.diamond(V2(0, 0.265), w: min(0.075, w * 0.5), h: 0.075))
            var outline: [V2] = []
            for k in 0...nS {
                let th = Float.pi + Float(k) / Float(nS) * .pi
                outline.append(V2(w / 2 * cos(th), 0.05 + 0.05 * sin(th)))
            }
            outline += [V2(w / 2, 0.95), V2(0, 1.0), V2(-w / 2, 0.95)]
            // Insert left-edge vertices (descending y) so each bridge has an anchor.
            outline += [V2(-w / 2, 0.745), V2(-w / 2, 0.50), V2(-w / 2, 0.265)]
            let faceMat = i == 7 ? "wood.pine-aged:C2A57E" : tints[(i * 5 + 1) % tints.count]
            let shape = Self.withHoles(outline, holes: holes.sorted { $0[0].y > $1[0].y }, leftX: -w / 2)
            // Authored sideways so the wood grain (texture U) runs up the board.
            m.add(Prim.extrude(shape.map { V2($0.y, -$0.x) }, depth: 0.016, bevel: lite ? 0 : 0.0018, bevelSegments: 1, material: faceMat), Xform(translation: V3(cx, 0, 0.008), rotation: FA.q(90, FA.Z)))
            if !lite {
                if i % 3 == 1 { bx(V3(0.003, rng.float(0.16...0.3), 0.0016), V3(cx + rng.float(-0.05...0.05), 0.62, 0.0168), "wood.oak:1E150C", r: 0.0003) }   // split check
                bx(V3(w - 0.03, 0.012, 0.0016), V3(cx, 0.115, 0.0168), "stone.granite-moss", r: 0.0003)
                bx(V3(w - 0.012, 0.09, 0.0012), V3(cx, 0.945 - 0.045 + 0.0, 0.0167), "wood.weathered:9C8D78", r: 0.0003)   // sun-bleached head
                bx(V3(w - 0.012, 0.075, 0.0012), V3(cx, 0.063, 0.0166), "wood.oak:2C2014", r: 0.0003)      // wet foot
                if i % 2 == 0 { bx(V3(0.012, rng.float(0.1...0.2), 0.0012), V3(cx + rng.float(-0.05...0.05), 0.7, 0.0166), "wood.weathered:2E2318", r: 0.0003) }   // rain streak
            }
        }

        // Rails in front, end stiles with caps.
        for (y, h) in [(0.855 as Float, 0.07 as Float), (0.155, 0.07)] {
            bx(V3(innerW, h, 0.014), V3(0, y, 0.023), trim, r: 0.003)
            bx(V3(innerW, 0.012, 0.018), V3(0, y + (y > 0.5 ? h / 2 + 0.003 : -h / 2 - 0.003), 0.021), trim, r: 0.002)
            for i in 0..<nB where !lite || i % 2 == 0 {
                let cx = -innerW / 2 + (Float(i) + 0.5) * bw
                for dy: Float in [-0.016, 0.016] {
                    m.add(Prim.cylinder(radius: 0.006, height: 0.003, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                          Xform(translation: V3(cx, y + dy, 0.0272), rotation: FA.q(90, FA.X)))
                    if !lite { bx(V3(0.006, rng.float(0.03...0.07), 0.0012), V3(cx, y + dy - 0.03, 0.0302), "metal.rust", r: 0.0003) }
                }
            }
        }
        for sx: Float in [-1, 1] {
            let x = sx * (hw - stileW / 2)
            bx(V3(stileW, 0.93, 0.03), V3(x, 0.465, 0.015), trim, r: 0.004)
            m.add(Prim.loft([Prim.ring(Shape2D.rect(stileW + 0.006, 0.03), y: 0.93, offset: V3(x, 0, 0.015)), Prim.ring(Shape2D.rect(0.008, 0.006), y: 1.0, offset: V3(x, 0, 0.015))], capStart: true, capEnd: true, material: trim))
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return FC.place(m)
    }
}
