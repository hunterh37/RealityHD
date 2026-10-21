import simd
import Foundation

/// Tripod spin feeder: 55 gallon blue plastic drum (58 cm, 88 cm tall) on a galvanized funnel and three braced steel
/// legs, ring-clamp lid, solar panel, battery and timer box, motor housing and spinner plate 1.2 m up,
/// corn spilled on a scuffed dirt ring. About 2.6 m tall.
public struct DeerFeeder: RealAsset {
    public static let id = "deer-feeder"
    public static let summary = "Tripod spin feeder: 55 gallon drum, galvanized funnel, braced steel legs, solar panel, timer box, spinner plate, spilled corn."
    public static let tags = ["prop", "hunting", "outdoor", "metal", "plastic"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 12, distance: 1.1)

    /// Drum radius and height in meters.
    public var drum = V2(0.29, 0.88)
    /// Height of the drum base above the ground in meters.
    public var drumBase: Float = 1.62
    /// Leg foot radius in meters.
    public var footRadius: Float = 0.72
    /// Drum color (sRGB hex).
    public var drumColor: UInt32 = 0x28578A
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let plastic = "plastic.white:" + HuntCampKit.hex(drumColor)
        let steel = "metal.galvanized-aged", zinc = "metal.galvanized"
        let R = drum.x, DH = drum.y, y0 = drumBase
        let legTopR: Float = 0.33, legTopY = y0 - 0.02

        // Scuffed dirt ring and spilled corn under the spinner.
        var dirt = Prim.extrude(Shape2D.circle(0.58, segments: 36).enumerated().map { (i, p) in p * (1 + 0.06 * Float(Noise.perlin(V3(p.x * 6, 2, p.y * 6)))) },
                                depth: 0.012, bevel: 0.005, bevelSegments: 1, material: "ground.dirt")
        dirt.displace { p, _ in Float(Noise.fbm(V3(p.x * 25, p.y * 25, p.z * 25), octaves: 3)) * 0.004 }
        m.add(dirt, Xform(translation: V3(0, 0.006, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        for _ in 0..<45 {
            let p = rng.inDisc(radius: 0.38)
            let r = simd_length(p) / 0.38
            if rng.float() < r * r * 0.5 { continue }
            let k = Prim.superellipsoid(V3(0.012, 0.0075, 0.0075), exponent: 2.6, subdivisions: 2, material: "plastic.matte:" + (rng.chance(0.2) ? "C79224" : "DDAE2F"))
            m.add(k, Xform(translation: V3(p.x, 0.014 + rng.float(0...0.006), p.y),
                           rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(0...50), axis: V3(0, 0, 1))))
        }

        // Legs: square tube from foot plate to the funnel collar, with a braced triangle at 0.62 m.
        func legR(_ y: Float) -> Float { footRadius + (legTopR - footRadius) * min(1, y / legTopY) }
        var legAt: [Float] = []
        for i in 0..<3 { legAt.append((90 + Float(i) * 120) * .pi / 180) }
        func pt(_ a: Float, _ r: Float, _ y: Float) -> V3 { V3(cos(a) * r, y, sin(a) * r) }
        for a in legAt {
            let foot = pt(a, footRadius, 0.012), top = pt(a, legTopR, legTopY)
            HuntCampKit.bar(&m, foot, top, w: 0.048, t: 0.048, up: V3(-sin(a), 0, cos(a)), mat: "metal.powdercoat:3B3E36", bevel: 0.004)
            // Foot plate with two bolt holes and a ground pin.
            m.add(Prim.roundedBox(V3(0.12, 0.012, 0.12), radius: 0.004, bevelSegments: 1, material: steel),
                  Xform(translation: V3(foot.x, 0.006, foot.z), rotation: simd_quatf(degrees: -a * 180 / .pi, axis: .up)))
            // Collar bracket to the funnel ring.
            HuntCampKit.bar(&m, top + V3(0, 0.0, 0), pt(a, R + 0.015, legTopY + 0.02), w: 0.05, t: 0.012, up: .up, mat: steel, bevel: 0.002)
            for k: Float in [-0.012, 0.012] { hexBolt(&m, at: pt(a, legTopR + 0.0, legTopY + 0.03) + V3(-sin(a), 0, cos(a)) * k * 2, normal: V3(cos(a), 0, sin(a)), size: 0.011, material: "metal.screw-zinc") }
        }
        let by: Float = 0.62
        for i in 0..<3 {
            let a0 = legAt[i], a1 = legAt[(i + 1) % 3]
            HuntCampKit.bar(&m, pt(a0, legR(by), by), pt(a1, legR(by), by), w: 0.032, t: 0.006, up: .up, mat: steel, bevel: 0.002)
            HuntCampKit.bar(&m, pt(a0, legR(by) - 0.02, by - 0.05), pt(a1, legR(by) - 0.02, by - 0.05), w: 0.028, t: 0.006, up: .up, mat: steel, bevel: 0.002)
        }
        // Funnel: galvanized cone from the drum to the discharge tube, rolled rim and a seam band.
        m.add(turned([(0.036, y0 - 0.34), (0.036, y0 - 0.30), (0.075, y0 - 0.26), (0.19, y0 - 0.14), (0.272, y0 - 0.024), (R + 0.012, y0 - 0.012), (R + 0.012, y0 + 0.03), (R - 0.02, y0 + 0.03)],
                      segments: 40, material: zinc), Xform())
        m.add(Prim.torus(major: R + 0.014, minor: 0.008, segments: 40, sides: 8, material: steel), Xform(translation: V3(0, y0 + 0.012, 0)))
        // Drum: rolled chimes, two rolling hoops, shoulder, lid with two bungs; ring clamp with lever bolt.
        let t: [(Float, Float)] = [(R - 0.03, 0.0), (R + 0.004, 0.012), (R + 0.004, 0.045), (R - 0.003, 0.055),
                                   (R - 0.003, DH * 0.28), (R + 0.006, DH * 0.285), (R + 0.006, DH * 0.31), (R - 0.003, DH * 0.315),
                                   (R - 0.003, DH * 0.64), (R + 0.006, DH * 0.645), (R + 0.006, DH * 0.67), (R - 0.003, DH * 0.675),
                                   (R - 0.003, DH - 0.06), (R + 0.004, DH - 0.05), (R + 0.004, DH - 0.012), (R - 0.01, DH),
                                   (R - 0.035, DH - 0.004), (R - 0.04, DH - 0.012), (0.0, DH - 0.012)]
        m.add(turned(t, segments: 56, material: plastic, seamTile: 0.2), Xform(translation: V3(0, y0, 0)))
        m.add(Prim.torus(major: R + 0.012, minor: 0.007, segments: 56, sides: 8, material: steel), Xform(translation: V3(0, y0 + DH - 0.03, 0)))
        m.add(Prim.roundedBox(V3(0.05, 0.034, 0.03), radius: 0.005, bevelSegments: 1, material: steel), Xform(translation: V3(R + 0.03, y0 + DH - 0.03, 0)))
        HuntCampKit.rod(&m, V3(R + 0.052, y0 + DH - 0.03, 0), V3(R + 0.052, y0 + DH + 0.045, 0), r: 0.005, mat: steel)
        for s: Float in [-1, 1] {
            m.add(turned([(0, 0), (0.026, 0), (0.026, 0.012), (0.021, 0.016), (0, 0.016)], segments: 16, material: plastic),
                  Xform(translation: V3(s * 0.14, y0 + DH - 0.012, 0.09)))
        }
        // Solar panel on a mast above the lid.
        let sp = V3(0, y0 + DH + 0.015, 0)
        HuntCampKit.rod(&m, sp, sp + V3(0, 0.085, -0.02), r: 0.009, mat: steel)
        let tilt = simd_quatf(degrees: -25, axis: V3(1, 0, 0))
        m.add(Prim.roundedBox(V3(0.27, 0.014, 0.2), radius: 0.003, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: sp + V3(0, 0.11, -0.02), rotation: tilt))
        m.add(Prim.roundedBox(V3(0.25, 0.004, 0.18), radius: 0.001, bevelSegments: 1, material: "glass.tinted"), Xform(translation: sp + V3(0, 0.1195, -0.0225) + tilt.act(V3(0, 0.002, 0)), rotation: tilt))
        // Motor housing, discharge, spinner plate with vanes; timer box and battery lead on a leg.
        m.add(Prim.roundedBox(V3(0.11, 0.1, 0.09), radius: 0.012, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, y0 - 0.39, 0)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.06, bevel: 0.002, segments: 12, material: steel), Xform(translation: V3(0, y0 - 0.49, 0)))
        m.add(turned([(0.0, 0.0), (0.03, 0.0), (0.15, 0.004), (0.158, 0.012), (0.152, 0.014), (0.03, 0.01), (0.0, 0.012)], segments: 40, material: zinc),
              Xform(translation: V3(0, y0 - 0.51, 0)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + 0.4
            HuntCampKit.bar(&m, pt(a, 0.035, y0 - 0.495), pt(a, 0.14, y0 - 0.495), w: 0.012, t: 0.004, up: .up, mat: steel, bevel: 0.001)
        }
        let la = legAt[1]
        let boxAt = pt(la, legR(1.3) + 0.0, 1.3)
        m.add(Prim.roundedBox(V3(0.15, 0.2, 0.08), radius: 0.008, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: boxAt + V3(cos(la), 0, sin(la)) * 0.052, rotation: simd_quatf(degrees: -la * 180 / .pi + 90, axis: .up)))
        let cable = catmull([boxAt + V3(0, 0.1, 0) + V3(cos(la), 0, sin(la)) * 0.05, V3(cos(la) * 0.34, y0 - 0.35, sin(la) * 0.34), V3(0, y0 - 0.37, 0.05)], per: 6)
        m.add(Prim.tube(cable, radii: cable.map { _ in 0.0035 }, sides: 6, seamTile: 0.03, material: "plastic.black"))
        groundAO(&m, height: 0.5, floor: 0.7)
        return LODModel(m)
    }
}
