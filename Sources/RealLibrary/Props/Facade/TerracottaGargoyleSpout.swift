import simd
import Foundation

/// Gothic Revival terracotta gargoyle spout, 0.3 x 0.6 x 0.7 m: a crouching grotesque seated on a stone-coloured corbel slab,
/// open mouth with a lolling tongue as the water lip, brow ridges, pointed ears, two horns (the left one broken), folded
/// wings with ribs, gripping forelegs with claws, a water trough along the back, a wall tail plate with hex bolts and an iron
/// strap over the haunches. Glazed terracotta in several firing tones with soot runs and a stained slab.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct TerracottaGargoyleSpout: RealAsset {
    public static let id = "terracotta-gargoyle-spout"
    public static let summary = "Gothic Revival terracotta gargoyle spout, 0.7 m projection: crouching grotesque, open mouth spout, horns, folded wings, trough, tail plate, iron strap."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.9)

    /// Main terracotta body.
    public var clay: MaterialKey = "ceramic.bisque:BC6B48"
    /// Paler fired clay for the eyes, horns and plate.
    public var pale: MaterialKey = "ceramic.bisque:D3AA82"
    /// Slab and base stone.
    public var stone: MaterialKey = "stone.limestone-sooted"
    /// Iron strap and bolts.
    public var iron: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed); _ = rng
        var m = Model(name: Self.id)
        let tones: [MaterialKey] = [clay, "ceramic.bisque:B0603F", "ceramic.bisque:C7805A", "ceramic.bisque:A85A3E"]
        let dark: MaterialKey = "stone.limestone:2A2622"

        // Hand-modelled clay: low-frequency lumps plus fine tool marks, so no form is a clean ellipsoid.
        func clayDisplace(_ surf: inout Surface, _ c: V3, amp: Float) {
            surf.displace { p, _ in
                let q = (p + c) * 22
                return amp * (Noise.fbm(q, octaves: 3, seed: 7) * 0.9 + Noise.perlin(q * 3.1, seed: 11) * 0.25)
            }
        }
        func blob(_ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, exp: Float = 2, sub: Int = 5, amp: Float = 0.007) {
            var surf = Prim.superellipsoid(size, exponent: exp, subdivisions: sub >= 5 ? sub + 1 : sub, material: mat)
            if amp > 0 { clayDisplace(&surf, c, amp: min(amp, min(size.x, min(size.y, size.z)) * 0.18)) }
            m.add(surf, Xform(translation: c, rotation: rot))
        }
        func limb(_ pts: [V3], _ radii: [Float], _ mat: MaterialKey, sides: Int = 10) {
            var surf = Prim.tube(pts, radii: radii, sides: sides, seamTile: 0.2, material: mat, capEnd: true)
            clayDisplace(&surf, pts[0], amp: 0.003)
            m.add(surf)
        }

        // Corbel slab with a chamfered nose, and the wall tail plate with hex bolts.
        FA.box(&m, V3(0.3, 0.1, 0.56), V3(0, 0.05, 0.28), stone, r: 0.008)
        FA.box(&m, V3(0.3, 0.02, 0.57), V3(0, 0.01, 0.285), "stone.limestone:B8AE94", r: 0.004)
        FA.box(&m, V3(0.3, 0.6, 0.04), V3(0, 0.3, 0.02), "stone.limestone:BDB296", r: 0.006)
        FA.box(&m, V3(0.3, 0.03, 0.05), V3(0, 0.585, 0.025), "stone.limestone:B2A78B", r: 0.005)
        for s: Float in [-1, 1] {
            for y in [Float(0.06), 0.5] { FA.cylZ(&m, r: 0.012, h: 0.008, at: V3(s * 0.115, y, 0.04), iron, bevel: 0.0015, segments: 6) }
        }

        // Body: tapering torso sloping to the front, chest, haunches, hind feet.
        limb([V3(0, 0.30, 0.04), V3(0, 0.285, 0.22), V3(0, 0.265, 0.4), V3(0, 0.25, 0.52)], [0.095, 0.105, 0.1, 0.085], tones[0], sides: 14)
        blob(V3(0.19, 0.19, 0.2), V3(0, 0.27, 0.45), tones[1])
        for s: Float in [-1, 1] {
            blob(V3(0.11, 0.2, 0.24), V3(s * 0.085, 0.2, 0.2), tones[s > 0 ? 2 : 3])
            blob(V3(0.07, 0.04, 0.13), V3(s * 0.09, 0.12, 0.31), tones[1], sub: 4)
            for k in -1...1 { blob(V3(0.014, 0.012, 0.03), V3(s * 0.09 + Float(k) * 0.022, 0.108, 0.385), pale, sub: 2, amp: 0) }
            // Forelegs gripping the slab, paws with three claws.
            limb([V3(s * 0.09, 0.27, 0.4), V3(s * 0.095, 0.18, 0.5), V3(s * 0.095, 0.115, 0.52)], [0.04, 0.03, 0.027], tones[(s > 0 ? 1 : 0) + 1])
            blob(V3(0.07, 0.035, 0.09), V3(s * 0.095, 0.117, 0.55), tones[2], sub: 4)
            for k in -1...1 {
                blob(V3(0.014, 0.012, 0.03), V3(s * 0.095 + Float(k) * 0.022, 0.108, 0.6), pale, sub: 2, amp: 0)
            }
        }

        // Ribs and shoulder blades on the flanks.
        for sg: Float in [-1, 1] {
            for k in 0..<4 {
                blob(V3(0.014, 0.1 - Float(k) * 0.008, 0.024), V3(sg * 0.1, 0.265, 0.27 + Float(k) * 0.05), tones[(k + 1) % 4], rot: FA.q(-sg * 8, FA.Z), sub: 3, amp: 0.001)
            }
            blob(V3(0.04, 0.12, 0.14), V3(sg * 0.075, 0.33, 0.37), tones[2], rot: FA.q(-sg * 14, FA.Y), sub: 4)
        }

        // Head: skull, snout, open lower jaw with tongue, dark mouth cavity.
        blob(V3(0.18, 0.18, 0.2), V3(0, 0.31, 0.55), tones[2], sub: 6)
        blob(V3(0.035, 0.04, 0.1), V3(0, 0.395, 0.56), tones[1], sub: 4)
        blob(V3(0.12, 0.075, 0.13), V3(0, 0.285, 0.64), tones[1], sub: 5)
        blob(V3(0.085, 0.04, 0.1), V3(0, 0.255, 0.60), dark, sub: 4)
        blob(V3(0.11, 0.04, 0.14), V3(0, 0.215, 0.62), tones[3], rot: FA.q(14, FA.X), sub: 5)
        blob(V3(0.05, 0.012, 0.11), V3(0, 0.236, 0.65), "ceramic.bisque:8E3F32", rot: FA.q(10, FA.X), sub: 4)
        // Teeth: eight small fangs on the upper lip, two on the jaw.
        for k in 0..<8 {
            let t = Float(k) / 7 - 0.5
            let x = t * 0.09
            let big = k == 1 || k == 6
            blob(V3(0.012, big ? 0.03 : 0.02, 0.012), V3(x, 0.252 - (big ? 0.008 : 0.0), 0.676 - abs(t) * 0.05), pale, sub: 2, amp: 0)
        }
        for s: Float in [-1, 1] { blob(V3(0.012, 0.022, 0.012), V3(s * 0.035, 0.232, 0.665), pale, sub: 2, amp: 0) }
        // Nose bridge, cheek bones, jaw muscles and forehead wrinkles.
        blob(V3(0.03, 0.03, 0.11), V3(0, 0.335, 0.63), tones[1], rot: FA.q(-8, FA.X), sub: 4)
        for sg: Float in [-1, 1] {
            blob(V3(0.05, 0.055, 0.075), V3(sg * 0.08, 0.285, 0.58), tones[3], sub: 4)
            blob(V3(0.035, 0.07, 0.1), V3(sg * 0.082, 0.24, 0.5), tones[1], rot: FA.q(sg * 10, FA.Z), sub: 4)
        }
        for k in 0..<3 {
            blob(V3(0.11 - Float(k) * 0.015, 0.01, 0.022), V3(0, 0.392 - Float(k) * 0.014, 0.585 - Float(k) * 0.03), tones[(k + 2) % 4], rot: FA.q(-25 - Float(k) * 5, FA.X), sub: 3, amp: 0.001)
        }
        // Nostrils, eyes with sockets, pupils, brow ridges.
        for s: Float in [-1, 1] {
            blob(V3(0.014, 0.012, 0.012), V3(s * 0.03, 0.3, 0.688), dark, sub: 2, amp: 0)
            blob(V3(0.05, 0.046, 0.04), V3(s * 0.057, 0.335, 0.63), dark, sub: 3, amp: 0)
            blob(V3(0.036, 0.034, 0.034), V3(s * 0.057, 0.333, 0.64), tones[2], sub: 4, amp: 0.002)
            blob(V3(0.05, 0.016, 0.04), V3(s * 0.057, 0.352, 0.642), tones[1], rot: FA.q(-s * 10, FA.Z), sub: 3, amp: 0)
            blob(V3(0.085, 0.03, 0.06), V3(s * 0.057, 0.37, 0.63), tones[1], rot: FA.q(-s * 22, FA.Z), sub: 4)
            // Pointed ears and the horns (the left horn is broken short).
            limb([V3(s * 0.085, 0.37, 0.52), V3(s * 0.115, 0.42, 0.5), V3(s * 0.13, 0.455, 0.49)], [0.024, 0.016, 0.004], tones[2], sides: 8)
            if s > 0 {
                limb([V3(0.05, 0.395, 0.5), V3(0.072, 0.46, 0.46), V3(0.064, 0.52, 0.4), V3(0.045, 0.56, 0.35)], [0.02, 0.015, 0.009, 0.003], pale, sides: 8)
            } else {
                limb([V3(-0.05, 0.395, 0.5), V3(-0.072, 0.45, 0.47)], [0.02, 0.014], pale, sides: 8)
                blob(V3(0.026, 0.01, 0.026), V3(-0.074, 0.452, 0.468), "ceramic.bisque:E6D6BC", rot: FA.q(-35, FA.Z), sub: 3, amp: 0)
            }
        }

        // Folded bat wings: scalloped membrane between three finger tips, finger ribs and a leading bone.
        let wingPts: [(Float, Float)] = [(0.30, 0.30), (0.34, 0.42), (0.28, 0.53), (0.07, 0.50), (0.14, 0.43), (0.04, 0.36),
                                         (0.12, 0.30), (0.09, 0.22), (0.19, 0.265), (0.28, 0.25)]
        let wingOutline = FO7.ccw(Shape2D.deduped(wingPts.map { V2(-$0.0, $0.1 - 0.38) }))
        for s: Float in [-1, 1] {
            let x = s * 0.112
            m.add(Prim.extrude(wingOutline, depth: 0.016, bevel: 0.0045, bevelSegments: 1, material: tones[s > 0 ? 3 : 1]),
                  Xform(translation: V3(x, 0.38, 0), rotation: FA.q(-s * 7, FA.Z) * FA.q(90, FA.Y)))
            let fx = x + s * 0.011
            limb([V3(fx, 0.41, 0.34), V3(fx, 0.5, 0.31), V3(fx, 0.53, 0.28)], [0.009, 0.008, 0.007], tones[2], sides: 6)
            for (tz, ty) in [(Float(0.07), Float(0.50)), (0.04, 0.36), (0.09, 0.22)] {
                limb([V3(fx, 0.53, 0.28), V3(fx, (0.53 + ty) / 2 + 0.01, (0.28 + tz) / 2), V3(fx, ty, tz)], [0.007, 0.006, 0.003], tones[2], sides: 6)
            }
        }

        // Water trough: floor and two lips along the back, running to the lip over the snout.
        FA.rod(&m, V3(-0.034, 0.395, 0.04), V3(-0.034, 0.345, 0.5), r: 0.011, tones[0], sides: 8)
        FA.rod(&m, V3(0.034, 0.395, 0.04), V3(0.034, 0.345, 0.5), r: 0.011, tones[0], sides: 8)
        m.add(Prim.extrude(Shape2D.roundedRect(0.07, 0.46, radius: 0.004), depth: 0.008, bevel: 0.002, bevelSegments: 1, material: "ceramic.bisque:6F3A2E"),
              Xform(translation: V3(0, 0.3705, 0.275), rotation: FA.q(-90, FA.X) * FA.q(0, FA.Z)))

        // Flat iron strap hugging the shoulders, bent to the body and bolted to the slab through foot plates.
        var strap: [V3] = [V3(0.126, 0.1, 0.37)]
        strap += FO7.ellipse(c: V2(0, 0.275), rx: 0.126, ry: 0.125, from: 0, to: 180, steps: 14, z: 0.37).dropFirst().dropLast().map { $0 }
        strap += [V3(-0.126, 0.1, 0.37)]
        strap.insert(V3(0.126, 0.275, 0.37), at: 1)
        strap.insert(V3(-0.126, 0.275, 0.37), at: strap.count - 1)
        let band: [V2] = [V2(-0.016, 0), V2(0.016, 0), V2(0.016, 0.007), V2(-0.016, 0.007)]
        m.add(Prim.sweep(FO7.ccw(band), along: strap, up: V3(0, 0, 1), material: iron))
        for sg: Float in [-1, 1] {
            FA.box(&m, V3(0.04, 0.008, 0.05), V3(sg * 0.128, 0.104, 0.37), iron, r: 0.002)
            FA.cylZ(&m, r: 0.008, h: 0.006, at: V3(sg * 0.128, 0.104, 0.37), iron, bevel: 0.001, segments: 6)
        }

        // Weathering: soot on the slab under the mouth, tear stains, and lichen patches on the upward faces.
        blob(V3(0.075, 0.003, 0.15), V3(0, 0.1003, 0.5), "stone.limestone:3A352D", sub: 3, amp: 0)
        for sg: Float in [-1, 1] {
            blob(V3(0.008, 0.045, 0.006), V3(sg * 0.057, 0.292, 0.655), "ceramic.bisque:5A2E25", sub: 2, amp: 0)
            blob(V3(0.07, 0.008, 0.06), V3(sg * 0.12, 0.468, 0.2), "ceramic.bisque:6C7440", rot: FA.q(-sg * 12, FA.Z), sub: 3, amp: 0)
            blob(V3(0.05, 0.007, 0.05), V3(sg * 0.07, 0.37, 0.45), "ceramic.bisque:7C8248", sub: 3, amp: 0)
            blob(V3(0.04, 0.006, 0.05), V3(sg * 0.085, 0.3, 0.13), "ceramic.bisque:5E6B3A", sub: 3, amp: 0)
        }
        blob(V3(0.07, 0.007, 0.05), V3(0, 0.395, 0.55), "ceramic.bisque:6C7440", sub: 3, amp: 0)
        blob(V3(0.12, 0.004, 0.11), V3(0.07, 0.1006, 0.15), "stone.limestone:566044", sub: 3, amp: 0)
        blob(V3(0.1, 0.004, 0.06), V3(-0.08, 0.1006, 0.4), "stone.limestone:566044", sub: 3, amp: 0)

        // Chips: pale fresh clay at the exposed tips, and a hairline crack across the right haunch.
        let chip: MaterialKey = "ceramic.bisque:E2C8A2"
        for (c, sz) in [(V3(-0.128, 0.452, 0.49), V3(0.012, 0.012, 0.012)), (V3(0.0, 0.282, 0.7), V3(0.03, 0.012, 0.014)), (V3(0.108, 0.5, 0.075), V3(0.01, 0.012, 0.014)),
                        (V3(-0.11, 0.36, 0.045), V3(0.01, 0.012, 0.014)), (V3(0.108, 0.22, 0.09), V3(0.01, 0.012, 0.014)), (V3(0.095, 0.103, 0.606), V3(0.016, 0.01, 0.014)),
                        (V3(-0.07, 0.228, 0.55), V3(0.02, 0.01, 0.02))] {
            blob(sz, c, chip, sub: 2, amp: 0)
        }
        blob(V3(0.003, 0.11, 0.004), V3(0.128, 0.2, 0.2), "ceramic.bisque:3A1E16", rot: FA.q(25, FA.Z), sub: 2, amp: 0)

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
