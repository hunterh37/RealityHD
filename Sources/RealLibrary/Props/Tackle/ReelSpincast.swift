import simd
import Foundation

/// Closed-face spincast reel standing on its foot (mounted, it sits on top of the rod), front (+X) toward
/// the rod tip: rounded rear housing on a short stem, chrome front cover tapering to a nose cone with a
/// ceramic line hole, rubber thumb button at the rear, star drag dial and a twin-knob crank on +Z.
/// Parts: `body`, `button` (press slides it forward), `handle` (spin). Anchors: `reelFoot` (-Y), `lineOut` (+X, nose hole).
public struct ReelSpincast: RealArticulated, RealAnchored {
    public static let id = "reel-spincast"
    public static let summary = "Closed-face spincast reel: rear housing, chrome nose cone with line hole, thumb button, star drag, twin-knob crank."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 20, distance: 1.0, studio: true)

    /// Rear housing colour (sRGB hex).
    public var bodyColor: UInt32 = 0x23262B
    /// Front cover finish (chrome by default).
    public var coverMaterial: MaterialKey = "metal.chrome"
    public init() {}

    static let yc: Float = 0.043
    static let offset = V3(-0.004, 0, -0.008)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.0461, yc, 0) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc
        let body: MaterialKey = "plastic.black:" + String(format: "%06X", bodyColor)
        let frame: MaterialKey = "metal.anodized-gunmetal", chrome = coverMaterial, rubber: MaterialKey = "rubber"
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }

        rig.part("body", pivot: V3(0, yc, 0) + o, joint: .fixed)
        add(ReelKit.foot(length: 0.052, width: 0.011, thick: 0.003, mat: frame), .identity, "body")
        // Stem: a short swept web from the foot up into the housing.
        var stem: [V3] = []
        for i in 0...6 { let t = Float(i) / 6; stem.append(V3(-0.004 * t, 0.002 + 0.024 * t, 0)) }
        add(Prim.sweep(Shape2D.roundedRect(0.024, 0.008, radius: 0.0035), along: stem, up: V3(1, 0, 0), scales: stem.map { 1 - 0.2 * ($0.y / 0.026) }, material: frame), .identity, "body")
        // Rear housing: domed back, cylindrical body with a shallow seam ring, flat gear boss on +Z.
        add(ReelKit.latheX([V2(0, 0), V2(0.012, 0.0012), V2(0.022, 0.006), V2(0.0268, 0.014), V2(0.028, 0.022), V2(0.028, 0.038), V2(0.0274, 0.039), V2(0.0274, 0.0405), V2(0.0282, 0.0412), V2(0.0282, 0.044)],
                            x0: -0.036, y: yc, seg: 40, body), .identity, "body")
        add(ReelKit.latheZ([V2(0, 0.0045), V2(0.012, 0.0042), V2(0.0175, 0.0025), V2(0.018, 0), V2(0.01, 0)].reversed(), z0: 0.0215, x: -0.012, y: yc, seg: 32, body), .identity, "body")
        // Front cover: threads onto the housing, tapers to the nose cone.
        add(ReelKit.latheX([V2(0.0284, 0), V2(0.0292, 0.001), V2(0.0292, 0.012), V2(0.0285, 0.018), V2(0.025, 0.026), V2(0.017, 0.033), V2(0.0085, 0.0375), V2(0.0058, 0.0385), V2(0.0042, 0.0386)],
                            x0: 0.0075, y: yc, seg: 44, chrome), .identity, "body")
        // Knurled grip band on the cover.
        var knurl: [V2] = []
        for i in 0...14 { knurl.append(V2(i % 2 == 0 ? 0.0294 : 0.0298, 0.002 + 0.008 * Float(i) / 14)) }
        add(ReelKit.latheX(knurl, x0: 0.0075, y: yc, seg: 44, chrome), .identity, "body")
        // Line hole: a ceramic grommet in the nose.
        add(Prim.torus(major: 0.0032, minor: 0.001, segments: 18, sides: 8, material: "ceramic.guide-insert").transformed(Xform(translation: V3(0.0458, yc, 0), rotation: RodKit.alongX)), .identity, "body")
        add(ReelKit.latheX([V2(0.0022, 0), V2(0.0022, 0.001), V2(0, 0.0012)], x0: 0.0448, y: yc, seg: 16, "plastic.black"), .identity, "body")
        // Star drag dial at the front of the gear boss.
        var star: [V2] = []
        for i in 0..<12 { let a = Float(i) / 12 * 2 * .pi; let r: Float = i % 2 == 0 ? 0.0095 : 0.0062; star.append(V2(cos(a) * r, sin(a) * r)) }
        add(Prim.extrude(Shape2D.rounded(star, radius: 0.0012), depth: 0.003, bevel: 0.0005, bevelSegments: 1, material: frame), Xform(translation: V3(-0.012, yc, 0.0275)), "body")

        // Thumb button: rubber pad over the rear dome, slides forward when pressed.
        rig.part("button", pivot: V3(-0.034, yc + 0.012, 0) + o, joint: .slide(axis: V3(1, 0, 0), 0...0.006, duration: 0.15))
        add(Prim.superellipsoid(V3(0.012, 0.03, 0.03), exponent: 2.6, subdivisions: 7, material: rubber), Xform(translation: V3(-0.037, yc + 0.004, 0)), "button")
        add(Prim.superellipsoid(V3(0.004, 0.022, 0.022), exponent: 2.2, subdivisions: 5, material: "metal.anodized-gunmetal-worn"), Xform(translation: V3(-0.0425, yc + 0.004, 0)), "button")

        // Crank: hub on +Z, flat arm, two oval knobs.
        let hub = V3(-0.012, yc, 0.031)
        rig.part("handle", pivot: hub + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.0))
        add(ReelKit.latheZ([V2(0.005, 0), V2(0.005, 0.004), V2(0.0035, 0.005), V2(0, 0.0052)], z0: hub.z, x: hub.x, y: hub.y, seg: 20, chrome), .identity, "handle")
        let armLen: Float = 0.036
        let arm = Shape2D.rounded([V2(-armLen, -0.0035), V2(-0.004, -0.006), V2(0.004, -0.006), V2(armLen, -0.0035), V2(armLen, 0.0035), V2(0.004, 0.006), V2(-0.004, 0.006), V2(-armLen, 0.0035)], radius: 0.0028)
        let tilt = simd_quatf(angle: 0.5, axis: V3(0, 0, 1))
        add(Prim.extrude(arm, depth: 0.0028, bevel: 0.0007, bevelSegments: 1, material: chrome), Xform(translation: hub + V3(0, 0, 0.004), rotation: tilt), "handle")
        for s: Float in [-1, 1] {
            let k = hub + tilt.act(V3(s * (armLen - 0.004), 0, 0))
            add(ReelKit.latheZ([V2(0.0015, 0), V2(0.0015, 0.004)], z0: hub.z + 0.005, x: k.x, y: k.y, seg: 10, chrome), .identity, "handle")
            add(Prim.superellipsoid(V3(0.0115, 0.019, 0.0115), exponent: 2.3, subdivisions: 6, material: "plastic.black"),
                Xform(translation: V3(k.x, k.y, hub.z + 0.0135), rotation: tilt), "handle")
        }
        _ = rng.float()
        rig.states = [RigState("rest"), RigState("pressed", ["button": 0.006]), RigState("cranked", ["handle": 120])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
