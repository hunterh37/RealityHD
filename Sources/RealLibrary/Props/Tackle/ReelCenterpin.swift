import simd
import Foundation

/// Centerpin float reel, 120 mm, standing on its foot (mounted, it hangs under the rod), spool face toward
/// +Z and the spool axis across the rod: machined back plate on a pillar and foot, free-running wide spool
/// with ten ported holes in the face, two handle knobs near the rim (no gearing), check button and a line guard.
/// Parts: `body`, `spool` (free running, 1:1 with the knobs), `check` (on/off). Anchors: `reelFoot` (-Y), `lineOut` (+X).
public struct ReelCenterpin: RealArticulated, RealAnchored {
    public static let id = "reel-centerpin"
    public static let summary = "Centerpin float reel, 120 mm: machined back plate, free-running ported spool, rim knobs, check button."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.0, studio: true)

    /// Spool and plate colour (sRGB hex).
    public var bodyColor: UInt32 = 0x6E747A
    /// Line colour.
    public var lineColor: UInt32 = 0xE8D84A
    /// Spool radius (m).
    public var radius: Float = 0.06
    public init() {}

    static let yc: Float = 0.071
    static let offset = V3(0, 0, 0.002)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.05, yc - 0.0, 0) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc, R = radius
        let body: MaterialKey = "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor)
        let dark: MaterialKey = "plastic.black", bright: MaterialKey = "metal.aluminum-brushed"
        let line: MaterialKey = "plastic.line:" + String(format: "%06X", lineColor)
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }
        let c = V3(0, yc, 0)

        rig.part("body", pivot: c + o, joint: .fixed)
        add(ReelKit.foot(length: 0.062, width: 0.012, thick: 0.0032, mat: bright), .identity, "body")
        // Pillar from the foot to the back plate (behind the spool, -Z).
        add(Prim.roundedBox(V3(0.018, yc - R + 0.012, 0.008), radius: 0.003, bevelSegments: 2, material: body), Xform(translation: V3(0, (yc - R + 0.012) / 2 + 0.002, -0.014)), "body")
        // Back plate: thin disc with a bevelled rim, a raised centre boss and spindle cap.
        add(ReelKit.latheZ([V2(0, 0), V2(R - 0.004, 0), V2(R - 0.0025, 0.0012), V2(R - 0.0025, 0.0032), V2(R - 0.004, 0.0042), V2(0, 0.0042)], z0: -0.0215, x: 0, y: yc, seg: 56, tile: 0.05, body), .identity, "body")
        add(ReelKit.latheZ([V2(0, 0), V2(0.009, 0), V2(0.0095, 0.004), V2(0.008, 0.005), V2(0, 0.005)], z0: -0.026, x: 0, y: yc, seg: 28, bright), .identity, "body")
        // Line guard: a bar across the front opening, between plate and spool rim.
        add(ReelKit.latheZ([V2(0.0018, 0), V2(0.0018, 0.036)], z0: -0.0175, x: R * 0.72, y: yc - R * 0.7, seg: 12, bright), .identity, "body")

        // Check: a slide button on the back plate rim.
        rig.part("check", pivot: V3(-R * 0.6, yc + R * 0.6, -0.024) + o, joint: .slide(axis: V3(-0.7, 0.7, 0), 0...0.004, duration: 0.15))
        add(Prim.roundedBox(V3(0.012, 0.007, 0.004), radius: 0.0018, bevelSegments: 1, material: dark), Xform(translation: V3(-R * 0.6, yc + R * 0.6, -0.0235), rotation: simd_quatf(angle: -.pi / 4, axis: V3(0, 0, 1))), "check")

        // Spool: back flange, wide arbor with line, ported front face, rim, two knobs.
        rig.part("spool", pivot: c + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 0.8))
        add(ReelKit.latheZ([V2(0.009, 0), V2(R - 0.001, 0), V2(R, 0.001), V2(R, 0.0022), V2(0.009, 0.0022)], z0: -0.017, x: 0, y: yc, seg: 56, body), .identity, "spool")
        add(ReelKit.latheZ(ReelKit.lineFill(r: R - 0.0055, core: R - 0.012, len: 0.03), z0: -0.0148, x: 0, y: yc, seg: 56, tile: 0.02, line), .identity, "spool")
        add(ReelKit.latheZ([V2(0.009, 0), V2(R - 0.001, 0), V2(R, 0.0012), V2(R, 0.0035), V2(R - 0.0015, 0.0045), V2(0.012, 0.0045), V2(0.009, 0.003)], z0: 0.0152, x: 0, y: yc, seg: 56, tile: 0.05, body), .identity, "spool")
        // Ports: ten round holes drilled through the face (dark recesses showing line beneath).
        for k in 0..<10 {
            let a = Float(k) / 10 * 2 * .pi
            let pr: Float = 0.0075
            add(ReelKit.latheZ([V2(0, 0), V2(pr, 0), V2(pr, 0.0004), V2(0, 0.0004)], z0: 0.0196, x: cos(a) * R * 0.62, y: yc + sin(a) * R * 0.62, seg: 18, dark), .identity, "spool")
            add(Prim.torus(major: pr + 0.0004, minor: 0.0005, segments: 18, sides: 5, material: bright)
                .transformed(Xform(translation: V3(cos(a) * R * 0.62, yc + sin(a) * R * 0.62, 0.0199), rotation: ReelKit.alongZ)), .identity, "spool")
        }
        // Centre hub nut.
        add(ReelKit.latheZ([V2(0, 0.004), V2(0.008, 0.0038), V2(0.0105, 0.002), V2(0.0105, 0), V2(0.006, 0)].reversed(), z0: 0.0196, x: 0, y: yc, seg: 24, bright), .identity, "spool")
        // Two knobs opposite each other near the rim.
        for a: Float in [0.9, 0.9 + .pi] {
            let k = V3(cos(a) * R * 0.86, yc + sin(a) * R * 0.86, 0)
            add(ReelKit.latheZ([V2(0, 0), V2(0.0035, 0.0002), V2(0.0035, 0.0015), V2(0.0024, 0.0022), V2(0, 0.0024)], z0: 0.0196, x: k.x, y: k.y, seg: 14, bright), .identity, "spool")
            add(ReelKit.latheZ([V2(0, 0), V2(0.0042, 0.0003), V2(0.0046, 0.002), V2(0.0046, 0.013), V2(0.0038, 0.015), V2(0, 0.0155)], z0: 0.0218, x: k.x, y: k.y, seg: 18, "wood.seat-burl"), .identity, "spool")
        }
        _ = rng.float()
        rig.states = [RigState("rest"), RigState("check-on", ["check": 0.004]), RigState("spun", ["spool": 200])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
