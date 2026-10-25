import simd
import Foundation

/// Helpers for the facade service and lighting props (vents, fire service fittings, luminaires).
/// Same frame as `FA`: wall plane at z = 0, piece projecting toward +Z.
enum FSV {
    /// Cylinder between two points, caps beveled.
    static func cyl(_ m: inout Model, _ a: V3, _ b: V3, r: Float, _ mat: MaterialKey, bevel: Float = 0.0015, segments: Int = 20) {
        let d = b - a, len = simd_length(d)
        guard len > 1e-5 else { return }
        m.add(Prim.cylinder(radius: r, height: len, bevel: min(bevel, r * 0.4), segments: segments, bevelSegments: 1, material: mat),
              Xform(translation: a, rotation: facing(d)))
    }
    /// Round-head screw (domed pan head with a slot) seated on a surface.
    static func screw(_ m: inout Model, at p: V3, normal n: V3, r: Float = 0.004, _ mat: MaterialKey = "metal.screw-zinc") {
        let q = facing(n)
        m.add(Prim.cylinder(radius: r, height: r * 0.5, bevel: r * 0.25, segments: 10, bevelSegments: 1, material: mat), Xform(translation: p, rotation: q))
        m.add(Prim.roundedBox(V3(r * 1.5, r * 0.28, r * 0.22), radius: r * 0.06, bevelSegments: 1, material: "metal.tool-ground"),
              Xform(translation: p + simd_normalize(n) * r * 0.5, rotation: q * simd_quatf(degrees: 35, axis: .up)))
    }
    /// Closed square ring (half = half width) at height y, centered on c.
    static func sq(_ half: Float, _ y: Float, c: V3 = .zero) -> [V3] {
        Prim.ring(Shape2D.rect(2 * half, 2 * half), y: y, offset: c)
    }
    /// Mitered square moulding built by lofting square rings: (outward offset from the half width, y) steps.
    static func squareMoulding(_ m: inout Model, half: Float, steps: [V2], y0: Float, c: V3 = .zero, _ mat: MaterialKey) {
        let rings = steps.map { sq(half + $0.x, y0 + $0.y, c: c) }
        m.add(Prim.loft(rings, capStart: true, capEnd: true, material: mat))
    }
    /// Spiral path in the XY plane at depth z: radius r0 to r1 over `turns`, starting at angle a0 (degrees).
    static func spiral(c: V2, z: Float, r0: Float, r1: Float, turns: Float, a0: Float, dir: Float = 1, steps: Int = 22) -> [V3] {
        (0...steps).map { i in
            let t = Float(i) / Float(steps)
            let a = (a0 * .pi / 180) + dir * t * turns * 2 * .pi, r = r0 + (r1 - r0) * t
            return V3(c.x + r * cos(a), c.y + r * sin(a), z)
        }
    }
    /// Drip streak under a fixing: a thin stained strip.
    static func streak(_ m: inout Model, at p: V3, w: Float, h: Float, _ mat: MaterialKey) {
        FA.box(&m, V3(w, h, 0.0012), p - V3(0, h / 2, 0), mat, r: 0.0004)
    }
}

extension FSV {
    /// Block capital letters (F I R E O X A N T S L P) built from bars, facing +Z, centered at c. h = cap height.
    static func letters(_ m: inout Model, _ text: String, c: V3, h: Float, stroke: Float, gap: Float, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        let w = h * 0.6
        let n = Float(text.count)
        var x = -(n * w + (n - 1) * gap) / 2
        for ch in text {
            func bar(_ cx: Float, _ cy: Float, _ bw: Float, _ bh: Float) {
                FA.box(&m, V3(bw, bh, stroke * 0.5), rot.act(V3(x + cx, cy, 0)) + c, mat, r: stroke * 0.12, rot: rot)
            }
            let l = stroke / 2, r = w - stroke / 2, t = h / 2 - stroke / 2, b = -h / 2 + stroke / 2
            switch ch {
            case "F": bar(l, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w * 0.42, 0, w * 0.8, stroke)
            case "I": bar(w / 2, 0, stroke, h)
            case "R": bar(l, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, 0, w, stroke); bar(r, h / 4, stroke, h / 2); bar(w * 0.7, b + h * 0.12, stroke, h * 0.32)
            case "E": bar(l, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, 0, w * 0.8, stroke); bar(w / 2, b, w, stroke)
            case "X": bar(w / 2, 0, stroke, h); bar(w / 2, 0, w, stroke)
            case "T": bar(w / 2, 0, stroke, h); bar(w / 2, t, w, stroke)
            case "L": bar(l, 0, stroke, h); bar(w / 2, b, w, stroke)
            case "D": bar(l, 0, stroke, h); bar(w / 2 - stroke / 4, t, w - stroke / 2, stroke); bar(w / 2 - stroke / 4, b, w - stroke / 2, stroke); bar(r, 0, stroke, h * 0.7)
            case "C": bar(l, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, b, w, stroke)
            case "O": bar(l, 0, stroke, h); bar(r, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, b, w, stroke)
            case "A": bar(l, 0, stroke, h); bar(r, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, 0, w, stroke)
            case "N": bar(l, 0, stroke, h); bar(r, 0, stroke, h); bar(w / 2, 0, stroke, h * 0.9)
            case "S": bar(w / 2, t, w, stroke); bar(w / 2, 0, w, stroke); bar(w / 2, b, w, stroke); bar(l, h / 4, stroke, h / 2); bar(r, -h / 4, stroke, h / 2)
            case "P": bar(l, 0, stroke, h); bar(w / 2, t, w, stroke); bar(w / 2, 0, w, stroke); bar(r, h / 4, stroke, h / 2)
            default: break
            }
            x += w + gap
        }
    }
}

extension FSV {
    /// Light hex bolt head (6-sided prism with a washer disc), size = across flats.
    static func bolt(_ m: inout Model, at p: V3, normal n: V3, size: Float = 0.013, material: MaterialKey) {
        let q = facing(n)
        m.add(Prim.cylinder(radius: size * 0.85, height: 0.0014, bevel: 0.0003, segments: 10, bevelSegments: 1, material: material), Xform(translation: p, rotation: q))
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: size / sqrt(3)), depth: size * 0.5, bevel: size * 0.05, bevelSegments: 1, material: material),
              Xform(translation: p + simd_normalize(n) * (0.0014 + size * 0.25), rotation: q * simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
    }
    /// Light chain: elongated oval links alternating 90 degrees along a path.
    static func chain(_ m: inout Model, along path: [V3], link: Float = 0.0075, wire: Float = 0.0018, _ mat: MaterialKey) {
        let pts = resample(path, spacing: link * 1.3)
        guard pts.count > 1 else { return }
        for i in 0..<(pts.count - 1) {
            let a = pts[i], b = pts[i + 1], d = simd_normalize(b - a)
            let q = simd_quatf(angle: Float(i % 2) * .pi / 2, axis: d) * simd_quatf(from: V3(1, 0, 0), to: d)
            m.add(Prim.torus(major: link * 0.5, minor: wire, segments: 8, sides: 4, material: mat),
                  Xform(translation: (a + b) / 2, rotation: q, scale: V3(1.45, 1, 1)))
        }
    }
}
