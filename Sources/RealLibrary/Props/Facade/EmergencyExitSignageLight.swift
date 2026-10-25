import simd
import Foundation

/// Emergency exit sign light: architectural facade customizer, Commercial. Thermoplastic housing with snap-on
/// edge frame, red EXIT legend on a white face with chevron arrow, green charge LED, push-to-test button and
/// battery access plate on screws, and two adjustable emergency lamp heads on ball swivels. The housing is slightly
/// yellowed and dusty at the top edge.
public struct EmergencyExitSignageLight: RealAsset {
    public static let id = "emergency-exit-signage-light"
    public static let summary = "Exit sign with emergency lamp heads, 0.3 m: white housing with red EXIT legend."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.3)

    /// Housing plastic.
    public var shell: MaterialKey = "plastic.matte:E6E0CC"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var m = Model(name: Self.id)
        let W: Float = 0.3, H: Float = 0.138, D: Float = 0.073
        let steel: MaterialKey = "metal.screw-zinc", red: MaterialKey = "sign.red", grime: MaterialKey = "metal.rust-grime"
        // Housing: back tray, face frame lip, sloped end caps.
        FA.box(&m, V3(W, H, D - 0.012), V3(0, H / 2, (D - 0.012) / 2), shell, r: 0.005)
        FA.box(&m, V3(W - 0.014, H - 0.014, 0.014), V3(0, H / 2, D - 0.019), shell, r: 0.003)
        // Face panel with red legend, inset behind a raised bezel.
        let fz = D - 0.011
        FA.box(&m, V3(W - 0.03, H - 0.03, 0.003), V3(0, H / 2, fz), "glass.frosted", r: 0.0008)
        FA.box(&m, V3(W - 0.03, 0.005, 0.005), V3(0, H - 0.0125, fz + 0.001), shell, r: 0.0015)
        FA.box(&m, V3(W - 0.03, 0.005, 0.005), V3(0, 0.0125, fz + 0.001), shell, r: 0.0015)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.005, H - 0.03, 0.005), V3(s * (W / 2 - 0.0125), H / 2, fz + 0.001), shell, r: 0.0015) }
        FSV.letters(&m, "EXIT", c: V3(0, H / 2, fz + 0.0024), h: 0.066, stroke: 0.0108, gap: 0.013, red)
        // Chevron arrow to the right of the legend, as bars.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.0115, 0.026, 0.0016), V3(0.126, H / 2 + s * 0.011, fz + 0.0022), red, r: 0.0004, rot: FA.q(s * 38, FA.Z))
        }
        // Charge LED and test button, battery access plate with two screws.
        FA.box(&m, V3(0.016, 0.008, 0.002), V3(-W / 2 + 0.03, 0.019, fz + 0.0022), "emissive.led-green", r: 0.0005)
        FSV.cyl(&m, V3(W / 2 - 0.03, 0.019, D - 0.012), V3(W / 2 - 0.03, 0.019, D - 0.008), r: 0.0055, shell, bevel: 0.001, segments: 12)
        // Emergency lamp heads: swivel ball on a stem, cylindrical head with lens, aimed outward and forward.
        for s: Float in [-1, 1] {
            let base = V3(s * 0.095, H - 0.004, 0.021)
            FSV.cyl(&m, base, base + V3(0, 0.022, 0), r: 0.009, shell, bevel: 0.0015, segments: 14)
            FC.bead(&m, r: 0.012, at: base + V3(0, 0.03, 0.002), shell, sub: 4)
            let d = simd_normalize(V3(s * 0.4, 0.12, 0.9)), c0 = base + V3(0, 0.032, 0.002)
            FSV.cyl(&m, c0, c0 + d * 0.066, r: 0.0235, shell, bevel: 0.003, segments: 20)
            FSV.cyl(&m, c0 + d * 0.066, c0 + d * 0.071, r: 0.0245, "metal.aluminum-brushed", bevel: 0.0008, segments: 20)
            FSV.cyl(&m, c0 + d * 0.0675, c0 + d * 0.0715, r: 0.0195, "glass.led-lens", bevel: 0.001, segments: 18)
            FC.bead(&m, r: 0.006, at: c0 + d * 0.07, "emissive.lamp-white", sub: 2)
            // Cooling slots on the head.
            let side = simd_normalize(simd_cross(d, V3(0, 1, 0))), up = simd_cross(side, d)
            for k in 0..<4 {
                FA.box(&m, V3(0.004, 0.002, 0.014), c0 + d * (0.014 + Float(k) * 0.008) + up * 0.0235, "metal.rust-grime", r: 0.0003, rot: facing(d) * FA.q(90, FA.X))
            }
        }
        // Mounting screws at the housing ends and a dust line along the top edge.
        for s: Float in [-1, 1] { FSV.screw(&m, at: V3(s * (W / 2 - 0.008), H / 2, D - 0.0105), normal: FA.Z, r: 0.0036, steel) }
        FA.box(&m, V3(W - 0.05, 0.0025, 0.001), V3(0, H - 0.0165, fz + 0.0026), "metal.rust-grime", r: 0.0003)
        return LODModel(FC.seatY(m))
    }
}
