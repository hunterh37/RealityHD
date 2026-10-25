import simd
import Foundation

/// Coastal solid-wood hurricane shutter pair, 1.2 m wide, closed: two leaves of five tongue-and-groove
/// cypress planks with dark joint lines, Z-braced with top and bottom battens and a diagonal brace
/// (nailed through each plank), arrow-tail strap hinges on wall pintles, a slide bolt with keepers and
/// strike plate, and a hook-and-eye stay. Salt-weathered teal paint, peeling to bare grey wood in the
/// splash zone, one replacement plank in fresher paint, one split plank.
public struct SolidWoodHurricaneShutter: RealAsset {
    public static let id = "solid-wood-hurricane-shutter"
    public static let summary = "Coastal solid-wood hurricane shutter pair, 1.2 m wide: tongue-and-groove planks on Z-battens with strap hinges and slide bolt."
    public static let tags = ["prop", "architecture", "facade", "window", "wood", "metal"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.7, studio: true)

    /// Overall width and height (m).
    public var width: Float = 1.2
    public var height: Float = 1.5
    /// Paint colour (sRGB hex).
    public var paint: UInt32 = 0x275866
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    func tone(_ k: Float) -> MaterialKey {
        func ch(_ v: UInt32) -> UInt32 { UInt32(max(0, min(255, Float(v) * (1 + k)))) }
        return "wood.painted-shaker-worn:" + String(format: "%02X%02X%02X", ch(paint >> 16 & 255), ch(paint >> 8 & 255), ch(paint & 255))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let lw = W / 2 - 0.002                 // leaf width
        let zP: Float = 0.012, tP: Float = 0.02 // plank back face and thickness
        let zB = zP + tP, tB: Float = 0.018    // batten back face and thickness
        let np = 5
        let pw = lw / Float(np)
        let replaced = 7                        // replacement plank index across both leaves (leaf 1, plank 2)
        for (li, e) in ([-1, 1] as [Float]).enumerated() {
            let xIn = e * 0.002, xOut = e * (W / 2)           // inner and hinge edges
            func cx(_ f: Float) -> Float { xIn + (xOut - xIn) * f }  // f 0 at centre seam, 1 at hinge edge
            // Planks: hinge side first. Joint lines are dark strips behind a 1 mm gap.
            for p in 0..<np {
                let f0 = Float(p) / Float(np), f1 = Float(p + 1) / Float(np)
                let x = (cx(f0) + cx(f1)) / 2
                let idx = li * np + p
                let k = idx == replaced ? 0.18 : rng.float(-0.1...0.06)
                FA.box(&m, V3(pw - 0.0012, H, tP), V3(x, H / 2, zP + tP / 2), tone(k), r: 0.0035)
                // tongue-and-groove joint: dark seam strip just behind, and a bead on the groove side
                FA.box(&m, V3(0.003, H - 0.01, 0.004), V3(cx(f1), H / 2, zP + 0.002), "wood.weathered", r: 0.0008)
                // grain-direction split on one plank
                if idx == 3 { FA.box(&m, V3(0.0012, 0.55, 0.0014), V3(x + 0.015, 0.62, zP + tP + 0.0004), "wood.charred", r: 0.0003) }
                // bare wood where paint has peeled in the splash zone (not on the replaced plank)
                if idx != replaced {
                    for n in 0..<(4 + rng.int(0...2)) {
                        // Peel runs with the grain along plank edges; a few squarer splash scabs low down.
                        let sliver = n < 3
                        let ph = sliver ? rng.float(0.06...0.2) : rng.float(0.015...0.035)
                        let pwid = sliver ? rng.float(0.005...0.014) : rng.float(0.02...0.045)
                        let y = sliver ? rng.float(0.2...1.35) : rng.float(0.02...0.3)
                        let px = sliver ? cx(f0 + 0.04) + (rng.chance(0.5) ? 0 : cx(f1 - 0.04) - cx(f0 + 0.04)) : x + rng.float(-0.02...0.02)
                        FA.box(&m, V3(pwid, ph, 0.001), V3(px, y, zP + tP + 0.0003), rng.chance(0.6) ? "wood.weathered" : "wood.driftwood", r: 0.0004)
                    }
                }
            }
            // Battens: top, bottom and diagonal brace, on the outer face.
            let bh: Float = 0.1
            let zb = zB + tB / 2
            for yc in [H - 0.11, 0.11] as [Float] {
                FA.box(&m, V3(lw - 0.016, bh, tB), V3(cx(0.5), yc, zb), tone(-0.05), r: 0.004)
            }
            let yTop = H - 0.11 - bh / 2, yBot = 0.11 + bh / 2
            let a = V2(cx(0.5 + (lw - 0.016) / lw / 2 - 0.12 / lw), yBot), b = V2(cx(0.5 - (lw - 0.016) / lw / 2 + 0.12 / lw), yTop)
            // Brace runs from the hinge-side bottom to the latch-side top.
            let hingeBot = V2(cx(0.5 + 0.5 - 0.08), yBot), latchTop = V2(cx(0.5 - 0.5 + 0.08), yTop)
            let d = latchTop - hingeBot
            let len = simd_length(d), ang = atan2(d.y, d.x) * 180 / .pi
            FA.box(&m, V3(len + 0.03, 0.085, tB), V3((hingeBot.x + latchTop.x) / 2, (hingeBot.y + latchTop.y) / 2, zb), tone(-0.03), r: 0.004, rot: FA.q(ang, FA.Z))
            _ = (a, b)
            // Nails through planks into battens (3 batten lines).
            for p in 0..<np {
                let x = (cx(Float(p) / Float(np)) + cx(Float(p + 1) / Float(np))) / 2
                for yc in [H - 0.11, 0.11] as [Float] {
                    FSH.nut(&m, at: V3(x, yc + (p % 2 == 0 ? 0.02 : -0.02), zB + tB), normal: FA.Z, size: 0.012, rng.chance(0.35) ? "metal.rust" : "metal.screw-zinc")
                }
                let t = (x - hingeBot.x) / (latchTop.x - hingeBot.x)
                if t > 0.02 && t < 0.98 { FSH.nut(&m, at: V3(x, hingeBot.y + d.y * t, zB + tB), normal: FA.Z, size: 0.012, "metal.screw-zinc") }
            }
            // Strap hinges: arrow-tail strap on the top and bottom battens, barrel round the pintle.
            for yc in [H - 0.11, 0.11] as [Float] {
                let L: Float = 0.46
                let strap: [V2] = [V2(0, -0.021), V2(L - 0.06, -0.021), V2(L, 0), V2(L - 0.06, 0.021), V2(0, 0.021)]
                let flip: Float = e > 0 ? -1 : 1   // strap extends from the hinge edge toward the centre
                m.add(Prim.extrude(strap, depth: 0.005, bevel: 0.0008, bevelSegments: 1, material: iron),
                      Xform(translation: V3(xOut + e * 0.006, yc, zB + tB + 0.0025), rotation: simd_quatf(angle: e > 0 ? .pi : 0, axis: FA.Y) * simd_quatf(angle: 0, axis: FA.Z)))
                _ = flip
                // barrel round the pintle (vertical)
                m.add(Prim.cylinder(radius: 0.0125, height: 0.048, bevel: 0.001, segments: 10, bevelSegments: 1, material: iron),
                      Xform(translation: V3(xOut + e * 0.0045, yc - 0.024, zB + tB * 0.4)))
                FSH.nut(&m, at: V3(xOut - e * 0.04, yc, zB + tB + 0.005), normal: FA.Z, size: 0.013, "metal.screw-zinc")
                FSH.nut(&m, at: V3(xOut - e * 0.14, yc, zB + tB + 0.005), normal: FA.Z, size: 0.013, "metal.rust")
                // wall pintle plate with pin
                FA.box(&m, V3(0.012, 0.07, 0.03), V3(xOut + e * 0.013, yc, 0.016), iron, r: 0.0015)
                m.add(Prim.cylinder(radius: 0.0065, height: 0.1, bevel: 0.0008, segments: 8, bevelSegments: 1, material: "metal.rust"),
                      Xform(translation: V3(xOut + e * 0.0045, yc - 0.05, zB + tB * 0.4)))
            }
        }
        // Slide bolt on the left leaf: plate, barrel, two guides, knob; strike on the right leaf.
        let yb: Float = 0.78, zs = zP + tP + 0.002
        FA.box(&m, V3(0.2, 0.04, 0.004), V3(-0.12, yb, zs), iron, r: 0.002)
        FA.cylX(&m, r: 0.0065, h: 0.2, at: V3(-0.2, yb, zs + 0.009), iron, bevel: 0.001, segments: 8)
        for x in [-0.17, -0.07] as [Float] { FA.box(&m, V3(0.014, 0.022, 0.011), V3(x, yb, zs + 0.0085), iron, r: 0.002) }
        FA.rod(&m, V3(-0.1, yb, zs + 0.012), V3(-0.1, yb + 0.03, zs + 0.012), r: 0.0035, iron, sides: 5)
        FC.bead(&m, r: 0.0085, at: V3(-0.1, yb + 0.034, zs + 0.012), iron, sub: 3)
        FA.box(&m, V3(0.04, 0.05, 0.004), V3(0.035, yb, zs), iron, r: 0.002)
        FA.box(&m, V3(0.014, 0.022, 0.011), V3(0.032, yb, zs + 0.0085), iron, r: 0.002)
        for (x, y) in [(-0.2, 0.0), (-0.04, 0.0), (0.04, 0.015), (0.04, -0.015)] as [(Float, Float)] {
            FSH.nut(&m, at: V3(x, yb + y, zs + 0.002), normal: FA.Z, size: 0.012, "metal.screw-zinc")
        }
        // Hook-and-eye stay across the seam near the foot.
        let ys: Float = 0.3
        FA.rod(&m, V3(-0.19, ys, zs + 0.012), V3(-0.015, ys, zs + 0.012), r: 0.0035, iron, sides: 5)
        m.add(Prim.torus(major: 0.01, minor: 0.0032, segments: 12, sides: 5, material: iron), Xform(translation: V3(-0.015, ys + 0.0, zs + 0.012), rotation: facing(V3(0, 0, 1))))
        m.add(Prim.torus(major: 0.011, minor: 0.0034, segments: 12, sides: 5, material: iron), Xform(translation: V3(0.035, ys, zs + 0.008), rotation: facing(V3(0, 0, 1))))
        FA.box(&m, V3(0.03, 0.02, 0.004), V3(-0.19, ys, zs), iron, r: 0.0015)
        // Rust bleed under the lower hinge barrels.
        for e: Float in [-1, 1] { FA.box(&m, V3(0.012, 0.09, 0.0008), V3(e * (W / 2 - 0.03), 0.06, zB + tB + 0.0004), "metal.rust-grime", r: 0.0003) }
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.seatY(m))
    }
}
