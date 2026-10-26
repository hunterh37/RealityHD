import simd
import Foundation

/// Stroke lettering for the facade signage props. Glyphs are polylines in a unit cell (x 0...1, y 0...1)
/// laid on the wall plane (XY), facing +Z. Each stroke is a beveled bar (raised cast, enamel or gilded
/// lettering) or a round rod (neon tube).
enum FS {
    typealias Stroke = (Float, Float, Float, Float)

    static func flip(_ s: [Stroke]) -> [Stroke] { s.map { (1 - $0.0, 1 - $0.1, 1 - $0.2, 1 - $0.3) } }

    static let six: [Stroke] = [(1, 0.85, 0.75, 1), (0.75, 1, 0.25, 1), (0.25, 1, 0, 0.75), (0, 0.75, 0, 0.25), (0, 0.25, 0.25, 0),
                                (0.25, 0, 0.75, 0), (0.75, 0, 1, 0.25), (1, 0.25, 1, 0.45), (1, 0.45, 0.75, 0.62), (0.75, 0.62, 0, 0.6)]

    static let glyphs: [Character: (w: Float, s: [Stroke])] = [
        "D": (0.8, [(0, 0, 0, 1), (0, 1, 0.55, 1), (0, 0, 0.55, 0), (0.55, 1, 1, 0.7), (1, 0.7, 1, 0.3), (1, 0.3, 0.55, 0)]),
        "E": (0.7, [(0, 0, 0, 1), (0, 1, 1, 1), (0, 0.5, 0.8, 0.5), (0, 0, 1, 0)]),
        "H": (0.8, [(0, 0, 0, 1), (1, 0, 1, 1), (0, 0.5, 1, 0.5)]),
        "I": (0.35, [(0.5, 0, 0.5, 1), (0.1, 1, 0.9, 1), (0.1, 0, 0.9, 0)]),
        "L": (0.65, [(0, 0, 0, 1), (0, 0, 1, 0)]),
        "N": (0.85, [(0, 0, 0, 1), (1, 0, 1, 1), (0, 1, 1, 0)]),
        "O": (0.85, [(0.25, 1, 0.75, 1), (0.75, 1, 1, 0.75), (1, 0.75, 1, 0.25), (1, 0.25, 0.75, 0), (0.75, 0, 0.25, 0), (0.25, 0, 0, 0.25), (0, 0.25, 0, 0.75), (0, 0.75, 0.25, 1)]),
        "R": (0.8, [(0, 0, 0, 1), (0, 1, 0.7, 1), (0, 0.5, 0.7, 0.5), (0.7, 1, 1, 0.85), (1, 0.85, 1, 0.65), (1, 0.65, 0.7, 0.5), (0.45, 0.5, 1, 0)]),
        "T": (0.75, [(0, 1, 1, 1), (0.5, 0, 0.5, 1)]),
        "U": (0.8, [(0, 1, 0, 0.25), (0, 0.25, 0.25, 0), (0.25, 0, 0.75, 0), (0.75, 0, 1, 0.25), (1, 0.25, 1, 1)]),
        "V": (0.8, [(0, 1, 0.5, 0), (0.5, 0, 1, 1)]),
        "1": (0.5, [(0.5, 0, 0.5, 1), (0.5, 1, 0.1, 0.8), (0.1, 0, 0.9, 0)]),
        "2": (0.75, [(0, 0.8, 0.25, 1), (0.25, 1, 0.75, 1), (0.75, 1, 1, 0.8), (1, 0.8, 1, 0.6), (1, 0.6, 0, 0), (0, 0, 1, 0)]),
        "6": (0.75, six),
        "9": (0.75, flip(six)),
    ]

    /// Stroke segments (start, end) in meters for `text` with its lower-left at `origin` (XY), cap height `h`,
    /// width scale `ws`, letter gap `gap` (fraction of h). Returns segments and the total advance.
    static func segments(_ text: String, origin: V2, h: Float, ws: Float = 1, gap: Float = 0.28) -> (segs: [(V2, V2)], width: Float) {
        var x: Float = 0
        var out: [(V2, V2)] = []
        for ch in text {
            guard let g = glyphs[ch] else { x += h * 0.45; continue }
            let w = g.w * h * ws
            for s in g.s {
                out.append((V2(origin.x + x + s.0 * w, origin.y + s.1 * h), V2(origin.x + x + s.2 * w, origin.y + s.3 * h)))
            }
            x += w + gap * h
        }
        return (out, max(0, x - gap * h))
    }

    /// Width of `text` without building it.
    static func width(_ text: String, h: Float, ws: Float = 1, gap: Float = 0.28) -> Float {
        segments(text, origin: .zero, h: h, ws: ws, gap: gap).width
    }

    /// Bar between two points on the wall plane at depth z (center), thickness `t` along Z, stroke width `w`.
    static func bar(_ m: inout Model, _ a: V2, _ b: V2, w: Float, z: Float, t: Float, _ mat: MaterialKey) {
        let d = b - a
        let len = simd_length(d) + w
        let ang = atan2(d.y, d.x)
        let hw = len / 2, hh = w / 2
        m.add(Prim.extrude([V2(-hw, -hh), V2(hw, -hh), V2(hw, hh), V2(-hw, hh)], depth: t, bevel: min(w, t) * 0.3, bevelSegments: 1, material: mat),
              Xform(translation: V3((a.x + b.x) / 2, (a.y + b.y) / 2, z), rotation: simd_quatf(angle: ang, axis: V3(0, 0, 1))))
    }

    /// Raised lettering built from bars.
    @discardableResult
    static func text(_ m: inout Model, _ s: String, origin: V2, h: Float, ws: Float = 1, w: Float, z: Float, t: Float, _ mat: MaterialKey) -> Float {
        let r = segments(s, origin: origin, h: h, ws: ws)
        for (a, b) in r.segs { bar(&m, a, b, w: w, z: z, t: t, mat) }
        return r.width
    }

    /// Neon tube lettering (round rods) with dark electrode caps at stroke ends is left to the caller.
    @discardableResult
    static func tubes(_ m: inout Model, _ s: String, origin: V2, h: Float, ws: Float = 1, r: Float, z: Float, sides: Int = 8, _ mat: MaterialKey) -> Float {
        let rs = segments(s, origin: origin, h: h, ws: ws)
        for (a, b) in rs.segs { FA.rod(&m, V3(a.x, a.y, z), V3(b.x, b.y, z), r: r, mat, sides: sides) }
        return rs.width
    }

    /// Slotted round screw head with its axis along +Z.
    static func screw(_ m: inout Model, at p: V3, r: Float, _ mat: MaterialKey, angle: Float = 0) {
        m.add(Prim.cylinder(radius: r, height: r * 0.45, bevel: r * 0.18, segments: 10, bevelSegments: 1, material: mat), Xform(translation: p - V3(0, 0, r * 0.05), rotation: FA.q(90, FA.X)))
        m.add(Prim.extrude([V2(-r * 0.8, -r * 0.1), V2(r * 0.8, -r * 0.1), V2(r * 0.8, r * 0.1), V2(-r * 0.8, r * 0.1)], depth: r * 0.12, bevel: 0.0002, bevelSegments: 1, material: "metal.painted:1B1B1D"),
              Xform(translation: p + V3(0, 0, r * 0.42), rotation: FA.q(angle, FA.Z)))
    }

    /// Flat irregular patch (stain, bloom, chip) as a squashed superellipsoid; `size` is its extent, z thin.
    static func blob(_ m: inout Model, at p: V3, size: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        m.add(Prim.superellipsoid(size, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: p, rotation: rot))
    }
}
