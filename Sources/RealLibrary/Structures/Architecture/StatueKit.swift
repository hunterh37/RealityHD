import simd
import Foundation

/// Simplified cast-bronze figures for monuments and fountains: robed standing and seated forms built
/// from lofted drapery with fold displacement, torso, head and arms. Local frame faces +Z, height in meters.
enum StatueKit {
    enum Attribute { case none, tablet, sword, anchor, branch, flag, trident, shell }

    /// Drapery folds: vertical ridges with noise, strongest toward the hem.
    static func folds(_ s: Surface, seed: UInt64, depth: Float, y0: Float, y1: Float) -> Surface {
        let sd = UInt32(truncatingIfNeeded: seed &* 2654435761 &+ 13)
        var r = s
        r.displace { p, n in
            let t = saturate((y1 - p.y) / max(0.01, y1 - y0))
            let a = atan2(p.z, p.x)
            return depth * (0.35 + 0.65 * t) * (sin(a * 9 + Noise.perlin(V3(p.x * 2, p.y * 1.5, p.z * 2), seed: sd) * 3) * 0.7
                + 0.3 * Noise.perlin(V3(p.x * 6, p.y * 3, p.z * 6), seed: sd &+ 1)) * saturate(1 - abs(n.y))
        }
        return r
    }

    static func ellipse(_ rx: Float, _ rz: Float, _ n: Int = 18) -> [V2] {
        (0..<n).map { k in let a = Float(k) / Float(n) * 2 * .pi; return V2(rx * cos(a), rz * sin(a)) }
    }

    /// Head with a laurel band or helmet crest, neck, at `c` (center of head).
    static func head(_ f: inout Model, c: V3, s: Float, mat: MaterialKey, helmet: Bool) {
        f.add(Prim.tube([c - V3(0, 0.22 * s, 0.01 * s), c - V3(0, 0.08 * s, 0)], radii: [0.06 * s, 0.05 * s], sides: 8, seamTile: 0.2, material: mat))
        f.add(Prim.superellipsoid(V3(0.19, 0.25, 0.22) * s, exponent: 2.2, subdivisions: 3, material: mat), Xform(translation: c))
        // Nose and brow give a profile against the sky.
        f.add(Prim.superellipsoid(V3(0.035, 0.07, 0.05) * s, exponent: 2, subdivisions: 2, material: mat), Xform(translation: c + V3(0, -0.01 * s, 0.11 * s)))
        if helmet {
            f.add(Prim.superellipsoid(V3(0.22, 0.16, 0.25) * s, exponent: 2.4, subdivisions: 4, material: mat), Xform(translation: c + V3(0, 0.07 * s, -0.01 * s)))
            f.add(Prim.roundedBox(V3(0.03, 0.12, 0.24) * s, radius: 0.012 * s, bevelSegments: 1, material: mat), Xform(translation: c + V3(0, 0.17 * s, -0.02 * s)))
        } else {
            f.add(Prim.superellipsoid(V3(0.21, 0.14, 0.23) * s, exponent: 2, subdivisions: 4, material: mat), Xform(translation: c + V3(0, 0.06 * s, -0.02 * s)))
            f.add(Prim.torus(major: 0.105 * s, minor: 0.018 * s, segments: 14, sides: 5, material: mat), Xform(translation: c + V3(0, 0.05 * s, -0.01 * s)))
        }
    }

    static func attribute(_ f: inout Model, _ a: Attribute, hand: V3, s: Float, mat: MaterialKey, side: Float) {
        switch a {
        case .none: break
        case .tablet:
            f.add(Prim.roundedBox(V3(0.34, 0.46, 0.05) * s, radius: 0.01 * s, bevelSegments: 1, material: mat),
                  Xform(translation: hand + V3(0, 0.12 * s, 0.02 * s), rotation: simd_quatf(degrees: -20 * side, axis: V3(0, 0, 1)) * simd_quatf(degrees: -25, axis: V3(1, 0, 0))))
        case .sword:
            f.add(Prim.tube([hand + V3(0, 0.12 * s, 0), hand - V3(0, 0.95 * s, -0.08 * s)], radii: [0.022 * s, 0.012 * s], sides: 6, seamTile: 0.2, material: mat))
            f.add(Prim.roundedBox(V3(0.2, 0.03, 0.04) * s, radius: 0.01 * s, bevelSegments: 1, material: mat), Xform(translation: hand))
        case .anchor:
            let foot = hand - V3(0, 1.05 * s, -0.1 * s)
            f.add(Prim.tube([hand + V3(0, 0.1 * s, 0), foot], radii: [0.03 * s, 0.03 * s], sides: 6, seamTile: 0.2, material: mat))
            f.add(Prim.torus(major: 0.24 * s, minor: 0.03 * s, segments: 12, sides: 5, arc: .pi, material: mat),
                  Xform(translation: foot + V3(0, 0.24 * s, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 180, axis: V3(0, 1, 0))))
            f.add(Prim.torus(major: 0.08 * s, minor: 0.022 * s, segments: 10, sides: 5, material: mat),
                  Xform(translation: hand + V3(0, 0.18 * s, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        case .branch:
            f.add(Prim.tube([hand, hand + V3(0.1 * side, 0.3 * s, 0.15 * s), hand + V3(0.2 * side, 0.5 * s, 0.1 * s)], radii: [0.018 * s, 0.012 * s, 0.006 * s], sides: 5, seamTile: 0.2, material: mat))
            for k in 0..<5 {
                let t = Float(k) / 5
                f.add(Prim.superellipsoid(V3(0.1, 0.03, 0.05) * s, exponent: 2, subdivisions: 2, material: mat),
                      Xform(translation: hand + V3((0.06 + 0.14 * t) * side, (0.15 + 0.35 * t) * s, 0.12 * s), rotation: simd_quatf(degrees: Float(k) * 70, axis: V3(0, 1, 0))))
            }
        case .flag:
            let top = hand + V3(0, 1.6 * s, 0), bottom = hand - V3(0, 1.4 * s, 0)
            f.add(Prim.tube([bottom, top], radii: [0.03 * s, 0.025 * s], sides: 8, seamTile: 0.2, material: mat))
            f.add(Prim.superellipsoid(V3(0.08, 0.1, 0.08) * s, exponent: 2, subdivisions: 2, material: mat), Xform(translation: top))
            // Furled flag hanging from the staff in heavy folds.
            var flag = Prim.loft([Prim.ring(ellipse(0.16 * s, 0.11 * s, 12), y: 0, offset: .zero),
                                  Prim.ring(ellipse(0.3 * s, 0.13 * s, 12), y: -0.6 * s, offset: V3(0.1 * side * s, 0, 0)),
                                  Prim.ring(ellipse(0.12 * s, 0.08 * s, 12), y: -1.3 * s, offset: V3(0.06 * side * s, 0, 0))],
                                 capStart: true, capEnd: true, material: mat)
            flag = folds(flag, seed: 5, depth: 0.03 * s, y0: -1.3 * s, y1: 0)
            f.add(flag, Xform(translation: top - V3(-0.12 * side * s, 0.12 * s, 0)))
        case .trident:
            let top = hand + V3(0, 1.2 * s, 0)
            f.add(Prim.tube([hand - V3(0, 0.9 * s, 0), top], radii: [0.022 * s, 0.02 * s], sides: 6, seamTile: 0.2, material: mat))
            for dx: Float in [-0.09, 0, 0.09] {
                f.add(Prim.tube([top + V3(dx * 0.4 * s, 0, 0), top + V3(dx * s, 0.08 * s, 0), top + V3(dx * s, 0.3 * s, 0)], radii: [0.015 * s, 0.013 * s, 0.004 * s], sides: 5, seamTile: 0.2, material: mat))
            }
        case .shell:
            f.add(Prim.superellipsoid(V3(0.26, 0.12, 0.2) * s, exponent: 2, subdivisions: 3, material: mat, bulge: { d in 1 + 0.08 * sin(atan2(d.x, d.z) * 9) }),
                  Xform(translation: hand + V3(0, 0.05 * s, 0.04 * s)))
        }
    }

    /// Arm as a tapered tube: shoulder, elbow, hand, with a sleeve bulge and a fist.
    static func arm(_ f: inout Model, _ pts: [V3], s: Float, mat: MaterialKey) {
        f.add(Prim.tube(catmull(pts, per: 3), radii: (0..<((pts.count - 1) * 3 + 1)).map { i in
            let t = Float(i) / Float((pts.count - 1) * 3); return (0.075 - 0.035 * t) * s }, sides: 7, seamTile: 0.3, material: mat))
        f.add(Prim.superellipsoid(V3(0.08, 0.1, 0.07) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: pts[pts.count - 1]))
    }

    /// Standing robed figure `h` tall, base at y = 0, facing +Z.
    static func standing(_ m: inout Model, at p: V3, yaw: Float, h: Float, mat: MaterialKey, right: Attribute, left: Attribute,
                         helmet: Bool = false, seed: UInt64, detail: Bool = true) {
        var f = Model(name: "figure")
        let s = h / 1.85
        let n = detail ? 14 : 8
        var robe = Prim.loft([Prim.ring(ellipse(0.34 * s, 0.3 * s, n), y: 0, offset: V3(0, 0, 0.03 * s)),
                              Prim.ring(ellipse(0.3 * s, 0.24 * s, n), y: 0.45 * s, offset: V3(0, 0, 0.02 * s)),
                              Prim.ring(ellipse(0.24 * s, 0.17 * s, n), y: 0.95 * s),
                              Prim.ring(ellipse(0.2 * s, 0.14 * s, n), y: 1.1 * s),
                              Prim.ring(ellipse(0.23 * s, 0.15 * s, n), y: 1.32 * s),
                              Prim.ring(ellipse(0.2 * s, 0.12 * s, n), y: 1.48 * s),
                              Prim.ring(ellipse(0.08 * s, 0.07 * s, n), y: 1.53 * s)],
                             capStart: true, capEnd: true, material: mat)
        if detail { robe = folds(robe, seed: seed, depth: 0.025 * s, y0: 0, y1: 1.1 * s) }
        f.add(robe)
        // Cloak over the shoulders.
        f.add(Prim.superellipsoid(V3(0.52, 0.16, 0.3) * s, exponent: 2.4, subdivisions: 4, material: mat), Xform(translation: V3(0, 1.44 * s, -0.01 * s)))
        // Toes under the hem.
        f.add(Prim.superellipsoid(V3(0.1, 0.07, 0.2) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: V3(0.1 * s, 0.035 * s, 0.27 * s)))
        head(&f, c: V3(0, 1.7 * s, 0.02 * s), s: s, mat: mat, helmet: helmet)
        for side: Float in [-1, 1] {
            let att = side > 0 ? right : left
            let sh = V3(side * 0.24 * s, 1.43 * s, 0)
            let pts: [V3]
            switch att {
            case .flag, .trident: pts = [sh, V3(side * 0.36 * s, 1.36 * s, 0.1 * s), V3(side * 0.36 * s, 1.55 * s, 0.22 * s)]
            case .sword, .anchor: pts = [sh, V3(side * 0.32 * s, 1.15 * s, 0.03 * s), V3(side * 0.3 * s, 0.92 * s, 0.12 * s)]
            default: pts = [sh, V3(side * 0.3 * s, 1.15 * s, 0.05 * s), V3(side * 0.16 * s, 1.0 * s, 0.22 * s)]
            }
            arm(&f, pts, s: s, mat: mat)
            if detail || att == .flag { attribute(&f, att, hand: pts[2], s: s, mat: mat, side: side) }
        }
        let x = Xform(translation: p, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0)))
        m.add(f, x)
    }

    /// Seated robed figure on a block seat; `h` is the standing-equivalent height, seat top at local y = 0.45 s.
    /// Base (feet) at y = 0. Includes the rock or block it sits on.
    static func seated(_ m: inout Model, at p: V3, yaw: Float, h: Float, mat: MaterialKey, attribute att: Attribute,
                       helmet: Bool = false, seed: UInt64, detail: Bool = true) {
        var f = Model(name: "figure")
        let s = h / 1.85
        let n = detail ? 12 : 8
        let seatY = 0.48 * s
        // Seat block behind the figure.
        f.add(Prim.roundedBox(V3(0.62, seatY, 0.5) * s, radius: 0.03 * s, bevelSegments: 1, material: mat), Xform(translation: V3(0, seatY / 2, -0.14 * s)))
        // Lap: thighs under drapery running forward.
        var lap = Prim.superellipsoid(V3(0.5, 0.2, 0.62) * s, exponent: 2.6, subdivisions: detail ? 4 : 2, material: mat)
        if detail { lap = folds(lap, seed: seed &+ 3, depth: 0.012 * s, y0: -0.1 * s, y1: 0.1 * s) }
        f.add(lap, Xform(translation: V3(0, seatY + 0.08 * s, 0.16 * s)))
        // Drapery falling from the knees to the hem over the shins.
        var shins = Prim.loft([Prim.ring(ellipse(0.25 * s, 0.1 * s, n), y: seatY + 0.1 * s, offset: V3(0, 0, 0.38 * s)),
                               Prim.ring(ellipse(0.27 * s, 0.13 * s, n), y: 0.25 * s, offset: V3(0, 0, 0.42 * s)),
                               Prim.ring(ellipse(0.32 * s, 0.2 * s, n), y: 0.0, offset: V3(0, 0, 0.42 * s))],
                              capStart: true, capEnd: true, material: mat)
        if detail { shins = folds(shins, seed: seed, depth: 0.02 * s, y0: 0, y1: seatY) }
        f.add(shins)
        f.add(Prim.superellipsoid(V3(0.1, 0.07, 0.18) * s, exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: V3(0.1 * s, 0.035 * s, 0.6 * s)))
        // Torso, slightly forward.
        var torso = Prim.loft([Prim.ring(ellipse(0.24 * s, 0.17 * s, n), y: seatY + 0.05 * s, offset: V3(0, 0, -0.04 * s)),
                               Prim.ring(ellipse(0.2 * s, 0.13 * s, n), y: seatY + 0.3 * s, offset: V3(0, 0, -0.02 * s)),
                               Prim.ring(ellipse(0.23 * s, 0.14 * s, n), y: seatY + 0.55 * s, offset: .zero),
                               Prim.ring(ellipse(0.2 * s, 0.12 * s, n), y: seatY + 0.68 * s),
                               Prim.ring(ellipse(0.08 * s, 0.07 * s, n), y: seatY + 0.72 * s)],
                              capStart: true, capEnd: true, material: mat)
        if detail { torso = folds(torso, seed: seed &+ 7, depth: 0.012 * s, y0: seatY, y1: seatY + 0.6 * s) }
        f.add(torso)
        f.add(Prim.superellipsoid(V3(0.5, 0.15, 0.28) * s, exponent: 2.4, subdivisions: 4, material: mat), Xform(translation: V3(0, seatY + 0.65 * s, 0)))
        head(&f, c: V3(0, seatY + 0.9 * s, 0.03 * s), s: s, mat: mat, helmet: helmet)
        for side: Float in [-1, 1] {
            let sh = V3(side * 0.23 * s, seatY + 0.63 * s, 0)
            let holds = side > 0 && att != .none
            let pts: [V3] = holds
                ? [sh, V3(side * 0.3 * s, seatY + 0.38 * s, 0.1 * s), V3(side * 0.24 * s, seatY + 0.3 * s, 0.34 * s)]
                : [sh, V3(side * 0.28 * s, seatY + 0.36 * s, 0.06 * s), V3(side * 0.12 * s, seatY + 0.22 * s, 0.3 * s)]
            arm(&f, pts, s: s, mat: mat)
            if holds && detail { attribute(&f, att, hand: pts[2], s: s, mat: mat, side: side) }
        }
        let x = Xform(translation: p, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0)))
        m.add(f, x)
    }
}
