import simd
import Foundation

/// Colonial Revival bracketed door hood, 1.8 m wide, 1.0 m projection, 0.9 m high: two scrolled console brackets
/// (S-curved underside, volute, raised relief panel) carry a painted-wood entablature (two-fascia architrave, dentil
/// band, cornice) and a shallow gable pediment with a raking cornice and a fan sunburst in the tympanum. Behind it
/// sit side eave beams, a wall backboard and a beaded soffit; above it a copper standing-seam roof with ridge roll
/// and drip edges. Paint is flaked to bare wood on the volutes, verdigris runs down the pediment, brass screws
/// hold the architrave. Wall plane at z = 0.
public struct BracketedPorchHood: RealAsset {
    public static let id = "bracketed-porch-hood"
    public static let summary = "Colonial Revival bracketed door hood, 1.8 m: scrolled consoles, dentil cornice, fan pediment, copper gable roof."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 16, distance: 2.6)

    /// Overall width in meters.
    public var width: Float = 1.8
    /// Paint on the trim.
    public var paint: MaterialKey = "wood.painted-exterior:E9E3D2"
    /// Worn paint on the brackets.
    public var worn: MaterialKey = "wood.painted-shaker-worn:D9D1BC"
    /// Roof metal.
    public var roof: MaterialKey = "metal.copper-patina:78A68C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2 - 0.03
        let W = width - 0.06
        let yB: Float = 0.475                       // underside of the entablature
        let shade: MaterialKey = "wood.painted-exterior:BDB59F"
        let bare: MaterialKey = "wood.weathered"
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
            if r <= 0.001 {   // decals and small blocks: unbeveled prism, 12 triangles
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }

        // Console brackets.
        var prof: [V2] = [V2(0, yB), V2(0.80, yB), V2(0.80, yB - 0.05)]
        let n = lite ? 6 : 12
        for i in 1...n {
            let t = Float(i) / Float(n), s = 3 * t * t - 2 * t * t * t
            prof.append(V2(0.80 - 0.63 * t, 0.11 + 0.315 * (1 - s)))
        }
        prof += [V2(0.14, 0.04), V2(0.09, 0.0), V2(0.03, 0.01), V2(0, 0.06)]
        for sx: Float in [-1, 1] {
            let bxp = sx * (hw - 0.30)
            m.add(Prim.extrude(prof, depth: 0.07, bevel: 0.004, bevelSegments: 1, material: paint),
                  Xform(translation: V3(bxp, 0, 0), rotation: FA.q(-90, FA.Y)))
            let inner = Shape2D.offset(Array(prof.reversed()), -0.016)
            m.add(Prim.extrude(inner, depth: 0.078, bevel: 0.003, bevelSegments: 1, material: worn),
                  Xform(translation: V3(bxp, 0, 0), rotation: FA.q(-90, FA.Y)))
            // Volute scroll disc, flaked to bare wood.
            FA.cylX(&m, r: 0.058, h: 0.086, at: V3(bxp + 0.043, 0.06, 0.115), paint, bevel: 0.004, segments: lite ? 12 : 20)
            FA.cylX(&m, r: 0.034, h: 0.094, at: V3(bxp + 0.047, 0.06, 0.115), worn, bevel: 0.003, segments: lite ? 10 : 16)
            FA.cylX(&m, r: 0.014, h: 0.098, at: V3(bxp + 0.049, 0.06, 0.115), bare, bevel: 0.002, segments: 10)
            if !lite {
                for f: Float in [-1, 1] {   // flaked-paint patches and grime on both faces of the arm and the S-curve
                    bx(V3(0.003, 0.05, 0.10), V3(bxp + f * 0.0405, 0.405, 0.50 + f * sx * 0.04), bare, r: 0.001)
                    bx(V3(0.003, 0.07, 0.07), V3(bxp + f * 0.0405, 0.19, 0.30), bare, r: 0.001)
                    bx(V3(0.003, 0.03, 0.30), V3(bxp + f * 0.0405, 0.31, 0.38), "wood.weathered:6B6252", r: 0.001)
                }
                for z: Float in [0.05, 0.40, 0.72] { FP.screw(&m, at: V3(bxp, yB + 0.003, z), "metal.brass-aged") }
            }
            // Wall cleat behind the bracket.
            bx(V3(0.11, 0.36, 0.014), V3(bxp, 0.24, 0.007), shade, r: 0.002)
        }

        // Wall backboard (gable outline) and soffit.
        let back: [V2] = [V2(-hw, yB), V2(hw, yB), V2(hw, 0.60), V2(0, 0.80), V2(-hw, 0.60)]
        m.add(Prim.extrude(back, depth: 0.03, bevel: 0.002, bevelSegments: 1, material: shade), Xform(translation: V3(0, 0, 0.015)))
        bx(V3(W - 0.08, 0.016, 0.90), V3(0, yB + 0.006, 0.47), shade, r: 0.002)
        if !lite {
            for k in 0..<10 { bx(V3(0.003, 0.004, 0.88), V3(-hw + 0.12 + Float(k) * (W - 0.24) / 9, yB - 0.003, 0.47), "wood.weathered:4A4234", r: 0.0008) }   // bead grooves
        }

        // Side eave beams with fascia.
        for sx: Float in [-1, 1] {
            bx(V3(0.09, 0.07, 0.97), V3(sx * (hw - 0.045), yB + 0.035, 0.485), paint, r: 0.004)
            bx(V3(0.026, 0.012, 0.97), V3(sx * (hw - 0.012), yB + 0.07 + 0.006, 0.485), paint, r: 0.002)
            bx(V3(0.036, 0.075, 0.97), V3(sx * (hw - 0.018), 0.6325, 0.485), paint, r: 0.003)
        }

        // Front entablature: architrave (two fasciae), dentil band, cornice.
        bx(V3(W, 0.026, 0.060), V3(0, yB + 0.013, 0.935), paint, r: 0.003)
        bx(V3(W, 0.020, 0.052), V3(0, yB + 0.026 + 0.010, 0.931), paint, r: 0.003)
        bx(V3(W - 0.04, 0.030, 0.052), V3(0, 0.535, 0.931), shade, r: 0.002)
        let dn = lite ? 0.09 : 0.042
        let dCount = Int((W - 0.12) / Float(dn))
        for k in 0..<dCount where !(k == 17 && !lite) {
            let x = -hw + 0.06 + (Float(k) + 0.5) * (W - 0.12) / Float(dCount)
            m.add(Prim.extrude([V2(-0.011, -0.013), V2(0.011, -0.013), V2(0.011, 0.013), V2(-0.011, 0.013)], depth: 0.034, bevel: lite ? 0 : 0.0012, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x, 0.535, 0.958)))
        }
        FA.run(&m, FP.cornice(d: 0.075, h: 0.045), length: W, at: V3(0, 0.55, 0.905), paint, bevel: 0.0015)
        if !lite {
            bx(V3(W - 0.08, 0.008, 0.004), V3(0, 0.5215, 0.9625), "wood.weathered:6B6252", r: 0.001)
            for (x, w) in [(-0.55 as Float, 0.14 as Float), (0.38, 0.1)] { bx(V3(w, 0.022, 0.003), V3(x, 0.572, 0.9815), bare, r: 0.001) }
        }
        if !lite { for x: Float in [-0.62, -0.31, 0.31, 0.62] { FP.screw(&m, at: V3(x, yB + 0.013, 0.966), "metal.brass-aged") } }

        // Tympanum with fan sunburst.
        let baseY: Float = 0.595
        let tymp: [V2] = [V2(-0.83, baseY), V2(0.83, baseY), V2(0, 0.772)]
        m.add(Prim.extrude(tymp, depth: 0.03, bevel: 0.002, bevelSegments: 1, material: shade), Xform(translation: V3(0, 0, 0.93)))
        let fanC = V3(0, baseY + 0.004, 0.948)
        for k in 0..<(lite ? 5 : 9) {
            let cnt = lite ? 5 : 9
            let a = (Float(k) + 0.5) / Float(cnt) * 180
            let ar = a * .pi / 180
            bx(V3(0.145, 0.014, 0.008), fanC + V3(cos(ar), sin(ar), 0) * 0.095, paint, r: 0.0015, rot: FA.q(a, FA.Z))
        }
        if !lite {
            for k in 0...12 { let ar = Float(k) / 12 * .pi; FC.bead(&m, r: 0.0085, at: fanC + V3(cos(ar) * 0.172, sin(ar) * 0.172, 0.002), paint, sub: 2) }
        }
        FA.cylZ(&m, r: 0.026, h: 0.012, at: V3(0, baseY + 0.002, 0.944), worn, bevel: 0.002, segments: 12)
        // Verdigris runs below the raking cornice.
        if !lite {
            for k in 0..<7 {
                let x = Float(k - 3) * 0.19 + rng.float(-0.03...0.03)
                let hgt = rng.float(0.05...0.13)
                let yTop = 0.7 - abs(x) * 0.215
                bx(V3(0.012, hgt, 0.002), V3(x, yTop - hgt / 2, 0.9455), "metal.copper-patina:5FA58B", r: 0.0005)
            }
        }

        // Raking cornices and roof.
        let rise: Float = 0.19, eaveY: Float = 0.625
        for sx: Float in [-1, 1] {
            let pts = [V2(sx * (hw - 0.02), eaveY), V2(0, eaveY + rise)]
            FP.sweepMould(&m, pts, z: 0.952, d: 0.075, h: 0.08, paint)
        }
        let alpha = atan2(rise, hw - 0.02)
        let slabLen = (hw + 0.03) / cos(alpha)
        for sx: Float in [-1, 1] {
            let mx = sx * (hw + 0.03) / 2 + sx * 0.0
            let yLine = eaveY + rise * (1 - abs(mx) / (hw - 0.02)) + 0.040 + 0.015
            let rot = FA.q(-sx * alpha * 180 / .pi, FA.Z)
            let c = V3(mx, yLine, 0.50)
            FA.box(&m, V3(slabLen, 0.030, 1.0), c, roof, r: 0.003, rot: rot)
            // Standing seams and the drip edge strip.
            let nSeam = lite ? 4 : 7
            for k in 0..<nSeam {
                let z = 0.10 + Float(k) * (0.80 / Float(nSeam - 1))
                let off = V3(0, 0.0215, 0) * 1
                m.add(Prim.roundedBox(V3(slabLen - 0.01, 0.014, 0.020), radius: 0.004, bevelSegments: 1, material: "metal.copper-patina:6C9C7C"),
                      Xform(translation: c + simd_act(rot, off) + V3(0, 0, z - 0.5), rotation: rot))
            }
            FA.box(&m, V3(slabLen, 0.018, 0.016), c + simd_act(rot, V3(0, -0.005, 0)) + V3(0, 0, 0.505), roof, r: 0.003, rot: rot)
            FA.box(&m, V3(0.016, 0.026, 1.0), c + simd_act(rot, V3(sx * slabLen / 2 - sx * 0.0, -0.014, 0)), roof, r: 0.003, rot: rot)
        }
        FA.rod(&m, V3(-0.012, eaveY + rise + 0.066, 0.01), V3(-0.012, eaveY + rise + 0.066, 0.99), r: 0.012, roof, sides: lite ? 8 : 12)
        FA.rod(&m, V3(0.012, eaveY + rise + 0.066, 0.01), V3(0.012, eaveY + rise + 0.066, 0.99), r: 0.012, roof, sides: lite ? 8 : 12)
        // Copper step flashing against the wall, following both slopes.
        for sx: Float in [-1, 1] {
            let mx = sx * (hw + 0.03) / 2
            let yLine = eaveY + rise * (1 - abs(mx) / (hw - 0.02)) + 0.040 + 0.015 + 0.012
            bx(V3(slabLen - 0.05, 0.030, 0.008), V3(mx, yLine, 0.004), "metal.copper-patina:4E8A72", r: 0.002, rot: FA.q(-sx * alpha * 180 / .pi, FA.Z))
        }

        groundAO(&m, height: 0.12, floor: 0.7)
        return FC.place(m)
    }
}
