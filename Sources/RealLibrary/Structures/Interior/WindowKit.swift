import simd
import Foundation

/// Shared window construction for the floor planning pack: rounded boxes, sill profiles and divided-lite
/// grilles. Windows put the origin at the sill center, thickness on Z, interior toward +Z.
enum WindowKit {
    typealias Part = (Surface, Xform)

    static func box(_ size: V3, _ c: V3, _ m: MaterialKey, r: Float = 0.002, seg: Int = 2) -> Part {
        (Prim.roundedBox(size, radius: min(r, min(size.x, size.y, size.z) * 0.45), bevelSegments: seg, material: m), Xform(translation: c))
    }

    /// Sloped exterior sill with drip nose, `width` along X. Profile x is the outward projection (toward -Z).
    /// `inner` is how far the block runs back toward +Z, `out` the nose projection, `rise` the height at the frame.
    static func sill(width: Float, inner: Float, out: Float, rise: Float, nose: Float, material: MaterialKey) -> Part {
        let prof = Shape2D.rounded([V2(-inner, 0), V2(out, 0), V2(out, nose), V2(0, rise), V2(-inner, rise)], radius: 0.004, segments: 2)
        return (Prim.extrude(prof, depth: width, bevel: 0.0015, bevelSegments: 1, material: material),
                Xform(translation: V3(0, 0, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
    }

    /// Divided-lite grille: vertical and horizontal bars over an opening, on both faces plus a spacer bar between panes.
    static func grille(cols: Int, rows: Int, w: Float, h: Float, cy: Float, bar: Float, zFaces: [Float], depth: Float,
                       zMid: Float?, midDepth: Float, mat: MaterialKey, midMat: MaterialKey, cx: Float = 0) -> [Part] {
        var out: [Part] = []
        var xs: [Float] = [], ys: [Float] = []
        for i in 1..<max(cols, 1) { xs.append(cx - w / 2 + w * Float(i) / Float(cols)) }
        for j in 1..<max(rows, 1) { ys.append(cy - h / 2 + h * Float(j) / Float(rows)) }
        for z in zFaces {
            for x in xs { out.append(box(V3(bar, h, depth), V3(x, cy, z), mat, r: 0.0015, seg: 1)) }
            for y in ys { out.append(box(V3(w, bar, depth), V3(cx, y, z), mat, r: 0.0015, seg: 1)) }
        }
        if let zm = zMid {
            for x in xs { out.append((cuboid(V3(bar * 0.7, h, midDepth), material: midMat), Xform(translation: V3(x, cy, zm)))) }
            for y in ys { out.append((cuboid(V3(w, bar * 0.7, midDepth), material: midMat), Xform(translation: V3(cx, y, zm)))) }
        }
        return out
    }

    /// Opening that `surround` leaves for a sash or glazing: half width, bottom and top y.
    struct Opening { var ox: Float; var y0: Float; var y1: Float; var jz: Float }

    /// Frame, sloped sill, stool, apron, casing, brickmould and head cap for a wall window of `W` x `H`.
    /// `frame` makes jambs and head, `trim` the casing and stool, `sillMat` the sill, brickmould and cap.
    static func surround(W: Float, H: Float, sillTop: Float, jw: Float, jz: Float, casing: Float, depth: Float, out: Float,
                         frame: MaterialKey, trim: MaterialKey, sillMat: MaterialKey, seg: Int) -> (parts: [Part], opening: Opening) {
        var p: [Part] = []
        let frameW = W - 2 * (casing + 0.012) - 0.0       // jamb outer width
        let headTop = H - 0.04
        let ox = frameW / 2 - jw
        let cz = jz + 0.01
        p.append(sill(width: W - 0.04, inner: jz, out: out, rise: sillTop, nose: sillTop * 0.45, material: sillMat))
        p.append(box(V3(W, 0.025, depth - jz + 0.0), V3(0, sillTop + 0.0125, (jz + depth) / 2 - 0.0 + 0.0), trim, r: 0.005, seg: seg))
        p.append(box(V3(frameW + 0.04, sillTop, 0.016), V3(0, sillTop / 2, jz + 0.008), trim, r: 0.002, seg: seg))
        for sx: Float in [-1, 1] {
            p.append(box(V3(jw, headTop - sillTop, 2 * jz), V3(sx * (frameW / 2 - jw / 2), (headTop + sillTop) / 2, 0), frame, r: 0.002, seg: seg))
            let c0 = sillTop + 0.025
            p.append(box(V3(casing, headTop - 0.01 - c0, 0.016), V3(sx * (frameW / 2 + casing / 2 - 0.012), (headTop - 0.01 + c0) / 2, cz - 0.002), trim, r: 0.002, seg: seg))
            p.append(box(V3(0.035, headTop + 0.015 - sillTop, 0.014), V3(sx * (frameW / 2 + 0.0175 - 0.004), (headTop + 0.015 + sillTop) / 2, -jz - 0.007), sillMat, r: 0.002, seg: seg))
        }
        p.append(box(V3(frameW - 2 * jw + 0.002, jw, 2 * jz), V3(0, headTop - jw / 2, 0), frame, r: 0.002, seg: seg))
        p.append(box(V3(frameW + 2 * casing - 0.024 + 0.04, 0.06, 0.016), V3(0, headTop - 0.01, cz - 0.002), trim, r: 0.003, seg: seg))
        p.append(box(V3(W - 0.0, 0.02, 0.028), V3(0, H - 0.01, jz + 0.014), trim, r: 0.004, seg: seg))
        p.append(box(V3(frameW + 0.07, 0.022, 0.014), V3(0, headTop + 0.008, -jz - 0.007), sillMat, r: 0.002, seg: seg))
        p.append(box(V3(frameW + 0.09, 0.01, 0.026), V3(0, headTop + 0.025, -jz - 0.012), sillMat, r: 0.003, seg: seg))
        return (p, Opening(ox: ox, y0: sillTop, y1: headTop - jw, jz: jz))
    }
}
