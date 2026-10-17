import simd
import Foundation

/// Gothic Revival pointed-arch doorway, 1.2 x 2.9 m. Equilateral arch (radius equals span, centres on the
/// springing line) in two orders of limestone: a stepped-chamfer inner order and a plain outer order, each cut
/// into joggled voussoirs that meet at a vertical crown joint, over coursed ashlar jambs with a chamfered
/// reveal and chamfered plinths. A roll-and-drip hood mould (label) runs over the arch and ends in carved
/// label stops with leaf bosses. The leaf is vertical oak planks with V-joints clipped to the arch, three
/// iron strap hinges with trefoil ends and clenched nails, a rose-plated ring pull and a lock plate.
public struct GothicPointedArchDoor: RealAsset {
    public static let id = "gothic-pointed-arch-door"
    public static let summary = "Gothic Revival pointed-arch door, 1.2 x 2.9 m: oak plank leaf, strap hinges, voussoir surround, hood mould with label stops."
    public static let tags = ["prop", "architecture", "facade", "door", "stone", "wood", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 2.5)

    /// Clear span of the opening (m); arch radius equals the span.
    public var span: Float = 0.8
    /// Stone of the surround.
    public var stone: MaterialKey = "stone.limestone"
    /// Soot-darkened stone for the lower courses, plinths and hood mould.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    public var oak: MaterialKey = "wood.oak:5B3F28"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = span / 2, R0 = span                 // opening half-span, intrados radius
        let spring: Float = 1.984
        let o1: Float = 0.07, o2: Float = 0.07, hood: Float = 0.06    // order widths
        let R1 = R0 + o1, R2 = R1 + o2, R3 = R2 + hood
        let z1: Float = 0.15, z2: Float = 0.19                         // front planes of the inner and outer orders

        // Arch geometry: right arc centre (-hw, spring), left arc centre (+hw, spring); apex where x = 0.
        func amax(_ R: Float) -> Float { acos(hw / R) }
        func arcPoint(_ e: Float, _ R: Float, _ a: Float) -> V2 { V2(e * (-hw + R * cos(a)), spring + R * sin(a)) }
        /// One voussoir: annular sector from fraction t0 to t1 of the arc, with a 4 mm mortar joint.
        func voussoir(_ e: Float, _ Ri: Float, _ Ro: Float, _ t0: Float, _ t1: Float, z0: Float, z1: Float, _ mat: MaterialKey) {
            let j0: Float = t0 == 0 ? 0 : 0.004 / Ro, j1: Float = t1 == 1 ? 0 : 0.004 / Ro
            var pts: [V2] = []
            let n = 3
            for k in 0...n {
                let t = t0 + (t1 - t0) * Float(k) / Float(n)
                let tt = min(max(t, t0 + j0 / amax(Ro)), t1 - j1 / amax(Ro))
                pts.append(arcPoint(e, Ro, tt * amax(Ro)))
            }
            for k in 0...n {
                let t = t1 - (t1 - t0) * Float(k) / Float(n)
                let tt = min(max(t, t0 + j0 / amax(Ri)), t1 - j1 / amax(Ri))
                pts.append(arcPoint(e, Ri, tt * amax(Ri)))
            }
            m.add(Prim.extrude(Shape2D.deduped(pts), depth: z1 - z0, bevel: 0.0025, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, 0, (z0 + z1) / 2)))
        }
        // Inner order: three-step chamfer. Outer order: plain, with offset joints.
        let steps: [(Float, Float, Float)] = [(R0, R0 + 0.022, 0.1), (R0 + 0.022, R0 + 0.046, 0.125), (R0 + 0.046, R1, z1)]
        for e: Float in [-1, 1] {
            for (i, st) in steps.enumerated() {
                for k in 0..<5 {
                    let mat: MaterialKey = (k + i + (e > 0 ? 1 : 0)) % 4 == 0 ? sooted : stone
                    voussoir(e, st.0, st.1, Float(k) / 5, Float(k + 1) / 5, z0: 0, z1: st.2, mat)
                }
            }
            for k in 0..<6 {
                let t0 = (Float(k) + (k == 0 ? 0 : 0.35)) / 6, t1 = k == 5 ? 1 : (Float(k + 1) + 0.35) / 6
                voussoir(e, R1, R2, t0, t1, z0: 0, z1: z2, k == 2 ? sooted : stone)
            }
        }
        // Hood mould: roll with an undercut drip, over the arch and down to the label stops.
        let stopY = spring - 0.28
        var path: [V3] = []
        let rm = (R2 + R3) / 2
        path.append(V3(-hw + rm, stopY, z2))
        for k in 0...24 {
            let a = Float(k) / 24 * amax(rm)
            path.append(V3(-hw + rm * cos(a), spring + rm * sin(a), z2))
        }
        for k in (0...23).reversed() {
            let a = Float(k) / 24 * amax(rm)
            path.append(V3(hw - rm * cos(a), spring + rm * sin(a), z2))
        }
        path.append(V3(hw - rm, stopY, z2))
        let label: [V2] = [V2(0, -0.03), V2(0.034, -0.03), V2(0.048, -0.022), V2(0.056, -0.006), V2(0.056, 0.006), V2(0.048, 0.022),
                           V2(0.034, 0.03), V2(0.026, 0.03), V2(0.026, 0.016), V2(0, 0.016)]
        m.add(Prim.sweep(label, along: path, up: V3(0, 0, 1), caps: true, grainAlongPath: true, material: sooted))
        // Label stops: carved block with a four-leaf boss.
        for e: Float in [-1, 1] {
            let x = e * (rm - hw - 0.03)
            FA.box(&m, V3(0.1, 0.13, 0.06), V3(x, stopY - 0.05, z2 + 0.03), sooted, r: 0.006)
            FC.bead(&m, r: 0.02, at: V3(x, stopY - 0.05, z2 + 0.03), stone, sub: 4)
            for q in 0..<4 {
                let a = Float(q) * .pi / 2 + .pi / 4
                FC.bead(&m, r: 0.009, at: V3(x + cos(a) * 0.04, stopY - 0.05 + sin(a) * 0.04, z2 + 0.032), stone)
            }
        }

        // Ashlar jambs: coursed blocks, inner order with a true 45 degree chamfer.
        func jamb(_ e: Float, xIn: Float, xOut: Float, y: Float, h: Float, zf: Float, chamfer: Float, _ mat: MaterialKey) {
            var p: [V2] = [V2(xIn, 0), V2(xOut, 0), V2(xOut, zf), V2(xIn + chamfer, zf)]
            if chamfer > 0 { p.append(V2(xIn, zf - chamfer)) }
            p = p.map { V2($0.x * e, $0.y) }
            m.add(Prim.extrude(p, depth: h - 0.004, bevel: 0.002, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, y + h / 2, 0), rotation: FA.q(90, FA.X)))
        }
        let base: Float = 0.3
        let nCourse = 6
        let ch = (spring - base) / Float(nCourse)
        for e: Float in [-1, 1] {
            // Plinth: sloped-top block.
            FA.run(&m, [V2(0, 0), V2(z2 + 0.02, 0), V2(z2 + 0.02, base - 0.07), V2(z2 - 0.01, base), V2(0, base)], length: 0.2,
                   at: V3(e * (hw + 0.1), 0, 0), sooted, bevel: 0.003)
            for c in 0..<nCourse {
                let y = base + Float(c) * ch
                let dirty: MaterialKey = c < 3 || (c == 4 && e < 0) ? sooted : stone
                jamb(e, xIn: hw, xOut: hw + o1, y: y, h: ch, zf: z1, chamfer: 0.03, c == 3 && e > 0 ? stone : dirty)
                jamb(e, xIn: hw + o1, xOut: hw + o1 + o2, y: y, h: ch, zf: z2, chamfer: 0, c == 1 && e > 0 ? stone : dirty)
            }
        }
        // Worn threshold step.
        FA.box(&m, V3(2 * hw + 0.06, 0.05, z2 + 0.05), V3(0, 0.025, (z2 + 0.05) / 2), sooted, r: 0.006)

        // Plank leaf clipped to the arch: seven planks with chamfered edges (V-joints).
        let dw = span - 0.02, dh = dw / 2, Rd = dw
        func top(_ x: Float) -> Float { spring + sqrt(max(0, Rd * Rd - (abs(x) + dh) * (abs(x) + dh))) }
        let np = 7
        let pwid = dw / Float(np)
        let zb: Float = 0.052, zt: Float = 0.044
        for i in 0..<np {
            let xa = -dw / 2 + Float(i) * pwid, xb = xa + pwid - 0.002
            let yb: Float = 0.052 + rng.float(0...0.003)
            var p: [V2] = [V2(xa, yb), V2(xb, yb)]
            for k in stride(from: 4, through: 0, by: -1) {
                let x = xa + (xb - xa) * Float(k) / 4
                p.append(V2(x, top(x)))
            }
            let mat: MaterialKey = i == 5 ? "wood.oak:7A5C40" : (i == 2 ? "wood.oak:4A3322" : oak)
            m.add(Prim.extrude(p, depth: zt, bevel: 0.0035, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, zb + zt / 2)))
        }
        let zfront = zb + zt
        // Strap hinges from the hinge side (left), trefoil ends, pintles at the jamb.
        for y in [0.45, 1.2, 1.86] as [Float] {
            FJ.strapHinge(&m, from: -dw / 2 + 0.01, to: dw / 2 - 0.12, y: y, z: zfront, width: 0.07, thick: 0.008, iron, nails: 6, rng: &rng)
            let tx = dw / 2 - 0.12
            for (dx, dy) in [(0.016, 0.0), (-0.002, 0.016), (-0.002, -0.016)] as [(Float, Float)] {
                FC.bead(&m, r: 0.012, at: V3(tx + dx, y + dy, zfront + 0.003), iron, sub: 3)
            }
            FA.cylZ(&m, r: 0.008, h: 0.07, at: V3(-dw / 2 - 0.004, y, 0.03), iron, bevel: 0.001, segments: 10)    // pintle
        }
        // Clenched nails: studs at the plank joints between the straps.
        for i in 1..<np {
            let x = -dw / 2 + Float(i) * pwid - 0.001
            for y in [0.8, 1.55] as [Float] { rivet(&m, at: V3(x, y, zfront), normal: FA.Z, radius: 0.0065, segments: 8, material: iron) }
        }
        // Ring pull on a rose plate and a lock plate.
        let rx: Float = 0.2, ry: Float = 1.05
        FA.cylZ(&m, r: 0.042, h: 0.007, at: V3(rx, ry, zfront), "metal.cast-iron", bevel: 0.002, segments: 20)
        FA.cylZ(&m, r: 0.012, h: 0.014, at: V3(rx, ry + 0.032, zfront + 0.002), "metal.cast-iron", bevel: 0.002, segments: 10)
        m.add(Prim.torus(major: 0.05, minor: 0.0065, segments: 28, sides: 8, material: "metal.cast-iron"),
              Xform(translation: V3(rx, ry - 0.02, zfront + 0.02), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.085, 0.2, 0.006), V3(rx, 0.68, zfront + 0.003), iron, r: 0.002)
        for (dx, dy) in [(-0.03, 0.08), (0.03, 0.08), (-0.03, -0.08), (0.03, -0.08)] as [(Float, Float)] {
            rivet(&m, at: V3(rx + dx, 0.68 + dy, zfront + 0.006), normal: FA.Z, radius: 0.0045, segments: 6, material: iron)
        }
        FA.box(&m, V3(0.012, 0.03, 0.004), V3(rx, 0.68, zfront + 0.007), "metal.brass-aged", r: 0.001)                // keyhole escutcheon

        // Damp and moss at the plinths and threshold, rust bleed under the lowest strap.
        var wetRng = rng.fork(9)
        FJ.chips(&m, spots: [V3(0.5, 0.1, 0), V3(-0.5, 0.12, 0), V3(0.3, 0.03, 0), V3(-0.25, 0.03, 0)], face: z2 + 0.02, "stone.granite-moss", rng: &wetRng, each: 3)
        FJ.chips(&m, spots: [V3(-0.1, 0.4, 0), V3(0.2, 0.43, 0), V3(-0.3, 0.38, 0)], face: zfront + 0.0085, "metal.rust", rng: &wetRng, each: 3)
        // Weathering: grey patches on the plank feet and soot-pale patches nowhere else.
        var chipRng = rng.fork(3)
        FJ.chips(&m, spots: [V3(-0.28, 0.14, 0), V3(0.12, 0.1, 0), V3(0.3, 0.2, 0), V3(-0.1, 1.5, 0)], face: zfront, "wood.oak:8E7A62", rng: &chipRng, each: 3)
        groundAO(&m, height: 0.3, floor: 0.7)
        return LODModel(FA.centerZ(m))
    }
}
