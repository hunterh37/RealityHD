import simd
import Foundation

/// Shared rod building: every rod and rod component lies along +X (butt at -X, tip at +X) on its side
/// with the reel side (reel foot, guides) facing +Y. Lathe parts run along the rod axis at height `y`.
enum RodKit {
    /// Lathe +Y axis to the rod's +X axis.
    static let alongX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))

    /// Surface of revolution along +X starting at `x0`, axis height `y`. Profile is (radius, distance along the axis).
    static func lathe(_ prof: [V2], x0: Float, y: Float, seg: Int = 20, tile: Float = 0.05, _ mat: MaterialKey) -> Surface {
        Prim.lathe(prof, segments: seg, seamTile: tile, material: mat, swapUV: true).transformed(Xform(translation: V3(x0, y, 0), rotation: alongX))
    }

    /// Tapered blank from `x0` (radius `r0`) to `x1` (radius `r1`), closed at the tip, with a slight
    /// convex taper (fast-action blanks thin quickly in the last third).
    static func blank(x0: Float, x1: Float, r0: Float, r1: Float, y: Float, mat: MaterialKey, seg: Int = 14) -> Surface {
        let L = x1 - x0
        var prof: [V2] = [V2(0, 0), V2(r0 * 0.98, 0)]
        for i in 0...16 {
            let t = Float(i) / 16
            prof.append(V2(r1 + (r0 - r1) * (1 - pow(t, 1.25)), L * t))
        }
        prof.append(V2(0, L + r1 * 0.5))
        return lathe(prof, x0: x0, y: y, seg: seg, tile: 0.03, mat)
    }

    /// Blank radius at `x` for a blank built with `blank(...)`.
    static func blankRadius(_ x: Float, x0: Float, x1: Float, r0: Float, r1: Float) -> Float {
        let t = min(1, max(0, (x - x0) / (x1 - x0)))
        return r1 + (r0 - r1) * (1 - pow(t, 1.25))
    }

    /// Thread wrap: an epoxy-coated band over the blank (`r` blank radius at x).
    static func wrap(x: Float, len: Float, r: Float, y: Float, mat: MaterialKey) -> Surface {
        let t: Float = 0.0006
        return lathe([V2(r * 0.99, 0), V2(r + t, len * 0.08), V2(r + t * 1.15, len * 0.5), V2(r + t, len * 0.92), V2(r * 0.99, len)], x0: x, y: y, seg: 10, tile: 0.01, mat)
    }

    /// Ring guide: ceramic insert in a wire frame on legs, foot or feet wrapped to the blank. `ring` is the
    /// insert's inner radius, `h` the ring centre height above the rod axis. Double-foot guides lean
    /// forward on two legs (stripper guides); single-foot guides have one leg from the rear foot.
    static func ringGuide(x: Float, ring: Float, h: Float, blankR: Float, y: Float, frame: MaterialKey, insert: MaterialKey,
                          wrap wrapMat: MaterialKey, double: Bool) -> [Surface] {
        var out: [Surface] = []
        let wire = max(0.0005, ring * 0.06), insT = max(0.0007, ring * 0.12)
        let c = V3(x, y + h, 0)
        // Insert: a rounded ring of width 2 insT, faced along X.
        out.append(Prim.torus(major: ring + insT, minor: insT, segments: 16, sides: 6, material: insert)
            .transformed(Xform(translation: c, rotation: alongX)))
        // Frame band around the insert.
        out.append(Prim.torus(major: ring + 2 * insT + wire * 0.6, minor: wire, segments: 16, sides: 4, material: frame)
            .transformed(Xform(translation: c, rotation: alongX)))
        let bottom = V3(x, y + h - ring - 2 * insT - wire, 0)
        let top = y + blankR + wire * 0.8
        let footLen = max(0.006, h * 0.45)
        // Legs to the foot (two legs splayed in Z for double-foot frames, meeting the feet fore and aft).
        let feet: [Float] = double ? [-footLen * 1.3, footLen * 0.5] : [-footLen * 1.4]
        for (k, fx) in feet.enumerated() {
            let footX = x + fx
            for side: Float in (double && k == 0 ? [-1, 1] : [0]) {
                let start = bottom + V3(0, 0, side * wire * 2.5)
                let knee = V3(footX * 0.35 + x * 0.65, top + (bottom.y - top) * 0.35, side * wire * 1.5)
                out.append(Prim.tube([start, knee, V3(footX, top, 0)], radii: [wire, wire, wire], sides: 6, seamTile: 0.01, material: frame))
            }
            // Flat foot along the blank, then the wrap over it.
            let dir: Float = fx < 0 ? -1 : 1
            out.append(Prim.tube([V3(footX, top, 0), V3(footX + dir * footLen, top - wire * 0.3, 0)], radii: [wire * 1.2, wire * 0.7], sides: 6, seamTile: 0.01, material: frame))
            let wx = dir < 0 ? footX - footLen - 0.002 : footX - 0.002
            out.append(wrap(x: wx, len: footLen + 0.004, r: blankR, y: y, mat: wrapMat))
        }
        return out
    }

    /// Snake guide: a twisted wire loop standing on two feet (fly rods).
    static func snakeGuide(x: Float, ring: Float, blankR: Float, y: Float, frame: MaterialKey, wrap wrapMat: MaterialKey) -> [Surface] {
        let wire: Float = 0.00045, top = y + blankR + wire
        var path: [V3] = []
        let footLen: Float = 0.006
        path.append(V3(x - footLen - ring * 0.6, top, 0))
        path.append(V3(x - ring * 0.6, top, 0))
        for i in 0...20 {
            let a = Float(i) / 20 * 2 * .pi
            path.append(V3(x - ring * 0.6 + ring * 1.2 * Float(i) / 20, top + ring * (1 - cos(a)) * 1.05, ring * sin(a) * 0.95))
        }
        path.append(V3(x + ring * 0.6 + footLen, top, 0))
        var s = [Prim.tube(path, radii: path.map { _ in wire }, sides: 6, seamTile: 0.01, material: frame)]
        s.append(wrap(x: x - footLen - ring * 0.6 - 0.002, len: footLen + 0.004, r: blankR, y: y, mat: wrapMat))
        s.append(wrap(x: x + ring * 0.6 - 0.002, len: footLen + 0.004, r: blankR, y: y, mat: wrapMat))
        return s
    }

    /// Roller guide (trolling rods): a cast frame of two cheek plates on a wrapped foot, a brass roller on a
    /// cross pin at the top, the line runs over the roller. `h` is the roller axis height above the rod axis.
    static func rollerGuide(x: Float, h: Float, blankR: Float, y: Float, frame: MaterialKey, roller: MaterialKey, wrap wrapMat: MaterialKey) -> [Surface] {
        var out: [Surface] = []
        let top = y + blankR, footLen: Float = 0.016, rr: Float = 0.0045, cheek: Float = 0.0062
        // Saddle foot and the wrap over both ends.
        out.append(Prim.roundedBox(V3(footLen * 2, 0.0022, blankR * 1.6), radius: 0.0008, bevelSegments: 1, material: frame).transformed(Xform(translation: V3(x, top + 0.0009, 0))))
        out.append(wrap(x: x - footLen - 0.004, len: 0.008, r: blankR, y: y, mat: wrapMat))
        out.append(wrap(x: x + footLen - 0.004, len: 0.008, r: blankR, y: y, mat: wrapMat))
        // Cheek plates: tapered webs from the foot up to the roller boss.
        for side: Float in [-1, 1] {
            let web: [V2] = [V2(-footLen * 0.8, 0), V2(footLen * 0.8, 0), V2(rr * 1.3, h - blankR), V2(-rr * 1.3, h - blankR)]
            out.append(Prim.extrude(Shape2D.rounded(web, radius: 0.0012), depth: 0.0016, bevel: 0.0004, bevelSegments: 1, material: frame)
                .transformed(Xform(translation: V3(x, top, side * cheek))))
            out.append(Prim.cylinder(radius: rr * 0.75, height: 0.0024, bevel: 0.0004, segments: 10, bevelSegments: 1, material: frame)
                .transformed(Xform(translation: V3(x, y + h, side * (cheek + 0.0008)), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        }
        // Roller: crowned brass spool between the cheeks.
        out.append(Prim.lathe([V2(rr * 0.6, 0), V2(rr, 0.0006), V2(rr * 0.82, cheek), V2(rr, cheek * 2 - 0.0006), V2(rr * 0.6, cheek * 2)], segments: 12, seamTile: 0.01, material: roller)
            .transformed(Xform(translation: V3(x, y + h, -cheek), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        return out
    }

    /// Roller tip-top: a tube over the blank with a forked frame carrying a brass roller at the line exit.
    static func rollerTip(x: Float, blankR: Float, y: Float, frame: MaterialKey, roller: MaterialKey) -> [Surface] {
        let tubeR = blankR + 0.0007, len: Float = 0.03, rr: Float = 0.006, cheek: Float = 0.007
        var out = [lathe([V2(0, 0), V2(tubeR, 0.0004), V2(tubeR, len - 0.0006), V2(tubeR * 0.9, len)], x0: x - len, y: y, seg: 12, tile: 0.01, frame)]
        let c = V3(x + 0.004, y + 0.004, 0)
        for side: Float in [-1, 1] {
            let web: [V2] = [V2(-0.02, -0.002), V2(-0.004, -0.004), V2(0.004 + 0.004, 0.0), V2(0.004, 0.009), V2(-0.02, 0.003)]
            out.append(Prim.extrude(Shape2D.rounded(web, radius: 0.0015), depth: 0.0018, bevel: 0.0004, bevelSegments: 1, material: frame)
                .transformed(Xform(translation: V3(x, y + 0.002, side * cheek))))
        }
        out.append(Prim.lathe([V2(rr * 0.6, 0), V2(rr, 0.0006), V2(rr * 0.8, cheek), V2(rr, cheek * 2 - 0.0006), V2(rr * 0.6, cheek * 2)], segments: 12, seamTile: 0.01, material: roller)
            .transformed(Xform(translation: V3(c.x, c.y, -cheek), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        return out
    }

    /// Tip-top: a tube over the blank tip with a small ring standing up.
    static func tipTop(x: Float, ring: Float, blankR: Float, y: Float, frame: MaterialKey, insert: MaterialKey) -> [Surface] {
        let tubeR = blankR + 0.0005, len: Float = 0.009
        var out = [lathe([V2(0, 0), V2(tubeR, 0.0003), V2(tubeR, len - 0.0005), V2(tubeR * 0.9, len)], x0: x - len, y: y, seg: 10, tile: 0.01, frame)]
        let insT = max(0.0006, ring * 0.14)
        let c = V3(x - 0.002, y + tubeR + ring + insT * 1.6, 0)
        out.append(Prim.torus(major: ring + insT, minor: insT, segments: 16, sides: 6, material: insert).transformed(Xform(translation: c, rotation: alongX)))
        out.append(Prim.torus(major: ring + 2.2 * insT, minor: insT * 0.5, segments: 16, sides: 6, material: frame).transformed(Xform(translation: c, rotation: alongX)))
        out.append(Prim.tube([V3(x - 0.004, y + tubeR * 0.6, 0), V3(x - 0.002, c.y - ring - insT, 0)], radii: [0.0006, 0.0005], sides: 6, seamTile: 0.01, material: frame))
        return out
    }

    /// Bends a blank part as a loaded rod: points past `from` follow an arc of `radius` that lifts toward +Y,
    /// with curvature growing toward the tip (progressive action).
    static func bend(_ s: Surface, from: Float, length: Float, y: Float, tipAngle: Float) -> Surface {
        var b = s
        b.deform { p in
            let sx = p.x - from
            guard sx > 0 else { return p }
            // Angle grows with the square of distance: theta(s) = tipAngle (s / L)^2; integrate the centreline.
            let steps = 24
            var cx: Float = 0, cy: Float = 0
            let ds = sx / Float(steps)
            for i in 0..<steps {
                let t = (Float(i) + 0.5) * ds / length
                let th = tipAngle * t * t
                cx += cos(th) * ds; cy += sin(th) * ds
            }
            let th = tipAngle * (sx / length) * (sx / length)
            let dy = p.y - y
            return V3(from + cx - sin(th) * dy, y + cy + cos(th) * dy, p.z)
        }
        return b
    }

    /// Rubber butt cap (domed) from `x0` toward +X.
    static func buttCap(x0: Float, r: Float, y: Float, mat: MaterialKey) -> Surface {
        lathe([V2(0, 0), V2(r * 0.55, 0.0006), V2(r * 0.9, 0.003), V2(r, 0.007), V2(r, 0.016), V2(r * 0.96, 0.018), V2(r * 0.7, 0.0185)], x0: x0, y: y, seg: 24, tile: 0.05, mat)
    }

    /// Grip shaped by `shape` ((radius, x) pairs from the rear end), with shallow ring seams every
    /// `ringPitch` meters (cork rings) or none (EVA, ringPitch 0).
    static func grip(x0: Float, shape: [V2], ringPitch: Float, y: Float, mat: MaterialKey, step: Float = 0.005) -> Surface {
        let L = shape.last!.y
        var prof: [V2] = [V2(0.0071, 0)]
        let n = max(16, Int(L / step))
        for i in 0...n {
            let s = L * Float(i) / Float(n)
            var r = interp(shape, s)
            if ringPitch > 0 {
                let f = (s / ringPitch).truncatingRemainder(dividingBy: 1)
                r -= 0.00018 * max(0, 1 - min(f, 1 - f) / 0.06)
            }
            // Rounded rear and front shoulders.
            let edge = min(s, L - s)
            r -= 0.0012 * max(0, 1 - edge / 0.002) * max(0, 1 - edge / 0.002)
            prof.append(V2(r, s))
        }
        prof.append(V2(0.0071, L))
        return lathe(prof, x0: x0, y: y, seg: 20, tile: 0.06, mat)
    }

    /// Piecewise-linear radius lookup in a (radius, x) shape.
    static func interp(_ shape: [V2], _ s: Float) -> Float {
        for i in 1..<shape.count where s <= shape[i].y {
            let a = shape[i - 1], b = shape[i]
            let t = (s - a.y) / max(1e-5, b.y - a.y)
            return a.x + (b.x - a.x) * t
        }
        return shape.last!.x
    }

    /// Winding check: a short metal collar where the blank leaves the grip.
    static func windingCheck(x: Float, blankR: Float, y: Float, mat: MaterialKey) -> Surface {
        lathe([V2(blankR, 0), V2(blankR + 0.0028, 0.0004), V2(blankR + 0.003, 0.004), V2(blankR + 0.0012, 0.0055), V2(blankR, 0.0056)], x0: x, y: y, seg: 20, tile: 0.02, mat)
    }

    /// Hook keeper: a small wire loop wrapped to the blank.
    static func hookKeeper(x: Float, blankR: Float, y: Float, frame: MaterialKey, wrap wrapMat: MaterialKey) -> [Surface] {
        let top = y + blankR + 0.0004
        var path: [V3] = [V3(x - 0.008, top, 0), V3(x, top, 0)]
        for i in 1...10 { let a = Float(i) / 10 * .pi; path.append(V3(x + 0.0025 - 0.0025 * cos(a), top + 0.0035 * sin(a), 0)) }
        return [Prim.tube(path, radii: path.map { _ in 0.0004 }, sides: 6, seamTile: 0.01, material: frame),
                wrap(x: x - 0.010, len: 0.011, r: blankR, y: y, mat: wrapMat)]
    }
}
