import simd
import Foundation

// Shared builders for the Aerospace props (craft parts stack on a 1.25 m bus along +Y).

/// Curved slab lying on a surface of revolution `r(y)`: outer face `lift` above it, `thickness` deep,
/// spanning angles a0...a1 (radians, 0 = +Z, increasing toward +X) and heights y0...y1. Hatches, panels,
/// windows and doublers that follow a cone or cylinder. UVs in meters.
func revPatch(radius r: (Float) -> Float, a0: Float, a1: Float, y0: Float, y1: Float, lift: Float, thickness t: Float,
              nu: Int = 8, nv: Int = 4, material: MaterialKey) -> Surface {
    var s = Surface(material: material)
    func P(_ a: Float, _ y: Float, _ off: Float) -> V3 { let R = r(y) + off; return V3(R * sin(a), y, R * cos(a)) }
    func A(_ i: Int) -> Float { a0 + (a1 - a0) * Float(i) / Float(nu) }
    func Y(_ j: Int) -> Float { y0 + (y1 - y0) * Float(j) / Float(nv) }
    for (off, inner) in [(lift, false), (lift - t, true)] {
        let base = UInt32(s.positions.count)
        for j in 0...nv { for i in 0...nu {
            let a = A(i), y = Y(j)
            s.add(P(a, y, off), inner ? V3(-sin(a), 0, -cos(a)) : V3(sin(a), 0, cos(a)), V2(r(y) * a, y))
        } }
        let w = UInt32(nu + 1)
        for j in 0..<nv { for i in 0..<nu {
            let a = base + UInt32(j) * w + UInt32(i), b = a + 1, c = a + w + 1, d = a + w
            if inner { s.quad(a, d, c, b) } else { s.quad(a, b, c, d) }
        } }
    }
    // Rim walls, counter-clockwise seen from outside.
    var loop: [(Float, Float)] = []
    for i in 0...nu { loop.append((A(i), Y(0))) }
    for j in 1...nv { loop.append((A(nu), Y(j))) }
    for i in stride(from: nu - 1, through: 0, by: -1) { loop.append((A(i), Y(nv))) }
    for j in stride(from: nv - 1, through: 0, by: -1) { loop.append((A(0), Y(j))) }
    for k in 0..<(loop.count - 1) {
        let (pa, py) = loop[k], (qa, qy) = loop[k + 1]
        let op = P(pa, py, lift), ip = P(pa, py, lift - t), oq = P(qa, qy, lift), iq = P(qa, qy, lift - t)
        let n = simd_normalize(simd_cross(ip - op, iq - ip))
        let u0 = Float(k) * 0.05
        let i0 = s.add(op, n, V2(u0, 0)), i1 = s.add(ip, n, V2(u0, t)), i2 = s.add(iq, n, V2(u0 + 0.05, t)), i3 = s.add(oq, n, V2(u0 + 0.05, 0))
        s.quad(i0, i1, i2, i3)
    }
    s.computeTangents()
    return s
}

/// Machined stack ring: a short band of radius `r` from y to y + h with chamfered lips and a groove.
func stackRing(radius r: Float, y: Float, height h: Float, proud: Float = 0.008, segments: Int = 64, material: MaterialKey) -> Surface {
    let c: Float = 0.003, R = r + proud
    return Prim.lathe([V2(r - 0.004, y), V2(R - c, y), V2(R, y + c), V2(R, y + h * 0.42), V2(R - 0.003, y + h * 0.46),
                       V2(R - 0.003, y + h * 0.54), V2(R, y + h * 0.58), V2(R, y + h - c), V2(R - c, y + h), V2(r - 0.004, y + h)],
                      segments: segments, seamTile: 0.5, material: material)
}

/// Fastener heads in a circle at height y on a cylinder of radius r (pointing out), or on a flat
/// annulus (pointing up) when `up` is set.
func boltCircle(_ m: inout Model, radius r: Float, y: Float, count: Int, phase: Float = 0, up: Bool = false,
                size: Float = 0.006, material: MaterialKey) {
    for k in 0..<count {
        let a = phase + Float(k) / Float(count) * 2 * .pi
        let d = V3(sin(a), 0, cos(a))
        rivet(&m, at: d * r + V3(0, y, 0), normal: up ? .up : d, radius: size, height: size * 0.55, segments: 6, material: material)
    }
}

/// Points along a vertical line on a surface of revolution at angle a.
func meridian(_ r: (Float) -> Float, a: Float, y0: Float, y1: Float, lift: Float, n: Int = 8) -> [V3] {
    (0...n).map { k in let y = y0 + (y1 - y0) * Float(k) / Float(n); return V3(sin(a), 0, cos(a)) * (r(y) + lift) + V3(0, y, 0) }
}

/// Shared fuel tank body for fuel-tank-s/-m/-l: brushed aluminum barrel between painted forward and aft
/// skirts with external stringers, machined stack rings with bolt circles, circumferential and
/// longitudinal weld beads, a fill/drain port with a bolted cap and optional roll-pattern stripes.
func fuelTankLOD(radius R: Float, height H: Float, stripes: Bool, barrel: MaterialKey, skirt: MaterialKey,
                 stripe: MaterialKey, seed: UInt64) -> LODModel {
    var rng = SeededRNG(seed: seed)
    var levels: [Model] = []
    let ringH: Float = 0.05, skirtH: Float = min(0.16, H * 0.12)
    let bodyR = R - 0.012
    for l in 0..<2 {
        var m = Model(name: "fuel-tank")
        let sg = l == 0 ? 64 : 28
        // Stack rings top and bottom.
        m.add(stackRing(radius: bodyR, y: 0, height: ringH, proud: 0.012, segments: sg, material: "metal.steel"))
        m.add(stackRing(radius: bodyR, y: H - ringH, height: ringH, proud: 0.012, segments: sg, material: "metal.steel"))
        // End decks (bulkhead closeouts seen through the rings).
        m.add(Prim.lathe([V2(bodyR - 0.004, 0.002), V2(0, 0.002)].reversed(), segments: sg, material: "metal.aluminum-brushed"))
        // Forward bulkhead dome showing inside the top ring, with a vent fitting.
        var dome: [V2] = [V2(bodyR - 0.004, H - 0.03)]
        for k in 1...6 { let t = Float(k) / 6; dome.append(V2((bodyR - 0.004) * cos(t * .pi / 2), H - 0.03 + 0.022 * sin(t * .pi / 2))) }
        dome[dome.count - 1] = V2(0, H - 0.008)
        m.add(Prim.lathe(dome, segments: sg, seamTile: 1, material: "metal.aluminum-brushed"))
        m.add(Prim.lathe([V2(0.06, H - 0.012), V2(0.06, H - 0.002), V2(0.045, H), V2(0, H)], segments: 16, material: "metal.steel"))
        // Skirts (painted) and barrel (bare brushed aluminum).
        m.add(Prim.lathe([V2(bodyR, ringH), V2(bodyR, ringH + skirtH)], segments: sg, seamTile: 1, material: skirt))
        m.add(Prim.lathe([V2(bodyR, H - ringH - skirtH), V2(bodyR, H - ringH)], segments: sg, seamTile: 1, material: skirt))
        var prof: [V2] = []
        let y0 = ringH + skirtH, y1 = H - ringH - skirtH
        // Weld beads: skirt joints plus circumferential seams every ~0.9 m.
        let seams = max(0, Int(((y1 - y0) / 0.9).rounded(.down)))
        var cuts: [Float] = [y0]
        for k in 1...max(1, seams + 1) where k <= seams { cuts.append(y0 + (y1 - y0) * Float(k) / Float(seams + 1)) }
        cuts.append(y1)
        // Barrel: four gores of mill-finish sheet with slightly different brushing, joined by weld beads.
        for g in 0..<4 {
            let a0 = Float(g) * .pi / 2 + 0.3
            m.add(revPatch(radius: { _ in bodyR }, a0: a0, a1: a0 + .pi / 2, y0: y0, y1: y1, lift: 0, thickness: 0.004,
                           nu: sg / 4, nv: 1, material: g % 2 == 0 ? barrel : "metal.satin-aluminum"))
            m.add(Prim.tube(meridian({ _ in bodyR }, a: a0, y0: y0 + 0.004, y1: y1 - 0.004, lift: 0.0005, n: 2),
                            radii: [0.0045, 0.0045, 0.0045], sides: 6, seamTile: 0.05, material: barrel, capEnd: true))
        }
        for c in cuts {
            // Friction-stir weld land: a brighter machined band either side of the bead.
            m.add(Prim.lathe([V2(bodyR + 0.0006, c - 0.022), V2(bodyR + 0.0006, c + 0.022)], segments: sg, seamTile: 1,
                             material: "metal.machined"))
            m.add(Prim.torus(major: bodyR + 0.0005, minor: 0.0045, segments: sg, sides: 6, material: barrel), Xform(translation: V3(0, c, 0)))
        }
        // Stringers on the skirts.
        let ns = l == 0 ? 32 : 16
        for k in 0..<ns {
            let a = Float(k) / Float(ns) * 2 * .pi
            for (sy0, sy1) in [(ringH, ringH + skirtH), (H - ringH - skirtH, H - ringH)] {
                let half = 0.007 / bodyR
                m.add(revPatch(radius: { _ in bodyR }, a0: a - half, a1: a + half, y0: sy0 + 0.002, y1: sy1 - 0.002, lift: 0.011,
                               thickness: 0.012, nu: 1, nv: 1, material: skirt))
            }
        }
        // Cable raceway: a painted cover running the barrel between the skirts, with clamp bands.
        let ra: Float = 1.1, rw: Float = 0.035 / bodyR
        m.add(revPatch(radius: { _ in bodyR }, a0: ra - rw, a1: ra + rw, y0: ringH + 0.01, y1: H - ringH - 0.01, lift: 0.04,
                       thickness: 0.04, nu: l == 0 ? 3 : 1, nv: 1, material: skirt))
        // Pressurization line beside the raceway, standing off on brackets.
        let la = ra + 0.13
        let line = meridian({ _ in bodyR }, a: la, y0: ringH + 0.02, y1: H - ringH - 0.02, lift: 0.03, n: 2)
        m.add(Prim.tube(line, radii: [0.013, 0.013, 0.013], sides: l == 0 ? 10 : 6, seamTile: 0.1, material: "metal.steel", capEnd: true))
        if l == 0 {
            var cy = y0 + 0.2
            while cy < y1 - 0.1 {
                m.add(revPatch(radius: { _ in bodyR }, a0: ra - rw * 1.5, a1: la + 0.03, y0: cy, y1: cy + 0.025, lift: 0.046,
                               thickness: 0.046, nu: 3, nv: 1, material: "metal.steel"))
                cy += 0.45
            }
        }
        if stripes {
            // Roll pattern: two opposite black quarters on the barrel.
            for q in [0, 2] {
                let a0 = Float(q) * .pi / 2 + .pi / 4
                m.add(revPatch(radius: { _ in bodyR }, a0: a0, a1: a0 + .pi / 2, y0: y0 + 0.01, y1: y1 - 0.01, lift: 0.0012,
                               thickness: 0.001, nu: l == 0 ? 12 : 6, nv: 1, material: stripe))
            }
        }
        // Fill / drain port with a bolted cap near the top.
        let pa: Float = 0.5, py = y1 - 0.12
        let d = V3(sin(pa), 0, cos(pa)), pc = d * bodyR + V3(0, py, 0)
        m.add(Prim.lathe([V2(0.055, -0.01), V2(0.055, 0.012), V2(0.05, 0.016), V2(0.035, 0.016), V2(0.035, 0.04),
                          V2(0.03, 0.045), V2(0, 0.045)], segments: l == 0 ? 20 : 10, seamTile: 0.1, material: "metal.steel"),
              Xform(translation: pc, rotation: facing(d)))
        if l == 0 {
            for k in 0..<6 {
                let t = Float(k) / 6 * 2 * .pi
                let q = facing(d)
                rivet(&m, at: pc + q.act(V3(cos(t) * 0.044, 0.016, sin(t) * 0.044)), normal: d, radius: 0.005, height: 0.004, segments: 6, material: "metal.steel")
            }
            boltCircle(&m, radius: bodyR - 0.03, y: H, count: 24, phase: rng.float(0...0.1), up: true, size: 0.006, material: "metal.steel")
            // Stencil-free story detail: a warning placard plate beside the port.
            m.add(revPatch(radius: { _ in bodyR }, a0: pa + 0.12, a1: pa + 0.26, y0: py - 0.03, y1: py + 0.05, lift: 0.0015, thickness: 0.0015,
                           nu: 2, nv: 1, material: "metal.painted:E8C21C"))
        }
        groundAO(&m, height: 0.12)
        levels.append(m)
    }
    return LODModel(levels: levels, switchDistances: [9])
}
