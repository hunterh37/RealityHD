import simd
import Foundation

/// Linear LED reveal strip: architectural facade customizer, Contemporary. 2.0 m clear-anodized aluminum extrusion
/// (back web, side walls, retaining lips) with a recessed opal diffuser snapped in, a end caps with a
/// cable entry gland, a mid-span profile joint and mounting clips on screws every 0.5 m. A smear of joint compound
/// and a nick in the anodize give a built-site finish.
public struct LinearLedRevealStrip: RealAsset {
    public static let id = "linear-led-reveal-strip"
    public static let summary = "Linear LED reveal strip, 2.0 m: anodized extrusion with opal diffuser and end caps."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 30, distance: 0.9)

    /// Strip length in meters.
    public var length: Float = 1.99
    /// Anodized extrusion.
    public var alu: MaterialKey = "metal.anodized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, steel: MaterialKey = "metal.screw-zinc", worn: MaterialKey = "metal.aluminum-brushed"
        let w: Float = 0.03, d: Float = 0.03, t: Float = 0.0022
        // Extrusion as two 1 m lengths with a 1 mm joint gap and a splice sleeve: back web, side walls, lips.
        for s: Float in [-1, 1] {
            let cx = s * (L / 4 + 0.0005), len = L / 2 - 0.001
            FA.box(&m, V3(len, w, t), V3(cx, w / 2, t / 2), alu, r: 0.0006)
            for e: Float in [-1, 1] {
                FA.box(&m, V3(len, t, d - t), V3(cx, w / 2 + e * (w / 2 - t / 2), t + (d - t) / 2), alu, r: 0.0006)
                FA.box(&m, V3(len, 0.0045, t), V3(cx, w / 2 + e * (w / 2 - 0.0045 / 2 - t), d - t / 2), alu, r: 0.0005)
            }
            // Opal diffuser snapped under the lips, with a bright LED line behind it.
            FA.box(&m, V3(len, w - 2 * t - 0.003, 0.0026), V3(cx, w / 2, d - 0.0042), "plastic.diffuser", r: 0.0006)
            FA.box(&m, V3(len - 0.01, 0.01, 0.0016), V3(cx, w / 2, 0.0105), "emissive.warm", r: 0.0004)
        }
        FA.box(&m, V3(0.06, w - 2 * t - 0.0006, 0.0009), V3(0, w / 2, t + 0.0005), worn, r: 0.0002)
        FA.box(&m, V3(0.008, w, d), V3(0, w / 2, d / 2), alu, r: 0.001)
        // End caps with a cable gland on the left cap.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.003, w, d), V3(s * (L / 2 + 0.0015), w / 2, d / 2), "plastic.matte", r: 0.0008)
        }
        FSV.cyl(&m, V3(-L / 2 - 0.003, w / 2, d / 2), V3(-L / 2 - 0.0065, w / 2, d / 2), r: 0.0065, "plastic.white", bevel: 0.0008, segments: 10)
        // Mounting clips every 0.5 m with a pan-head screw each.
        for k in 0..<5 {
            let x = -L / 2 + 0.1 + Float(k) * (L - 0.2) / 4
            FA.box(&m, V3(0.014, w, 0.0016), V3(x, w / 2, d + 0.0008 - 0.0016 * 0 - 0.012), "metal.galvanized", r: 0.0004)
            FSV.screw(&m, at: V3(x, w / 2 + 0.0, 0.0025), normal: FA.Z, r: 0.0026, steel)
        }
        // Site finish: a joint-compound smear on the lip and a nick in the anodize.
        FA.box(&m, V3(0.09, 0.0035, 0.0007), V3(0.42, w / 2 + w / 2 - 0.004, d + 0.0002), "metal.painted:E8E6DF", r: 0.0002)
        FA.box(&m, V3(0.014, 0.002, 0.0006), V3(-0.31, w / 2 - w / 2 + 0.0035, d + 0.0002), worn, r: 0.0002)
        FA.box(&m, V3(0.05, 0.0035, 0.0007), V3(-0.78, w / 2 + w / 2 - 0.004, d + 0.0002), "metal.painted:DAD7CC", r: 0.0002)
        _ = rng
        return LODModel(FC.place(m))
    }
}
