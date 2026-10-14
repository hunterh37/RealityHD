import simd
import Foundation

/// Inline ice reel, 60 mm, standing on its foot (mounted, it hangs under the rod), spool face toward +Z
/// and the line leaving straight along the rod: molded frame with a foot, narrow spool with mono, ported
/// face, single handle knob, rear drag knob, and a free-spool trigger under the front.
/// Parts: `body`, `trigger` (press for free spool), `spool` (follows the handle 2.6:1), `handle` (spin).
/// Anchors: `reelFoot` (-Y), `lineOut` (+X, line guide).
public struct ReelIce: RealArticulated, RealAnchored {
    public static let id = "reel-ice"
    public static let summary = "Inline ice reel, 60 mm: molded frame, narrow ported spool with mono, handle knob, drag knob, free-spool trigger."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.0, studio: true)

    /// Frame colour (sRGB hex).
    public var bodyColor: UInt32 = 0x1E2226
    /// Spool colour.
    public var spoolColor: UInt32 = 0xB02A2A
    /// Line colour.
    public var lineColor: UInt32 = 0x9FC4D8
    public init() {}

    static let R: Float = 0.03, yc: Float = 0.039
    static let offset = V3(0, 0, 0)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(0.024, yc - R + 0.002, 0) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let o = Self.offset, yc = Self.yc, R = Self.R
        let body: MaterialKey = "plastic.black:" + String(format: "%06X", bodyColor)
        let spool: MaterialKey = "metal.anodized:" + String(format: "%06X", spoolColor)
        let chrome: MaterialKey = "metal.chrome", frame: MaterialKey = "metal.anodized-gunmetal"
        let line: MaterialKey = "plastic.line:" + String(format: "%06X", lineColor)
        func add(_ s: Surface, _ x: Xform = .identity, _ part: String) { ReelKit.add(&rig, s, x, to: part, offset: o) }
        let c = V3(0, yc, 0)

        rig.part("body", pivot: c + o, joint: .fixed)
        add(ReelKit.foot(length: 0.048, width: 0.0105, thick: 0.0028, mat: frame), .identity, "body")
        add(Prim.roundedBox(V3(0.02, 0.012, 0.008), radius: 0.003, bevelSegments: 2, material: body), Xform(translation: V3(0, 0.0075, -0.007)), "body")
        // Frame plate behind the spool and the lower cage that carries the line guide.
        add(ReelKit.latheZ([V2(0, 0), V2(R + 0.002, 0), V2(R + 0.0035, 0.0012), V2(R + 0.0035, 0.003), V2(R + 0.002, 0.0042), V2(0, 0.0042)], z0: -0.0145, x: 0, y: yc, seg: 44, tile: 0.04, body), .identity, "body")
        add(Prim.extrude(Shape2D.rounded(ReelFly.sector(R + 0.0008, R + 0.0035, .pi * 1.2, .pi * 1.85), radius: 0.0008), depth: 0.02, bevel: 0.0008, bevelSegments: 1, material: body),
            Xform(translation: c + V3(0, 0, -0.001)), "body")
        add(Prim.torus(major: 0.0022, minor: 0.0007, segments: 14, sides: 6, material: "ceramic.guide-insert").transformed(Xform(translation: V3(0.022, yc - R + 0.002, 0), rotation: RodKit.alongX)), .identity, "body")
        // Rear drag knob on the back plate.
        add(ReelKit.latheZ(ReelKit.ribbedKnob(r: 0.009, len: 0.0065, ridges: 10), z0: -0.021, x: 0, y: yc, seg: 28, frame), .identity, "body")

        // Free-spool trigger: a curved paddle under the front of the frame.
        rig.part("trigger", pivot: V3(0.006, yc - R - 0.002, -0.004) + o, joint: .hinge(axis: V3(0, 0, 1), -12...0, duration: 0.15))
        var path: [V3] = []
        for i in 0...8 { let t = Float(i) / 8; path.append(V3(0.006 + 0.022 * t, yc - R + 0.001 - 0.0055 * sin(t * .pi * 0.7), -0.004)) }
        add(Prim.sweep(Shape2D.roundedRect(0.004, 0.009, radius: 0.0016), along: path, up: V3(0, 0, 1), material: body), .identity, "trigger")

        rig.part("handle", pivot: c + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.0))
        rig.part("spool", pivot: c + o, joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...936, mimic: .init("handle", ratio: 2.6)))
        add(ReelKit.latheZ([V2(0.006, 0), V2(R - 0.001, 0), V2(R, 0.001), V2(R, 0.0018), V2(0.006, 0.0018)], z0: -0.0102, x: 0, y: yc, seg: 44, spool), .identity, "spool")
        add(ReelKit.latheZ(ReelKit.lineFill(r: R - 0.005, core: R * 0.4, len: 0.016), z0: -0.0084, x: 0, y: yc, seg: 44, tile: 0.02, line), .identity, "spool")
        add(ReelKit.latheZ([V2(0.006, 0), V2(R - 0.001, 0), V2(R, 0.001), V2(R, 0.0028), V2(R - 0.0012, 0.0036), V2(0.006, 0.0036)], z0: 0.0078, x: 0, y: yc, seg: 44, spool), .identity, "spool")
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + 0.3
            add(Prim.superellipsoid(V3(0.0085, 0.0055, 0.0012), exponent: 2.2, subdivisions: 4, material: "plastic.black"),
                Xform(translation: c + V3(cos(a) * R * 0.58, sin(a) * R * 0.58, 0.0115), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))), "spool")
        }
        add(ReelKit.latheZ([V2(0, 0.003), V2(0.005, 0.0028), V2(0.0065, 0.0015), V2(0.0065, 0), V2(0.004, 0)].reversed(), z0: 0.0112, x: 0, y: yc, seg: 20, chrome), .identity, "spool")
        // Handle knob near the rim.
        let k = c + V3(0.015, 0.018, 0)
        add(ReelKit.latheZ([V2(0, 0), V2(0.0032, 0.0002), V2(0.0032, 0.0014), V2(0.002, 0.002), V2(0, 0.0022)], z0: 0.0112, x: k.x, y: k.y, seg: 14, chrome), .identity, "handle")
        add(ReelKit.latheZ([V2(0, 0), V2(0.0036, 0.0003), V2(0.004, 0.0016), V2(0.004, 0.012), V2(0.0034, 0.0135), V2(0, 0.014)], z0: 0.0132, x: k.x, y: k.y, seg: 16, "plastic.black"), .identity, "handle")
        _ = rng.float()
        rig.states = [RigState("rest"), RigState("free-spool", ["trigger": -12]), RigState("cranked", ["handle": 120])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
