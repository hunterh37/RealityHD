import simd
import Foundation

/// Georgian cast iron lion head door knocker, 0.12 x 0.20 x 0.06 m: a modelled mask (brow ridges, deep eyes, bridged
/// nose, puffed muzzle, jaw) inside two layers of teardrop mane curls on a round back boss, holding a hanging ring
/// in a staple. A wall strike plate under it carries a block the ring lands on and two hex bolts. Black paint is worn to
/// burnished iron on the brow, nose, mane tips and the base of the ring; rust sits at the bolts and in the lower hollows.
public struct IronDoorKnockerLion: RealAsset {
    public static let id = "iron-door-knocker-lion"
    public static let summary = "Georgian cast iron lion head door knocker: modelled mask with a ring in its mouth, strike plate and bolts, black paint worn at the high points."
    public static let tags = ["prop", "architecture", "facade", "door", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.1)

    /// Black japanning.
    public var paint: MaterialKey = "metal.painted:1B1A1C"
    /// Paint worn to burnished iron.
    public var bare: MaterialKey = "metal.nickel-worn"
    public var rust: MaterialKey = "metal.rust"
    /// Ring radius (m).
    public var ringRadius: Float = 0.036
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.128                               // lion centre height
        func q(_ d: Float, _ a: V3) -> simd_quatf { simd_quatf(degrees: d, axis: a) }

        // Strike plate, a bevelled backplate with the ring's landing block and two bolts.
        FA.box(&m, V3(0.075, 0.034, 0.012), V3(0, 0.017, 0.006), paint, r: 0.0025)
        FA.box(&m, V3(0.03, 0.010, 0.044), V3(0, 0.005, 0.012 + 0.022 - 0.002), paint, r: 0.002)   // stand carrying the landing block
        for e: Float in [-1, 1] { hexBolt(&m, at: V3(e * 0.027, 0.017, 0.012), normal: FA.Z, size: 0.0095, material: rust) }
        // Back boss: shallow dome behind the mask with a cast rim.
        m.add(Prim.lathe([V2(0, 0), V2(0.050, 0), V2(0.052, 0.002), V2(0.052, 0.008), V2(0.047, 0.013), V2(0.041, 0.016), V2(0, 0.018)], segments: 40, seamTile: 0.1, material: paint),
              Xform(translation: V3(0, cy, 0), rotation: q(90, FA.X)))
        // Mane: cast flame locks in two layers, each a pointed curl with a raised centre rib and a worn tip.
        func flame(_ len: Float, _ w: Float) -> [V2] {
            Shape2D.rounded([V2(-w * 0.5, 0), V2(-w * 0.48, len * 0.3), V2(-w * 0.28, len * 0.66), V2(w * 0.04, len), V2(w * 0.42, len * 0.78),
                             V2(w * 0.5, len * 0.35), V2(w * 0.5, 0)], radius: 0.0025, segments: 2)
        }
        for k in 0..<18 {
            let a = Float(k) / 18 * 2 * .pi + 0.1
            let L = 0.033 + rng.float(-0.003...0.002), r0: Float = 0.028
            let dir = V3(cos(a), sin(a), 0)
            m.add(Prim.extrude(flame(L, 0.0175), depth: 0.010, bevel: 0.0028, bevelSegments: 1, material: paint),
                  Xform(translation: V3(0, cy, 0.0135) + dir * r0, rotation: q(a * 180 / .pi - 90 + rng.float(-5...5), FA.Z)))
            FJ.slab(&m, V3(0.0026, L * 0.62, 0.002), V3(0, cy, 0.0262) + dir * (r0 + L * 0.34), paint, rot: q(a * 180 / .pi - 90, FA.Z))
            FC.bead(&m, r: 0.0034, at: V3(0, cy, 0.0245) + dir * (r0 + L * 0.9), bare, sub: 2)
        }
        for k in 0..<13 {
            let a = Float(k) / 13 * 2 * .pi + 0.26
            let L = 0.026 + rng.float(-0.002...0.002), r0: Float = 0.020
            let dir = V3(cos(a), sin(a), 0)
            m.add(Prim.extrude(flame(L, 0.0158), depth: 0.010, bevel: 0.0026, bevelSegments: 1, material: paint),
                  Xform(translation: V3(0, cy, 0.0245) + dir * r0, rotation: q(a * 180 / .pi - 90, FA.Z)))
            FJ.slab(&m, V3(0.0022, L * 0.6, 0.0018), V3(0, cy, 0.0358) + dir * (r0 + L * 0.34), bare, rot: q(a * 180 / .pi - 90, FA.Z))
        }
        // Head: cheek mass, brow ridges, ears, deep-set eyes.
        m.add(Prim.superellipsoid(V3(0.056, 0.064, 0.030), exponent: 2.6, subdivisions: 7, material: paint), Xform(translation: V3(0, cy - 0.002, 0.040)))
        for e: Float in [-1, 1] {
            m.add(Prim.extrude(Shape2D.rounded([V2(-0.0185, -0.004), V2(0.0185, -0.0065), V2(0.0185, 0.0055), V2(-0.0185, 0.0035)], radius: 0.002, segments: 1), depth: 0.014,
                               bevel: 0.0035, bevelSegments: 2, material: paint), Xform(translation: V3(e * 0.0185, cy + 0.0175, 0.0485), rotation: q(e * -12, FA.Z)))
            FJ.slab(&m, V3(0.028, 0.0028, 0.0022), V3(e * 0.0185, cy + 0.0195, 0.0638), bare, rot: q(e * -12, FA.Z))                 // worn brow crest
            m.add(Prim.superellipsoid(V3(0.014, 0.0085, 0.008), exponent: 2.4, subdivisions: 4, material: "metal.painted:0A0909"), Xform(translation: V3(e * 0.0168, cy + 0.0085, 0.0572)))   // eye socket + eye
            FC.bead(&m, r: 0.0019, at: V3(e * 0.0168, cy + 0.0088, 0.0618), bare, sub: 2)
            m.add(Prim.superellipsoid(V3(0.013, 0.015, 0.009), exponent: 2.2, subdivisions: 3, material: paint), Xform(translation: V3(e * 0.0315, cy + 0.0295, 0.0425)))
            FJ.slab(&m, V3(0.002, 0.012, 0.0016), V3(e * 0.0045, cy + 0.031, 0.0575), bare)                                          // forehead furrows
        }
        // Nose: bridge widening to flared nostril wings, worn tip; muzzle puffs; whisker pits; jaw and mouth.
        m.add(Prim.extrude(Shape2D.rounded([V2(-0.0055, 0.016), V2(-0.0035, -0.008), V2(-0.0115, -0.021), V2(-0.0115, -0.0285), V2(0.0115, -0.0285), V2(0.0115, -0.021),
                                            V2(0.0035, -0.008), V2(0.0055, 0.016)], radius: 0.003, segments: 2), depth: 0.016, bevel: 0.0032, bevelSegments: 2, material: paint),
              Xform(translation: V3(0, cy - 0.001, 0.0505)))
        m.add(Prim.superellipsoid(V3(0.013, 0.0055, 0.0055), exponent: 2.4, subdivisions: 3, material: bare), Xform(translation: V3(0, cy - 0.0272, 0.0668)))   // worn nose tip
        for e: Float in [-1, 1] {
            FC.bead(&m, r: 0.0027, at: V3(e * 0.0078, cy - 0.0305, 0.0652), "metal.painted:0A0909", sub: 2)
            m.add(Prim.superellipsoid(V3(0.026, 0.021, 0.016), exponent: 2.3, subdivisions: 4, material: paint), Xform(translation: V3(e * 0.0125, cy - 0.0345, 0.0515)))
            for w in 0..<3 { FC.bead(&m, r: 0.0016, at: V3(e * (0.0165 + Float(w % 2) * 0.004), cy - 0.0265 - Float(w) * 0.0045, 0.0592 - Float(w % 2) * 0.002), bare, sub: 2) }
        }
        m.add(Prim.superellipsoid(V3(0.034, 0.018, 0.014), exponent: 2.3, subdivisions: 5, material: paint), Xform(translation: V3(0, cy - 0.052, 0.047)))
        FJ.slab(&m, V3(0.024, 0.0018, 0.004), V3(0, cy - 0.0435, 0.0575), "metal.painted:070606")
        // Ring: staple through the mouth, ring hanging to the strike block; worn bright along its lower arc.
        let mouthY = cy - 0.0445
        m.add(Prim.torus(major: 0.0085, minor: 0.0028, segments: 14, sides: 6, material: paint), Xform(translation: V3(0, mouthY + 0.002, 0.0535), rotation: q(90, FA.X)))
        let R = ringRadius, rcY = mouthY - R + 0.0045
        m.add(Prim.torus(major: R, minor: 0.0058, segments: 32, sides: 8, material: paint), Xform(translation: V3(0, rcY, 0.0535), rotation: q(90, FA.X)))
        m.add(Prim.torus(major: R, minor: 0.0062, segments: 16, sides: 8, arc: .pi * 0.7, material: bare), Xform(translation: V3(0, rcY, 0.0535), rotation: q(90, FA.X) * q(-215, FA.Y)))
        // Landing block under the ring.
        FA.box(&m, V3(0.034, 0.010, 0.030), V3(0, 0.005, 0.0535), paint, r: 0.0015)
        FJ.slab(&m, V3(0.028, 0.0012, 0.026), V3(0, 0.0102, 0.0535), bare)

        // Cast detail: parting-line seam round the boss and rust where water sits.
        for k in 0..<5 {
            let a = Float(k) * 1.256 + 0.4
            FJ.slab(&m, V3(0.006, 0.014, 0.0014), V3(cos(a) * 0.047, cy + sin(a) * 0.047, 0.0125), rust, rot: q(a * 180 / .pi - 90, FA.Z))
        }
                FJ.streak(&m, x: -0.027, top: 0.012, length: 0.011, width: 0.006, z: 0.012, rust)
        FJ.streak(&m, x: 0.027, top: 0.012, length: 0.008, width: 0.005, z: 0.012, rust)
        // Rear: casting nut on the boss and rust blooms in the face hollows.
        for e: Float in [-1, 1] {
            FC.bead(&m, r: 0.0022, at: V3(e * 0.0245, cy + 0.003, 0.0505), rust, sub: 2)
            FC.bead(&m, r: 0.0018, at: V3(e * 0.021, cy - 0.020, 0.0545), rust, sub: 2)
        }
        // Pitting and bare chips: rust specks on the boss rim and plate, bright chips on the plate edges and the lion's cheeks.
        for k in 0..<16 {
            let a = Float(k) * 0.39 + rng.float(0...0.2)
            FC.bead(&m, r: rng.float(0.0012...0.0021), at: V3(cos(a) * 0.0455, cy + sin(a) * 0.0455, 0.0128), rust, sub: 1)
        }
        for (x, y, w, h) in [(-0.0315, 0.0305, 0.009, 0.0045), (0.033, 0.0045, 0.008, 0.004), (0.0, 0.0315, 0.012, 0.003), (-0.034, 0.007, 0.003, 0.009)] as [(Float, Float, Float, Float)] {
            FJ.peel(&m, at: V3(x, y, 0.0121), w: w, h: h, bare, rng: &rng, rot: 0)
        }
        for e: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.0065, 0.0065, 0.004), exponent: 2.4, subdivisions: 2, material: bare), Xform(translation: V3(e * 0.0235, cy - 0.0155, 0.0535)))   // worn cheekbone
            FC.bead(&m, r: 0.0017, at: V3(e * 0.0063, rcY + R - 0.0005, 0.0585), rust, sub: 1)
        }
        groundAO(&m, height: 0.02, floor: 0.9)
        // Seat the cast to the stated 0.20 x 0.06 envelope regardless of the curl jitter.
        let bb = m.bounds
        let fit = m.transformed(Xform(scale: V3(1, 0.2 / (bb.max.y - bb.min.y), 0.06 / (bb.max.z - bb.min.z))))
        return LODModel(FC.place(fit))
    }
}
