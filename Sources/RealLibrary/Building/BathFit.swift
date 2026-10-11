import simd
import Foundation

/// Bathroom fixture helpers shared by the floor planning pack (toilet, bidet, sinks, tubs).
public enum BathFit {
    /// "D" plan outline for toilet bowls, seats and lids: straight sides, a squared rear with corner
    /// radius `rr`, and a superellipse front reaching `front`. Plan coordinates (x, -z) so it feeds
    /// `Prim.ring`; counter-clockwise from +Y. Point count is constant for a given `nFront`.
    public static func dOutline(hw: Float, front: Float, rear: Float, rr: Float, exponent: Float = 2.4, nFront: Int = 16) -> [V2] {
        let r = max(rr, 0.001)
        let zs = rear + r + (front - rear) * 0.22   // where the straight sides end
        var pts: [V2] = []
        pts.append(V2(hw, -zs))
        for i in 0...4 {
            let a = Float(i) / 4 * .pi / 2
            pts.append(V2(hw - r + r * cos(a), -(rear + r - r * sin(a))))
        }
        for i in 0...4 {
            let a = Float(i) / 4 * .pi / 2
            pts.append(V2(-hw + r - r * sin(a), -(rear + r - r * cos(a))))
        }
        pts.append(V2(-hw, -zs))
        // Front: half superellipse from the left side round to the right side.
        let b = front - zs
        for i in 1..<(2 * nFront) {
            let t = Float(i) / Float(2 * nFront) * .pi
            let cx = -cos(t), sz = sin(t)
            let px = (cx < 0 ? -1 : 1) * pow(abs(cx), 2 / exponent) * hw
            let pz = pow(sz, 2 / exponent) * b
            pts.append(V2(px, -(zs + pz)))
        }
        return pts
    }

    /// Deck-mounted centerset or widespread faucet, deck at `at.y`, spout reaching +Z. `spread` is the handle
    /// spacing center to center (0 for a single lever at the spout base), `reach` the spout length.
    public static func faucet(_ m: inout Model, at o: V3, finish: MaterialKey = "metal.chrome", spread: Float = 0.1,
                              reach: Float = 0.11, height: Float = 0.085, hi: Bool = true) {
        let seg = hi ? 20 : 10
        // Escutcheon and spout body.
        m.add(Prim.lathe([V2(0.001, 0), V2(0.026, 0), V2(0.026, 0.0025), V2(0.021, 0.006), V2(0.017, 0.016), V2(0.016, 0.022), V2(0.001, 0.022)],
                         segments: seg, seamTile: 0.05, material: finish), Xform(translation: o))
        let path = catmull([V3(0, 0.02, 0), V3(0, height * 0.7, 0.002), V3(0, height + 0.006, reach * 0.18), V3(0, height, reach * 0.62),
                            V3(0, height - 0.012, reach)], per: hi ? 5 : 2).map { $0 + o }
        let n = path.count
        m.add(Prim.tube(path, radii: (0..<n).map { i in 0.0115 - 0.0018 * Float(i) / Float(n - 1) }, sides: hi ? 14 : 8, seamTile: 0.04, material: finish))
        // Aerator ring at the tip.
        m.add(Prim.cylinder(radius: 0.0108, height: 0.012, bevel: 0.0015, segments: hi ? 14 : 8, material: finish),
              Xform(translation: path[n - 1] + V3(0, -0.009, 0)))
        // Handles.
        let hs: [Float] = spread > 0 ? [-spread / 2, spread / 2] : [0.03]
        for hx in hs {
            let base = V3(hx, 0, 0) + o
            m.add(Prim.lathe([V2(0.001, 0), V2(0.0215, 0), V2(0.0215, 0.002), V2(0.017, 0.007), V2(0.0115, 0.02), V2(0.001, 0.02)],
                             segments: seg, seamTile: 0.05, material: finish), Xform(translation: base))
            let lever = catmull([base + V3(0, 0.018, 0), base + V3(hx < 0 || spread == 0 ? -0.004 : 0.004, 0.04, 0.0), base + V3(hx < 0 || spread == 0 ? -0.03 : 0.03, 0.052, 0.0), base + V3(hx < 0 || spread == 0 ? -0.058 : 0.058, 0.052, 0.0)], per: hi ? 4 : 2)
            m.add(Prim.tube(lever, radii: lever.indices.map { i in i < lever.count - 2 ? Float(0.0058) : Float(0.0072) }, sides: hi ? 10 : 6, seamTile: 0.03, material: finish))
        }
    }

    /// Undermount oval basin seen through a counter hole: lip just inside the hole at `topY`, coved wall to
    /// `topY - depth`, chrome drain and a dark overflow slot at the rear wall. `size` is the hole (x, z).
    public static func undermountBasin(_ m: inout Model, center c: V3, size: V2, topY: Float, depth: Float = 0.15,
                                       radius: Float = 0.15, hi: Bool = true, material: MaterialKey = "ceramic.vitreous") {
        let seg = hi ? 5 : 3
        func ring(_ w: Float, _ d: Float, _ r: Float, _ y: Float) -> [V3] {
            Prim.ring(Shape2D.roundedRect(w, d, radius: min(r, min(w, d) / 2 - 0.001), segments: seg), y: y, offset: V3(c.x, 0, c.z))
        }
        let rows: [[V3]] = [ring(size.x - 0.003, size.y - 0.003, radius, topY - 0.0005), ring(size.x - 0.012, size.y - 0.012, radius, topY - 0.03),
                            ring(size.x - 0.045, size.y - 0.045, radius - 0.02, topY - depth * 0.55), ring(size.x - 0.12, size.y - 0.1, radius - 0.06, topY - depth * 0.92),
                            ring(size.x - 0.16, size.y - 0.13, radius - 0.08, topY - depth)]
        m.add(Prim.loft(rows, capEnd: true, material: material))
        let dc = V3(c.x, topY - depth, c.z + 0.01)
        m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.024, 0.0005), V2(0.026, 0.002), V2(0.022, 0.0042), V2(0.001, 0.0042)], segments: hi ? 20 : 10, seamTile: 0.05, material: "metal.chrome"), Xform(translation: dc))
        m.add(Prim.lathe([V2(0.001, 0.0042), V2(0.016, 0.0042), V2(0.017, 0.0062), V2(0.001, 0.0068)], segments: hi ? 16 : 8, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
        m.add(Prim.roundedBox(V3(0.03, 0.012, 0.003), radius: 0.0012, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(c.x, topY - 0.035, c.z - (size.y - 0.012) / 2 + 0.006), rotation: simd_quatf(degrees: -10, axis: V3(1, 0, 0))))
    }

    /// Stone vanity top with several rounded-rect basin cutouts (`KitchenFit.counterSlab` takes one). Same
    /// edge profile; top and bottom faces are keyhole-triangulated so the stone stays one piece. Top at y =
    /// `thickness`, centered on X/Z. Hole centers are in slab-local (x, z).
    public static func vanityTop(width: Float, depth: Float, thickness th: Float, ease: Float = 0.003, corner: Float = 0.004,
                                 holes: [(center: V2, size: V2, radius: Float)], material: MaterialKey) -> Surface {
        var s = KitchenFit.counterSlab(width: width, depth: depth, thickness: th, ease: ease, corner: corner, hole: nil, material: material)
        let n = 4
        let outerTop = KitchenFit.rrect(center: .zero, size: V2(width - 2 * ease, depth - 2 * ease), radius: max(0.0005, corner - ease), n: n)
        s.indices.removeLast(2 * outerTop.count * 3)
        let eb = ease * 0.5
        let he = min(0.002, ease)
        let topOuter = outerTop.map { $0.p }
        let botOuter = outerTop.map { $0.p + $0.n * (ease - eb) }
        // Keyhole polygon builder: outer ring (CCW) plus holes (CW) bridged to the rear corners.
        func face(outer: [V2], holeRings: [[V2]], y: Float, up: Bool) {
            var poly: [V2] = outer
            // Rear corners of the outer ring: the points with the most negative z, left and right.
            for h in holeRings.indices {
                let ring = holeRings[h]
                let cx = ring.map(\.x).reduce(0, +) / Float(ring.count)
                // Bridge to the outer vertex nearest the rear corner on the hole's side.
                let target = V2(cx < 0 ? -9 : 9, -9)
                let hv = ring.indices.min { simd_distance_squared(ring[$0], target) < simd_distance_squared(ring[$1], target) }!
                let oiOuter = outer.indices.filter { outer[$0].y < 0 }.min { simd_distance_squared(outer[$0], target) < simd_distance_squared(outer[$1], target) }!
                let oi = poly.firstIndex { $0 == outer[oiOuter] }!
                var hole: [V2] = []
                for k in 0...ring.count { hole.append(ring[(hv + ring.count - k) % ring.count]) }   // clockwise, closed
                poly.insert(contentsOf: hole + [poly[oi]], at: oi + 1)
            }
            let nn = V3(0, up ? 1 : -1, 0)
            let ids = poly.map { s.add(V3($0.x, y, $0.y), nn, $0) }
            // Ear clipping runs in (x, -z) so counter-clockwise means up.
            let tris = Shape2D.triangulate(poly.map { V2($0.x, -$0.y) })
            var k = 0
            while k + 2 < tris.count {
                let a = ids[Int(tris[k])], b = ids[Int(tris[k + 1])], c = ids[Int(tris[k + 2])]
                if up { s.tri(a, b, c) } else { s.tri(a, c, b) }
                k += 3
            }
        }
        let topHoles = holes.map { h in KitchenFit.rrect(center: h.center, size: h.size + V2(2 * he, 2 * he), radius: h.radius + he, n: n).map { $0.p } }
        let botHoles = holes.map { h in KitchenFit.rrect(center: h.center, size: h.size, radius: h.radius, n: n).map { $0.p } }
        face(outer: topOuter, holeRings: topHoles, y: th, up: true)
        face(outer: botOuter, holeRings: botHoles, y: 0, up: false)
        // Hole walls with an eased top lip, normals toward the hole center.
        for h in holes {
            let ringAt: (Float, Float) -> [V3] = { grow, y in
                KitchenFit.rrect(center: h.center, size: h.size + V2(2 * grow, 2 * grow), radius: h.radius + grow, n: n).map { V3($0.p.x, y, $0.p.y) }
            }
            let wall = Prim.loft([ringAt(0, 0), ringAt(0, th - he), ringAt(he * 0.3, th - he * 0.35), ringAt(he, th)], material: material).flipped()
            s.append(wall)
        }
        s.computeTangents()
        return s
    }

    /// Leaner five-piece shaker front than `KitchenFit.shakerFront` (one bevel segment, plain recessed panel)
    /// for pieces with many fronts. Front face at z = c.z facing +Z, centered on X/Y.
    public static func shakerLean(_ m: inout Model, width w: Float, height h: Float, t: Float = 0.019, frame: Float = 0.06,
                                  at c: V3, material: MaterialKey, bottomRail: MaterialKey? = nil) {
        let fz = c.z - t / 2
        let edge: Float = 0.0025
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(frame, h, t), radius: edge, bevelSegments: 1, material: material), Xform(translation: V3(c.x + sx * (w / 2 - frame / 2), c.y, fz)))
        }
        for sy: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(w - 2 * frame - 0.0006, frame, t), radius: edge, bevelSegments: 1, material: sy < 0 ? (bottomRail ?? material) : material),
                  Xform(translation: V3(c.x, c.y + sy * (h / 2 - frame / 2), fz)))
        }
        m.add(Prim.roundedBox(V3(w - 2 * frame + 0.004, h - 2 * frame + 0.004, 0.006), radius: 0.001, bevelSegments: 1, material: material),
              Xform(translation: V3(c.x, c.y, c.z - 0.012)))
    }

    /// Lean bar pull (8-sided bar, 6-sided posts), along +X, posts toward -Z to a mounting face at z = 0.
    public static func pull(length: Float = 0.128, standoff: Float = 0.022, radius: Float = 0.0055, overhang: Float = 0.02, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let half = length / 2
        let bar = Prim.lathe([V2(0.001, 0), V2(radius * 0.8, 0), V2(radius, 0.002), V2(radius, length + 2 * overhang - 0.002), V2(radius * 0.8, length + 2 * overhang), V2(0.001, length + 2 * overhang)],
                             segments: 8, seamTile: 0.05, material: material)
        s.append(bar, Xform(translation: V3(-half - overhang, 0, standoff), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        for x in [-half, half] {
            s.append(Prim.lathe([V2(0.001, 0), V2(radius * 0.85, 0), V2(radius * 0.85, standoff), V2(0.001, standoff)], segments: 6, seamTile: 0.05, material: material),
                     Xform(translation: V3(x, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        return s
    }

    /// Wall-mounted shower arm and round head. `wall` is the point on the wall surface (wall faces +Z); the arm
    /// leaves the wall, rises and ends in a head tilted `tilt` degrees down. Head center ends about
    /// `reach` m from the wall.
    public static func showerHead(_ m: inout Model, wall w: V3, reach: Float = 0.2, headRadius: Float = 0.085, tilt: Float = 18,
                                  finish: MaterialKey = "metal.chrome", hi: Bool = true) {
        let seg = hi ? 24 : 12
        m.add(Prim.lathe([V2(0.001, 0), V2(0.036, 0), V2(0.036, 0.003), V2(0.03, 0.009), V2(0.017, 0.016), V2(0.001, 0.016)], segments: seg, seamTile: 0.05, material: finish),
              Xform(translation: w, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let arm = catmull([w + V3(0, 0, 0.012), w + V3(0, 0, 0.07), w + V3(0, 0.012, reach * 0.62), w + V3(0, 0.03, reach)], per: hi ? 5 : 2)
        m.add(Prim.tube(arm, radii: Array(repeating: 0.0095, count: arm.count), sides: hi ? 14 : 8, seamTile: 0.05, material: finish))
        let c = arm[arm.count - 1]
        m.add(Prim.lathe([V2(0.001, 0), V2(0.016, 0), V2(0.018, 0.012), V2(0.012, 0.024), V2(0.001, 0.026)], segments: hi ? 16 : 8, seamTile: 0.05, material: finish),
              Xform(translation: c + V3(0, -0.012, 0)))
        // Head: slightly domed disc facing down and out.
        let q = simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))
        let h = headRadius
        m.add(Prim.lathe([V2(0.001, 0), V2(h - 0.004, 0), V2(h, 0.003), V2(h, 0.011), V2(h - 0.012, 0.018), V2(0.03, 0.021), V2(0.001, 0.021)], segments: seg, seamTile: 0.05, material: finish),
              Xform(translation: c + V3(0, -0.03, 0), rotation: q))
        // Silicone nozzle rings on the face.
        if hi {
            for r in [h * 0.35, h * 0.62, h * 0.85] {
                m.add(Prim.lathe([V2(r - 0.003, -0.0004), V2(r + 0.003, -0.0004), V2(r + 0.003, 0.0006), V2(r - 0.003, 0.0006)], segments: 32, seamTile: 0.05, material: "rubber.silicone:262626"),
                      Xform(translation: c + V3(0, -0.03, 0), rotation: q))
            }
        }
    }

    /// Round valve escutcheon with a lever handle on a wall facing +Z. `at` is the point on the wall.
    public static func valveTrim(_ m: inout Model, at w: V3, finish: MaterialKey = "metal.chrome", hi: Bool = true) {
        let seg = hi ? 24 : 10
        m.add(Prim.lathe([V2(0.001, 0), V2(0.058, 0), V2(0.058, 0.003), V2(0.05, 0.009), V2(0.034, 0.014), V2(0.001, 0.014)], segments: seg, seamTile: 0.05, material: finish),
              Xform(translation: w, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.lathe([V2(0.001, 0), V2(0.018, 0), V2(0.016, 0.018), V2(0.012, 0.028), V2(0.001, 0.029)], segments: hi ? 16 : 8, seamTile: 0.05, material: finish),
              Xform(translation: w + V3(0, 0, 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let lever = catmull([w + V3(0, 0, 0.04), w + V3(0.01, 0.002, 0.05), w + V3(0.04, 0.002, 0.058), w + V3(0.065, 0, 0.058)], per: hi ? 4 : 2)
        m.add(Prim.tube(lever, radii: lever.indices.map { i in i < lever.count - 2 ? Float(0.0065) : Float(0.0085) }, sides: hi ? 12 : 6, seamTile: 0.03, material: finish))
    }
}
