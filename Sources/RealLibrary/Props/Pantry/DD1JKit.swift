import simd
import Foundation

/// Shared geometry for the pantry batch: tin cans, glass bottles and jars, cartons. Printed art is raised
/// geometry (patches that follow the surface), so no texture files are needed.
enum DD1JKit {
    static func sm(_ t: Float) -> Float { let c = max(0, min(1, t)); return c * c * (3 - 2 * c) }

    /// Smoothstep through (y, value) knots.
    static func interp(_ k: [(Float, Float)], _ y: Float) -> Float {
        if y <= k[0].0 { return k[0].1 }
        for i in 1..<k.count where y <= k[i].0 {
            let t = (y - k[i - 1].0) / (k[i].0 - k[i - 1].0)
            return k[i - 1].1 + (k[i].1 - k[i - 1].1) * sm(t)
        }
        return k[k.count - 1].1
    }

    static func tint(_ base: String, _ c: UInt32) -> MaterialKey { base + ":" + String(format: "%06X", c) }

    /// Surface patch over (u, v) in meters: `pos(u, v)` gives the point, `normal` the outward direction.
    static func grid(u0: Float, u1: Float, v0: Float, v1: Float, cols: Int, rows: Int, material: MaterialKey,
                     pos: (Float, Float) -> V3, normal: (Float, Float) -> V3) -> Surface {
        var s = Surface(material: material)
        for j in 0...rows { for i in 0...cols {
            let u = u0 + (u1 - u0) * Float(i) / Float(cols), v = v0 + (v1 - v0) * Float(j) / Float(rows)
            _ = s.add(pos(u, v), normal(u, v), V2(u, v))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(cols) { let a = j * row + i; s.quad(a, a + 1, a + row + 1, a + row) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    /// Patch on a surface of revolution. `center` is the angle (radians, -pi/2 faces +Z), `width` the arc length in meters.
    static func arcPatch(center: Float, width: Float, y0: Float, y1: Float, offset: Float, material: MaterialKey,
                         radius: (Float) -> Float, shift: ((V3, V3) -> Float)? = nil, cols: Int = 0, rows: Int = 6) -> Surface {
        let rm = radius((y0 + y1) / 2)
        let full = width >= 2 * .pi * rm - 1e-4
        let span: Float = full ? 2 * .pi : width / rm
        let nc = cols > 0 ? cols : max(2, Int(span * 7))
        var s = Surface(material: material)
        for j in 0...rows { for i in 0...nc {
            let t = Float(i) / Float(nc), a = center - span / 2 + span * t
            let y = y0 + (y1 - y0) * Float(j) / Float(rows)
            let n = V3(cos(a), 0, -sin(a))
            var p = n * (radius(y) + offset) + V3(0, y, 0)
            if let shift { p += n * shift(p, n) }
            _ = s.add(p, n, V2(a * rm, y))
        } }
        let row = UInt32(nc + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(nc) { let a = j * row + i; s.quad(a, a + 1, a + row + 1, a + row) } }
        s.recomputeNormals(weldSeams: full)
        s.computeTangents()
        return s
    }

    /// Dent: gaussian pit around angle `a` (radians) and height `y`, radius `sigma` meters.
    struct Dent {
        var a: Float, y: Float, depth: Float, sigma: Float
        func at(_ p: V3, rad: Float) -> Float {
            var da = atan2(-p.z, p.x) - a
            while da > .pi { da -= 2 * .pi }
            while da < -.pi { da += 2 * .pi }
            let d2 = (da * rad) * (da * rad) + (p.y - y) * (p.y - y)
            return -depth * exp(-d2 / (2 * sigma * sigma))
        }
    }

    // MARK: Tin can

    struct CanLabel {
        var base: UInt32, band: UInt32, panel: UInt32, accent: UInt32, ink: UInt32 = 0x2A2420
        var bandHeight: Float = 0.008
        var margin: Float = 0.0065
    }

    static func canBodyRadius(r: Float, beads: [Float], h: Float) -> (Float) -> Float {
        { y in
            var d: Float = 0
            for b in beads { let t = (y - b * h) / 0.0024; d += 0.0007 * exp(-t * t) }
            return r - 0.0008 - d
        }
    }

    /// Tin can standing on its bottom seam at y = 0. Double-seam rims, rolled beads, ring-pull lid, wrapped label.
    static func can(r: Float, h: Float, label L: CanLabel, beads: [Float], dent: Dent?, rustArc: Float, rustAt: Float,
                    peel: Bool, detail: Bool, reliefs: (inout Model, (Float) -> Float, Float, Float) -> Void) -> Model {
        var m = Model(name: "can")
        let steel: MaterialKey = "metal.galvanized-aged", bright: MaterialKey = "metal.aluminum-brushed"
        let rb = canBodyRadius(r: r, beads: beads, h: h)
        let seg = detail ? 48 : 24
        var pts: [V2] = [V2(0, 0.0018), V2(r * 0.76, 0.0018), V2(r * 0.80, 0.0034), V2(r * 0.83, 0.0012), V2(r * 0.87, 0.0002),
                         V2(r - 0.0010, 0), V2(r - 0.0001, 0.0010), V2(r, 0.0030), V2(r - 0.0001, 0.0050), V2(rb(0.007), 0.0062)]
        let n = detail ? 36 : 10
        let y0: Float = 0.0070, y1: Float = h - 0.0070
        for i in 0...n { let y = y0 + (y1 - y0) * Float(i) / Float(n); pts.append(V2(rb(y), y)) }
        pts += [V2(rb(h - 0.0062), h - 0.0062), V2(r - 0.0001, h - 0.0050), V2(r, h - 0.0030), V2(r - 0.0001, h - 0.0010),
                V2(r - 0.0010, h), V2(r * 0.87, h - 0.0002), V2(r * 0.85, h - 0.0012), V2(r * 0.83, h - 0.0036), V2(r * 0.66, h - 0.0036),
                V2(r * 0.64, h - 0.0048), V2(r * 0.52, h - 0.0048), V2(r * 0.50, h - 0.0036), V2(0, h - 0.0036)]
        var body = Prim.lathe(pts, segments: seg, seamTile: 0.1, material: steel)
        if let dent { body.displace { p, _ in p.y > 0.008 && p.y < h - 0.008 ? dent.at(p, rad: r) : 0 } }
        m.add(body)

        // Wrapped paper label following the beads, with overlap seam and a dirty lower edge.
        let ly0 = L.margin, ly1 = h - L.margin
        let lr: (Float) -> Float = { rb($0) + 0.0005 }
        let dentShift: ((V3, V3) -> Float)? = dent.map { d in { p, _ in d.at(p, rad: r) * 0.85 } }
        var lp: [V2] = [V2(lr(ly0) - 0.0004, ly0)]
        let ln = detail ? 20 : 6
        for i in 0...ln { let y = ly0 + (ly1 - ly0) * Float(i) / Float(ln); lp.append(V2(lr(y), y)) }
        lp.append(V2(lr(ly1) - 0.0004, ly1))
        var lab = Prim.lathe(lp, segments: seg, seamTile: 0.1, material: tint("plastic.matte", L.base))
        if let dentShift { lab.displace { p, n in dentShift(p, n) } }
        m.add(lab)
        let bh = min(L.bandHeight, (ly1 - ly0) * 0.28)
        for (a, b) in [(ly0, ly0 + bh), (ly1 - bh, ly1)] {
            m.add(arcPatch(center: 0, width: 2 * .pi * r, y0: a, y1: b, offset: 0.0004, material: tint("plastic.gloss", L.band),
                           radius: lr, shift: dentShift, rows: 2))
        }
        // Grime along the bottom edge of the label.
        m.add(arcPatch(center: 0, width: 2 * .pi * r, y0: ly0, y1: ly0 + 0.0022, offset: 0.0006, material: tint("plastic.matte", 0x4A3F33),
                       radius: lr, shift: dentShift, rows: 1))
        // Overlap seam on the back-left.
        let seamA: Float = .pi / 2 + 0.6
        m.add(arcPatch(center: seamA, width: 0.0035, y0: ly0, y1: ly1, offset: 0.0010, material: tint("paper.screwbox-kraft", L.base ^ 0x0A0A0A),
                       radius: lr, shift: dentShift, rows: 2))
        // Front panel and ink bars.
        let mid = (ly0 + ly1) / 2, ph = (ly1 - ly0 - 2 * bh) * 0.8
        m.add(arcPatch(center: -.pi / 2, width: r * 1.35, y0: mid - ph / 2, y1: mid + ph / 2, offset: 0.0008,
                       material: tint("plastic.gloss", L.panel), radius: lr, shift: dentShift, rows: 5))
        for k in 0..<(h > 0.05 ? 3 : 0) {
            let by = mid + ph / 2 - 0.0045 - Float(k) * 0.0042 * (h > 0.05 ? 1 : 0.7)
            let w = r * (k == 0 ? 1.0 : 0.72 - 0.1 * Float(k))
            if by - 0.0014 > ly0 + bh { m.add(arcPatch(center: -.pi / 2, width: w, y0: by - 0.0014, y1: by + 0.0014, offset: 0.0013,
                                                     material: tint("plastic.matte", L.ink), radius: lr, shift: dentShift, rows: 1)) }
        }
        // Barcode on the back.
        for k in 0..<(detail ? 14 : 5) {
            let wd: Float = (k % 3 == 0) ? 0.0016 : 0.0009
            m.add(arcPatch(center: .pi / 2 - 0.62 + Float(k) * 0.045, width: wd, y0: mid - 0.008, y1: mid + 0.004, offset: 0.0008,
                           material: tint("plastic.matte", 0x1C1A18), radius: lr, rows: 1))
        }
        if peel {
            // Lifted label corner at the top seam: a small flap curling off the tin.
            let flap = Prim.roundedBox(V3(0.012, 0.0004, 0.0100), radius: 0.0001, bevelSegments: 1, material: tint("paper.screwbox-kraft", L.base))
            m.add(flap, Xform(translation: V3(r * 0.66, ly1 - 0.012, -r * 0.74), rotation: simd_quatf(angle: 0.9, axis: V3(0.6, 0, 0.8))))
        }
        // Scuffs and a creased edge on the band: lighter arcs where the label rubbed on a shelf.
        for i in 0..<5 {
            let a = Float(i) * 1.37 + 0.4, w: Float = 0.004 + 0.0025 * Float(i % 3)
            let y = i % 2 == 0 ? ly1 - bh * (0.2 + 0.1 * Float(i)) : ly0 + bh * 0.3
            m.add(arcPatch(center: a, width: w, y0: y, y1: y + 0.0012, offset: 0.0009, material: tint("plastic.matte", 0xE7DFD0),
                           radius: lr, shift: dentShift, rows: 1))
        }
        // Food stain and vertical creases on the label, bare steel chips and rust specks on the rims.
        m.add(arcPatch(center: -.pi / 2 + 0.55, width: 0.011, y0: ly0 + bh * 0.9, y1: ly0 + bh * 0.9 + 0.0075, offset: 0.0010,
                       material: tint("plastic.matte", 0x7A5A32), radius: lr, shift: dentShift, rows: 3))
        for (i, a) in [Float(-0.4), 1.2, 2.2].enumerated() {
            m.add(arcPatch(center: a, width: 0.0007, y0: ly0 + 0.003, y1: ly1 - 0.003, offset: 0.0009,
                           material: tint("plastic.matte", i == 1 ? 0x403830 : 0xF4EEE0), radius: lr, shift: dentShift, cols: 1, rows: 8))
        }
        for (i, a) in [Float(0.3), 2.1, 3.9, 5.2].enumerated() {
            m.add(Prim.torus(major: r - 0.0004, minor: 0.0006, segments: 6, sides: 4, arc: 0.22 + 0.06 * Float(i), material: "metal.steel"),
                  Xform(translation: V3(0, h - 0.0030, 0), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        reliefs(&m, lr, mid, ph)

        // Pull tab: rivet, lever and ring on the countersunk lid, plus the scored opening.
        let lidY = h - 0.0036
        var tab = Model(name: "tab")
        tab.add(Prim.cylinder(radius: 0.0030, height: 0.0016, bevel: 0.0006, segments: detail ? 14 : 8, bevelSegments: 1, material: bright),
                Xform(translation: V3(-r * 0.18, 0.0002, 0)))
        tab.add(Prim.roundedBox(V3(r * 0.78, 0.0012, 0.0062), radius: 0.0004, bevelSegments: 1, material: bright),
                Xform(translation: V3(r * 0.22, 0.0014, 0)))
        tab.add(Prim.torus(major: r * 0.19, minor: 0.0011, segments: detail ? 28 : 12, sides: detail ? 8 : 4, minorY: 0.0008, material: bright),
                Xform(translation: V3(r * 0.43, 0.0016, 0)))
        m.add(tab.transformed(Xform(translation: V3(0, lidY, 0), rotation: simd_quatf(angle: 0.35, axis: V3(0, 1, 0)))))
        m.add(Prim.torus(major: r * 0.745, minor: 0.00045, segments: detail ? 48 : 18, sides: 4, arc: 5.0, material: "metal.steel"),
              Xform(translation: V3(0, lidY + 0.0001, 0), rotation: simd_quatf(angle: 0.35 + 0.65, axis: V3(0, 1, 0))))
        if rustArc > 0 {
            m.add(Prim.torus(major: r - 0.0009, minor: 0.0008, segments: detail ? 20 : 8, sides: 5, arc: rustArc * 0.6, material: "metal.rust"),
                  Xform(translation: V3(0, h - 0.0030, 0), rotation: simd_quatf(angle: rustAt + 2.5, axis: V3(0, 1, 0))))
            m.add(Prim.torus(major: r - 0.0009, minor: 0.0009, segments: detail ? 24 : 10, sides: 5, arc: rustArc, material: "metal.rust"),
                  Xform(translation: V3(0, 0.0024, 0), rotation: simd_quatf(angle: rustAt, axis: V3(0, 1, 0))))
        }
        return m
    }

    // MARK: Glass bottle and jar

    struct Bottle {
        var r: Float
        var knots: [(Float, Float)]       // (y, outer radius) from the foot ring up to the lip
        var top: Float                    // lip height
        var wall: Float = 0.0028
        var punt: Float = 0.006           // floor thickness
        var fillTop: Float                // fluid surface height
        var glass: MaterialKey
        var fluid: MaterialKey?
        var seam = true
        func outer(_ y: Float) -> Float { DD1JKit.interp(knots, y) }
    }

    static func bottleGlass(_ b: Bottle, detail: Bool) -> Model {
        var m = Model(name: "glass")
        var body = Model(name: "glassBody")
        let seg = detail ? 44 : 20
        let r = b.r, t = b.top
        var pts: [V2] = [V2(0, 0.0048), V2(r * 0.45, 0.0042), V2(r * 0.72, 0.0014), V2(r - 0.0034, 0.0004), V2(r - 0.0012, 0.0003),
                         V2(r - 0.0002, 0.0016)]
        let n = detail ? 28 : 10
        for i in 0...n { let y = 0.0045 + (t - 0.0045) * Float(i) / Float(n); pts.append(V2(b.outer(y), y)) }
        // Lip: rounded, then inner wall down to the floor.
        let ro = b.outer(t)
        pts += [V2(ro - 0.0003, t + 0.0003), V2(ro - b.wall * 0.5, t + 0.0004), V2(ro - b.wall + 0.0002, t - 0.0004)]
        for i in (0...n).reversed() {
            let y = b.punt + (t - 0.002 - b.punt) * Float(i) / Float(n)
            pts.append(V2(max(0.002, b.outer(y) - b.wall), y))
        }
        pts += [V2(max(0.002, b.outer(b.punt) - b.wall - 0.002), b.punt - 0.0004), V2(0, b.punt - 0.0006)]
        var gs = Prim.lathe(pts, segments: seg, seamTile: 0.1, material: b.glass)
        gs.recomputeNormals(weldSeams: true)
        gs.computeTangents()
        body.add(gs)
        // Fluid: slightly inset from the inner wall, flat surface with a small meniscus.
        if let fluid = b.fluid {
        let fy = b.fillTop
        var fp: [V2] = [V2(0, b.punt)]
        let fn = detail ? 40 : 8
        for i in 0...fn { let y = b.punt + (fy - b.punt) * Float(i) / Float(fn); fp.append(V2(max(0.002, b.outer(y) - b.wall - 0.0016), y)) }
        fp.append(V2(max(0.002, b.outer(fy) - b.wall - 0.0010), fy + 0.0008))
        fp.append(V2(max(0.002, b.outer(fy) - b.wall - 0.0030), fy))
        fp.append(V2(0, fy))
        body.add(Prim.lathe(fp, segments: seg, seamTile: 0.1, material: fluid))
        }
        // Scuffed bottom edge where it has slid on shelves.
        body.add(Prim.lathe([V2(r - 0.0006, 0.0010), V2(r + 0.0002, 0.0022), V2(r + 0.0003, 0.0048), V2(r - 0.0002, 0.0062)],
                         segments: seg, seamTile: 0.1, material: "glass.frosted"))
        // Lathe seams sit at the back, behind the label, where shading breaks are hidden.
        m.add(body.transformed(Xform(rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0)))))
        if b.seam && detail {
            // Mould seam: faint raised vertical line on two sides.
            for a in [Float(0), .pi] {
                m.add(arcPatch(center: a, width: 0.0008, y0: 0.006, y1: t - 0.004, offset: 0.0003, material: b.glass,
                               radius: { b.outer($0) }, cols: 1, rows: 40))
            }
        }
        return m
    }

    /// Screw cap: skirt with vertical knurls, rolled bottom edge, flat top with a stepped ring. `bandGap` adds a pilfer band.
    static func cap(r: Float, h: Float, y: Float, material: MaterialKey, knurls: Int, bandGap: Bool, button: Bool, detail: Bool) -> Model {
        var m = Model(name: "cap")
        let seg = detail ? 48 : 20
        var pts: [V2] = [V2(r - 0.0004, 0.0004), V2(r + 0.0004, 0.0012), V2(r + 0.0002, 0.0028), V2(r, 0.0040)]
        pts += [V2(r, h - 0.0030), V2(r - 0.0008, h - 0.0006), V2(r - 0.0020, h)]
        if button {
            pts += [V2(r * 0.70, h - 0.0004), V2(r * 0.66, h - 0.0014), V2(r * 0.40, h - 0.0016), V2(r * 0.36, h - 0.0010),
                    V2(r * 0.34, h - 0.0020), V2(0, h - 0.0022)]
        } else {
            pts += [V2(r * 0.74, h), V2(r * 0.70, h - 0.0010), V2(0, h - 0.0010)]
        }
        var s = Prim.lathe(pts, segments: seg, seamTile: 0.1, material: material)
        if detail && knurls > 0 {
            s.displace { p, n in
                guard abs(n.y) < 0.5, p.y > 0.006, p.y < h - 0.0035 else { return 0 }
                let a = atan2(-p.z, p.x)
                return 0.00028 * (0.5 + 0.5 * cos(a * Float(knurls)))
            }
        }
        m.add(s)
        if bandGap {
            // Dark shadow groove between cap and pilfer band, so the break line reads.
            m.add(Prim.lathe([V2(r - 0.0006, 0.0034), V2(r + 0.0001, 0.0036), V2(r + 0.0001, 0.0046), V2(r - 0.0006, 0.0048)],
                             segments: seg, seamTile: 0.1, material: "metal.cast-iron"))
        }
        return m.transformed(Xform(translation: V3(0, y, 0)))
    }

    // MARK: Cartons

    struct Carton {
        var w: Float, h: Float, d: Float
        var crush: V3?                      // corner center pushed inward
        var bulge: Float = 0.0008
        func shift(_ p: V3, _ n: V3) -> Float {
            var s: Float = 0
            if abs(n.z) > 0.5 {
                let ux = 2 * p.x / w, uy = 2 * (p.y - h / 2) / h
                s += bulge * max(0, 1 - ux * ux) * max(0, 1 - uy * uy)
            } else if abs(n.x) > 0.5 {
                s += bulge * 0.4 * max(0, 1 - pow(2 * (p.y - h / 2) / h, 2))
            }
            if let c = crush {
                let q = p - c, d2 = q.x * q.x + q.y * q.y + q.z * q.z
                s -= 0.0048 * exp(-d2 / (2 * 0.011 * 0.011))
            }
            return s
        }
    }

    static func cartonBody(_ c: Carton, material: MaterialKey, detail: Bool) -> Surface {
        let rows = detail ? 36 : 8, pn = detail ? 56 : 28
        let rings: [[V3]] = (0...rows).map { i in
            let y = c.h * Float(i) / Float(rows)
            let t = Float(i == 0 ? 0.0008 : (i == rows ? 0.0006 : 0))
            return Prim.ring(Shape2D.superellipse(c.w - 2 * t, c.d - 2 * t, exponent: 22, segments: pn), y: y)
        }
        var s = Prim.loft(rings, capStart: true, capEnd: true, material: material)
        if detail { s.displace { p, n in c.shift(p, n) } }
        return s
    }

    /// Flat patch on one carton face. face: 0 front (+Z), 1 back (-Z), 2 right (+X), 3 left (-X). (u, v) are meters along the face.
    static func facePatch(_ c: Carton, face: Int, u0: Float, u1: Float, v0: Float, v1: Float, offset: Float = 0.0006,
                          material: MaterialKey, detail: Bool = true, cols: Int = 4, rows: Int = 4) -> Surface {
        let o: [V3] = [V3(0, 0, c.d / 2), V3(0, 0, -c.d / 2), V3(c.w / 2, 0, 0), V3(-c.w / 2, 0, 0)]
        let uAxis: [V3] = [V3(1, 0, 0), V3(-1, 0, 0), V3(0, 0, -1), V3(0, 0, 1)]
        let nrm: [V3] = [V3(0, 0, 1), V3(0, 0, -1), V3(1, 0, 0), V3(-1, 0, 0)]
        let n = nrm[face]
        return grid(u0: u0, u1: u1, v0: v0, v1: v1, cols: detail ? cols : 1, rows: detail ? rows : 1, material: material,
                    pos: { u, v in
                        let p = o[face] + uAxis[face] * u + V3(0, v, 0)
                        return p + n * (offset + (detail ? c.shift(p, n) : 0))
                    }, normal: { _, _ in n })
    }

    /// Thin dark groove or edge line as a box.
    static func line(_ m: inout Model, from a: V3, size: V3, material: MaterialKey) {
        m.add(Prim.roundedBox(size, radius: min(size.x, size.y, size.z) * 0.35, bevelSegments: 1, material: material), Xform(translation: a))
    }
}
