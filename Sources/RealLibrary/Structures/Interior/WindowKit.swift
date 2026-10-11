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
}
