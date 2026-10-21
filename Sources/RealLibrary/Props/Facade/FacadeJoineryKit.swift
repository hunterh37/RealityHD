import simd
import Foundation

/// Joinery helpers for the library-A facade props (doors, windows, shutters, columns). Same frame as
/// `FA`: wall plane at z = 0, piece projecting toward +Z.
enum FJ {
    /// Closed CCW rectangle loop in the XY plane at depth z, corners filleted to `r`.
    static func loop(cx: Float, cy: Float, w: Float, h: Float, z: Float, r: Float = 0.004) -> [V3] {
        Shape2D.roundedRect(w, h, radius: r, segments: 2).map { V3($0.x + cx, $0.y + cy, z) }
    }
    /// Half-round bead section: flat base on z = 0, dome toward +z. Symmetric, so path orientation is irrelevant.
    static func beadProfile(_ r: Float, segments: Int = 6) -> [V2] {
        var p: [V2] = []
        for k in 0...segments { let a = Float(k) / Float(segments) * .pi; p.append(V2(r * sin(a), r * cos(a) * 0.999)) }
        return p
    }
    /// Ovolo (quarter-round) with a fillet: the sticking moulding of a panelled door.
    static func ovoloProfile(width: Float, height: Float) -> [V2] {
        var p: [V2] = [V2(0, -width / 2)]
        for k in 0...5 {
            let a = Float(k) / 5 * (.pi / 2)
            p.append(V2(height * 0.35 + (height * 0.65) * sin(a), -width / 2 + width * 0.8 * (1 - cos(a))))
        }
        p.append(V2(height * 0.35, width / 2))
        p.append(V2(0, width / 2))
        return p
    }
    /// A moulding run mitred around a rectangle.
    static func mouldedFrame(_ m: inout Model, cx: Float, cy: Float, w: Float, h: Float, z: Float, profile: [V2],
                             _ mat: MaterialKey, r: Float = 0.004, backFacing: Bool = false) {
        let prof = backFacing ? profile.map { V2(-$0.x, $0.y) } : profile
        m.add(Prim.sweep(prof, along: loop(cx: cx, cy: cy, w: w, h: h, z: z, r: r), up: V3(0, 0, 1), closedPath: true, caps: false,
                         grainAlongPath: true, material: mat))
    }
    /// Raised-and-fielded panel: back panel plus a bevelled field skinned with a loft, facing +Z, back on z0.
    static func raisedPanel(_ m: inout Model, cx: Float, cy: Float, w: Float, h: Float, z0: Float, rise: Float = 0.012,
                            bevelRun: Float = 0.026, _ mat: MaterialKey) {
        let levels: [(Float, Float)] = [(0, 0), (bevelRun * 0.55, rise * 0.45), (bevelRun, rise * 0.9), (bevelRun + 0.002, rise)]
        let rings = levels.map { inset, dz in
            Prim.ring(Shape2D.roundedRect(w - 2 * inset, h - 2 * inset, radius: max(0.002, 0.004 - inset * 0.05), segments: 2), y: dz)
        }
        m.add(Prim.loft(rings, capEnd: true, material: mat), Xform(translation: V3(cx, cy, z0), rotation: FA.q(90, FA.X)))
    }
    /// Tapered strap hinge leaf lying on a face (x along the strap, y up): flat bar with a pointed tail, nail-headed.
    static func strapHinge(_ m: inout Model, from x0: Float, to x1: Float, y: Float, z: Float, width: Float, thick: Float,
                          _ mat: MaterialKey, nails: Int = 4, rng: inout SeededRNG) {
        let dir: Float = x1 >= x0 ? 1 : -1, len = abs(x1 - x0)
        let w = width / 2
        let outline: [V2] = [V2(0, -w * 1.15), V2(len * 0.78, -w * 0.8), V2(len, 0), V2(len * 0.78, w * 0.8), V2(0, w * 1.15)]
        m.add(Prim.extrude(Shape2D.rounded(outline, radius: 0.003, segments: 2), depth: thick, bevel: 0.0012, bevelSegments: 1, material: mat),
              Xform(translation: V3(x0, y, z + thick / 2), rotation: dir > 0 ? .identity : FA.q(180, FA.Y)))
        // Eye wrapped around the pintle at the hinge end.
        FA.cylZ(&m, r: w * 1.15, h: thick, at: V3(x0, y, z), mat, bevel: 0.001, segments: 14)
        for i in 0..<nails {
            let t = (Float(i) + 0.6) / (Float(nails) + 0.2)
            let nx = x0 + dir * len * t * 0.8
            let ny = y + rng.float(-0.0015...0.0015)
            rivet(&m, at: V3(nx, ny, z + thick), normal: FA.Z, radius: 0.0055, segments: 8, material: mat)
        }
    }
}

extension FJ {
    /// Scattered paint chips: thin bare-wood patches on a flat face (z = face plane), clustered at `spots`.
    static func chips(_ m: inout Model, spots: [V3], face z: Float, _ mat: MaterialKey, rng: inout SeededRNG, each: Int = 3) {
        for s in spots {
            for _ in 0..<each {
                let w = rng.float(0.006...0.026), h = rng.float(0.004...0.018)
                let o = V3(rng.float(-0.02...0.02), rng.float(-0.025...0.025), 0)
                let pts = Shape2D.rounded([V2(-w / 2, -h / 2), V2(w / 2, -h * 0.35), V2(w * 0.4, h / 2), V2(-w / 2, h * 0.3)], radius: 0.0015, segments: 1)
                m.add(Prim.extrude(pts, depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: mat),
                      Xform(translation: V3(s.x + o.x, s.y + o.y, z + 0.0002), rotation: FA.q(rng.float(-30...30), FA.Z)))
            }
        }
    }
}

extension FJ {
    /// Glazed rectangular sash: stiles and rails, one glass quad, glazing bars and a bead stop around the lights.
    /// Back face on z0, front at z0 + thick, facing +Z.
    static func sash(_ m: inout Model, cx: Float, cy: Float, w: Float, h: Float, z0: Float, thick: Float = 0.04, stile: Float = 0.038,
                     cols: Int, rows: Int, bar: Float = 0.016, _ frame: MaterialKey, glass: MaterialKey) {
        let iw = w - 2 * stile, ih = h - 2 * stile
        for e: Float in [-1, 1] {
            FA.box(&m, V3(stile, h, thick), V3(cx + e * (w / 2 - stile / 2), cy, z0 + thick / 2), frame, r: 0.002)
            FA.box(&m, V3(iw + 0.004, stile, thick), V3(cx, cy + e * (h / 2 - stile / 2), z0 + thick / 2), frame, r: 0.002)
        }
        slab(&m, V3(iw, ih, 0.004), V3(cx, cy, z0 + thick * 0.45), glass)
        for c in 1..<max(cols, 1) + (cols > 1 ? 0 : 0) where cols > 1 {
            let x = cx - iw / 2 + iw * Float(c) / Float(cols)
            slab(&m, V3(bar, ih + 0.004, thick * 0.78), V3(x, cy, z0 + thick * 0.45), frame)
        }
        for r in 1..<max(rows, 1) where rows > 1 {
            let y = cy - ih / 2 + ih * Float(r) / Float(rows)
            slab(&m, V3(iw + 0.004, bar, thick * 0.78), V3(cx, y, z0 + thick * 0.45), frame)
        }
        mouldedFrame(&m, cx: cx, cy: cy, w: iw + 0.006, h: ih + 0.006, z: z0 + thick - 0.0005, profile: beadProfile(0.006, segments: 4), frame, r: 0.003)
    }
    /// Thin box arc: bars of a fanlight laid on a circle about (cx, cy).
    static func radial(_ m: inout Model, cx: Float, cy: Float, z: Float, angles: [Float], r0: Float, r1: Float, bar: Float, depth: Float,
                       _ mat: MaterialKey) {
        for a in angles {
            let rad = a * .pi / 180, mid = (r0 + r1) / 2
            slab(&m, V3(r1 - r0, bar, depth), V3(cx + cos(rad) * mid, cy + sin(rad) * mid, z), mat, rot: FA.q(a, FA.Z))
        }
    }
}

extension FJ {
    /// Plain six-face box (24 vertices, 12 triangles) for small repeated members whose bevel is invisible
    /// (dentils, glazing bars, glass). `FA.box` costs about 100 triangles per box.
    static func slab(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        let h = size / 2
        var s = Surface(material: mat)
        let faces: [(Int, Float, Int, Int)] = [(0, 1, 2, 1), (0, -1, 2, 1), (1, 1, 0, 2), (1, -1, 0, 2), (2, 1, 0, 1), (2, -1, 0, 1)]
        for (ax, sign, ua, va) in faces {
            let base = UInt32(s.positions.count)
            for v in [-h[va], h[va]] { for u in [-h[ua], h[ua]] {
                var p = V3.zero
                p[ax] = sign * h[ax]; p[ua] = u; p[va] = v
                var n = V3.zero; n[ax] = sign
                var uv = V2(u, v)
                if sign < 0 { uv.x = -uv.x }
                s.add(p, n, uv)
            }}
            var cu = V3.zero, cv = V3.zero; cu[ua] = 1; cv[va] = 1
            var f = V3.zero; f[ax] = sign
            let outward = simd_dot(simd_cross(cu, cv), f) > 0
            if outward { s.quad(base, base + 1, base + 3, base + 2) } else { s.quad(base, base + 2, base + 3, base + 1) }
        }
        s.recomputeNormals()
        s.computeTangents()
        m.add(s, Xform(translation: c, rotation: rot))
    }
}
