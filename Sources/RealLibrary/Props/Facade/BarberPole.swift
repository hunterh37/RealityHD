import simd
import Foundation

/// Victorian barber pole: a glass cylinder over a white core wound with red and blue bands, capped top and
/// bottom with turned cast iron, an acorn drop below and a ball finial above, clamped to a pair of
/// wrought wall brackets. Black enamel chipped to rust at the clamps.
public struct BarberPole: RealAsset {
    public static let id = "barber-pole"
    public static let summary = "Victorian barber pole 1.0 m: glass cylinder with red, white and blue spiral, cast iron caps, finial and wall brackets."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 8, distance: 1.2)

    /// Glass cylinder radius (m).
    public var glassRadius: Float = 0.078
    public var iron: MaterialKey = "metal.painted:17171A"
    public var red: MaterialKey = "sign.red"
    public var blue: MaterialKey = "sign.white:1C3C93"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pz: Float = 0.1, R = glassRadius, y0: Float = 0.15, y1: Float = 0.85
        let at = V3(0, 0, pz)
        // White core and the two spiral bands (flattened tubes) under the glass.
        m.add(Prim.cylinder(radius: R - 0.006, height: y1 - y0, bevel: 0.001, segments: 32, bevelSegments: 1, material: "sign.white:EDEAE0"), Xform(translation: at + V3(0, y0, 0)))
        let turns: Float = 3.4, pitch = (y1 - y0 - 0.08) / turns, stripeLen = y1 - y0 - 0.08
        for (k, mat) in [red, blue].enumerated() {
            var h = Prim.helix(radius: R - 0.0065, pitch: pitch * 2, turns: (stripeLen - Float(k) * pitch) / (pitch * 2), wire: 0.024, perTurn: 28, sides: 6, material: mat)
            h = h.transformed(Xform(scale: V3(1, 1, 1)))
            m.add(h, Xform(translation: at + V3(0, y0 + 0.03 + Float(k) * pitch, 0), rotation: FA.q(Float(k) * 0, FA.Y)))
        }
        // Glass shell: slightly proud of the bands, with a faint dirt line near the base.
        m.add(Prim.cylinder(radius: R, height: y1 - y0, bevel: 0.002, segments: 32, bevelSegments: 1, material: "glass.pane"), Xform(translation: at + V3(0, y0, 0)))
        // Turned cast iron caps: bottom cap with an acorn drop, top cap with neck and ball finial.
        let bottom: [V2] = [V2(0, 0.045), V2(0.018, 0.05), V2(0.03, 0.068), V2(0.028, 0.088), V2(0.014, 0.1), V2(0.04, 0.1), V2(0.07, 0.104), V2(0.09, 0.114), V2(0.1, 0.126), V2(0.1, 0.138), V2(0.09, 0.142), V2(0.084, 0.15), V2(0, 0.15)]
        m.add(Prim.lathe(bottom, segments: 32, seamTile: 0.3, material: iron), Xform(translation: at))
        let top: [V2] = [V2(0, y1), V2(0.084, y1), V2(0.09, y1 + 0.008), V2(0.1, y1 + 0.016), V2(0.1, y1 + 0.03), V2(0.088, y1 + 0.036), V2(0.07, y1 + 0.05), V2(0.03, y1 + 0.062), V2(0.016, y1 + 0.07), V2(0.02, y1 + 0.082), V2(0.012, y1 + 0.088), V2(0, y1 + 0.09)]
        m.add(Prim.lathe(top, segments: 32, seamTile: 0.3, material: iron), Xform(translation: at))
        FA.ball(&m, r: 0.036, at: at + V3(0, y1 + 0.118, 0), iron)
        m.add(Prim.lathe([V2(0, 0), V2(0.01, 0.004), V2(0.008, 0.02), V2(0.003, 0.034), V2(0, 0.04)], segments: 12, seamTile: 0.2, material: iron), Xform(translation: at + V3(0, y1 + 0.15, 0)))
        // Wall brackets: plate, arm, scrolled brace and a collar clamping the cap.
        for (by, scrollDir) in [(0.2 as Float, Float(1)), (0.78 as Float, Float(-1))] {
            FA.box(&m, V3(0.07, 0.17, 0.012), V3(0, by, 0.006), iron, r: 0.003)
            for dy: Float in [-1, 1] { hexBolt(&m, at: V3(0, by + dy * 0.06, 0.012), normal: FA.Z, size: 0.012, material: "metal.rust") }
            FA.rod(&m, V3(0, by, 0.012), V3(0, by, pz - 0.075), r: 0.0115, iron, sides: 10)
            m.add(Prim.torus(major: R + 0.004, minor: 0.0085, segments: 28, sides: 8, material: iron), Xform(translation: V3(0, by, pz)))
            FA.cylX(&m, r: 0.0035, h: 0.03, at: V3(-0.015, by - 0.006, pz + R + 0.008), "metal.rust", bevel: 0.0005, segments: 8)
            let sp = FG.spiral(c: V3(0, by - scrollDir * 0.045, 0.05), u: FA.Z, v: FA.Y, r0: 0.045, r1: 0.012, a0: scrollDir > 0 ? 1.57 : -1.57, turns: 0.9 * scrollDir, steps: 18)
            FA.path(&m, sp, r: 0.006, iron, sides: 6)
        }
        // Story detail: the lower band chipped, with a fresh rust bloom under the bottom clamp.
        FG.flat(&m, V3(0.018, 0.04, 0.0006), V3(0.012, 0.145, pz + R + 0.0005), "metal.rust")
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
