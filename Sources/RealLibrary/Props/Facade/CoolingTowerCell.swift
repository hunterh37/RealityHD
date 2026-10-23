import simd
import Foundation

/// Cooling Tower Cell: architectural facade customizer, Commercial, rooftop induced-draft cooling tower cell with louvered faces, fan stack and guard. Parts: concrete basin curb, corner posts, louver fill faces, corrugated upper casing, deck, fan stack, fan guard, fan blades and hub, access door, ladder, inlet pipe and flange, overflow pipe.
public struct CoolingTowerCell: RealAsset {
    public static let id = "cooling-tower-cell"
    public static let summary = "Cooling tower cell, 2.4 x 2.4 x 2.4 m: basin curb, louvered casing, corrugated upper panels, fan stack with guard."
    public static let tags = ["prop", "architecture", "facade", "metal", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 2.4, 2.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let gal: MaterialKey = "metal.galvanized-aged", pnt: MaterialKey = "metal.painted:6E7F86", rust: MaterialKey = "metal.rust", grime: MaterialKey = "metal.rust-grime"
        let iron: MaterialKey = "metal.cast-iron", zinc: MaterialKey = "metal.screw-zinc", conc: MaterialKey = "stone.cast-grey"
        func bolt(_ m: inout Model, _ p: V3, _ n: V3, _ mat: MaterialKey) {
            m.add(Prim.cylinder(radius: 0.007, height: 0.007, bevel: 0.001, segments: 6, bevelSegments: 1, material: mat), Xform(translation: p - n * 0.001, rotation: facing(n)))
        }
        let W: Float = 1.0, yb: Float = 0.30, yTop: Float = 1.85   // half width, basin top, casing top
        // Concrete basin curb with a cap lip, stained splash band and a drain sump crack line.
        FA.box(&m, V3(2.4, yb, 2.4), V3(0, yb / 2, 0), conc, r: 0.008)
        FA.box(&m, V3(2.44, 0.03, 2.44), V3(0, yb + 0.015 - 0.03, 0), conc, r: 0.006)
        FA.box(&m, V3(2.402, 0.05, 0.004), V3(0, 0.03, 1.2), grime, r: 0.001)
        // Corner posts: galvanized square tubes with base plates, anchor bolts and fastener rows.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            let c = V3(sx * W, 0, sz * W)
            FA.box(&m, V3(0.12, yTop - yb, 0.12), V3(c.x, (yTop + yb) / 2, c.z), gal, r: 0.004)
            FA.box(&m, V3(0.22, 0.012, 0.22), V3(c.x, yb + 0.006, c.z), gal, r: 0.003)
            for k in 0..<2 {
                let ox: Float = (k == 0 ? -1 : 1) * 0.085, oz: Float = (k == 0 ? -1 : 1) * 0.085
                m.add(Prim.cylinder(radius: 0.011, height: 0.016, bevel: 0.002, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(c.x + ox, yb + 0.012, c.z + oz)))
            }
            for k in 0..<3 {
                let y = yb + 0.3 + Float(k) * 0.5
                for n in [V3(sx, 0, 0), V3(0, 0, sz)] {
                    bolt(&m, V3(c.x, y, c.z) + n * 0.062, n, zinc)
                }
            }
        } }
        // Louvered fill faces: slanted fiberglass slats between mid rails, drift eliminator frame above.
        let lo: Float = 0.42, hi: Float = 1.42, nSl = 8
        // Slat profile (x out, y up): a slanted parallelogram, 4 mm thick, extruded along the face.
        let slat: [V2] = [V2(0, 0), V2(0.07, 0.085), V2(0.07, 0.089), V2(0, 0.004)]
        // Corrugated skin: trapezoid wave (x across, y out), 12 mm deep, 2 mm skin.
        var wave: [V2] = [], back: [V2] = []
        let pitch: Float = 0.2, nW = 9
        for k in 0..<nW {
            let x0 = -0.9 + Float(k) * pitch
            for (dx, dy) in [(0.0, 0.0), (0.1, 0.03)] as [(Float, Float)] {
                wave.append(V2(x0 + dx, dy)); back.append(V2(x0 + dx, dy - 0.003))
            }
        }
        wave = Shape2D.deduped(wave); back = Shape2D.deduped(back)
        let corr = wave + back.reversed()
        FA.box(&m, V3(1.86, hi - lo + 0.05, 1.86), V3(0, (lo + hi) / 2, 0), "asphalt.worn", r: 0.004)
        for f in 0..<4 {
            let rot = FA.q(Float(f) * 90, FA.Y)
            for k in 0..<nSl {
                let y = lo + 0.01 + Float(k) / Float(nSl) * (hi - lo - 0.05)
                m.add(Prim.extrude(slat, depth: 1.84, bevel: 0.0008, bevelSegments: 1, material: k % 7 == 3 ? gal : pnt),
                      Xform(translation: rot.act(V3(rng.float(-0.003...0.003), y, 0.945)), rotation: rot * FA.q(-90, FA.Y)))
            }
            for s in [-0.9, 0.9] as [Float] { FA.box(&m, V3(0.03, hi - lo + 0.04, 0.03), rot.act(V3(s, (lo + hi) / 2, 0.955)), gal, r: 0.003, rot: rot) }
            for y in [lo - 0.02, hi + 0.02] as [Float] { FA.box(&m, V3(1.9, 0.045, 0.05), rot.act(V3(0, y, 0.965)), gal, r: 0.004, rot: rot) }
            // Upper corrugated casing panel with belt rail and rivet row.
            m.add(Prim.extrude(corr, depth: yTop - hi - 0.08, bevel: 0.0006, bevelSegments: 1, material: pnt),
                  Xform(translation: rot.act(V3(0, (yTop + hi) / 2 - 0.01, 0.975)), rotation: rot * FA.q(90, FA.X)))
            FA.box(&m, V3(1.92, 0.05, 0.04), rot.act(V3(0, yTop - 0.025, 0.985)), gal, r: 0.004, rot: rot)
            rivetRow(&m, along: [rot.act(V3(-0.9, hi + 0.045, 1.0)), rot.act(V3(0.9, hi + 0.045, 1.0))], spacing: 0.3, normal: { _ in rot.act(V3(0, 0, 1)) }, radius: 0.0045, material: zinc)
        }
        // Access door on the front louver zone with hinges, latch and a rust drip streak.
        FA.box(&m, V3(0.6, 0.85, 0.03), V3(0.0, 0.84, 1.03), gal, r: 0.005)
        FA.box(&m, V3(0.52, 0.77, 0.012), V3(0.0, 0.84, 1.048), pnt, r: 0.003)
        for y in [0.55, 1.15] as [Float] { FA.cylZ(&m, r: 0.012, h: 0.05, at: V3(-0.31, y, 1.03), iron, bevel: 0.002, segments: 10) }
        FA.box(&m, V3(0.04, 0.16, 0.012), V3(0.22, 0.84, 1.058), iron, r: 0.004)
        FA.box(&m, V3(0.03, 0.30, 0.004), V3(-0.28, 0.45, 1.052), grime, r: 0.001)
        // Deck, fan stack (venturi cone), guard rods and rings, hub and blades.
        FA.box(&m, V3(2.18, 0.06, 2.18), V3(0, yTop + 0.03, 0), gal, r: 0.005)
        FA.box(&m, V3(2.24, 0.025, 2.24), V3(0, yTop + 0.0125, 0), pnt, r: 0.004)
        let yS = yTop + 0.06
        let stack: [V2] = [V2(0.80, yS), V2(0.80, yS + 0.02), V2(0.74, yS + 0.14), V2(0.64, yS + 0.34), V2(0.62, yS + 0.46), V2(0.60, yS + 0.455), V2(0.62, yS + 0.34), V2(0.72, yS + 0.14), V2(0.78, yS + 0.02), V2(0.78, yS)]
        m.add(Prim.lathe(stack, segments: 32, seamTile: 0.4, material: pnt))
        m.add(Prim.torus(major: 0.62, minor: 0.014, segments: 32, sides: 4, material: gal), Xform(translation: V3(0, yS + 0.46, 0)))
        for i in 0..<8 {
            let a = Float(i) / 8 * 360
            bolt(&m, FA.q(a, FA.Y).act(V3(0.775, yS + 0.04, 0)), FA.q(a, FA.Y).act(V3(1, 0, 0)), zinc)
        }
        let yG = yS + 0.48
        for i in 0..<8 {
            let a = Float(i) / 8 * 360
            FA.rod(&m, FA.q(a, FA.Y).act(V3(0.05, yG + 0.012, 0)), FA.q(a, FA.Y).act(V3(0.62, yG + 0.012, 0)), r: 0.0045, gal, sides: 5)
        }
        for r in [0.12, 0.28, 0.45] as [Float] { m.add(Prim.torus(major: r, minor: 0.005, segments: 24, sides: 4, material: gal), Xform(translation: V3(0, yG + 0.012, 0))) }
        // Fan below the guard: hub, 6 twisted blades, drive shaft and motor.
        m.add(Prim.cylinder(radius: 0.07, height: 0.09, bevel: 0.01, segments: 20, bevelSegments: 2, material: iron), Xform(translation: V3(0, yG - 0.12, 0)))
        for i in 0..<5 {
            let a = Float(i) / 5 * 360
            FA.box(&m, V3(0.50, 0.006, 0.10), FA.q(a, FA.Y).act(V3(0.32, yG - 0.08, 0)), pnt, r: 0.002, rot: FA.q(a, FA.Y) * FA.q(14, V3(1, 0, 0)))
        }
        m.add(Prim.cylinder(radius: 0.012, height: 0.12, bevel: 0.002, segments: 10, bevelSegments: 1, material: zinc), Xform(translation: V3(0, yG - 0.20, 0)))
        // Inlet pipe with flange and valve along the left side, overflow pipe, and a side ladder.
        let py: Float = 0.62
        FA.path(&m, [V3(-1.24, 0.12, -0.5), V3(-1.24, py, -0.5), V3(-1.1, py, -0.5)], r: 0.055, iron, sides: 14)
        FA.cylX(&m, r: 0.085, h: 0.02, at: V3(-1.13, py, -0.5), iron, bevel: 0.003, segments: 16)
        FA.cylX(&m, r: 0.085, h: 0.02, at: V3(-1.24 + 0.0, 0.2, -0.5), iron, bevel: 0.003, segments: 16)
        for i in 0..<8 { let a = Float(i) / 8 * 2 * .pi
            m.add(Prim.cylinder(radius: 0.008, height: 0.016, bevel: 0.002, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(-1.145, py + 0.07 * cos(a), -0.5 + 0.07 * sin(a)), rotation: FA.q(90, FA.Z))) }
        FA.cylX(&m, r: 0.016, h: 0.1, at: V3(-1.24, py + 0.0, -0.5), rust, bevel: 0.002, segments: 10)
        FA.path(&m, [V3(1.14, 0.16, 0.5), V3(1.14, 0.30, 0.5), V3(1.14, 0.30, 0.64)], r: 0.032, gal, sides: 10)
        for sz in [-1, 1] as [Float] { FA.rod(&m, V3(1.1, 0.4, sz * 0.2 - 0.6), V3(1.1, yTop + 0.1, sz * 0.2 - 0.6), r: 0.016, gal, sides: 8) }
        for k in 0..<12 { FA.rod(&m, V3(1.1, 0.5 + Float(k) * 0.12, -0.8), V3(1.1, 0.5 + Float(k) * 0.12, -0.4), r: 0.011, k == 5 ? rust : gal, sides: 6) }
        // Debris and rust bloom at the curb.
        for _ in 0..<1 {
            let a = rng.float(0...(2 * .pi))
            m.add(Prim.superellipsoid(V3(0.05, 0.003, 0.03), exponent: 2, subdivisions: 4, material: "wood.weathered"), Xform(translation: V3(0.5 * cos(a), yTop + 0.03 + 0.012, 0.5 * sin(a)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
