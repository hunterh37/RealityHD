import simd
import Foundation

/// Sloped glazing atrium bay: contemporary lean-to rooflight, 4.0 m wide on a concrete curb against a buff brick wall.
/// Anthracite aluminium rafters at 0.93 m carry eight 6/16/6 double glazed units under screwed pressure plates and
/// snap caps, with a transom, an opening vent light, zinc wall flashing under stone coping, glazed end triangles
/// and an eaves gutter with downpipe. Grime, rust at the screws, leaves in the gutter and algae at the curb age it.
public struct SlopedGlazingAtriumBay: RealAsset {
    public static let id = "sloped-glazing-atrium-bay"
    public static let summary = "Sloped glazing atrium bay, 4.0 m wide: aluminium rafters with pressure plates and caps, double-glazed units, curb, zinc wall flashing, vent light and gutter."
    public static let tags = ["prop", "architecture", "facade", "roofline", "roof"]
    public static let budget = 15_000
    public static let author = "realityhd"

    /// Frame powder coat (sRGB hex tint, anthracite).
    public var frame: MaterialKey = "metal.powdercoat:2F3235"
    /// Glass material for the outer pane.
    public var glass: MaterialKey = "glass.pane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 4.0
        let th: Float = atan2(0.90, 2.60), sn = sin(th), cs = cos(th)
        let L: Float = 0.90 / sn
        let zE: Float = 1.30, yE: Float = 0.377
        let deg = th * 180 / .pi
        let rot = FA.q(deg, FA.X)
        // Point on the roof plane: x across, t up-slope from the eave, h normal to the plane.
        func P(_ x: Float, _ t: Float, _ h: Float = 0) -> V3 {
            V3(x, yE + t * sn + h * cs, zE - t * cs + h * sn)
        }
        // The vent light swings open about its head hinge; parts built while `vOpen` is true follow it.
        var vOpen = false
        let vAng: Float = -15
        let qv = simd_quatf(degrees: vAng, axis: FA.X)
        let hingeP = P(0.465, L - 0.06, 0.045)
        func PP(_ x: Float, _ t: Float, _ h: Float) -> V3 {
            let p = P(x, t, h)
            return vOpen ? hingeP + qv.act(p - hingeP) : p
        }
        func slab(_ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey, r: Float = 0.0015) {
            FA.box(&m, size, PP(x, t, h), mat, r: r, rot: vOpen ? FA.q(deg + vAng, FA.X) : rot)
        }
        func decal(_ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey) {
            RK.plate(&m, size, PP(x, t, h), mat, rot: vOpen ? FA.q(deg + vAng, FA.X) : rot)
        }
        let zinc: MaterialKey = "metal.galvanized-aged"
        let seal: MaterialKey = "rubber.seal"
        let alu: MaterialKey = "metal.aluminum-brushed"
        let frameWorn: MaterialKey = "metal.powdercoat:44474A"

        // Brick wall behind: 0.19 m thick, courses with slightly different tints and mortar recesses, stone coping.
        let wallZ: Float = -1.40
        FA.box(&m, V3(W - 0.04, 1.40, 0.19), V3(0, 0.06 + 0.70, wallZ), "brick.red", r: 0.002)
        FA.box(&m, V3(W - 0.04, 0.06, 0.205), V3(0, 0.03, wallZ), "concrete.smooth", r: 0.003)
        FA.box(&m, V3(W, 0.055, 0.25), V3(0, 1.4725, wallZ + 0.005), "stone.limestone-sooted", r: 0.004)
        // Drip groove under the coping and a weathered flat stone joint.
        FA.box(&m, V3(W - 0.01, 0.004, 0.004), V3(0, 1.443, wallZ + 0.114), "stone.limestone", r: 0.001)
        for jx: Float in [-0.9, 1.1] {
            RK.plate(&m, V3(0.003, 0.055, 0.2505), V3(jx, 1.4725, wallZ + 0.005), "brick.mortar-grey")
        }

        // Curb: concrete upstand around the bay with aluminium capping and a drip downstand.
        let curbTop: Float = 0.28
        FA.box(&m, V3(W - 0.02, curbTop, 0.2), V3(0, curbTop / 2, 1.30), "concrete.smooth", r: 0.003)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.2, curbTop, 2.84), V3(e * 1.89, curbTop / 2, -0.02), "concrete.smooth", r: 0.003)
            FA.box(&m, V3(0.24, 0.012, 2.84), V3(e * 1.88, curbTop + 0.006, -0.02), frameWorn, r: 0.002)
            FA.box(&m, V3(0.003, 0.05, 2.84), V3(e * 1.998, curbTop - 0.025, -0.02), frameWorn, r: 0.0008)
        }
        FA.box(&m, V3(W - 0.02, 0.012, 0.24), V3(0, curbTop + 0.006, 1.30), frameWorn, r: 0.002)
        FA.box(&m, V3(W - 0.02, 0.05, 0.003), V3(0, curbTop - 0.025, 1.419), frameWorn, r: 0.0008)
        // Screw heads along the capping.
        for cx in stride(from: Float(-1.8), through: 1.8, by: 0.6) {
            RK.plate(&m, V3(0.009, 0.003, 0.009), V3(cx, curbTop + 0.012, 1.40), "metal.screw-zinc")
        }
        // Concrete staining: algae and water runs below the capping drip, a chipped corner.
        for _ in 0..<4 {
            let x = rng.float(-1.8...1.8), h = rng.float(0.05...0.14)
            RK.plate(&m, V3(rng.float(0.01...0.04), h, 0.0006), V3(x, curbTop - 0.06 - h / 2, 1.4015), "concrete.sealed-dim")
        }
        FA.box(&m, V3(0.05, 0.035, 0.0012), V3(-1.55, 0.03, 1.4015), "concrete.rough", r: 0.0005)

        // Rafters (end rafters sit over the end glazing), with thermal break gaskets and pressure plates.
        let xs: [Float] = [-1.86, -0.93, 0, 0.93, 1.86]
        let tT: Float = 1.40
        for (i, x) in xs.enumerated() {
            slab(V3(0.05, 0.09, L - 0.03), x: x, t: (L - 0.03) / 2, h: -0.045, frame, r: 0.003)
            decal(V3(0.036, 0.004, L - 0.05), x: x, t: (L - 0.05) / 2, h: 0.002, seal)
            // Bearing blocks every 0.6 m under the glass.
            decal(V3(0.05, 0.006, L - 0.06), x: x, t: (L - 0.06) / 2, h: 0.035, alu)
            slab(V3(0.038, 0.012, L - 0.07), x: x, t: (L - 0.07) / 2, h: 0.044, frame, r: 0.004)
            // Screws every 0.25 m through the cap, a few with rust runs.
            var t: Float = 0.12
            var k = 0
            while t < L - 0.1 {
                var sr = rng.fork(100 + i * 40 + k)
                RK.plate(&m, V3(0.009, 0.003, 0.009), P(x, t, 0.0495), "metal.screw-zinc", rot: rot)
                if sr.chance(0.28) {
                    decal(V3(0.0035, 0.0003, sr.float(0.03...0.07)), x: x, t: t - 0.03, h: 0.0502, "metal.rust")
                }
                t += 0.4; k += 1
            }
        }
        // Transom with cap, snap-in end plates and gasket.
        for b in 0..<4 {
            let xc = (xs[b] + xs[b + 1]) / 2
            slab(V3(0.88, 0.07, 0.05), x: xc, t: tT, h: -0.035, frame, r: 0.003)
            decal(V3(0.88, 0.004, 0.036), x: xc, t: tT, h: 0.002, seal)
            decal(V3(0.88, 0.006, 0.05), x: xc, t: tT, h: 0.035, alu)
            slab(V3(0.88, 0.011, 0.038), x: xc, t: tT, h: 0.0435, frame, r: 0.004)
            for dx in stride(from: Float(-0.36), through: 0.36, by: 0.36) {
                RK.plate(&m, V3(0.009, 0.003, 0.009), P(xc + dx, tT, 0.0488), "metal.screw-zinc", rot: rot)
            }
        }

        // Double glazed units: 6 mm outer, 16 mm cavity with aluminium spacer, 6 mm inner, black edge seal.
        let courses: [(Float, Float)] = [(-0.09, tT - 0.03 + 0.012), (tT + 0.03 - 0.012, L - 0.03)]
        let gw: Float = 0.93 - 0.05 + 0.024
        for b in 0..<4 {
            let xc = (xs[b] + xs[b + 1]) / 2
            for (ci, (t0, t1)) in courses.enumerated() {
                let tl = t1 - t0, tc = (t0 + t1) / 2
                decal(V3(gw, 0.006, tl), x: xc, t: tc, h: 0.007, "glass.tinted")
                vOpen = (b == 2 && ci == 1)
                slab(V3(gw, 0.006, tl), x: xc, t: tc, h: 0.029, glass, r: 0.0008)
                for sx: Float in [-1, 1] {
                    decal(V3(0.012, 0.016, tl - 0.02), x: xc + sx * (gw / 2 - 0.012), t: tc, h: 0.018, alu)
                    decal(V3(0.004, 0.028, tl), x: xc + sx * (gw / 2 - 0.002), t: tc, h: 0.018, seal)
                }
                for st: Float in [-1, 1] {
                    decal(V3(gw - 0.03, 0.016, 0.012), x: xc, t: tc + st * (tl / 2 - 0.012), h: 0.018, alu)
                    decal(V3(gw, 0.028, 0.004), x: xc, t: tc + st * (tl / 2 - 0.002), h: 0.018, seal)
                }
                // Grime, pollen film and bird droppings.
                var gr = rng.fork(300 + b * 2 + ci)
                for _ in 0..<2 {
                    let sx = gr.float(-0.38...0.38), tt = gr.float(t0 + 0.1...t1 - 0.1)
                    decal(V3(gr.float(0.01...0.02), 0.0003, gr.float(0.1...0.3)), x: xc + sx, t: tt, h: 0.0325, "glass.tinted")
                }
                vOpen = false
                if gr.chance(0.5) {
                    let sx = gr.float(-0.3...0.3), tt = gr.float(t0 + 0.2...t1 - 0.2)
                    decal(V3(0.016, 0.0004, 0.011), x: xc + sx, t: tt, h: 0.0328, "plastic.white")
                    decal(V3(0.004, 0.0004, 0.03), x: xc + sx + 0.003, t: tt - 0.02, h: 0.0328, "plastic.white")
                }
            }
        }
        // Dirt band along the lower glass edge.
        for b in 0..<4 {
            var dr = rng.fork(400 + b)
            for _ in 0..<6 {
                decal(V3(dr.float(0.05...0.2), 0.0003, dr.float(0.01...0.04)), x: (xs[b] + xs[b + 1]) / 2 + dr.float(-0.38...0.38), t: dr.float(-0.07...0.05), h: 0.0326, "glass.tinted")
            }
            for sx: Float in [-1, 1] {
                decal(V3(0.014, 0.0003, 1.2), x: (xs[b] + xs[b + 1]) / 2 + sx * 0.425, t: 0.65, h: 0.0326, "glass.tinted")
            }
        }
        // Soot and moss on the coping, soot runs under it down the brick.
        for _ in 0..<9 {
            let h = rng.float(0.2...0.55)
            RK.plate(&m, V3(rng.float(0.04...0.11), h, 0.0008), V3(rng.float(-1.9...1.9), 1.43 - h / 2, wallZ + 0.0966), "brick.unit-sooted")
        }
        for _ in 0..<7 {
            let h = rng.float(0.25...0.6), x = rng.float(-1.9...1.9)
            RK.plate(&m, V3(rng.float(0.05...0.12), h, 0.0008), V3(x, 1.43 - h / 2, wallZ - 0.0966), "brick.unit-sooted")
        }
        for _ in 0..<7 {
            RK.plate(&m, V3(rng.float(0.15...0.4), rng.float(0.05...0.12), 0.0008), V3(rng.float(-1.9...1.9), rng.float(0.1...0.5), wallZ - 0.0968), "brick.unit-efflorescent")
        }
        // Curb face: algae and rust runs from the capping and fixings.
        for _ in 0..<8 {
            let h = rng.float(0.08...0.2)
            RK.plate(&m, V3(rng.float(0.03...0.08), h, 0.0008), V3(rng.float(-1.9...1.9), curbTop - 0.055 - h / 2, 1.4018), rng.chance(0.6) ? "concrete.river-algae" : "metal.rust-grime")
        }
        for _ in 0..<6 {
            RK.plate(&m, V3(rng.float(0.12...0.3), rng.float(0.04...0.1), 0.0008), V3(rng.float(-1.9...1.9), rng.float(0.1...0.35), wallZ + 0.0968), "brick.unit-efflorescent")
        }

        // Vent light in the upper course of bay 2, propped open: sash bars, hinges at the head, lock and friction stays.
        let vx: Float = 0.465
        let vt0 = courses[1].0 + 0.03, vt1 = courses[1].1 - 0.03
        let vL = vt1 - vt0, vtc = (vt0 + vt1) / 2
        vOpen = true
        for sx: Float in [-1, 1] {
            slab(V3(0.034, 0.016, vL), x: vx + sx * 0.419, t: vtc, h: 0.040, frame, r: 0.003)
        }
        for st: Float in [-1, 1] {
            slab(V3(0.84, 0.016, 0.034), x: vx, t: vtc + st * (vL / 2 - 0.017), h: 0.040, frame, r: 0.003)
        }
        slab(V3(0.07, 0.01, 0.03), x: vx, t: vt0 + 0.0, h: 0.053, alu, r: 0.002)
        slab(V3(0.012, 0.011, 0.006), x: vx, t: vt0 + 0.018, h: 0.0595, "metal.satin-aluminum", r: 0.001)
        for sx: Float in [-1, 1] {
            // Moving hinge leaf on the sash and a stay arm pinned at the sash side bar.
            slab(V3(0.07, 0.003, 0.05), x: vx + sx * 0.3, t: vt1 - 0.03, h: 0.050, alu, r: 0.0008)
            let pin = PP(vx + sx * 0.405, vtc, 0.050)
            vOpen = false
            let foot = P(vx + sx * 0.405, vt0 + 0.1, 0.05)
            FA.rod(&m, foot, pin, r: 0.004, alu, sides: 8)
            for pt in [foot, pin] {
                m.add(Prim.cylinder(radius: 0.006, height: 0.004, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: pt, rotation: rot))
            }
            // Fixed hinge leaf on the cap and the hinge barrel.
            slab(V3(0.07, 0.003, 0.05), x: vx + sx * 0.3, t: vt1 + 0.01, h: 0.050, alu, r: 0.0008)
            m.add(Prim.cylinder(radius: 0.006, height: 0.07, bevel: 0.001, segments: 10, bevelSegments: 1, material: alu),
                  Xform(translation: P(vx + sx * 0.3 + 0.035, vt1 + 0.0, 0.053), rotation: simd_normalize(rot * FA.q(-90, FA.Z))))
            vOpen = true
        }
        vOpen = false
        // Chain actuator housing on the bay's transom side, with a short chain run.
        slab(V3(0.08, 0.05, 0.14), x: vx, t: tT + 0.1, h: -0.08, "metal.casework", r: 0.004)
        for ci in 0..<7 {
            FA.box(&m, V3(0.006, 0.0035, 0.009), P(vx, tT + 0.18 + Float(ci) * 0.011, -0.075), "metal.steel", r: 0.001, rot: rot)
        }

        // Glazed end triangles: single laminated pane in the plane of each end rafter, framed at wall and curb.
        let tri: [V2] = [V2(zE + 0.09, curbTop + 0.012), V2(wallZ + 0.12, curbTop + 0.012), V2(wallZ + 0.12, yE + L * sn - 0.04)]
        for e: Float in [-1, 1] {
            FA.run(&m, tri, length: 0.012, at: V3(e * 1.835, 0, 0), "glass.pane", bevel: 0.0008)
            FA.box(&m, V3(0.04, yE + L * sn - curbTop - 0.06, 0.04), V3(e * 1.835, (yE + L * sn + curbTop) / 2 - 0.03, wallZ + 0.12), frame, r: 0.003)
            FA.box(&m, V3(0.04, 0.04, 2.6), V3(e * 1.835, curbTop + 0.032, (zE + wallZ + 0.12) / 2 - 0.02), frame, r: 0.003)
        }

        // Wall abutment: aluminium wall plate, sealant bead, zinc apron tucked into a brick chase, soaker laps.
        let zW = zE - L * cs
        slab(V3(W - 0.26, 0.012, 0.05), x: 0, t: L - 0.025, h: 0.0345, alu, r: 0.001)
        slab(V3(W - 0.26, 0.012, 0.016), x: 0, t: L - 0.038, h: 0.0305, seal, r: 0.004)
        slab(V3(W - 0.26, 0.003, 0.14), x: 0, t: L - 0.07, h: 0.054, zinc, r: 0.0006)
        FA.box(&m, V3(W - 0.26, 0.17, 0.003), V3(0, 1.255 + 0.085 + 0.03, zW + 0.036), zinc, r: 0.0006)
        FA.box(&m, V3(W - 0.26, 0.006, 0.014), V3(0, 1.43, zW + 0.045), zinc, r: 0.0006)
        // Zinc standing seams on the apron and a soldered end cap.
        for sx in stride(from: Float(-1.8), through: 1.8, by: 0.45) {
            FA.box(&m, V3(0.012, 0.17, 0.0035), V3(sx, 1.37, zW + 0.0385), zinc, r: 0.001)
        }
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.003, 0.17, 0.05), V3(sx * (W - 0.26) / 2, 1.37, zW + 0.012), zinc, r: 0.0006)
        }
        // Eaves gutter: aluminium box section on brackets, with leaf litter, outlet and downpipe.
        let gutter: [V2] = [V2(0, 0.14), V2(0, 0.0), V2(0.095, 0.0), V2(0.095, 0.13), V2(0.092, 0.13), V2(0.092, 0.003), V2(0.003, 0.003), V2(0.003, 0.14)]
        FA.run(&m, gutter, length: W - 0.06, at: V3(0, 0.14, 1.405), frame, bevel: 0.0008)
        for gx in stride(from: Float(-1.7), through: 1.7, by: 0.85) {
            FA.box(&m, V3(0.012, 0.01, 0.1), V3(gx, 0.138, 1.45), alu, r: 0.001)
            FA.box(&m, V3(0.012, 0.15, 0.006), V3(gx, 0.2, 1.402), alu, r: 0.001)
        }
        FA.box(&m, V3(0.006, 0.12, 0.092), V3(-(W - 0.06) / 2, 0.205, 1.452), frameWorn, r: 0.001)
        FA.box(&m, V3(0.006, 0.12, 0.092), V3((W - 0.06) / 2, 0.205, 1.452), frameWorn, r: 0.001)
        m.add(Prim.cylinder(radius: 0.03, height: 0.145, bevel: 0.002, segments: 14, bevelSegments: 1, material: "metal.painted:2F3235"),
              Xform(translation: V3(1.7, 0.0, 1.452)))
        m.add(Prim.cylinder(radius: 0.033, height: 0.012, bevel: 0.002, segments: 14, bevelSegments: 1, material: "metal.painted:2F3235"),
              Xform(translation: V3(1.7, 0.0, 1.452)))
        FA.box(&m, V3(0.01, 0.005, 0.07), V3(1.7, 0.0075, 1.452), "metal.painted:2F3235", r: 0.001)
        for k in 0..<8 {
            var lr = rng.fork(700 + k)
            RK.plate(&m, V3(lr.float(0.05...0.11), 0.0006, lr.float(0.03...0.06)), V3(lr.float(1.4...1.9) * (lr.chance(0.8) ? 1 : -0.7), 0.1445 + lr.float(0...0.01), 1.45 + lr.float(-0.02...0.02)),
                     lr.pick(["wood.deadwood", "wood.pine-aged", "wood.cedar-weathered"]),
                     rot: FA.q(lr.float(0...360), FA.Y))
        }
        // Water staining below the gutter overflow.
        RK.plate(&m, V3(0.04, 0.2, 0.0006), V3(1.95, 0.1, 1.3992), "concrete.river-algae")

        // Shadow gap, rust at the wall plate fixings and moss at the coping.
        for sx in stride(from: Float(-1.7), through: 1.7, by: 0.5) {
            RK.plate(&m, V3(0.009, 0.003, 0.009), P(sx, L - 0.025, 0.041), "metal.screw-zinc", rot: rot)
        }
        for _ in 0..<6 {
            RK.plate(&m, V3(rng.float(0.012...0.03), rng.float(0.05...0.16), 0.0006), V3(rng.float(-1.9...1.9), 1.35 - rng.float(0.0...0.2), wallZ + 0.0965), "brick.unit-efflorescent")
        }
        for _ in 0..<5 {
            RK.plate(&m, V3(rng.float(0.02...0.06), 0.0006, rng.float(0.02...0.05)), V3(rng.float(-1.9...1.9), 1.5, wallZ + rng.float(-0.05...0.12)), "concrete.river-algae")
        }

        groundAO(&m, height: 0.08, floor: 0.85)
        return LODModel(m)
    }
}
