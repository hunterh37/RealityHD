import simd
import Foundation

/// Medieval Tudor jettied corner, 1.5 x 2.8 x 1.5 m: a limestone plinth and brick-nogged lower storey with a
/// corner post, bressumer beams and a diagonal dragon beam, then an upper storey that overhangs by 0.3 m on
/// joist ends, framed in oak with a jowled corner post, studs, mid rails, curved and straight braces, plaster infill
/// panels, one patch of fallen daub showing the wattle, oak pegs at the joints and a top plate. Timbers are silvered and
/// checked, plaster is stained under the sills and cracked at the corners, and the plinth is splashed and mossy.
public struct TimberFrameJettiedCorner: RealAsset {
    public static let id = "timber-frame-jettied-corner"
    public static let summary = "Medieval Tudor jettied corner, 1.5 x 2.8 x 1.5 m: oak frame on a stone plinth, dragon beam, joist ends, braced studs, plaster and brick infill, pegged joints."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 222, elevation: 12, distance: 1.0)

    /// Oak framing.
    public var oak: MaterialKey = "wood.weathered"
    /// Darker oak of pegs and shaded timbers.
    public var dark: MaterialKey = "wood.pole-creosote"
    /// End grain of joists and beams.
    public var endGrain: MaterialKey = "wood.endgrain-weathered"
    /// Lime plaster infill.
    public var plaster: MaterialKey = "paint.stucco:C4B898"
    /// Stained plaster.
    public var stain: MaterialKey = "paint.stucco:A59B84"
    /// Brick nogging on the lower storey.
    public var brick: MaterialKey = "brick.red"
    /// Plinth stone.
    public var stone: MaterialKey = "stone.limestone-sooted"
    /// Moss on the plinth.
    public var moss: MaterialKey = "stone.granite-moss:4F6B2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 1.5, jet: Float = 0.3, t: Float = 0.16
        /// Chamfered axis-aligned beam: octagonal outline in XY, depth along Z.
        func bx(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ z0: Float, _ z1: Float, _ mat: MaterialKey, c: Float = 0.004) {
            let w = x1 - x0, h = y1 - y0, d = z1 - z0
            guard w > 0, h > 0, d > 0 else { return }
            let k = min(c, min(w, h) * 0.3), hx = w / 2, hy = h / 2
            let o: [V2] = [V2(-hx + k, -hy), V2(hx - k, -hy), V2(hx, -hy + k), V2(hx, hy - k), V2(hx - k, hy), V2(-hx + k, hy), V2(-hx, hy - k), V2(-hx, -hy + k)]
            m.add(Prim.extrude(o, depth: d, bevel: min(0.0025, d * 0.3), bevelSegments: 1, material: mat), Xform(translation: V3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)))
        }
        /// Wall-space box: u along the wall from the corner, w outward (negative into the wall), offset `off` from the world axes.
        func wb(_ wall: Int, _ off: Float, _ u0: Float, _ u1: Float, _ y0: Float, _ y1: Float, _ w0: Float, _ w1: Float, _ mat: MaterialKey, c: Float = 0.004) {
            if wall == 0 { bx(u0, u1, y0, y1, off - w1, off - w0, mat, c: c) } else { bx(off - w1, off - w0, y0, y1, u0, u1, mat, c: c) }
        }
        /// Diagonal brace as a parallelogram in the wall plane (u, y) with width `wd`, between two centre points.
        func diag(_ wall: Int, _ off: Float, _ a: V2, _ b: V2, _ w0: Float, _ w1: Float, wd: Float, _ mat: MaterialKey) {
            let d = b - a, len = simd_length(d), ang = atan2(d.y, d.x)
            let hx = len / 2 + wd * 0.35, hy = wd / 2
            let o: [V2] = [V2(-hx, -hy), V2(hx, -hy), V2(hx, hy), V2(-hx, hy)]
            let mid = (a + b) / 2, depth = w1 - w0
            if wall == 0 {
                m.add(Prim.extrude(o, depth: depth, bevel: 0.0025, bevelSegments: 1, material: mat),
                      Xform(translation: V3(mid.x, mid.y, off - (w0 + w1) / 2), rotation: FA.q(ang * 180 / .pi, FA.Z)))
            } else {
                m.add(Prim.extrude(o, depth: depth, bevel: 0.0025, bevelSegments: 1, material: mat),
                      Xform(translation: V3(off - (w0 + w1) / 2, mid.y, mid.x), rotation: FA.q(-90, FA.Y) * FA.q(ang * 180 / .pi, FA.Z)))
            }
        }
        func peg(_ wall: Int, _ off: Float, _ u: Float, _ y: Float) {
            guard !lite else { return }
            let rot: simd_quatf = wall == 0 ? FA.q(-90, FA.X) : FA.q(90, FA.Z)
            let p = wall == 0 ? V3(u, y, off) : V3(off, y, u)
            m.add(Prim.cylinder(radius: 0.0085, height: 0.007, bevel: 0.0015, segments: 6, bevelSegments: 1, material: dark), Xform(translation: p, rotation: rot))
        }
        // MARK: plinth
        for wall in 0..<2 {
            let u0: Float = wall == 0 ? 0.3 : 0.46
            wb(wall, jet, u0, L, 0, 0.3, -0.24, 0.02, stone, c: 0.01)
        }
        wb(0, jet, 0.28, 0.48, 0, 0.3, -0.24, 0.02, stone, c: 0.01)
        // MARK: lower storey (wall plane offset by the jetty)
        let ly0: Float = 0.3, ly1: Float = 1.3
        for wall in 0..<2 {
            let uS: Float = wall == 0 ? jet : jet + 0.16
            wb(wall, jet, uS, L, ly0, ly0 + 0.1, -t, 0.0, oak)                      // sill
            for (a, b) in [(Float(0.85), Float(0.97)), (1.38, 1.5)] { wb(wall, jet, a, b, ly0 + 0.1, ly1, -t, 0.0, oak) }   // posts
            wb(wall, jet, jet + 0.16, L, 0.8, 0.88, -t, 0.0, oak)                   // mid rail
            // Brick nogging in the three lower cells, inset behind the timber.
            for (a, b) in [(Float(jet + 0.16), Float(0.85)), (0.97, 1.38)] {
                wb(wall, jet, a, b, ly0 + 0.1, 0.8, -0.12, -0.03, brick, c: 0.002)
                wb(wall, jet, a, b, 0.88, ly1, -0.12, -0.03, brick, c: 0.002)
            }
            // Braces in the lower cells.
            diag(wall, jet, V2(jet + 0.16, ly0 + 0.1), V2(0.85, 0.8), -0.15, -0.005, wd: 0.07, oak)
            diag(wall, jet, V2(1.38, ly0 + 0.1), V2(0.97, 0.8), -0.15, -0.005, wd: 0.07, oak)
            for (u, y) in [(Float(0.91), Float(0.4)), (0.91, 0.84), (1.44, 0.4), (1.44, 0.84), (0.91, 1.28), (1.44, 1.28)] { peg(wall, jet, u, y) }
        }
        // Lower corner post (square) and bressumer beams.
        bx(jet, jet + t, ly0 + 0.1, ly1, jet, jet + t, oak)
        wb(0, jet, jet, L, ly1, ly1 + 0.16, -t, 0.0, oak)
        wb(1, jet, jet + t, L, ly1, ly1 + 0.16, -t, 0.0, oak)
        for (u, y) in [(Float(0.5), Float(1.38)), (1.0, 1.38), (1.44, 1.38)] { peg(0, jet, u, y); peg(1, jet, u, y) }
        // MARK: jetty joists and dragon beam
        let jy0: Float = 1.46, jy1: Float = 1.58
        for k in 0..<4 {
            let u = 0.55 + Float(k) * 0.28
            bx(u - 0.05, u + 0.05, jy0, jy1, 0.0, 0.5, oak)          // wall A joists run along z
            bx(0.0, 0.5, jy0, jy1, u - 0.05, u + 0.05, oak)           // wall B joists run along x
            // End-grain faces on the projecting ends.
            m.add(Prim.extrude([V2(-0.05, -0.06), V2(0.05, -0.06), V2(0.05, 0.06), V2(-0.05, 0.06)], depth: 0.003, bevel: 0.0006, bevelSegments: 1, material: endGrain), Xform(translation: V3(u, (jy0 + jy1) / 2, 0.0015)))
            m.add(Prim.extrude([V2(-0.05, -0.06), V2(0.05, -0.06), V2(0.05, 0.06), V2(-0.05, 0.06)], depth: 0.003, bevel: 0.0006, bevelSegments: 1, material: endGrain), Xform(translation: V3(0.0015, (jy0 + jy1) / 2, u), rotation: FA.q(90, FA.Y)))
        }
        m.add(Prim.extrude([V2(-0.31, -0.06), V2(0.31, -0.06), V2(0.31, 0.06), V2(-0.31, 0.06)], depth: 0.14, bevel: 0.003, bevelSegments: 1, material: oak),
              Xform(translation: V3(0.26, (jy0 + jy1) / 2, 0.26), rotation: FA.q(-45, FA.Y) * FA.q(0, FA.X)))
        // MARK: upper storey
        let sy0: Float = 1.58, uy0: Float = 1.68, uy1: Float = 2.68, ty1: Float = 2.8
        for wall in 0..<2 {
            let uS: Float = wall == 0 ? 0 : t
            wb(wall, 0, uS, L, sy0, uy0, -t, 0.0, oak)                         // sill
            wb(wall, 0, uS, L, uy1, ty1, -t, 0.0, oak)                         // top plate
            wb(wall, 0, t + 0.0, L, 2.2, 2.28, -t, 0.0, oak)                   // mid rail
            // Posts and studs.
            for (a, b) in [(Float(0.46), Float(0.54)), (0.94, 1.06), (1.38, 1.5)] { wb(wall, 0, a, b, uy0, uy1, -t, 0.0, oak) }
            // Plaster infill in three cells, upper and lower, inset behind the timber face.
            for (a, b) in [(Float(t), Float(0.46)), (0.54, 0.94), (1.06, 1.38)] {
                wb(wall, 0, a, b, uy0, 2.2, -0.13, -0.04, plaster, c: 0.002)
                wb(wall, 0, a, b, 2.28, uy1, -0.13, -0.04, plaster, c: 0.002)
            }
            // Braces: long diagonals in the lower cells, short ones above, raking toward the centre.
            diag(wall, 0, V2(t, uy0), V2(0.46, 2.2), -0.155, -0.005, wd: 0.075, oak)
            diag(wall, 0, V2(0.94, uy0), V2(0.54, 2.2), -0.155, -0.005, wd: 0.075, oak)
            diag(wall, 0, V2(1.38, uy0), V2(1.06, 2.2), -0.155, -0.005, wd: 0.075, oak)
            diag(wall, 0, V2(t, 2.28), V2(0.46, uy1), -0.155, -0.005, wd: 0.075, oak)
            diag(wall, 0, V2(0.54, 2.28), V2(0.94, uy1), -0.155, -0.005, wd: 0.075, oak)
            for (u, y) in [(Float(0.5), Float(1.76)), (0.5, 2.24), (0.5, 2.6), (1.0, 1.76), (1.0, 2.24), (1.0, 2.6), (1.44, 1.76), (1.44, 2.24), (1.44, 2.6), (0.08, 1.76), (0.08, 2.24), (0.08, 2.6)] { peg(wall, 0, u, y) }
        }
        // Upper corner post with jowled head: the post plus a flaring block under the plate.
        bx(0, t, uy0, uy1, 0, t, dark)
        bx(-0.006, t + 0.006, 2.44, uy1, -0.006, t + 0.006, dark, c: 0.006)
        // Knee braces from the corner post to the top plate on both walls.
        for wall in 0..<2 { diag(wall, 0, V2(t + 0.01, 2.36), V2(0.4, uy1 - 0.01), -0.15, -0.008, wd: 0.07, dark) }
        // Wattle and daub: the plaster in one cell of wall A has fallen, exposing the lath grid.
        if !lite {
            let a: Float = 0.6, b: Float = 0.88
            // Withies (horizontal) and staves (vertical) in the cell above the mid rail.
            for k in 0..<7 { let y = 2.31 + Float(k) * 0.05; bx(a, b, y - 0.008, y + 0.008, 0.1, 0.13, "wood.cedar-weathered", c: 0.003) }
            for k in 0..<5 { let u = a + 0.02 + Float(k) * 0.06; bx(u - 0.01, u + 0.01, 2.29, 2.66, 0.085, 0.115, "wood.cedar-weathered", c: 0.003) }
        }
        // MARK: weathering
        if !lite {
            // Plaster stained under the sills and cracked beside the posts.
            for wall in 0..<2 {
                for (a, b, y) in [(Float(0.16), Float(0.46), Float(1.72)), (0.54, 0.94, 1.72), (1.06, 1.38, 1.72), (0.16, 0.46, 2.32), (1.06, 1.38, 2.32)] {
                    wb(wall, 0, a + 0.01, b - 0.01, y - 0.02, y + 0.12, -0.0405, -0.0392, stain, c: 0.001)
                }
                wb(wall, 0, 1.0 - 0.0, 1.0 + 0.004, 1.72, 2.1, -0.0402, -0.0392, "paint.stucco:5A5448", c: 0.0005)
            }
            // Moss and splash on the plinth.
            for _ in 0..<6 { FO.patch(&m, cx: rng.float(0.7...1.45), cy: rng.float(0.01...0.2), rx: rng.float(0.03...0.09), ry: rng.float(0.02...0.06), z: jet - 0.0005 - 0.02, moss, rng: &rng, depth: 0.0008) }
            for _ in 0..<5 { FO.patchTop(&m, cx: rng.float(0.5...1.4), cz: jet + rng.float(0.03...0.2), rx: rng.float(0.05...0.12), rz: rng.float(0.02...0.05), y: 0.3001, moss, rng: &rng, depth: 0.0008) }
            // Checks (drying cracks) along the beams and silvered ends.
            for k in 0..<5 {
                let u = 0.3 + Float(k) * 0.2 + rng.float(-0.04...0.04)
                bx(u, u + rng.float(0.1...0.2), 1.37 + rng.float(0...0.05), 1.372 + rng.float(0...0.05), jet - 0.0002, jet + 0.0, "wood.charred", c: 0.0003)
            }
        }
        groundAO(&m, height: 0.35, floor: 0.7)
        return FC.place(m)
    }
}
