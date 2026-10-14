import simd
import Foundation

/// Low-profile baitcast reel standing on its foot, front (+X) toward the rod tip, spool axis across the
/// rod (Z): two anodized side plates (palming side and handle side), cross bars, thumb bar, level-wind
/// with its line guide and worm gear, spool loaded with braid, star drag, cast control knob and a double
/// paddle handle on +Z.
/// Parts: `body`, `spool` (follows the crank 6.4:1), `handle` (spin). Anchors: `reelFoot` (-Y), `lineOut` (+X, level wind).
public struct ReelBaitcast: RealArticulated, RealAnchored {
    public static let id = "reel-baitcast"
    public static let summary = "Low-profile baitcast reel: side plates, spool with line, level wind, star drag, double paddle handle."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 22, distance: 1.0, studio: true)

    /// Side plate colour (sRGB hex).
    public var bodyColor: UInt32 = 0x7A1E1C
    /// Line colour (braid).
    public var lineColor: UInt32 = 0x5E7A3A
    public init() {}

    static let yc: Float = 0.032
    static let offset = V3(0.004, 0, -0.012)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.031, yc - 0.004, 0.003) + offset, direction: V3(1, 0, 0))]
    }

    /// Side plate outline in XY: a rounded teardrop, deeper at the rear gear housing.
    static func plate(_ s: Float) -> [V2] {
        var p: [V2] = []
        for i in 0..<56 {
            let a = Float(i) / 56 * 2 * .pi
            let r: Float = 0.0295 + 0.004 * max(0, -cos(a)) * (1 - abs(sin(a)) * 0.4)
            p.append(V2(cos(a) * r, sin(a) * r * 0.97) * s)
        }
        return p
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc
        let body: MaterialKey = "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor)
        let frame: MaterialKey = "metal.anodized-gunmetal", dark: MaterialKey = "plastic.black", chrome: MaterialKey = "metal.chrome"
        let line: MaterialKey = "plastic.line:" + String(format: "%06X", lineColor)
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }
        let c = V3(0, yc, 0)

        rig.part("body", pivot: c + o, joint: .fixed)
        add(ReelKit.foot(length: 0.056, width: 0.011, thick: 0.003, mat: frame), .identity, "body")
        // Pillar from the foot into the frame.
        add(Prim.roundedBox(V3(0.03, 0.006, 0.01), radius: 0.002, bevelSegments: 1, material: frame), Xform(translation: V3(-0.002, 0.005, 0)), "body")
        // Side plates: palming side (-Z) and handle side (+Z, deeper gear housing), domed caps.
        for side: Float in [-1, 1] {
            let thick: Float = side > 0 ? 0.014 : 0.01
            add(Prim.extrude(Shape2D.rounded(Self.plate(1), radius: 0.003), depth: thick, bevel: 0.003, bevelSegments: 2, material: body),
                Xform(translation: c + V3(0, 0, side * (0.0165 + thick / 2))), "body")
            add(Prim.superellipsoid(V3(0.04, 0.04, 0.008), exponent: 2.4, subdivisions: 7, material: body),
                Xform(translation: c + V3(-0.002, 0, side * (0.0165 + thick))), "body")
        }
        // Frame cross bars (front top, rear bottom) and thumb bar at the rear top.
        for (p, r) in [(V3(0.017, 0.02, 0), Float(0.0026)), (V3(-0.021, -0.017, 0), 0.0028), (V3(0.004, -0.026, 0), 0.0026)] {
            add(ReelKit.latheZ([V2(r, 0), V2(r, 0.034)], z0: -0.017, x: p.x, y: yc + p.y, seg: 14, frame), .identity, "body")
        }
        var thumb: [V3] = []
        for i in 0...8 { let t = Float(i) / 8; thumb.append(V3(-0.026 - 0.004 * sin(t * .pi), yc + 0.02 + 0.006 * sin(t * .pi), -0.016 + 0.032 * t)) }
        add(Prim.sweep(Shape2D.roundedRect(0.008, 0.0035, radius: 0.0015), along: thumb, up: V3(1, 1, 0), material: dark), .identity, "body")
        // Level wind: guide housing on a worm-gear bar at the front, with the line passing through.
        // Level wind: chrome tube over the worm gear (cross-cut ridges) with the line guide riding on it.
        var worm: [V2] = []
        for i in 0...34 { worm.append(V2(i % 2 == 0 ? 0.0026 : 0.0023, 0.033 * Float(i) / 34)) }
        add(ReelKit.latheZ(worm, z0: -0.0165, x: 0.023, y: yc - 0.014, seg: 14, chrome), .identity, "body")
        add(ReelKit.latheZ([V2(0.0014, 0), V2(0.0014, 0.033)], z0: -0.0165, x: 0.026, y: yc - 0.006, seg: 10, chrome), .identity, "body")
        add(Prim.roundedBox(V3(0.009, 0.016, 0.009), radius: 0.002, bevelSegments: 2, material: dark), Xform(translation: V3(0.025, yc - 0.008, 0.003)), "body")
        add(Prim.torus(major: 0.0022, minor: 0.0007, segments: 14, sides: 6, material: "ceramic.guide-insert").transformed(Xform(translation: V3(0.0298, yc - 0.004, 0.003), rotation: RodKit.alongX)), .identity, "body")
        // Cast control knob (handle side) and brake dial (palming side).
        add(ReelKit.latheZ(ReelKit.ribbedKnob(r: 0.0075, len: 0.0045, ridges: 6), z0: 0.034, x: 0.008, y: yc + 0.004, seg: 24, dark), .identity, "body")
        add(ReelKit.latheZ(ReelKit.ribbedKnob(r: 0.009, len: 0.0035, ridges: 4), z0: -0.0335, x: -0.006, y: yc, seg: 24, frame), .identity, "body")

        // Handle: hub behind the spool on +Z, star drag, double paddle arm.
        let hub = V3(-0.014, yc - 0.002, 0.036)
        rig.part("handle", pivot: hub + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.0))
        rig.part("spool", pivot: c + o, joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...2304, mimic: .init("handle", ratio: 6.4)))
        // Spool: flanges and braid.
        for z: Float in [-0.0155, 0.0135] {
            add(ReelKit.latheZ([V2(0.004, 0), V2(0.0175, 0.0002), V2(0.018, 0.001), V2(0.0175, 0.0019), V2(0.004, 0.002)], z0: z, x: 0, y: yc, seg: 36, frame), .identity, "spool")
        }
        add(ReelKit.latheZ(ReelKit.lineFill(r: 0.0158, core: 0.008, len: 0.0272), z0: -0.0136, x: 0, y: yc, seg: 36, tile: 0.02, line), .identity, "spool")
        // Star drag (5 points).
        var star: [V2] = []
        for i in 0..<10 { let a = Float(i) / 10 * 2 * .pi + .pi / 2; let r: Float = i % 2 == 0 ? 0.0125 : 0.0065; star.append(V2(cos(a) * r, sin(a) * r)) }
        add(Prim.extrude(Shape2D.rounded(star, radius: 0.0016), depth: 0.0035, bevel: 0.0006, bevelSegments: 1, material: frame), Xform(translation: hub + V3(0, 0, 0.002)), "handle")
        add(ReelKit.latheZ([V2(0.005, 0), V2(0.005, 0.006), V2(0.0035, 0.0072), V2(0, 0.0075)], z0: hub.z + 0.003, x: hub.x, y: hub.y, seg: 20, chrome), .identity, "handle")
        let armLen: Float = 0.043
        let arm = Shape2D.rounded([V2(-armLen, -0.004), V2(-0.004, -0.0065), V2(0.004, -0.0065), V2(armLen, -0.004), V2(armLen, 0.004), V2(0.004, 0.0065), V2(-0.004, 0.0065), V2(-armLen, 0.004)], radius: 0.003)
        let tilt = simd_quatf(angle: 0.35, axis: V3(0, 0, 1))
        add(Prim.extrude(arm, depth: 0.003, bevel: 0.0008, bevelSegments: 1, material: frame), Xform(translation: hub + V3(0, 0, 0.0095), rotation: tilt), "handle")
        add(ReelKit.latheZ([V2(0.0045, 0), V2(0.0048, 0.002), V2(0.0038, 0.004), V2(0, 0.0042)], z0: hub.z + 0.011, x: hub.x, y: hub.y, seg: 16, chrome), .identity, "handle")
        for s: Float in [-1, 1] {
            let k = hub + tilt.act(V3(s * (armLen - 0.004), 0, 0))
            add(ReelKit.latheZ([V2(0.0016, 0), V2(0.0016, 0.004)], z0: hub.z + 0.011, x: k.x, y: k.y, seg: 10, chrome), .identity, "handle")
            add(Prim.superellipsoid(V3(0.012, 0.022, 0.012), exponent: 2.4, subdivisions: 6, material: dark),
                Xform(translation: V3(k.x, k.y, hub.z + 0.021), rotation: tilt), "handle")
        }
        _ = rng.float()
        rig.states = [RigState("rest"), RigState("cranked", ["handle": 90])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
