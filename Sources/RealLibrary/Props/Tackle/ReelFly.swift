import simd
import Foundation

/// Machined large-arbor fly reel, 95 mm, standing on its foot with the spool face toward +Z: ported back
/// plate with a ribbed drag knob, lower frame cage with a line guard, foot on a short pillar, large-arbor
/// spool wound with fly line, five-spoke front face, counterweight and a cylindrical handle knob.
/// Parts: `body`, `spool` (follows the handle 1:1), `handle` (spin). Anchors: `reelFoot` (-Y), `lineOut` (+X).
public struct ReelFly: RealArticulated, RealAnchored {
    public static let id = "reel-fly"
    public static let summary = "Large-arbor fly reel: machined ported frame and spool, fly line, handle knob, foot."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.0, studio: true)

    /// Frame and spool colour (sRGB hex).
    public var bodyColor: UInt32 = 0x80868C
    /// Fly line colour.
    public var lineColor: UInt32 = 0xAEB848
    /// Frame outer radius (m).
    public var radius: Float = 0.0475
    public init() {}

    static let yc: Float = 0.0585
    static let offset = V3(0, 0, 0.003)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.03, yc - 0.033, 0) + offset, direction: V3(1, 0, 0))]
    }

    /// Annular sector in XY (angles in radians, counter-clockwise from +X).
    static func sector(_ r0: Float, _ r1: Float, _ a0: Float, _ a1: Float, _ n: Int = 16) -> [V2] {
        var p: [V2] = []
        for i in 0...n { let a = a0 + (a1 - a0) * Float(i) / Float(n); p.append(V2(cos(a), sin(a)) * r1) }
        for i in (0...n).reversed() { let a = a0 + (a1 - a0) * Float(i) / Float(n); p.append(V2(cos(a), sin(a)) * r0) }
        return p
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc, R = radius
        let body: MaterialKey = "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor)
        let dark: MaterialKey = "plastic.black", bright: MaterialKey = "metal.anodized"
        let line: MaterialKey = "plastic.line:" + String(format: "%06X", lineColor)
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }
        let c = V3(0, yc, 0)

        rig.part("body", pivot: c + o, joint: .fixed)
        add(ReelKit.foot(length: 0.062, width: 0.012, thick: 0.0032, mat: body), .identity, "body")
        add(Prim.roundedBox(V3(0.016, 0.012, 0.009), radius: 0.003, bevelSegments: 2, material: body), Xform(translation: V3(0, 0.008, -0.004)), "body")
        // Back plate with a bevelled rim, closed by the drag knob boss.
        add(ReelKit.latheZ([V2(0.012, 0), V2(R - 0.002, 0), V2(R, 0.0015), V2(R, 0.004), V2(R - 0.0015, 0.0052), V2(0.012, 0.0052)], z0: -0.0185, x: c.x, y: yc, seg: 48, tile: 0.05, body), .identity, "body")
        // Ports: six oval recesses machined into the back plate (dark through-holes over the spool).
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + 0.3
            add(Prim.superellipsoid(V3(0.016, 0.0095, 0.0016), exponent: 2.2, subdivisions: 5, material: dark),
                Xform(translation: c + V3(cos(a) * 0.029, sin(a) * 0.029, -0.0191), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))), "body")
        }
        add(ReelKit.latheZ(ReelKit.ribbedKnob(r: 0.0125, len: 0.009, ridges: 12), z0: -0.0275, x: c.x, y: yc, seg: 32, dark), .identity, "body")
        add(ReelKit.latheZ([V2(0.012, 0), V2(0.0128, 0.001), V2(0.0128, 0.002), V2(0.012, 0.0024)], z0: -0.0205, x: c.x, y: yc, seg: 32, bright), .identity, "body")
        // Lower cage: the frame wraps the spool's bottom third and carries the foot.
        add(Prim.extrude(Shape2D.rounded(Self.sector(R - 0.0032, R, .pi * 1.18, .pi * 1.82), radius: 0.001), depth: 0.026, bevel: 0.0012, bevelSegments: 2, material: body),
            Xform(translation: c + V3(0, 0, -0.0005)), "body")
        // Line guard bar across the cage opening.
        add(ReelKit.latheZ([V2(0.0022, 0), V2(0.0022, 0.024)], z0: -0.012, x: 0.026, y: yc - 0.038, seg: 12, bright), .identity, "body")

        // Handle drives the spool 1:1.
        rig.part("handle", pivot: c + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.0))
        rig.part("spool", pivot: c + o, joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...360, mimic: .init("handle", ratio: 1)))
        add(ReelKit.latheZ([V2(0.008, 0), V2(R - 0.0045, 0), V2(R - 0.0042, 0.0016), V2(0.008, 0.0016)], z0: -0.0128, x: c.x, y: yc, seg: 48, body), .identity, "spool")
        add(ReelKit.latheZ([V2(0.027, 0), V2(0.027, 0.0205)], z0: -0.0112, x: c.x, y: yc, seg: 40, body), .identity, "spool")
        add(ReelKit.latheZ(ReelKit.lineFill(r: 0.0365, core: 0.027, len: 0.0196), z0: -0.011, x: c.x, y: yc, seg: 48, tile: 0.03, line), .identity, "spool")
        // Front face: rim, hub and five spokes, so the line shows through.
        add(ReelKit.latheZ([V2(R - 0.0085, 0), V2(R - 0.0045, 0), V2(R - 0.0042, 0.003), V2(R - 0.0052, 0.0042), V2(R - 0.0085, 0.0042)], z0: 0.0092, x: c.x, y: yc, seg: 48, body), .identity, "spool")
        add(ReelKit.latheZ([V2(0, 0.0045), V2(0.0035, 0.0046), V2(0.012, 0.0042), V2(0.0125, 0.0025), V2(0.0125, 0), V2(0.005, 0)].reversed(), z0: 0.0092, x: c.x, y: yc, seg: 32, body), .identity, "spool")
        for k in 0..<5 {
            let a = Float(k) / 5 * 2 * .pi + .pi / 2
            let mid = (0.012 + R - 0.008) / 2
            add(Prim.roundedBox(V3(R - 0.008 - 0.012 + 0.002, 0.0075, 0.0034), radius: 0.0012, bevelSegments: 1, material: body),
                Xform(translation: c + V3(cos(a) * mid, sin(a) * mid, 0.0112), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))), "spool")
        }
        // Counterweight opposite the handle.
        add(Prim.roundedBox(V3(0.012, 0.006, 0.003), radius: 0.0012, bevelSegments: 1, material: body), Xform(translation: c + V3(-0.03, -0.02, 0.0118), rotation: simd_quatf(angle: 0.6, axis: V3(0, 0, 1))), "spool")
        // Handle knob on a screw post near the rim.
        let k = c + V3(0.022, 0.026, 0)
        add(ReelKit.latheZ([V2(0, 0), V2(0.0045, 0.0002), V2(0.0045, 0.0018), V2(0.0028, 0.0025), V2(0.0028, 0.0035), V2(0, 0.0036)], z0: 0.013, x: k.x, y: k.y, seg: 16, bright), .identity, "handle")
        add(ReelKit.latheZ([V2(0, 0), V2(0.0052, 0.0003), V2(0.0058, 0.002), V2(0.0058, 0.019), V2(0.005, 0.0215), V2(0, 0.022)], z0: 0.0165, x: k.x, y: k.y, seg: 20, dark), .identity, "handle")
        _ = rng.float()
        rig.states = [RigState("rest"), RigState("cranked", ["handle": 120])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
