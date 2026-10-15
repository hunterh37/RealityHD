import simd
import Foundation

/// Helpers for wall-cladding panels (shingles, shakes, clapboards, board and batten). Same frame as `FA`:
/// wall plane at z = 0, cladding toward +Z. Pieces are authored as flat outlines with the grain along
/// outline x, then tapered in thickness and placed.
enum CLAD {
    enum Butt { case square, round, octagon, split }

    /// Clips a closed outline to `lo <= y <= hi` (Sutherland-Hodgman, two passes).
    static func clipY(_ pts: [V2], lo: Float, hi: Float) -> [V2] {
        func pass(_ input: [V2], keep: (V2) -> Bool, cut: (V2, V2) -> V2) -> [V2] {
            guard !input.isEmpty else { return [] }
            var out: [V2] = []
            for i in input.indices {
                let a = input[i], b = input[(i + 1) % input.count]
                let ka = keep(a), kb = keep(b)
                if ka { out.append(a) }
                if ka != kb { out.append(cut(a, b)) }
            }
            return out
        }
        func at(_ y: Float) -> (V2, V2) -> V2 { { a, b in let t = (y - a.y) / (b.y - a.y); return a + (b - a) * t } }
        let p1 = pass(pts, keep: { $0.y >= lo }, cut: at(lo))
        return pass(p1, keep: { $0.y <= hi }, cut: at(hi))
    }

    /// Shingle outline: x along the grain (butt at x = 0, head at x = len), y across (centered on 0).
    static func shingleOutline(len: Float, width w: Float, butt: Butt, rng: inout SeededRNG) -> [V2] {
        let h = w / 2
        var p: [V2] = []
        switch butt {
        case .square:
            p = Shape2D.rounded([V2(0, -h), V2(len, -h), V2(len, h), V2(0, h)], radius: 0.003, segments: 2)
        case .split:
            let j = rng.float(-0.006...0.006)
            p = [V2(j + rng.float(0...0.003), -h), V2(len, -h + rng.float(0...0.004)), V2(len, h), V2(-j, h)]
            p = Shape2D.rounded(p, radius: 0.004, segments: 2)
        case .round:
            p.append(V2(len, -h)); p.append(V2(len, h))
            let n = 10
            for i in 0...n {
                let a = Float.pi / 2 - Float.pi * Float(i) / Float(n)   // +90 .. -90 deg
                p.append(V2(h - cos(a) * h, sin(a) * h))
            }
            p = Shape2D.deduped(p)
        case .octagon:
            let c = w * 0.3
            p = Shape2D.rounded([V2(len, -h), V2(len, h), V2(c, h), V2(0, h - c), V2(0, -h + c), V2(c, -h)],
                                radius: 0.004, segments: 2)
        }
        return p
    }

    /// Flat piece from an outline (x along grain) whose back face lies on z = 0 and whose thickness at
    /// outline point p is `thick(p)`.
    static func taperedPiece(_ outline: [V2], thick: (V2) -> Float, bevel: Float, material: MaterialKey,
                             acrossGrain: Float = 1) -> Surface {
        var s = Prim.extrude(outline, depth: 1, bevel: bevel, bevelSegments: 1, material: material)
        // Unit-depth prism (z in -0.5...0.5): rescale z per vertex so the bevel stays at its real size.
        s.deform { q in
            let t = thick(V2(q.x, q.y))
            let back = q.z < 0
            let d = 0.5 - abs(q.z)                       // distance in from the cap, 0 on the cap
            return V3(q.x, q.y, back ? min(d, t * 0.4) : max(t - d, t * 0.6))
        }
        if acrossGrain != 1 {   // compress the grain across the piece (split shakes: tight straight grain)
            s.uvs = s.uvs.map { V2($0.x, $0.y * acrossGrain) }
            s.computeTangents()
        }
        return s
    }

    /// Places a piece authored with grain along x so its x runs up the wall (+Y), butt at `butt`.
    static func upright(at butt: V3, tilt: Float, yaw: Float = 0) -> Xform {
        let rz = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        let tx = simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))
        let ty = simd_quatf(degrees: yaw, axis: V3(0, 0, 1))
        return Xform(translation: butt, rotation: tx * ty * rz)
    }

    /// Square-cut iron nail head (cut nail), face toward +Z.
    static func cutNail(_ m: inout Model, at c: V3, _ mat: MaterialKey, size s: Float = 0.006) {
        FA.box(&m, V3(s, s * 0.75, 0.002), c + V3(0, 0, 0.001), mat, r: 0.0006)
    }
    /// Round wire-nail head, face toward +Z.
    static func wireNail(_ m: inout Model, at c: V3, _ mat: MaterialKey, r: Float = 0.0042) {
        FA.cylZ(&m, r: r, h: 0.0016, at: c, mat, bevel: 0.0006, segments: 10)
    }

    /// Plywood sheathing backer: face on z in 0...t, plies visible on the edges.
    static func backer(_ m: inout Model, w: Float, h: Float, t: Float, face: MaterialKey, edge: MaterialKey) {
        FA.box(&m, V3(w, h, t * 0.7), V3(0, h / 2, t * 0.35), face, r: 0.001)
        FA.box(&m, V3(w - 0.002, h - 0.002, t), V3(0, h / 2, t / 2), edge, r: 0.001)
    }

    /// Vertical beaded casing board: board of `w` x `h` x `t` with a quirk bead on its inner edge.
    static func beadedCasing(_ m: inout Model, x: Float, z: Float, w: Float, h: Float, t: Float, beadSide: Float,
                             _ mat: MaterialKey) {
        let outline = Shape2D.rounded([V2(0, -w / 2), V2(h, -w / 2), V2(h, w / 2), V2(0, w / 2)], radius: 0.003, segments: 2)
        m.add(taperedPiece(outline, thick: { _ in t }, bevel: 0.003, material: mat), upright(at: V3(x, 0, z), tilt: 0))
        let bx = x + beadSide * (w / 2 - 0.007)
        FA.rod(&m, V3(bx, 0.002, z + t - 0.001), V3(bx, h - 0.002, z + t - 0.001), r: 0.008, mat, sides: 12)
    }

    /// Victorian decorative-shingle panel: sheathing backer, beaded side casings, frieze board with a
    /// drip cap at the head, a square-butt starter course and staggered fancy-butt courses between.
    static func shinglePanel(name: String, W: Float, H: Float, butt: Butt, width sw: Float, exposure: Float,
                             tints: [String], trim: String, worn: String, sheath: MaterialKey, plyEdge: MaterialKey,
                             nail: MaterialKey, seed: UInt64) -> Model {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: name)
        let tB: Float = 0.012, casW: Float = 0.09, casT: Float = 0.02, friezeH: Float = 0.11
        let paint = MaterialKey(stringLiteral: "wood.painted-exterior:" + trim)
        let paintWorn = MaterialKey(stringLiteral: "wood.painted-shaker-worn:" + trim)
        backer(&m, w: W, h: H, t: tB, face: sheath, edge: plyEdge)
        // Side casings, bead on the inner edge; bottoms weathered.
        beadedCasing(&m, x: -W / 2 + casW / 2, z: tB, w: casW, h: H, t: casT, beadSide: 1, paint)
        beadedCasing(&m, x: W / 2 - casW / 2, z: tB, w: casW, h: H, t: casT, beadSide: -1, paint)
        // Frieze board between the casings, drip cap (ovolo + fillet) along its bottom edge, cap on top.
        let xL = -W / 2 + casW, xR = W / 2 - casW
        // Backband on the outer edge of each casing; skirt board and drip cap at the base.
        for sx in [Float(-1), 1] {
            FA.box(&m, V3(0.022, H - 0.022, casT + 0.006), V3(sx * (W / 2 - 0.011), (H - 0.022) / 2, tB + (casT + 0.006) / 2), paint, r: 0.004)
        }
        let skirt: Float = 0.1
        FA.box(&m, V3(xR - xL - 0.002, skirt, casT * 0.9), V3(0, skirt / 2, tB + casT * 0.45), paintWorn, r: 0.003)
        FA.rod(&m, V3(xL + 0.001, skirt + 0.006, tB + 0.01), V3(xR - 0.001, skirt + 0.006, tB + 0.01), r: 0.01, paint, sides: 12)
        FA.box(&m, V3(xR - xL - 0.002, 0.008, 0.026), V3(0, skirt + 0.004, tB + 0.013), paint, r: 0.002)
        for x in stride(from: xL + 0.1, through: xR - 0.05, by: 0.27) { cutNail(&m, at: V3(x, skirt * 0.5, tB + casT * 0.9), nail) }
        FA.box(&m, V3(xR - xL - 0.002, friezeH, casT * 0.9), V3(0, H - friezeH / 2, tB + casT * 0.45), paint, r: 0.003)
        FA.rod(&m, V3(xL + 0.001, H - friezeH - 0.004, tB + 0.012), V3(xR - 0.001, H - friezeH - 0.004, tB + 0.012), r: 0.012, paintWorn, sides: 12)
        FA.box(&m, V3(W + 0.01, 0.02, 0.027), V3(0, H - 0.01, tB + 0.0135), paint, r: 0.004)
        for x in stride(from: xL + 0.08, through: xR - 0.05, by: 0.21) {
            cutNail(&m, at: V3(x, H - friezeH * 0.35, tB + casT * 0.9), nail)
            cutNail(&m, at: V3(x + 0.004, H - friezeH * 0.75, tB + casT * 0.9), nail)
        }
        for x in [-W / 2 + casW / 2, W / 2 - casW / 2] {
            for y in stride(from: Float(0.12), through: H - 0.15, by: 0.3) { cutNail(&m, at: V3(x - 0.012, y, tB + casT), nail) }
        }
        // Courses. Butt k sits at y = k * exposure (k = 0 doubled over a square starter strip).
        let headLimit = H - friezeH + 0.02
        let L: Float = 0.4, tButt: Float = 0.011, tHead: Float = 0.003
        let lo = xL + 0.001, hi = xR - 0.001
        let n = Int(((xR - xL) / sw).rounded())
        let w = (xR - xL) / Float(n)
        let storyRow = 4, storyCol = 3
        var k = -1
        while true {
            let yb = skirt + 0.018 + Float(max(k, 0)) * exposure
            if yb > headLimit - 0.06 { break }
            let starter = k < 0
            let off: Float = (k % 2 == 0 || starter) ? 0 : w / 2
            let rowLen = min(L, headLimit - yb)
            let standoff: Float = starter ? 0.003 : (k == 0 ? 0.01 : 0.0075)
            let tilt = atan(standoff / rowLen) * 180 / .pi
            var cx = xL + w / 2 - off
            var col = 0
            while cx - w / 2 < xR {
                var r = rng.fork((k + 2) * 97 + col)
                let ww = w - r.float(0.002...0.004)
                let shape: Butt = starter ? .square : butt
                var o = shingleOutline(len: rowLen, width: ww, butt: shape, rng: &r)
                o = clipY(o, lo: cx - hi, hi: cx - lo)   // outline y maps to world -x
                if o.count >= 3, Shape2D.area(o) != 0 {
                    let story = k == storyRow && col == storyCol
                    let low = k <= 0
                    let key = story || (low ? r.chance(0.6) : r.chance(0.3)) ? "wood.painted-shaker-worn:" : "wood.painted-exterior:"
                    var mat = MaterialKey(stringLiteral: key + tints[r.int(0...(tints.count - 1))])
                    if story { mat = "wood.cedar-weathered" }   // paint flaked off one shingle
                    if k == storyRow - 2 && col == storyCol + 2 {   // one shingle split along the grain
                        let a = clipY(o, lo: -1, hi: -0.012), b = clipY(o, lo: -0.009, hi: 1)
                        for half in [a, b] where half.count >= 3 {
                            m.add(taperedPiece(half, thick: { p in tHead + (tButt - tHead) * max(0, 1 - p.x / L) }, bevel: 0.0015, material: mat),
                                  upright(at: V3(cx, yb, tB + standoff), tilt: tilt, yaw: half == a ? -0.6 : 0.3))
                        }
                        cx += w; col += 1; continue
                    }
                    let piece = taperedPiece(o, thick: { p in tHead + (tButt - tHead) * max(0, 1 - p.x / L) }, bevel: 0.0015, material: mat)
                    let yaw = story ? Float(1.4) : r.float(-0.25...0.25)
                    m.add(piece, upright(at: V3(cx, yb - (story ? 0.004 : 0), tB + standoff), tilt: tilt, yaw: yaw))
                }
                cx += w; col += 1
            }
            k += 1
        }
        groundAO(&m, height: 0.12, floor: 0.75)
        return FC.place(m)
    }
}
