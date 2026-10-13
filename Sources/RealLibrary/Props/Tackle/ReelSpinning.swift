import simd
import Foundation

/// 2500-size spinning reel standing on its foot (the rod would sit on the foot; mounted, the reel hangs
/// under the rod), front (+X) toward the rod tip: graphite gearbox with bulged side covers, curved stem,
/// rotor cup with two arms, wire bail with a line roller, skirted aluminum spool loaded with mono,
/// front drag knob, folding crank with a T knob on +Z.
/// Parts: `body`, `rotor` (follows the crank 5.2:1), `bail` (open/closed), `spool`, `handle` (spin).
/// Anchors: `reelFoot` (-Y, foot underside centre), `lineOut` (+X, spool front lip).
public struct ReelSpinning: RealArticulated, RealAnchored {
    public static let id = "reel-spinning"
    public static let summary = "2500 spinning reel standing on its foot: gearbox body, rotor, wire bail, skirted spool with line, crank handle."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 11500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.0, studio: true)

    /// Body colour (sRGB hex), anodized side covers and spool.
    public var bodyColor: UInt32 = 0x9A9EA4
    /// Accent colour for the drag knob ring and rotor trim.
    public var accentColor: UInt32 = 0xB0722A
    /// Line colour.
    public var lineColor: UInt32 = 0x8FA58A
    public init() {}

    /// Rotor axis height and the offset that centres the reel on X/Z.
    static let yc: Float = 0.071
    static let offset = V3(-0.016, 0, -0.012)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(0, 0, 0) + V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.057, yc + 0.0245, 0) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc
        let body: MaterialKey = "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor)
        let dark: MaterialKey = "plastic.black", chrome: MaterialKey = "metal.chrome"
        let accent: MaterialKey = "metal.anodized:" + String(format: "%06X", accentColor)
        let line: MaterialKey = "plastic.line:" + String(format: "%06X", lineColor)
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }

        rig.part("body", pivot: V3(0, yc, 0) + o, joint: .fixed)
        // Foot and curved stem.
        add(ReelKit.foot(length: 0.058, width: 0.0115, thick: 0.0032, mat: body), .identity, "body")
        var stem: [V3] = []
        for i in 0...10 { let t = Float(i) / 10; stem.append(V3(-0.002 - 0.012 * t * t, 0.002 + 0.05 * t, 0)) }
        add(Prim.sweep(Shape2D.roundedRect(0.013, 0.0062, radius: 0.0028), along: stem, up: V3(1, 0, 0), scales: stem.map { 1 + 0.25 * max(0, ($0.y - 0.03) / 0.022) }, material: body), .identity, "body")
        // Gearbox: rounded housing, bulged side covers, rear cap.
        let bc = V3(-0.016, yc, 0)
        add(Prim.superellipsoid(V3(0.05, 0.046, 0.026), exponent: 4.2, subdivisions: 10, material: dark), Xform(translation: bc), "body")
        for side: Float in [-1, 1] {
            add(Prim.superellipsoid(V3(0.046, 0.042, 0.005), exponent: 4.5, subdivisions: 8, material: body), Xform(translation: bc + V3(0.001, 0, side * 0.0122)), "body")
            add(Prim.cylinder(radius: 0.0045, height: 0.0012, bevel: 0.0004, segments: 16, bevelSegments: 1, material: chrome), Xform(translation: bc + V3(-0.01, 0.01, side * 0.0146), rotation: simd_quatf(angle: side * .pi / 2, axis: V3(1, 0, 0))), "body")
        }
        add(ReelKit.latheX([V2(0, 0), V2(0.009, 0.001), V2(0.011, 0.006), V2(0.0115, 0.012)], x0: -0.048, y: yc, seg: 24, body), .identity, "body")
        // Handle boss on +Z and the anti-reverse lever under the body.
        add(ReelKit.latheZ([V2(0.0085, 0), V2(0.0085, 0.004), V2(0.006, 0.0055), V2(0, 0.0058)], z0: 0.017, x: bc.x, y: yc, seg: 24, body), .identity, "body")
        add(Prim.roundedBox(V3(0.008, 0.004, 0.006), radius: 0.0015, bevelSegments: 1, material: dark), Xform(translation: bc + V3(-0.02, -0.02, 0)), "body")

        // Rotor (spins with the crank): cup, two arms, then the bail on the arm tips.
        rig.part("handle", pivot: bc + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.2))
        rig.part("rotor", pivot: V3(0, yc, 0) + o, joint: Joint(.revolute, axis: V3(1, 0, 0), range: 0...1872, mimic: .init("handle", ratio: 5.2)))
        add(ReelKit.latheX([V2(0.011, 0), V2(0.0175, 0.002), V2(0.0235, 0.012), V2(0.0245, 0.021), V2(0.0225, 0.0215), V2(0.008, 0.016)], x0: 0.009, y: yc, seg: 36, dark), .identity, "rotor")
        add(ReelKit.latheX([V2(0.0236, 0), V2(0.0249, 0.0006), V2(0.0249, 0.002), V2(0.0236, 0.0026)], x0: 0.028, y: yc, seg: 36, accent), .identity, "rotor")
        let armX0: Float = 0.022, armX1: Float = 0.051, armR: Float = 0.0275
        for side: Float in [-1, 1] {
            let path = [V3(armX0, yc + side * 0.022, 0), V3(0.036, yc + side * 0.0268, 0), V3(armX1, yc + side * armR, 0)]
            add(Prim.sweep(Shape2D.roundedRect(0.0035, 0.009, radius: 0.0014), along: path, up: V3(0, side, 0), material: dark), .identity, "rotor")
            add(ReelKit.latheX([V2(0, 0), V2(0.004, 0.0003), V2(0.0042, 0.003), V2(0, 0.0034)], x0: armX1 - 0.0017, y: yc + side * armR, seg: 12, body), .identity, "rotor")
        }
        // Bail: wire arc from the top arm tip around the +Z side to the bottom tip, line roller at the top.
        rig.part("bail", parent: "rotor", pivot: V3(armX1, yc, 0) + o, joint: .hinge(axis: V3(0, 1, 0), -115...0, duration: 0.35))
        var arc: [V3] = []
        for i in 0...24 {
            let a = Float(i) / 24 * .pi
            arc.append(V3(armX1 + 0.006 * sin(a), yc + armR * cos(a), armR * sin(a) * 1.04))
        }
        add(Prim.tube(arc, radii: arc.map { _ in 0.00125 }, sides: 8, seamTile: 0.01, material: chrome), .identity, "bail")
        add(ReelKit.latheZ([V2(0.0026, 0), V2(0.003, 0.001), V2(0.003, 0.006), V2(0.0026, 0.007)], z0: -0.0035, x: armX1 + 0.001, y: yc + armR + 0.0005, seg: 14, chrome), .identity, "bail")
        add(Prim.roundedBox(V3(0.008, 0.005, 0.01), radius: 0.0018, bevelSegments: 1, material: body), Xform(translation: V3(armX1, yc - armR, 0.002)), "bail")

        // Spool (fixed on the main shaft): skirt, line arbor with mono, front lip, drag knob.
        rig.part("spool", pivot: V3(0.04, yc, 0) + o, joint: .fixed)
        add(ReelKit.latheX([V2(0.0272, 0), V2(0.0276, 0.001), V2(0.0276, 0.0085), V2(0.0262, 0.0098), V2(0.018, 0.0102)], x0: 0.0255, y: yc, seg: 40, body), .identity, "spool")
        add(ReelKit.latheX(ReelKit.lineFill(r: 0.0218, core: 0.016, len: 0.0185), x0: 0.0355, y: yc, seg: 40, tile: 0.02, line), .identity, "spool")
        add(ReelKit.latheX([V2(0.016, 0), V2(0.0244, 0.0002), V2(0.0249, 0.0012), V2(0.0249, 0.0024), V2(0.0238, 0.0034), V2(0.012, 0.0036)], x0: 0.0538, y: yc, seg: 40, body), .identity, "spool")
        add(ReelKit.latheX(ReelKit.ribbedKnob(r: 0.0118, len: 0.012, ridges: 10), x0: 0.057, y: yc, seg: 30, dark), .identity, "spool")
        add(ReelKit.latheX([V2(0.0121, 0), V2(0.0122, 0.0015), V2(0.0119, 0.002)], x0: 0.0585, y: yc, seg: 30, accent), .identity, "spool")

        // Crank: arm from the +Z boss out to a T knob, resting angled up and back.
        let ang: Float = 2.2
        let dir = V3(cos(ang), sin(ang), 0), armLen: Float = 0.046
        let hub = bc + V3(0, 0, 0.0235)
        add(ReelKit.latheZ([V2(0.0055, 0), V2(0.0058, 0.002), V2(0.0058, 0.006), V2(0.0045, 0.007)], z0: 0.0225, x: bc.x, y: yc, seg: 20, body), .identity, "handle")
        let armPath = [hub + V3(0, 0, 0.002), hub + dir * armLen * 0.5 + V3(0, 0, 0.004), hub + dir * armLen + V3(0, 0, 0.006)]
        add(Prim.sweep(Shape2D.roundedRect(0.0035, 0.0075, radius: 0.0015), along: armPath, up: V3(0, 0, 1), scales: [1.15, 1, 0.85], material: body), .identity, "handle")
        let knobBase = hub + dir * armLen + V3(0, 0, 0.006)
        add(ReelKit.latheZ([V2(0.0022, 0), V2(0.0022, 0.006)], z0: knobBase.z, x: knobBase.x, y: knobBase.y, seg: 10, chrome), .identity, "handle")
        add(Prim.superellipsoid(V3(0.024, 0.009, 0.016), exponent: 2.6, subdivisions: 6, material: dark),
            Xform(translation: knobBase + V3(0, 0, 0.014), rotation: simd_quatf(angle: ang, axis: V3(0, 0, 1))), "handle")
        _ = rng.float()

        rig.states = [RigState("closed"), RigState("open", ["bail": -115]), RigState("cranked", ["handle": 180])]
        groundAO(&rig, height: 0.03, floor: 0.6)
        return rig
    }
}
