import simd
import Foundation

/// Fire alarm call box: architectural facade customizer, Municipal. Cast iron base plate on four hex bolts, flared
/// fluted base and tapered post, red enamel housing with a hinged door, pull lever, lock hasp and a raised
/// FIRE plate under a hipped cap with ball finial. Enamel chips and runoff show rust.
public struct CallBoxFireAlarm: RealAsset {
    public static let id = "call-box-fire-alarm"
    public static let summary = "Municipal pedestal fire alarm call box, 1.0 m: red cast housing on a flanged post."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.4)

    /// Housing enamel.
    public var enamel: MaterialKey = "metal.fire-extinguisher-red"
    /// Cast iron for base parts.
    public var cast: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rust: MaterialKey = "metal.rust", brass: MaterialKey = "metal.brass-aged", dark: MaterialKey = "metal.rust-grime"
        // Base plate with bolts, flared skirt with a bead, fluted shaft base.
        m.add(Prim.extrude(Shape2D.rounded(Shape2D.rect(0.3, 0.3), radius: 0.012), depth: 0.02, bevel: 0.004, bevelSegments: 2, material: cast),
              Xform(translation: V3(0, 0.01, 0), rotation: FA.q(90, FA.X)))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            hexBolt(&m, at: V3(sx * 0.125, 0.02, sz * 0.125), normal: FA.Y, size: 0.02, material: sx * sz > 0 ? "metal.rust" : "metal.screw-zinc")
        } }
        m.add(Prim.lathe([V2(0, 0.02), V2(0.13, 0.02), V2(0.13, 0.03), V2(0.115, 0.036), V2(0.1, 0.05), V2(0.085, 0.09), V2(0.07, 0.13), V2(0.075, 0.138), V2(0.07, 0.146), V2(0, 0.146)],
                          segments: 32, seamTile: 0.3, material: cast))
        // Tapered post with three collar rings.
        m.add(Prim.lathe([V2(0, 0.14), V2(0.062, 0.14), V2(0.056, 0.3), V2(0.05, 0.55), V2(0.06, 0.556), V2(0.065, 0.575), V2(0, 0.575)], segments: 32, seamTile: 0.3, material: enamel))
        for y: Float in [0.22, 0.38, 0.5] {
            m.add(Prim.torus(major: 0.0575 - (y - 0.2) * 0.04, minor: 0.0045, segments: 28, sides: 6, material: enamel), Xform(translation: V3(0, y, 0)))
        }
        // Brass maker's plate on the post.
        FA.box(&m, V3(0.07, 0.04, 0.004), V3(0, 0.32, 0.0545), brass, r: 0.001)
        for s: Float in [-1, 1] { FSV.screw(&m, at: V3(s * 0.03, 0.32, 0.0565), normal: FA.Z, r: 0.0025, "metal.brass") }
        // Housing: shell, foot ledge, cap.
        let hw: Float = 0.23, hh: Float = 0.33, hd: Float = 0.17, y0: Float = 0.575, zf = hd / 2
        FA.box(&m, V3(hw, hh, hd), V3(0, y0 + hh / 2, 0), enamel, r: 0.008)
        FA.box(&m, V3(hw + 0.02, 0.016, hd + 0.02), V3(0, y0 + 0.008, 0), enamel, r: 0.004)
        FA.box(&m, V3(hw + 0.01, 0.01, hd + 0.01), V3(0, y0 + 0.021, 0), enamel, r: 0.003)
        let top = y0 + hh
        FA.run(&m, [V2(-hd / 2 - 0.012, top), V2(hd / 2 + 0.012, top), V2(hd / 2 + 0.012, top + 0.012), V2(hd / 2 - 0.01, top + 0.026), V2(0.04, top + 0.052), V2(-0.04, top + 0.052), V2(-hd / 2 + 0.01, top + 0.026), V2(-hd / 2 - 0.012, top + 0.012)],
               length: hw + 0.024, at: V3(0, 0, 0), enamel, bevel: 0.003)
        m.add(Prim.lathe([V2(0, 0), V2(0.018, 0), V2(0.01, 0.006), V2(0.014, 0.014), V2(0.011, 0.02), V2(0, 0.022)], segments: 14, seamTile: 0.1, material: cast), Xform(translation: V3(0, top + 0.05, 0)))
        FA.ball(&m, r: 0.016, at: V3(0, top + 0.08, 0), cast)
        // Door: recessed seam, raised panel with bead, hinges, hasp and pull lever.
        let dw: Float = 0.19, dh: Float = 0.25, dc = y0 + 0.14
        FA.box(&m, V3(dw + 0.006, dh + 0.006, 0.002), V3(0, dc, zf + 0.0005), dark, r: 0.0006)
        FA.box(&m, V3(dw, dh, 0.008), V3(0, dc, zf + 0.004), enamel, r: 0.003)
        for (c, s) in [(V3(0, dh / 2 - 0.012, 0), V3(dw - 0.03, 0.006, 0.005)), (V3(0, -dh / 2 + 0.012, 0), V3(dw - 0.03, 0.006, 0.005))] {
            FA.box(&m, s, V3(0, dc, zf + 0.0095) + c, enamel, r: 0.0018)
        }
        for e: Float in [-1, 1] { FA.box(&m, V3(0.006, dh - 0.03, 0.005), V3(e * (dw / 2 - 0.012), dc, zf + 0.0095), enamel, r: 0.0018) }
        for y: Float in [dc - 0.085, dc + 0.085] {
            m.add(Prim.cylinder(radius: 0.007, height: 0.05, bevel: 0.0015, segments: 12, bevelSegments: 1, material: cast), Xform(translation: V3(-dw / 2 - 0.004, y - 0.025, zf + 0.004)))
            FA.box(&m, V3(0.035, 0.05, 0.004), V3(-dw / 2 + 0.014, y, zf + 0.009), cast, r: 0.001)
            FSV.screw(&m, at: V3(-dw / 2 + 0.022, y, zf + 0.011), normal: FA.Z, r: 0.0028, "metal.screw-zinc")
        }
        // Pull lever on a brass back plate and a hasp with keyhole.
        FA.box(&m, V3(0.06, 0.09, 0.004), V3(0, dc, zf + 0.011), brass, r: 0.0015)
        FA.path(&m, [V3(0, dc + 0.025, zf + 0.014), V3(0, dc + 0.025, zf + 0.04), V3(0, dc - 0.015, zf + 0.046), V3(0, dc - 0.026, zf + 0.03)], r: 0.0055, cast, sides: 8)
        FA.box(&m, V3(0.034, 0.034, 0.007), V3(dw / 2 - 0.028, dc + 0.09, zf + 0.012), brass, r: 0.002)
        FA.box(&m, V3(0.004, 0.012, 0.002), V3(dw / 2 - 0.028, dc + 0.09, zf + 0.0165), dark, r: 0.0006)
        // FIRE plate: enamel white field with a red border and block letters, under the cap.
        let py = top - 0.032
        FA.box(&m, V3(0.17, 0.05, 0.004), V3(0, py, zf + 0.002), "sign.white", r: 0.0015)
        FA.box(&m, V3(0.176, 0.0035, 0.005), V3(0, py + 0.0265, zf + 0.002), "sign.red", r: 0.0006)
        FA.box(&m, V3(0.176, 0.0035, 0.005), V3(0, py - 0.0265, zf + 0.002), "sign.red", r: 0.0006)
        FSV.letters(&m, "FIRE", c: V3(0, py, zf + 0.0045), h: 0.032, stroke: 0.0065, gap: 0.007, "sign.red")
        // Wear: chipped enamel at the foot and door edge, rust bleed from the base bolts.
        for _ in 0..<6 {
            let x = rng.float(-hw / 2 + 0.01...hw / 2 - 0.01)
            FA.box(&m, V3(rng.float(0.006...0.018), rng.float(0.004...0.012), 0.0012), V3(x, y0 + 0.014, zf + 0.0105), rust, r: 0.0004)
        }
        return LODModel(FC.place(m))
    }
}
