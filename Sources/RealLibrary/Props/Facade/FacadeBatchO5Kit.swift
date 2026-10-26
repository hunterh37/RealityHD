import simd
import Foundation

/// Helpers for the lib-o5 facade props (door surround, fanlight, corbel, mullion window, Crittall panel,
/// shutter box, awning, sun screens, pergola). Same frame as `FA`: wall plane at z = 0, piece projecting toward +Z.
enum FO {
    /// Prism whose section is given in the (x, z) plane, extruded between `y0` and `y1` (a jamb, post or fin).
    static func colY(_ m: inout Model, _ section: [V2], y0: Float, y1: Float, _ mat: MaterialKey, bevel: Float = 0.0015) {
        var local = section.map { V2($0.x, -$0.y) }
        if FM.area(local) < 0 { local.reverse() }
        m.add(Prim.extrude(local, depth: y1 - y0, bevel: min(bevel, (y1 - y0) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: V3(0, (y0 + y1) / 2, 0), rotation: FA.q(-90, FA.X)))
    }

    /// Prism whose section is given in the (z, y) plane, extruded along X from `x0` to `x1` (a beam, rail or sill).
    static func colX(_ m: inout Model, _ section: [V2], x0: Float, x1: Float, _ mat: MaterialKey, bevel: Float = 0.0015) {
        var pts = section
        if FM.area(pts) < 0 { pts.reverse() }
        m.add(Prim.extrude(pts, depth: x1 - x0, bevel: min(bevel, (x1 - x0) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: V3((x0 + x1) / 2, 0, 0), rotation: FA.q(-90, FA.Y)))
    }

    /// Quarter-circle hollow (concave) arc about `c` from angle `a0` to `a1` (degrees), `steps` segments plus both ends.
    static func arc(c: V2, r: Float, from a0: Float, to a1: Float, steps: Int) -> [V2] {
        (0...steps).map { i in
            let a = (a0 + (a1 - a0) * Float(i) / Float(steps)) * .pi / 180
            return V2(c.x + r * cos(a), c.y + r * sin(a))
        }
    }

    /// Octagonal peg or dowel head standing proud of a face (axis along `n`).
    static func peg(_ m: inout Model, at p: V3, normal n: V3, r: Float, h: Float, _ mat: MaterialKey, sides: Int = 8) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(0.0018, r * 0.25), segments: sides, bevelSegments: 1, material: mat),
              Xform(translation: p, rotation: facing(n)))
    }

    /// Thin weathering patch (stain, chip, run) lying on a face with normal +Z at depth `z`.
    static func patch(_ m: inout Model, _ size: V2, _ c: V2, z: Float, _ mat: MaterialKey, rot: Float = 0) {
        FJ.slab(&m, V3(size.x, size.y, 0.0012), V3(c.x, c.y, z + 0.0004), mat, rot: FA.q(rot, FA.Z))
    }

    /// Closed half-ring polygon between two ellipses (outer a0 x b0, inner a1 x b1) about (0, cy), upper half only.
    static func halfRing(outer a0: Float, _ b0: Float, inner a1: Float, _ b1: Float, cy: Float, steps: Int = 28) -> [V2] {
        var pts: [V2] = []
        for i in 0...steps { let t = Float(i) / Float(steps) * .pi; pts.append(V2(a0 * cos(t), cy + b0 * sin(t))) }
        for i in 0...steps { let t = (1 - Float(i) / Float(steps)) * .pi; pts.append(V2(a1 * cos(t), cy + b1 * sin(t))) }
        return pts
    }

    /// Solid half-ellipse polygon about (0, cy).
    static func halfDisc(_ a: Float, _ b: Float, cy: Float, steps: Int = 28) -> [V2] {
        var pts: [V2] = []
        for i in 0...steps { let t = Float(i) / Float(steps) * .pi; pts.append(V2(a * cos(t), cy + b * sin(t))) }
        return pts
    }

    /// Flat bar between two points in the XY plane (width w in-plane, depth d along z, centred on z).
    static func bar(_ m: inout Model, from a: V2, to b: V2, w: Float, d: Float, z: Float, _ mat: MaterialKey) {
        let dv = b - a, len = simd_length(dv)
        let ang = atan2(dv.y, dv.x) * 180 / .pi
        FJ.slab(&m, V3(len, w, d), V3((a.x + b.x) / 2, (a.y + b.y) / 2, z), mat, rot: FA.q(ang, FA.Z))
    }

    /// Thin weathering patch lying on a face with normal +/-X at x (size is (z, y), centre is (z, y)).
    static func patchSide(_ m: inout Model, _ size: V2, _ c: V2, x: Float, _ mat: MaterialKey) {
        let sgn: Float = x >= 0 ? 1 : -1
        FJ.slab(&m, V3(0.0012, size.y, size.x), V3(x + sgn * 0.0004, c.y, c.x), mat)
    }
}
