import simd
import Foundation

/// Shared construction helpers for the dd1k pantry props: glass and plastic vessels, threaded necks, ribbed caps,
/// wrapped labels with a lap seam, mould seams, and folded paper bags. All lengths in meters.
enum DD1KPantry {
    /// Radius of an outer profile (ascending y) at height `y`.
    static func radius(_ pts: [V2], at y: Float) -> Float {
        for i in 1..<pts.count where pts[i].y >= y {
            let a = pts[i - 1], b = pts[i]
            let t = b.y == a.y ? 0 : (y - a.y) / (b.y - a.y)
            return a.x + (b.x - a.x) * t
        }
        return pts.last!.x
    }

    /// Hollow vessel shell from an outer profile (points ascending, first at the base edge, last at the rim).
    /// Adds a punted base, a rounded lip and the inner wall. Returns the inner profile function via `radius`.
    static func shell(_ m: inout Model, outer: [V2], wall: Float, baseThick: Float, material: MaterialKey, seg: Int = 40, tile: Float = 0.1) {
        let rim = outer.last!
        var p: [V2] = [V2(0, baseThick * 0.9), V2(outer[0].x * 0.55, baseThick * 0.35), V2(outer[0].x * 0.92, 0.0004)]
        p += outer
        p.append(V2(rim.x - wall * 0.3, rim.y + 0.0004))
        p.append(V2(rim.x - wall * 0.8, rim.y + 0.0002))
        for o in outer.reversed() where o.y < rim.y - 0.0006 && o.y > baseThick {
            p.append(V2(max(0.002, o.x - wall), o.y))
        }
        p.append(V2(max(0.002, outer[0].x - wall - 0.002), baseThick))
        p.append(V2(0, baseThick - 0.0003))
        m.add(Prim.lathe(p, segments: seg, seamTile: tile, material: material))
    }

    /// Liquid or fill body inside a shell, up to `fillY`, with a slightly raised meniscus.
    static func fill(_ m: inout Model, outer: [V2], wall: Float, baseThick: Float, fillY: Float, material: MaterialKey, seg: Int = 40) {
        let gap: Float = 0.0004
        var p: [V2] = [V2(0, baseThick + 0.0004), V2(outer[0].x - wall - gap - 0.002, baseThick + 0.0004)]
        for o in outer where o.y > baseThick && o.y < fillY - 0.001 { p.append(V2(o.x - wall - gap, o.y)) }
        let r = radius(outer, at: fillY) - wall - gap
        p.append(V2(r, fillY - 0.001)); p.append(V2(r - 0.0012, fillY)); p.append(V2(0, fillY - 0.0008))
        m.add(Prim.lathe(p, segments: seg, seamTile: 0.1, material: material))
    }

    /// Screw thread: a helix wire wound on a neck of radius `r`, starting at `y`.
    static func threads(_ m: inout Model, r: Float, y: Float, turns: Float, pitch: Float, wire: Float, material: MaterialKey) {
        m.add(Prim.helix(radius: r, pitch: pitch, turns: turns, wire: wire, perTurn: 20, sides: 6, material: material),
              Xform(translation: V3(0, y, 0)))
    }

    /// Vertical mould seam: a hairline ridge up two opposite sides of a glass body.
    static func mouldSeam(_ m: inout Model, profile: [V2], y0: Float, y1: Float, material: MaterialKey) {
        let steps = 6
        for side in [Float(1), -1] {
            var path: [V3] = []
            for k in 0...steps {
                let y = y0 + (y1 - y0) * Float(k) / Float(steps)
                path.append(V3(side * (radius(profile, at: y) + 0.0001), y, 0))
            }
            m.add(Prim.tube(path, radii: path.map { _ in 0.00045 }, sides: 4, seamTile: 0.05, material: material, capEnd: true))
        }
    }

    /// Label wrapped around a straight section with a lap seam on the back, plus optional printed bands
    /// (y0, y1, material) and a front panel disc (center y, radius, material).
    static func label(_ m: inout Model, r: Float, y0: Float, y1: Float, material: MaterialKey,
                      bands: [(Float, Float, MaterialKey)] = [], panel: (Float, Float, MaterialKey)? = nil, seg: Int = 40) {
        let t: Float = 0.0004
        m.add(Prim.lathe([V2(r, y0), V2(r + t, y0 + 0.0003), V2(r + t, y1 - 0.0003), V2(r, y1)], segments: seg, seamTile: 0.1, material: material))
        for b in bands {
            m.add(Prim.lathe([V2(r + t, b.0), V2(r + t + 0.0003, b.0 + 0.0002), V2(r + t + 0.0003, b.1 - 0.0002), V2(r + t, b.1)],
                             segments: seg, seamTile: 0.1, material: b.2))
        }
        if let p = panel {
            m.add(Prim.cylinder(radius: p.1, height: 0.0005, bevel: 0.0002, segments: 28, bevelSegments: 1, material: p.2),
                  Xform(translation: V3(0, p.0, r + t + 0.0003), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Lap seam: the overlapping edge of the wrapped label, stepped 0.4 mm proud on the back.
        m.add(Prim.roundedBox(V3(0.006, y1 - y0, 0.0005), radius: 0.00015, bevelSegments: 1, material: material),
              Xform(translation: V3(0, (y0 + y1) / 2, -(r + t + 0.0002))))
    }

    /// Screw cap or lid: dome top, ribbed skirt (knurl displaced), and a lower lip. Base at `y`.
    static func cap(_ m: inout Model, r: Float, y: Float, h: Float, ribs: Int, ribDepth: Float, material: MaterialKey, seg: Int = 56) {
        let p: [V2] = [V2(0, y + h), V2(r * 0.55, y + h), V2(r - 0.0015, y + h - 0.0006), V2(r, y + h - 0.0022),
                       V2(r + 0.0003, y + h * 0.55), V2(r + 0.0003, y + 0.0018), V2(r, y), V2(r - 0.0016, y + 0.0004),
                       V2(r - 0.0016, y + h - 0.003), V2(0, y + h - 0.003)]
        var s = Prim.lathe(p, segments: seg, seamTile: 0.08, material: material)
        let n = Float(ribs)
        s.displace { pos, _ in
            guard pos.y > y + 0.002 && pos.y < y + h - 0.003 && hypot(pos.x, pos.z) > r - 0.001 else { return 0 }
            let a = atan2(pos.z, pos.x) * n
            return ribDepth * max(0, sin(a)) * 0.9
        }
        m.add(s)
    }

    /// Tamper-evident band under a cap: a thin ring with a breakable bridge gap.
    static func tamperRing(_ m: inout Model, r: Float, y: Float, h: Float, material: MaterialKey) {
        m.add(Prim.torus(major: r, minor: h / 2, segments: 40, sides: 6, arc: 2 * .pi * 0.94, minorY: h / 2, material: material),
              Xform(translation: V3(0, y + h / 2, 0), rotation: simd_quatf(degrees: 20, axis: .up)))
    }

    /// Folded paper bag with a pinched, folded-over top, gusset creases, back glue seam and a taped closure.
    /// Width x depth at the base, `h` total height, `fold` height of the folded top.
    static func paperBag(_ m: inout Model, w: Float, d: Float, h: Float, fold: Float, paper: MaterialKey, crease: MaterialKey,
                         tape: MaterialKey, rng: inout SeededRNG, crumple: Float) {
        let hb = h - fold - 0.03
        var body = Prim.roundedBox(V3(w, hb, d), radius: 0.003, bevelSegments: 2, material: paper).subdivided().subdivided()
        let k0 = rng.float(0...6), k1 = rng.float(0...6)
        body.displace { p, _ in
            crumple * (sin(p.y * 90 + k0 + p.x * 40) * 0.5 + sin(p.x * 130 + p.y * 60 + k1) * 0.35)
        }
        m.add(body, Xform(translation: V3(0, hb / 2, 0)))
        // Pinch from the full section to the flat top.
        let a = Prim.ring(Shape2D.superellipse(w, d, exponent: 8), y: hb - 0.002)
        let b = Prim.ring(Shape2D.superellipse(w * 0.985, 0.012, exponent: 8), y: hb + 0.03)
        m.add(Prim.loft([a, b], capStart: false, capEnd: true, material: paper))
        // Folded top: a flat double layer, then the front flap folded over it.
        let ty = hb + 0.03
        m.add(Prim.roundedBox(V3(w * 0.985, fold, 0.011), radius: 0.0012, bevelSegments: 2, material: paper), Xform(translation: V3(0, ty + fold / 2, 0)))
        m.add(Prim.roundedBox(V3(w * 0.985, fold * 0.8, 0.0022), radius: 0.0006, bevelSegments: 1, material: paper),
              Xform(translation: V3(0, ty + fold * 0.45, 0.0066), rotation: simd_quatf(degrees: 1.5, axis: V3(1, 0, 0))))
        // Fold crease shadow lines and taped closure.
        m.add(Prim.roundedBox(V3(w * 0.97, 0.0008, 0.0012), radius: 0.0003, bevelSegments: 1, material: crease), Xform(translation: V3(0, ty + 0.0006, 0.0078)))
        m.add(Prim.roundedBox(V3(w * 0.5, 0.012, 0.0006), radius: 0.00015, bevelSegments: 1, material: tape),
              Xform(translation: V3(0, ty + fold * 0.62, 0.0082)))
        // Gusset creases on both sides and the glued back seam.
        for s in [Float(1), -1] {
            m.add(Prim.roundedBox(V3(0.0008, hb * 0.96, 0.0006), radius: 0.0002, bevelSegments: 1, material: crease),
                  Xform(translation: V3(s * (w / 2 + 0.0006), hb / 2, 0)))
        }
        m.add(Prim.roundedBox(V3(0.018, hb * 0.98, 0.0007), radius: 0.0002, bevelSegments: 1, material: paper),
              Xform(translation: V3(w * 0.12, hb / 2, -(d / 2 + 0.0004))))
        // Bottom edge fold.
        m.add(Prim.roundedBox(V3(w * 1.003, 0.003, d * 1.003), radius: 0.0012, bevelSegments: 2, material: crease), Xform(translation: V3(0, 0.0015, 0)))
    }

    /// Shifts a whole model so its lowest point sits at y = 0 and it is centred on X/Z.
    static func grounded(_ m: inout Model) {
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 + shift } }
    }
}
