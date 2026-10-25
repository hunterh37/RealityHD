import simd
import Foundation

/// Mediterranean balcony support, 0.5 m cube: two carved sandstone scroll corbels (S-curved underside, volute discs
/// on both faces, raised panel, acanthus leaves) carry a moulded stone slab with a bullnose nosing and a drip groove.
/// A forged iron tie bar with square end plates and rusted hex bolts runs under the slab, a star anchor plate sits on
/// the wall between the corbels. The wall is an ochre stucco patch chipped to brick, with salt staining under the slab,
/// moss in the volute crevices and rust streaks below the bolts. Wall plane at z = 0.
public struct BalconyUndersideBracketPair: RealAsset {
    public static let id = "balcony-underside-bracket-pair"
    public static let summary = "Mediterranean balcony support, 0.5 m: two carved sandstone scroll corbels, moulded slab, iron tie bar and star anchor."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.1)

    /// Corbel sandstone.
    public var sandstone: MaterialKey = "stone.sandstone:D8B880"
    /// Slab stone.
    public var slab: MaterialKey = "stone.limestone:E2D6B8"
    /// Wall stucco.
    public var stucco: MaterialKey = "paint.stucco:D9B887"
    /// Forged iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [3])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let slabY0: Float = 0.43
        let soot: MaterialKey = "stone.sandstone:B39868"
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) {
            if r <= 0.0006 {
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }

        // Stucco wall patch, chipped to brick.
        bx(V3(0.5, 0.5, 0.03), V3(0, 0.25, 0.015), stucco, r: 0.003)
        bx(V3(0.5, 0.012, 0.034), V3(0, 0.006, 0.017), "paint.stucco:B89B6E", r: 0.002)   // damp-darkened foot
        for (x, y, w, h) in [(-0.17 as Float, 0.12 as Float, 0.11 as Float, 0.09 as Float), (0.19, 0.20, 0.08, 0.12), (0.02, 0.05, 0.10, 0.05)] {
            let chip: [V2] = [V2(-w / 2, -h * 0.4), V2(-w * 0.2, -h / 2), V2(w * 0.3, -h * 0.45), V2(w / 2, -h * 0.1), V2(w * 0.4, h * 0.4), V2(0.0, h / 2), V2(-w * 0.35, h * 0.35)]
            m.add(Prim.extrude(chip.map { V2($0.x + x, $0.y + y) }, depth: 0.0035, bevel: 0, bevelSegments: 1, material: "brick.common"), Xform(translation: V3(0, 0, 0.0305)))
            m.add(Prim.extrude(chip.map { V2($0.x * 1.14 + x, $0.y * 1.14 + y) }, depth: 0.002, bevel: 0, bevelSegments: 1, material: "paint.stucco:A98A5E"), Xform(translation: V3(0, 0, 0.0305)))
        }
        bx(V3(0.004, 0.2, 0.0016), V3(0.09, 0.30, 0.0308), "paint.stucco:6E5A40", r: 0.0003, rot: FA.q(12, FA.Z))     // crack
        for k in 0..<5 {   // salt-staining streaks from the slab underside
            let x = -0.2 + Float(k) * 0.1 + rng.float(-0.02...0.02), h = rng.float(0.06...0.14)
            bx(V3(0.018, h, 0.0016), V3(x, slabY0 - h / 2, 0.0308), "paint.stucco:BFAE8C", r: 0.0003)
        }

        // Slab with bullnose nosing and drip groove.
        let sp: [V2] = [V2(0.0, slabY0), V2(0.47, slabY0), V2(0.472, slabY0 + 0.004), V2(0.494, slabY0 + 0.012), V2(0.5, slabY0 + 0.026), V2(0.494, slabY0 + 0.05),
                        V2(0.47, slabY0 + 0.067), V2(0.0, slabY0 + 0.07)]
        FA.run(&m, sp, length: 0.5, at: .zero, slab, bevel: 0.001)
        bx(V3(0.5, 0.004, 0.004), V3(0, slabY0 + 0.0005, 0.452), "stone.limestone:8E8268", r: 0.0003)   // drip groove
        bx(V3(0.46, 0.0016, 0.4), V3(0, slabY0 + 0.0708, 0.24), "stone.limestone:CFC3A4", r: 0.0003)   // worn floor patch
        bx(V3(0.5, 0.01, 0.018), V3(0, slabY0 + 0.015, 0.036), slab, r: 0.001)

        // Corbel profile (z out, y up).
        var prof: [V2] = [V2(0.026, slabY0), V2(0.43, slabY0), V2(0.448, slabY0 - 0.006), V2(0.456, slabY0 - 0.02), V2(0.45, slabY0 - 0.036), V2(0.436, slabY0 - 0.046)]
        let n = lite ? 8 : 16
        for i in 1...n {
            let t = Float(i) / Float(n), s = 3 * t * t - 2 * t * t * t
            prof.append(V2(0.436 - 0.336 * t, 0.12 + 0.255 * (1 - s)))
        }
        prof += [V2(0.085, 0.06), V2(0.06, 0.025), V2(0.026, 0.02)]
        let cx: Float = 0.14
        for sx: Float in [-1, 1] {
            let x = sx * cx
            m.add(Prim.extrude(prof, depth: 0.10, bevel: 0.004, bevelSegments: 1, material: sandstone), Xform(translation: V3(x, 0, 0), rotation: FA.q(-90, FA.Y)))
            for f: Float in [-1, 1] {   // volute discs on both faces
                FA.cylX(&m, r: 0.04, h: 0.012, at: V3(x + f * 0.054 - 0.006, 0.075, 0.095), sandstone, bevel: 0.0025, segments: lite ? 12 : 20)
                FA.cylX(&m, r: 0.024, h: 0.014, at: V3(x + f * 0.056 - 0.007, 0.075, 0.095), "stone.sandstone:E6CB95", bevel: 0.002, segments: lite ? 10 : 16)
                FA.cylX(&m, r: 0.009, h: 0.016, at: V3(x + f * 0.057 - 0.008, 0.075, 0.095), soot, bevel: 0.001, segments: 8)
            }
            if !lite {
                // Acanthus leaves down the curve.
                for k in 0..<4 {
                    let t = 0.3 + Float(k) * 0.14
                    let z = 0.45 - 0.35 * t, y = 0.12 + 0.265 * (1 - (3 * t * t - 2 * t * t * t)) + 0.055
                    let ang = atan2(0.265 * (6 * t - 6 * t * t), 0.35) * 180 / .pi
                    for f: Float in [-1, 1] {
                        m.add(Prim.superellipsoid(V3(0.010, 0.022, 0.05), exponent: 2.5, subdivisions: 3, material: "stone.sandstone:E3C78F"),
                              Xform(translation: V3(x + f * 0.0545, y, z), rotation: FA.q(ang, FA.X)))
                    }
                }
                // Moss in the volute crevice and soot under the slab.
                bx(V3(0.1, 0.012, 0.05), V3(x, 0.052, 0.09), "stone.granite-moss", r: 0.0005)
            }
            // Wall plate behind the corbel, with iron bolts.
            bx(V3(0.13, 0.30, 0.012), V3(x, 0.21, 0.036), "stone.sandstone:C8A870", r: 0.002)
            for yy: Float in [0.13, 0.29] {
                hexBolt(&m, at: V3(x, yy, 0.043), normal: FA.Z, size: 0.016, material: "metal.rust")
                if !lite { bx(V3(0.006, 0.07, 0.0016), V3(x + 0.003, yy - 0.04, 0.0431), "metal.rust", r: 0.0003) }
            }
        }

        // Tie bar under the slab with square end plates, star anchor on the wall.
        FA.rod(&m, V3(-0.235, slabY0 - 0.012, 0.30), V3(0.235, slabY0 - 0.012, 0.30), r: 0.011, iron, sides: lite ? 8 : 12)
        for sx: Float in [-1, 1] {
            bx(V3(0.012, 0.07, 0.07), V3(sx * 0.243, slabY0 - 0.012, 0.30), iron, r: 0.002)
            hexBolt(&m, at: V3(sx * 0.25, slabY0 - 0.012, 0.30), normal: V3(sx, 0, 0), size: 0.018, material: "metal.rust")
        }
        FA.cylZ(&m, r: 0.028, h: 0.008, at: V3(0, 0.255, 0.032), iron, bevel: 0.002, segments: lite ? 12 : 20)
        for a: Float in [0, 90, 45, 135] {
            bx(V3(a < 60 && a > 20 ? 0.12 : 0.15, 0.022, 0.007), V3(0, 0.255, 0.04), iron, r: 0.002, rot: FA.q(a, FA.Z))
        }
        FA.cylZ(&m, r: 0.012, h: 0.007, at: V3(0, 0.255, 0.046), "metal.rust", bevel: 0.002, segments: 10)
        if !lite { bx(V3(0.02, 0.1, 0.0016), V3(0.004, 0.19, 0.0305), "metal.rust", r: 0.0003) }

        groundAO(&m, height: 0.06, floor: 0.75)
        return FC.place(m)
    }
}
