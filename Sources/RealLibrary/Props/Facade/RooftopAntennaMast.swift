import simd
import Foundation

/// Rooftop antenna mast: architectural facade customizer, Commercial, galvanized telescoping antenna mast on a bolted base plate with guy wires, turnbuckles, dipole array and coax run. Parts: base plate, anchor bolts, gussets, telescoping mast sections, coupling collars, guy wires, turnbuckles, dipole crossarm, coax cable, whip tip.
public struct RooftopAntennaMast: RealAsset {
    public static let id = "rooftop-antenna-mast"
    public static let summary = "Rooftop antenna mast, 0.3 x 6.0 x 0.3 m: galvanized telescoping mast on a bolted plate with guy wires and dipole."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 6.0, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let gal: MaterialKey = "metal.galvanized-aged", gal2: MaterialKey = "metal.galvanized", rust: MaterialKey = "metal.rust-grime", zinc: MaterialKey = "metal.screw-zinc", alu: MaterialKey = "metal.aluminum", coax: MaterialKey = "rubber.tubing"
        // Base plate with four anchor bolts (nut, washer, thread stub), rust bleed and corner gussets.
        FA.box(&m, V3(0.3, 0.012, 0.3), V3(0, 0.006, 0), gal, r: 0.002)
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let p = V3(sx * 0.12, 0.012, sz * 0.12)
                m.add(Prim.cylinder(radius: 0.012, height: 0.0025, bevel: 0.0005, segments: 16, bevelSegments: 1, material: zinc), Xform(translation: p))
                m.add(Prim.cylinder(radius: 0.0105, height: 0.011, bevel: 0.0015, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: p + V3(0, 0.0025, 0), rotation: FA.q(rng.float(0...60), FA.Y)))
                m.add(Prim.cylinder(radius: 0.0055, height: 0.012, bevel: 0.0008, segments: 8, bevelSegments: 1, material: zinc), Xform(translation: p + V3(0, 0.0135, 0)))
                m.add(Prim.cylinder(radius: 0.017, height: 0.0006, bevel: 0.0002, segments: 14, bevelSegments: 1, material: rust), Xform(translation: V3(p.x, 0.012, p.z)))
            }
        }
        for i in 0..<4 {
            let a = Float(i) * 90
            let tri: [V2] = [V2(0.040, 0.012), V2(0.100, 0.012), V2(0.100, 0.0125), V2(0.040, 0.20)]
            m.add(Prim.extrude(tri, depth: 0.007, bevel: 0.0009, bevelSegments: 1, material: gal), Xform(rotation: FA.q(a, FA.Y)))
        }
        // Lower stand pipe: welded to a flange ring with a weld bead and a drain hole mark.
        m.add(Prim.lathe([V2(0.0, 0.012), V2(0.062, 0.012), V2(0.062, 0.020), V2(0.050, 0.026), V2(0.046, 0.034), V2(0.0, 0.034)], segments: 28, seamTile: 0.2, material: gal2))
        m.add(Prim.torus(major: 0.046, minor: 0.0035, segments: 28, sides: 6, material: "metal.solder"), Xform(translation: V3(0, 0.034, 0)))
        // Telescoping sections with swaged step collars and set-screw clamps.
        let secs: [(y0: Float, y1: Float, r: Float)] = [(0.03, 2.1, 0.0480), (2.0, 4.1, 0.0400), (4.0, 5.35, 0.0320)]
        for (i, s) in secs.enumerated() {
            m.add(Prim.lathe([V2(0.0, s.y0), V2(s.r, s.y0), V2(s.r, s.y1 - 0.004), V2(s.r - 0.002, s.y1), V2(0.0, s.y1)], segments: 24, seamTile: 0.25, material: i == 0 ? gal : gal2))
            if i < 2 {
                let yc = s.y1 - 0.12
                let rc = s.r + 0.012
                m.add(Prim.lathe([V2(s.r, yc - 0.06), V2(rc, yc - 0.055), V2(rc + 0.002, yc - 0.045), V2(rc + 0.002, yc + 0.075), V2(rc, yc + 0.085), V2(s.r, yc + 0.09)], segments: 24, seamTile: 0.15, material: gal))
                for k in 0..<2 {
                    let a = Float(k) * 90 + 20 * Float(i)
                    let dir = FA.q(a, FA.Y).act(V3(1, 0, 0))
                    FA.cylX(&m, r: 0.006, h: 0.014, at: V3(dir.x * (rc + 0.001), yc + 0.02, dir.z * (rc + 0.001)), zinc, bevel: 0.001, segments: 6)
                    if k == 0 { _ = dir }
                }
            }
        }
        // Rust streaks at joints and the foot.
        for (i, y) in [Float(0.05), 2.02, 4.02].enumerated() {
            let r = secs[i].r + 0.0008
            m.add(Prim.cylinder(radius: r + (i > 0 ? 0.0004 : 0), height: i == 0 ? 0.30 : 0.10, bevel: 0.0002, segments: 20, bevelSegments: 1, material: rust), Xform(translation: V3(0, y, 0)))
        }
        // Guy rings at 3.9 m: split collar with three eye plates, 120 degrees apart.
        let gy: Float = 3.85, gr: Float = 0.0400 + 0.0095
        m.add(Prim.lathe([V2(0.0400, gy - 0.025), V2(gr, gy - 0.022), V2(gr, gy + 0.022), V2(0.0400, gy + 0.025)], segments: 24, seamTile: 0.12, material: gal))
        for k in 0..<3 {
            let a = Float(k) * 120 + 30
            let q = FA.q(a, FA.Y)
            let eye = q.act(V3(gr + 0.012, gy, 0))
            m.add(Prim.torus(major: 0.0075, minor: 0.0018, segments: 14, sides: 6, material: zinc), Xform(translation: eye, rotation: q * FA.q(90, FA.X)))
            FA.box(&m, V3(0.014, 0.005, 0.012), q.act(V3(gr + 0.004, gy, 0)), gal, r: 0.0008, rot: q)
            // Guy: wire from the eye to a turnbuckle, then to a padeye on the base plate.
            let lug = q.act(V3(0.128, 0.0, 0)) + V3(0, 0.0, 0)
            let foot = V3(lug.x, 0.0225, lug.z)
            FA.box(&m, V3(0.024, 0.0035, 0.016), V3(foot.x, 0.0138, foot.z), gal, r: 0.0006, rot: q)
            m.add(Prim.torus(major: 0.0065, minor: 0.0017, segments: 12, sides: 6, material: zinc), Xform(translation: V3(foot.x, 0.0205, foot.z), rotation: q))
            let top = eye + V3(0, -0.004, 0)
            func at(_ t: Float) -> V3 { foot + (top - foot) * t }
            FA.rod(&m, foot, at(0.07), r: 0.0035, gal2, sides: 6)
            // Turnbuckle: body tube with two threaded ends and a cross hole mark.
            FA.rod(&m, at(0.07), at(0.115), r: 0.0085, gal, sides: 8)
            FA.rod(&m, at(0.062), at(0.075), r: 0.0045, "metal.galvanized", sides: 6)
            FA.rod(&m, at(0.113), at(0.125), r: 0.0045, "metal.galvanized", sides: 6)
            let sag = q.act(V3(0.002, 0, 0))
            FA.path(&m, [at(0.125), at(0.35) + sag, at(0.62) + sag * 1.4, at(0.86) + sag, top], r: 0.0045, "metal.galvanized", sides: 6)
            // Wire clamp (two bolts) at the eye.
            FA.box(&m, V3(0.010, 0.012, 0.007), at(0.975), gal, r: 0.0015, rot: q)
        }
        // Dipole crossarm at 4.62 m: boom, mount saddle, two element pairs with insulators and end caps.
        let dy: Float = 4.62
        FA.box(&m, V3(0.040, 0.050, 0.020), V3(0, dy, 0.0320 + 0.010), gal, r: 0.003)
        FA.rod(&m, V3(0, dy, 0.038), V3(0, dy, 0.148), r: 0.0075, alu, sides: 12)
        for (n, z) in [Float(0.09), 0.142].enumerated() {
            FA.rod(&m, V3(-0.138 + Float(n) * 0.014, dy, z), V3(0.138 - Float(n) * 0.014, dy, z), r: 0.0042, alu, sides: 8)
            FA.box(&m, V3(0.018, 0.012, 0.012), V3(0, dy, z), "metal.anodized-black", r: 0.002)
            for sx: Float in [-1, 1] { FA.ball(&m, r: 0.0042, at: V3(sx * (0.138 - Float(n) * 0.014), dy, z), alu) }
        }
        FA.box(&m, V3(0.012, 0.012, 0.012), V3(0, dy, 0.148), "metal.anodized-black", r: 0.002)
        // Coax run: down the mast on three stand-off clips, then a drip loop that ends at the base.
        let cx = V3(0, 0, 0.0)
        var run: [V3] = [V3(0, dy, 0.148)]
        _ = cx
        run += [V3(0, dy - 0.02, 0.09), V3(0.001, 4.5, 0.060), V3(0.004, 4.2, 0.0475), V3(0.004, 3.0, 0.0540), V3(0.004, 2.0, 0.0680), V3(0.004, 1.0, 0.0600), V3(0.003, 0.3, 0.0620), V3(0.001, 0.12, 0.080), V3(-0.04, 0.05, 0.10), V3(-0.07, 0.03, 0.125)]
        m.add(Prim.tube(catmull(run, per: 5), radii: Array(repeating: 0.0042, count: catmull(run, per: 5).count), sides: 8, seamTile: 0.1, material: coax, capEnd: true))
        for (y, z, r0) in [(Float(4.2), Float(0.0475), secs[2].r), (3.0, 0.054, secs[1].r), (1.0, 0.060, secs[0].r), (0.3, 0.062, secs[0].r)] {
            FA.box(&m, V3(0.014, 0.012, z - r0 + 0.004), V3(0.004, y, (z + r0) / 2 - 0.002), zinc, r: 0.0015)
            m.add(Prim.torus(major: 0.0055, minor: 0.0013, segments: 10, sides: 5, material: zinc), Xform(translation: V3(0.004, y, z), rotation: FA.q(90, FA.X)))
        }
        // Whip tip: tapered aluminum rod above the top section with a base ferrule and a ball tip.
        m.add(Prim.lathe([V2(0.0, 5.33), V2(0.0165, 5.33), V2(0.0165, 5.40), V2(0.0085, 5.43), V2(0.0045, 5.50), V2(0.0035, 5.95), V2(0.0028, 5.985), V2(0.0, 5.995)], segments: 14, seamTile: 0.2, material: alu))
        m.add(Prim.cylinder(radius: 0.009, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: zinc), Xform(translation: V3(0, 5.28, 0)))
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m)
        return LODModel(m)
    }
}
