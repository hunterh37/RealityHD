import simd
import Foundation

/// Helpers for the signage facade props (batch n6a). Same frame as `FA`: wall plane at z = 0, piece
/// projecting toward +Z. Finish every prop with `FC.place`.
enum FG {
    /// Low-poly flat patch (stain, spall, streak, decal): a plain cuboid, no bevel.
    static func flat(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        m.add(cuboid(size, material: mat), Xform(translation: c, rotation: rot))
    }
    /// Block lettering from `strokeText`, centered on `at` (x, y), standing off the wall from z = `at.z`.
    static func text(_ m: inout Model, _ s: String, h: Float, stroke: Float, depth: Float, at: V3, _ mat: MaterialKey,
                     rot: simd_quatf = .identity, squeeze: Float = 1) {
        let t = strokeText(s, height: h, stroke: stroke, depth: depth, material: mat)
        m.add(t, Xform(translation: at, rotation: rot, scale: V3(squeeze, 1, 1)))
    }
    /// Width of block lettering with a squeeze factor.
    static func width(_ s: String, h: Float, squeeze: Float = 1) -> Float { strokeTextWidth(s, height: h) * squeeze }

    /// Slotted round-head screw on a +Z facing surface at `p` (z = surface).
    static func screw(_ m: inout Model, at p: V3, r: Float = 0.004, mat: MaterialKey = "metal.brass", slot: MaterialKey = "metal.steel:1A1A1A", ang: Float = 0.6) {
        FA.cylZ(&m, r: r, h: r * 0.55, at: p, mat, bevel: r * 0.25, segments: 12)
        FA.box(&m, V3(r * 1.7, r * 0.3, r * 0.2), V3(p.x, p.y, p.z + r * 0.52), slot, r: 0.0002, rot: FA.q(ang * 57.3, FA.Z))
    }
    /// Acorn / dome cap nut.
    static func dome(_ m: inout Model, at p: V3, r: Float, mat: MaterialKey) {
        m.add(Prim.superellipsoid(V3(r * 2, r * 2, r * 1.3), exponent: 2, subdivisions: 4, material: mat), Xform(translation: p))
    }
    /// Spiral scroll in the plane spanned by `u`, `v` around `c`, radius `r0` to `r1` over `turns`.
    static func spiral(c: V3, u: V3, v: V3, r0: Float, r1: Float, a0: Float, turns: Float, steps: Int = 28) -> [V3] {
        (0...steps).map { k in
            let t = Float(k) / Float(steps), a = a0 + turns * 2 * .pi * t, r = r0 + (r1 - r0) * t
            return c + u * (cos(a) * r) + v * (sin(a) * r)
        }
    }
    /// Smooth path through control points (Catmull-Rom).
    static func smooth(_ pts: [V3], per: Int = 6) -> [V3] {
        guard pts.count > 2 else { return pts }
        var out: [V3] = []
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(pts.count - 1, i + 2)]
            for k in 0..<per {
                let t = Float(k) / Float(per), t2 = t * t, t3 = t2 * t
                let a: V3 = 2 * p1
                let b: V3 = (p2 - p0) * t
                let c: V3 = (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                let d: V3 = (3 * p1 - p0 - 3 * p2 + p3) * t3
                out.append((a + b + c + d) * 0.5)
            }
        }
        out.append(pts[pts.count - 1])
        return out
    }
    /// Bulb row (lamp bases are dull brass, glass is emissive) along a line, bulbs facing +Z.
    static func bulbs(_ m: inout Model, from a: V3, to b: V3, count: Int, r: Float = 0.014, lit: MaterialKey = "emissive.warm", dead: Set<Int> = []) {
        for i in 0..<count {
            let t = count == 1 ? 0.5 : Float(i) / Float(count - 1)
            let p = a + (b - a) * t
            FA.cylZ(&m, r: r * 0.7, h: r * 0.8, at: p - V3(0, 0, r * 0.2), "metal.brass-aged", bevel: 0.0005, segments: 8)
            m.add(Prim.superellipsoid(V3(r * 2, r * 2, r * 2.2), exponent: 2, subdivisions: 3, material: dead.contains(i) ? "glass.frosted" : lit),
                  Xform(translation: p + V3(0, 0, r * 0.9)))
        }
    }
}

/// Block capitals (copy of the City stroke font table), 4 x 6 grid.
let fgGlyphs: [Character: [[(Float, Float)]]] = [
    "A": [[(0, 0), (0, 4.5), (1, 6), (3, 6), (4, 4.5), (4, 0)], [(0, 3), (4, 3)]],
    "B": [[(0, 0), (0, 6), (3, 6), (4, 5), (4, 4), (3, 3.1), (0, 3.1)], [(3, 3.1), (4, 2.1), (4, 1), (3, 0), (0, 0)]],
    "C": [[(4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0), (3, 0), (4, 1)]],
    "D": [[(0, 0), (0, 6), (2.6, 6), (4, 4.6), (4, 1.4), (2.6, 0), (0, 0)]],
    "E": [[(4, 6), (0, 6), (0, 0), (4, 0)], [(0, 3.1), (3, 3.1)]],
    "F": [[(4, 6), (0, 6), (0, 0)], [(0, 3.1), (3, 3.1)]],
    "G": [[(4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0), (3, 0), (4, 1), (4, 2.8), (2.2, 2.8)]],
    "H": [[(0, 0), (0, 6)], [(4, 0), (4, 6)], [(0, 3.1), (4, 3.1)]],
    "I": [[(2, 0), (2, 6)], [(1, 6), (3, 6)], [(1, 0), (3, 0)]],
    "J": [[(4, 6), (4, 1), (3, 0), (1, 0), (0, 1)]],
    "K": [[(0, 0), (0, 6)], [(4, 6), (0, 2.6)], [(1.3, 3.7), (4, 0)]],
    "L": [[(0, 6), (0, 0), (4, 0)]],
    "M": [[(0, 0), (0, 6), (2, 3), (4, 6), (4, 0)]],
    "N": [[(0, 0), (0, 6), (4, 0), (4, 6)]],
    "O": [[(1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 1), (3, 0), (1, 0)]],
    "P": [[(0, 0), (0, 6), (3, 6), (4, 5), (4, 3.8), (3, 2.8), (0, 2.8)]],
    "Q": [[(1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 1), (3, 0), (1, 0)], [(2.5, 1.5), (4, 0)]],
    "R": [[(0, 0), (0, 6), (3, 6), (4, 5), (4, 3.8), (3, 2.8), (0, 2.8)], [(2.2, 2.8), (4, 0)]],
    "S": [[(4, 5), (3, 6), (1, 6), (0, 5), (0, 4), (1, 3.1), (3, 3.1), (4, 2.1), (4, 1), (3, 0), (1, 0), (0, 1)]],
    "T": [[(0, 6), (4, 6)], [(2, 6), (2, 0)]],
    "U": [[(0, 6), (0, 1), (1, 0), (3, 0), (4, 1), (4, 6)]],
    "V": [[(0, 6), (2, 0), (4, 6)]],
    "W": [[(0, 6), (0.8, 0), (2, 3.5), (3.2, 0), (4, 6)]],
    "X": [[(0, 0), (4, 6)], [(0, 6), (4, 0)]],
    "Y": [[(0, 6), (2, 3), (4, 6)], [(2, 3), (2, 0)]],
    "Z": [[(0, 6), (4, 6), (0, 0), (4, 0)]],
    "0": [[(1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 1), (3, 0), (1, 0)]],
    "1": [[(1, 5), (2, 6), (2, 0)], [(1, 0), (3, 0)]],
    "2": [[(0, 5), (1, 6), (3, 6), (4, 5), (4, 4), (0, 0), (4, 0)]],
    "3": [[(0, 5), (1, 6), (3, 6), (4, 5), (4, 4), (3, 3.1), (1.5, 3.1)], [(3, 3.1), (4, 2.1), (4, 1), (3, 0), (1, 0), (0, 1)]],
    "4": [[(3, 0), (3, 6), (0, 2), (4, 2)]],
    "5": [[(4, 6), (0, 6), (0, 3.4), (3, 3.4), (4, 2.4), (4, 1), (3, 0), (0, 0)]],
    "6": [[(4, 5.2), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0), (3, 0), (4, 1), (4, 2.4), (3, 3.4), (0, 3.4)]],
    "7": [[(0, 6), (4, 6), (1.5, 0)]],
    "8": [[(1, 3.1), (0, 4), (0, 5), (1, 6), (3, 6), (4, 5), (4, 4), (3, 3.1), (1, 3.1), (0, 2.1), (0, 1), (1, 0), (3, 0), (4, 1), (4, 2.1), (3, 3.1)]],
    "9": [[(4, 2.6), (1, 2.6), (0, 3.6), (0, 5), (1, 6), (3, 6), (4, 5), (4, 1), (3, 0), (0, 0)]],
    ".": [[(1.6, 0), (1.6, 0.6)]],
    "-": [[(0.8, 3), (3.2, 3)]],
]

extension FG {
    /// Light-weight marquee bulbs: socket cuboid plus a faceted glass bead, facing +Z. `dead` indices are dark.
    static func lamps(_ m: inout Model, from a: V3, to b: V3, count: Int, r: Float = 0.016, lit: MaterialKey = "emissive.warm", dead: Set<Int> = []) {
        var glass = Surface(material: lit), off = Surface(material: "glass.frosted"), sock = Surface(material: "metal.brass-aged")
        let bead = Prim.superellipsoid(V3(r * 2, r * 2, r * 2.2), exponent: 2, subdivisions: 1, material: lit)
        let cap = cuboid(V3(r * 1.2, r * 1.2, r * 0.7), material: "metal.brass-aged")
        for i in 0..<count {
            let t = count == 1 ? 0.5 : Float(i) / Float(count - 1)
            let p = a + (b - a) * t
            sock.append(cap, Xform(translation: p))
            if dead.contains(i) { off.append(bead, Xform(translation: p + V3(0, 0, r * 1.0))) } else { glass.append(bead, Xform(translation: p + V3(0, 0, r * 1.0))) }
        }
        m.add(sock); m.add(glass)
        if !dead.isEmpty { m.add(off) }
    }
    /// Lettering built from beveled strokes with round joints, centered on `at`, depth along +Z from at.z.
    /// `bevel` rounds every stroke edge (m). Pass `bulge` > 0 to swell the stroke joints for cast lettering.
    static func soft(_ m: inout Model, _ s: String, h: Float, stroke w: Float, depth: Float, at: V3, _ mat: MaterialKey,
                     bevel: Float = 0.002, squeeze: Float = 1, rot: simd_quatf = .identity) {
        let u = h / 6
        let total = strokeTextWidth(s, height: h)
        var surf = Surface(material: mat)
        let bv = min(bevel, min(w, depth) * 0.45)
        for (i, ch) in s.uppercased().enumerated() {
            guard let lines = fgGlyphs[ch] else { continue }
            let ox = -total / 2 + Float(i) * 5.4 * u
            for line in lines {
                for k in 0..<(line.count - 1) {
                    let a = V2(ox + line[k].0 * u, line[k].1 * u - h / 2), b = V2(ox + line[k + 1].0 * u, line[k + 1].1 * u - h / 2)
                    let d = b - a, L = simd_length(d)
                    guard L > 1e-5 else { continue }
                    let box = Prim.roundedBox(V3(L + w * 0.55, w, depth), radius: bv, bevelSegments: 1, material: mat)
                    surf.append(box, Xform(translation: V3((a.x + b.x) / 2, (a.y + b.y) / 2, depth / 2), rotation: simd_quatf(angle: atan2(d.y, d.x), axis: V3(0, 0, 1))))
                }
            }
        }
        m.add(surf, Xform(translation: at, rotation: rot, scale: V3(squeeze, 1, 1)))
    }
}
