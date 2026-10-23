import simd
import Foundation

/// Colonial Revival two-column portico, 2.4 m wide, 1.4 m deep, 3.4 m high: a cast-stone stylobate with a granite
/// front step carries two Tuscan columns (square plinth, torus base, entasis shaft, astragal, necking, echinus,
/// abacus) and two wall pilasters. Over them runs a two-fascia architrave, plain frieze, dentil band and cornice with
/// side returns, then a shallow pediment with a raking cornice, a louvered oval vent in the tympanum and a slate-clad
/// roof with a ridge cap. The soffit is beaded board. Paint is flaked and damp-stained at the column feet, moss
/// grows on the stone. Wall plane at z = 0.
public struct PedimentPorticoTwoColumn: RealAsset {
    public static let id = "pediment-portico-two-column"
    public static let summary = "Colonial Revival two-column portico, 3.4 m: Tuscan columns on a stone stylobate, dentil entablature, pediment, slate roof."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 6.0)

    /// Overall width in meters.
    public var width: Float = 2.4
    /// Paint on the order.
    public var paint: MaterialKey = "wood.painted-exterior:E6DEC8"
    /// Stylobate stone.
    public var stone: MaterialKey = "stone.cast-stone:CFC6B2"
    /// Roof slate.
    public var slate: MaterialKey = "stone.slate:4D5259"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [8])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2
        let shade: MaterialKey = "wood.painted-exterior:B8AF97"
        let bare: MaterialKey = "wood.weathered"
        let damp: MaterialKey = "wood.weathered:5E5646"
        let slabH: Float = 0.14, yE: Float = 2.54   // stylobate top is slabH; entablature starts at yE
        let colX: Float = 0.78, colZ: Float = 0.95

        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
            if r <= 0.001 {
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }

        // Footing apron under the stylobate and step.
        bx(V3(width + 0.04, 0.03, 1.19), V3(0, -0.005, 0.585), "stone.cast-grey", r: 0.003)
        bx(V3(width - 0.12, 0.05, 0.29), V3(0, 0.005, 1.285), "stone.cast-grey", r: 0.003)
        // Stylobate and step.
        bx(V3(width, slabH, 1.15), V3(0, slabH / 2, 0.575), stone, r: 0.006)
        bx(V3(width + 0.02, 0.016, 1.17), V3(0, 0.008, 0.575), "stone.cast-stone:A89F8C", r: 0.003)
        bx(V3(width - 0.20, 0.07, 0.25), V3(0, 0.035, 1.275), "stone.granite-paver", r: 0.008)
        if !lite {
            for z: Float in [0.30, 0.60, 0.90] { bx(V3(width - 0.02, 0.0016, 0.004), V3(0, slabH + 0.0004, z), "stone.cast-stone:8E8674", r: 0.0005) }
            for x: Float in [-0.40, 0.45] { bx(V3(0.004, 0.0016, 1.1), V3(x, slabH + 0.0004, 0.575), "stone.cast-stone:8E8674", r: 0.0005) }
        }

        // Column profile: torus base, shaft with entasis, astragal, necking, echinus.
        let yb = slabH + 0.1
        var prof: [(Float, Float)] = [(0, yb), (0.195, yb), (0.205, yb + 0.012), (0.205, yb + 0.03), (0.19, yb + 0.045), (0.195, yb + 0.058), (0.178, yb + 0.075), (0.165, yb + 0.09)]
        let shaftY0 = yb + 0.09, shaftY1: Float = yE - 0.20
        let ns = lite ? 6 : 12
        for i in 1...ns {
            let t = Float(i) / Float(ns)
            let r = 0.165 - 0.028 * t + 0.008 * sin(t * .pi)
            prof.append((r, shaftY0 + (shaftY1 - shaftY0) * t))
        }
        prof += [(0.150, shaftY1 + 0.012), (0.158, shaftY1 + 0.020), (0.158, shaftY1 + 0.030), (0.140, shaftY1 + 0.036), (0.140, shaftY1 + 0.075), (0.162, shaftY1 + 0.11), (0.188, shaftY1 + 0.145), (0.198, shaftY1 + 0.16), (0.198, yE - 0.04), (0, yE - 0.04)]
        let abY = yE - 0.04
        for sx: Float in [-1, 1] {
            let x = sx * colX
            m.add(turned(prof, segments: lite ? 14 : 28, material: sx < 0 ? paint : "wood.painted-exterior:D8CDB2", seamTile: 0.3, grainVertical: true), Xform(translation: V3(x, 0, colZ)))
            bx(V3(0.38, 0.1, 0.38), V3(x, slabH + 0.05, colZ), paint, r: 0.004)             // plinth
            bx(V3(0.40, 0.04, 0.40), V3(x, abY + 0.02, colZ), paint, r: 0.004)               // abacus
            bx(V3(0.405, 0.008, 0.405), V3(x, abY + 0.0005, colZ), shade, r: 0.002)
            if !lite {
                // Damp rise and flaked paint at the column foot, grime on the plinth.
                m.add(turned([(0, yb + 0.09), (0.1675, yb + 0.09), (0.1655, yb + 0.30), (0.1645, yb + 0.55), (0.164, yb + 0.55), (0, yb + 0.55)].map { ($0.0 * 1.0, $0.1) }, segments: 20, material: "wood.weathered:6A604E", seamTile: 0.3, grainVertical: true),
                      Xform(translation: V3(x, 0, colZ), scale: V3(1.0, 1.0, 1.0)))
                for k in 0..<9 {
                    let a = rng.float(0...(2 * .pi)), yy = yb + rng.float(0.45...1.6)
                    bx(V3(0.07, 0.17, 0.003), V3(x + cos(a) * 0.158, yy, colZ + sin(a) * 0.158), bare, r: 0.001, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
                }
                bx(V3(0.386, 0.03, 0.386), V3(x, slabH + 0.015, colZ), damp, r: 0.003)
            }
        }
        if !lite {
            // Moss on the stone at the foot of the plinths and the step.
            for (x, z, w, d) in [(-0.78 as Float, 0.55 as Float, 0.5 as Float, 0.3 as Float), (0.2, 0.05, 0.6, 0.12), (0.95, 0.9, 0.35, 0.3), (-0.2, 1.33, 0.7, 0.14)] {
                bx(V3(w, 0.004, d), V3(x, z > 1.2 ? 0.072 : slabH + 0.002, z), "stone.granite-moss", r: 0.001)
            }
        }
        // Wall pilasters.
        for sx: Float in [-1, 1] {
            let x = sx * colX
            bx(V3(0.34, 0.10, 0.07), V3(x, slabH + 0.05, 0.035), paint, r: 0.003)
            bx(V3(0.28, 2.2, 0.06), V3(x, slabH + 0.1 + 1.1, 0.03), paint, r: 0.003)
            bx(V3(0.34, 0.10, 0.075), V3(x, yE - 0.12, 0.0375), paint, r: 0.003)
            bx(V3(0.40, 0.04, 0.085), V3(x, yE - 0.02, 0.0425), paint, r: 0.003)
        }

        // Soffit (beaded board, painted pale blue).
        let sof: MaterialKey = "wood.painted-exterior:B8CFD2"
        bx(V3(width - 0.20, 0.02, 1.06), V3(0, yE + 0.008, 0.58), sof, r: 0.002)
        if !lite { for k in 0..<17 { bx(V3(0.004, 0.003, 1.0), V3(-hw + 0.20 + Float(k) * (width - 0.40) / 16, yE - 0.0035, 0.58), "wood.painted-exterior:7E9A9E", r: 0.0008) } }

        // Entablature: architrave (two fasciae), frieze, dentils, cornice. Front face z = fz, side faces x = +-sx.
        let fz: Float = colZ + 0.20, sxF = hw - 0.19
        let aH: Float = 0.13, fH: Float = 0.12, dH: Float = 0.04, cH: Float = 0.11
        bx(V3(2 * sxF, aH * 0.5, 0.12), V3(0, yE + aH * 0.25, fz - 0.06), paint, r: 0.003)
        bx(V3(2 * sxF, aH * 0.5, 0.135), V3(0, yE + aH * 0.75, fz - 0.0675 + 0.0), paint, r: 0.003)
        bx(V3(2 * sxF, fH, 0.11), V3(0, yE + aH + fH / 2, fz - 0.07), shade, r: 0.003)
        for sx: Float in [-1, 1] {
            bx(V3(0.12, aH * 0.5, fz), V3(sx * (sxF - 0.06), yE + aH * 0.25, fz / 2), paint, r: 0.003)
            bx(V3(0.135, aH * 0.5, fz), V3(sx * (sxF - 0.0675), yE + aH * 0.75, fz / 2), paint, r: 0.003)
            bx(V3(0.11, fH, fz), V3(sx * (sxF - 0.07), yE + aH + fH / 2, fz / 2), shade, r: 0.003)
        }
        let dy = yE + aH + fH
        bx(V3(2 * sxF + 0.02, dH, 0.12), V3(0, dy + dH / 2, fz - 0.06), paint, r: 0.002)
        let dN = Int((2 * sxF - 0.1) / (lite ? 0.09 : 0.055))
        for k in 0..<dN where !(k == 11 && !lite) {
            let x = -sxF + 0.05 + (Float(k) + 0.5) * (2 * sxF - 0.1) / Float(dN)
            m.add(Prim.extrude([V2(-0.0125, -0.0165), V2(0.0125, -0.0165), V2(0.0125, 0.0165), V2(-0.0125, 0.0165)], depth: 0.045, bevel: lite ? 0 : 0.0012, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x, dy + dH / 2, fz + 0.012)))
        }
        for sx: Float in [-1, 1] {
            bx(V3(0.12, dH, fz), V3(sx * (sxF - 0.06 + 0.01), dy + dH / 2, fz / 2), paint, r: 0.002)
            let nS = Int(fz / 0.055)
            for k in 0..<nS where k > 2 {
                let z = (Float(k) + 0.5) * fz / Float(nS)
                m.add(Prim.extrude([V2(-0.0165, -0.0165), V2(0.0165, -0.0165), V2(0.0165, 0.0165), V2(-0.0165, 0.0165)], depth: 0.025, bevel: lite ? 0 : 0.0012, bevelSegments: 1, material: paint),
                      Xform(translation: V3(sx * (sxF + 0.012), dy + dH / 2, z), rotation: FA.q(90, FA.Y)))
            }
        }
        let cy = dy + dH
        FA.run(&m, FP.cornice(d: 0.19, h: cH), length: 2 * sxF + 0.38, at: V3(0, cy, fz - 0.02 - 0.0), paint, bevel: 0.002)
        // Side returns of the cornice (profile mirrored, extruded along z).
        let cp = FP.cornice(d: 0.19, h: cH)
        for sx: Float in [-1, 1] {
            let pr = cp.map { V2(sx * $0.x, $0.y) }
            m.add(Prim.extrude(pr, depth: fz + 0.19 - 0.02, bevel: 0.002, bevelSegments: 1, material: paint),
                  Xform(translation: V3(sx * (sxF - 0.0), cy, (fz + 0.19 - 0.02) / 2 - 0.19 + 0.0 + 0.19 - 0.0)))
        }

        // Tympanum, louvered oval vent.
        let baseY = cy + cH
        let apex: Float = 3.29 - 0.05
        let tymp: [V2] = [V2(-hw + 0.08, baseY), V2(hw - 0.08, baseY), V2(0, apex - 0.002)]
        let tz = fz + 0.19 - 0.12
        m.add(Prim.extrude(tymp, depth: 0.05, bevel: 0.002, bevelSegments: 1, material: shade), Xform(translation: V3(0, 0, tz)))
        let ventC = V3(0, baseY + 0.115, tz + 0.025)
        m.add(Prim.extrude(Shape2D.superellipse(0.44, 0.24, exponent: 2), depth: 0.026, bevel: 0.004, bevelSegments: 1, material: paint), Xform(translation: ventC))
        m.add(Prim.extrude(Shape2D.superellipse(0.36, 0.17, exponent: 2), depth: 0.034, bevel: 0.002, bevelSegments: 1, material: "wood.weathered:3A342B"), Xform(translation: ventC))
        for k in 0..<7 {
            let yy = -0.062 + Float(k) * 0.0207
            let hwv = 0.18 * (1 - (yy / 0.085) * (yy / 0.085)).squareRoot()
            bx(V3(hwv * 2 - 0.016, 0.009, 0.014), V3(0, ventC.y + yy, ventC.z + 0.018), paint, r: 0.002, rot: FA.q(-22, FA.X))
        }
        if !lite {
            for k in 0..<6 {
                let x = Float(k - 3) * 0.32 + rng.float(-0.05...0.05)
                let h = rng.float(0.06...0.14)
                bx(V3(0.018, h, 0.002), V3(x, baseY + 0.27 - abs(x) * 0.12 - h / 2, tz + 0.026), "wood.weathered:4C4436", r: 0.0005)
            }
        }
        // Raking cornices and roof.
        let eaveY = baseY + 0.03, ridgeY = apex + 0.04
        let rise = ridgeY - eaveY
        for sx: Float in [-1, 1] {
            FP.sweepMould(&m, [V2(sx * (hw - 0.06), eaveY), V2(0, ridgeY)], z: tz + 0.025, d: 0.16, h: 0.10, paint)
        }
        let alpha = atan2(rise, hw - 0.06)
        let run = hw + 0.02
        let slabLen = run / cos(alpha)
        let roofZ0: Float = 0.0, roofZ1 = fz + 0.19 + 0.01
        let roofD = roofZ1 - roofZ0
        for sx: Float in [-1, 1] {
            let mx = sx * run / 2
            let yLine = eaveY + rise * (1 - abs(mx) / (hw - 0.06)) + 0.05 + 0.02
            let rot = FA.q(-sx * alpha * 180 / .pi, FA.Z)
            let c = V3(mx, yLine, (roofZ0 + roofZ1) / 2)
            bx(V3(slabLen, 0.04, roofD), c, "stone.slate:34383D", r: 0.003, rot: rot)
            // Slate courses.
            let nC = lite ? 6 : 14
            for k in 0..<nC {
                let u = -slabLen / 2 + (Float(k) + 0.5) * slabLen / Float(nC)
                let tints: [MaterialKey] = [slate, "stone.slate:565B62", "stone.slate:444A51", "stone.slate:5C6168"]
                bx(V3(slabLen / Float(nC) - 0.004, 0.006, roofD - 0.01), c + simd_act(rot, V3(u, 0.022, 0)), tints[rng.int(0...3)], r: 0.001, rot: rot)
            }
            FA.box(&m, V3(0.018, 0.03, roofD), c + simd_act(rot, V3(sx * slabLen / 2, -0.01, 0)), "metal.galvanized-aged", r: 0.002, rot: rot)
            if !lite {   // lichen and moss on the slate, heavier low on the slope
                for k in 0..<7 {
                    let u = rng.float(-slabLen / 2 + 0.1...slabLen / 2 - 0.1), z = rng.float(0.15...roofZ1 - 0.15)
                    let wv = rng.float(0.10...0.26)
                    bx(V3(wv, 0.0016, wv * rng.float(0.6...1.4)), c + simd_act(rot, V3(u, 0.0263, 0)) + V3(0, 0, z - (roofZ0 + roofZ1) / 2), k % 3 == 0 ? "stone.granite-moss" : "stone.slate:7C8574", r: 0.0005, rot: rot)
                }
            }
        }
        FA.rod(&m, V3(0, ridgeY + 0.082, roofZ0 + 0.02), V3(0, ridgeY + 0.082, roofZ1 - 0.02), r: 0.025, "stone.slate:4A4F56", sides: lite ? 8 : 12)
        // Backboard gable on the wall.
        let back: [V2] = [V2(-hw + 0.08, yE), V2(hw - 0.08, yE), V2(hw - 0.08, baseY + 0.02), V2(0, ridgeY - 0.04), V2(-hw + 0.08, baseY + 0.02)]
        m.add(Prim.extrude(back, depth: 0.03, bevel: 0.002, bevelSegments: 1, material: shade), Xform(translation: V3(0, 0, 0.015)))

        groundAO(&m, height: 0.3, floor: 0.7)
        return FC.place(m)
    }
}
