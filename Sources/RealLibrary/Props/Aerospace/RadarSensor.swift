import simd
import Foundation

/// Airborne radar unit with a 0.3 m antenna, standing on its mounting bracket and facing +Z. A white
/// domed radome is screwed to a cast aluminium back shell with radial cooling fins; a machined bracket
/// with a gusseted foot carries it, and a coax connector and serial label sit on the back.
public struct RadarSensor: RealAsset {
    public static let id = "radar-sensor"
    public static let summary = "Airborne radar unit, 0.3 m dish: white domed radome on a finned aluminium back shell, carried on a base bracket with a coax connector."
    public static let tags = ["prop", "aerospace", "electronics"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.1, studio: true)

    /// Radome diameter (m).
    public var diameter: Float = 0.3
    /// Radome dome rise and back shell depth (m).
    public var domeRise: Float = 0.045
    public var shellDepth: Float = 0.06
    public var radome: MaterialKey = "plastic.white"
    public var shell: MaterialKey = "metal.aluminum-cast"
    public var bracket: MaterialKey = "metal.aluminum-brushed"
    public var fastener: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, cy = R + 0.03
        let toZ = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))     // lathe +Y -> +Z
        let z0 = -0.01                                               // shell/radome joint plane
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 56 : 24, bs = l == 0 ? 2 : 1
            // Back shell: shallow cup from the rim back to a flat rear face.
            m.add(Prim.lathe([V2(0, -shellDepth), V2(R - 0.03, -shellDepth), V2(R - 0.012, -shellDepth + 0.012), V2(R - 0.002, -0.012),
                              V2(R + 0.004, -0.008), V2(R + 0.004, 0), V2(R - 0.01, 0.001)], segments: sg, seamTile: 0.2, material: shell),
                  Xform(translation: V3(0, cy, Float(z0)), rotation: toZ))
            // Radome: low dome with a rolled edge sitting on the flange.
            var dome: [V2] = [V2(R + 0.002, 0), V2(R + 0.003, 0.006)]
            for k in 0...(l == 0 ? 12 : 5) {
                let t = Float(k) / Float(l == 0 ? 12 : 5)
                dome.append(V2((R - 0.004) * cos(t * .pi / 2) + 0.0001, 0.008 + domeRise * sin(t * .pi / 2)))
            }
            m.add(Prim.lathe(dome, segments: sg, seamTile: 0.3, material: radome), Xform(translation: V3(0, cy, Float(z0)), rotation: toZ))
            // Radial cooling fins on the back.
            if l == 0 {
                // Central electronics boss, ribs running from it to the shell shoulder.
                m.add(Prim.cylinder(radius: 0.05, height: 0.02, bevel: 0.003, segments: 32, material: shell),
                      Xform(translation: V3(0, cy, Float(z0) - shellDepth + 0.002), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                // Stiffening ring cast into the back.
                m.add(Prim.lathe([V2(0.085, 0), V2(0.085, 0.008), V2(0.089, 0.012), V2(0.097, 0.012), V2(0.101, 0.008), V2(0.101, 0)],
                                 segments: 48, seamTile: 0.2, material: shell),
                      Xform(translation: V3(0, cy, Float(z0) - shellDepth + 0.001), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                // Flange screws.
                for k in 0..<16 {
                    let a = (Float(k) + 0.5) / 16 * 2 * .pi
                    rivet(&m, at: V3(cos(a) * (R + 0.0005), cy + sin(a) * (R + 0.0005), Float(z0) - 0.004), normal: V3(cos(a), sin(a), 0), radius: 0.0032, segments: 6, material: fastener)
                }
                // Coax connector and label on the rear face.
                m.add(Prim.cylinder(radius: 0.011, height: 0.018, bevel: 0.0015, segments: 18, material: "metal.anodized:B9A46A"),
                      Xform(translation: V3(0.0, cy + 0.075, Float(z0) - shellDepth), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                m.add(Prim.cylinder(radius: 0.006, height: 0.024, bevel: 0.001, segments: 14, material: "plastic.matte:2A2C2E"),
                      Xform(translation: V3(0.0, cy + 0.075, Float(z0) - shellDepth - 0.016), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                m.add(Prim.roundedBox(V3(0.06, 0.03, 0.0008), radius: 0.0003, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: V3(0, cy, Float(z0) - shellDepth - 0.0184), rotation: simd_quatf(angle: rng.float(-0.05...0.05), axis: V3(0, 0, 1))))
            }
            // Bracket: foot plate, upright web with gussets, clamp pad under the shell.
            let footZ = Float(z0) - shellDepth / 2
            m.add(Prim.roundedBox(V3(0.16, 0.008, 0.15), radius: 0.003, bevelSegments: bs, material: bracket), Xform(translation: V3(0, 0.004, footZ)))
            m.add(Prim.roundedBox(V3(0.1, 0.05, 0.012), radius: 0.003, bevelSegments: bs, material: bracket), Xform(translation: V3(0, 0.031, footZ - 0.02)))
            for s: Float in [-1, 1] {
                m.add(Prim.extrude([V2(-0.035, 0), V2(0.03, 0), V2(-0.035, 0.045)], depth: 0.008, bevel: 0.0015, bevelSegments: 1, material: bracket),
                      Xform(translation: V3(s * 0.045, 0.008, footZ - 0.03), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 1, 0))))
            }
            if l == 0 {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    hexBolt(&m, at: V3(sx * 0.062, 0.008, footZ + sz * 0.055), normal: .up, size: 0.006, material: fastener)
                } }
            }
            levels.append(m)
        }
        groundAO(&levels[0], height: 0.05, floor: 0.6)
        groundAO(&levels[1], height: 0.05, floor: 0.6)
        return LODModel(levels: levels, switchDistances: [4])
    }
}
