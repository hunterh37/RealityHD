import simd
import Foundation

/// Helpers for the o9 facade props: stroke lettering, irregular wear patches, pegs and polygon plates.
/// Same frame as `FA`: wall plane at z = 0, piece projecting toward +Z.
enum FO {
    /// Stroke font: unit-box polylines (x 0...1, y 0...1) for the capitals used on signs.
    static let glyphs: [Character: [[V2]]] = [
        "A": [[V2(0, 0), V2(0.5, 1), V2(1, 0)], [V2(0.2, 0.4), V2(0.8, 0.4)]],
        "B": [[V2(0, 0), V2(0, 1), V2(0.7, 1), V2(0.88, 0.9), V2(0.88, 0.6), V2(0.7, 0.5), V2(0, 0.5)],
              [V2(0.7, 0.5), V2(0.95, 0.4), V2(0.95, 0.1), V2(0.75, 0), V2(0, 0)]],
        "D": [[V2(0, 0), V2(0, 1), V2(0.62, 1), V2(1, 0.75), V2(1, 0.25), V2(0.62, 0), V2(0, 0)]],
        "E": [[V2(0.95, 1), V2(0, 1), V2(0, 0), V2(0.95, 0)], [V2(0, 0.5), V2(0.7, 0.5)]],
        "H": [[V2(0, 0), V2(0, 1)], [V2(1, 0), V2(1, 1)], [V2(0, 0.5), V2(1, 0.5)]],
        "I": [[V2(0.5, 0), V2(0.5, 1)]],
        "K": [[V2(0, 0), V2(0, 1)], [V2(0.95, 1), V2(0, 0.4)], [V2(0.3, 0.62), V2(1, 0)]],
        "L": [[V2(0, 1), V2(0, 0), V2(0.9, 0)]],
        "N": [[V2(0, 0), V2(0, 1), V2(1, 0), V2(1, 1)]],
        "O": [[V2(0.3, 0), V2(0, 0.25), V2(0, 0.75), V2(0.3, 1), V2(0.7, 1), V2(1, 0.75), V2(1, 0.25), V2(0.7, 0), V2(0.3, 0)]],
        "R": [[V2(0, 0), V2(0, 1), V2(0.72, 1), V2(0.9, 0.9), V2(0.9, 0.62), V2(0.72, 0.5), V2(0, 0.5)], [V2(0.45, 0.5), V2(1, 0)]],
        "S": [[V2(1, 0.9), V2(0.8, 1), V2(0.2, 1), V2(0, 0.88), V2(0, 0.64), V2(0.2, 0.52), V2(0.8, 0.48), V2(1, 0.36), V2(1, 0.12), V2(0.8, 0), V2(0.2, 0), V2(0, 0.1)]],
        "T": [[V2(0, 1), V2(1, 1)], [V2(0.5, 1), V2(0.5, 0)]],
        "W": [[V2(0, 1), V2(0.25, 0), V2(0.5, 0.7), V2(0.75, 0), V2(1, 1)]],
        "-": [[V2(0.1, 0.5), V2(0.9, 0.5)]],
    ]

    /// Raised stroke lettering on the plane z = `z` (letters grow toward +Z by `depth`). Returns the width used.
    @discardableResult
    static func letters(_ m: inout Model, _ text: String, x0: Float, y0: Float, height: Float, width: Float, gap: Float,
                        stroke: Float, depth: Float, z: Float, _ mat: MaterialKey, rng: inout SeededRNG, loss: Float = 0, cheap: Bool = false, bevel: Float = 0) -> Float {
        var x = x0
        for ch in text {
            guard let g = glyphs[ch] else { x += width * 0.6; continue }
            for line in g {
                for k in 0..<(line.count - 1) {
                    if loss > 0 && rng.chance(loss) { continue }
                    let a = V2(x + line[k].x * width, y0 + line[k].y * height), b = V2(x + line[k + 1].x * width, y0 + line[k + 1].y * height)
                    seg(&m, a, b, stroke: stroke, depth: depth, z: z, mat, cheap: cheap, bevel: bevel)
                }
            }
            x += width + gap
        }
        return x - x0 - gap
    }

    /// Flat bar between two 2D points on the plane z, `depth` thick toward +Z, ends slightly overlapped.
    static func seg(_ m: inout Model, _ a: V2, _ b: V2, stroke: Float, depth: Float, z: Float, _ mat: MaterialKey, cheap: Bool = false, bevel: Float = 0) {
        let d = b - a, len = simd_length(d) + stroke * 0.7
        let mid = (a + b) / 2, ang = atan2(d.y, d.x)
        if cheap {
            let hx = len / 2, hy = stroke / 2
            m.add(Prim.extrude([V2(-hx, -hy), V2(hx, -hy), V2(hx, hy), V2(-hx, hy)], depth: depth, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(mid.x, mid.y, z + depth / 2), rotation: FA.q(ang * 180 / .pi, FA.Z)))
            return
        }
        m.add(Prim.roundedBox(V3(len, stroke, depth), radius: min(0.0012, depth * 0.35), bevelSegments: 1, material: mat),
              Xform(translation: V3(mid.x, mid.y, z + depth / 2), rotation: FA.q(ang * 180 / .pi, FA.Z)))
    }

    /// Irregular worn patch (flat, 0.5 mm proud) facing +Z at plane z, or facing +Y at height y when `up`.
    static func patch(_ m: inout Model, cx: Float, cy: Float, rx: Float, ry: Float, z: Float, _ mat: MaterialKey,
                      rng: inout SeededRNG, depth: Float = 0.0007, n: Int = 9) {
        var poly: [V2] = []
        for j in 0..<n {
            let a = Float(j) / Float(n) * 2 * .pi
            poly.append(V2(cx + cos(a) * rx * rng.float(0.5...1.1), cy + sin(a) * ry * rng.float(0.5...1.1)))
        }
        m.add(HTKit.plate(outer: poly, depth: depth, bevel: depth * 0.3, segments: 1, material: mat), Xform(translation: V3(0, 0, z)))
    }

    /// Same patch lying on a horizontal surface at height y (x, z extents).
    static func patchTop(_ m: inout Model, cx: Float, cz: Float, rx: Float, rz: Float, y: Float, _ mat: MaterialKey,
                         rng: inout SeededRNG, depth: Float = 0.0007, n: Int = 9) {
        var poly: [V2] = []
        for j in 0..<n {
            let a = Float(j) / Float(n) * 2 * .pi
            poly.append(V2(cx + cos(a) * rx * rng.float(0.5...1.1), cz - sin(a) * rz * rng.float(0.5...1.1)))
        }
        m.add(HTKit.plate(outer: poly, depth: depth, bevel: depth * 0.3, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
    }

    /// Slotted screw or hex bolt head facing +Z at a point on a surface plane.
    static func head(_ m: inout Model, at c: V3, r: Float, h: Float = 0.003, segments: Int = 8, _ mat: MaterialKey) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(0.0008, h * 0.3), segments: segments, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: FA.q(90, FA.X)))
    }

    /// Wooden peg (round, proud 3 mm) facing +Z.
    static func peg(_ m: inout Model, at c: V3, r: Float = 0.007, _ mat: MaterialKey) { head(&m, at: c, r: r, h: 0.004, segments: 8, mat) }

    /// Closed polygon of a pointed (two-centre) arch: springing half-width `hw` at y0, rise `rise`, base down to yBase.
    static func pointedArch(hw: Float, spring y0: Float, rise: Float, base yBase: Float, n: Int = 10) -> [V2] {
        // Two-centre arch: each side a circle of radius 2*hw centred on the opposite springing point.
        let R = 2 * hw
        var pts: [V2] = [V2(hw, yBase), V2(hw, y0)]
        for k in 1...n {
            let t = Float(k) / Float(n)
            let a = t * (.pi / 3)       // 0 ... 60 degrees about the centre at (-hw, y0)
            pts.append(V2(-hw + R * cos(a), y0 + R * sin(a)))
        }
        for k in (0..<n).reversed() {
            let t = Float(k) / Float(n)
            let a = t * (.pi / 3)
            pts.append(V2(hw - R * cos(a), y0 + R * sin(a)))
        }
        pts.append(V2(-hw, yBase))
        _ = rise
        return Shape2D.deduped(pts)
    }
}
