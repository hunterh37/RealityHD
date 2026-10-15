import simd
import Foundation

/// Bark mulch play surface, 2 x 2 m: play-grade softwood bark chips (10-50 mm, fines removed) laid
/// 300 mm deep inside treated timber edging on pegs. Under a swing seat the chips are kicked out into
/// a hollow showing the geotextile, and the displaced chips heap at its ends.
public struct BarkMulchPlaySurface: RealAsset {
    public static let id = "bark-mulch-play-surface"
    public static let summary = "Bark mulch play surface, 2 x 2 m: play-grade softwood bark chips 300 mm deep inside treated timber edging, scuffed into a hollow under a swing."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.8, studio: true)

    /// Overall size in meters (x width, y edging top, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Edging board thickness (m).
    public var boardThick: Float = 0.032
    /// Loose chips modelled individually.
    public var chipCount: Int = 640
    /// Chip tones: fresh pine bark, weathered grey-brown, reddish inner bark.
    public var chipKeys: [MaterialKey] = ["mulch.bark:5E3A22", "mulch.bark:4A2E1C", "mulch.bark:6E4628", "mulch.bark:56402E", "wood.deadwood:7A5232"]
    /// Bed material under the loose chips.
    public var bark: MaterialKey = "mulch.bark:6A4A34"
    /// Edging board material.
    public var boardKey: MaterialKey = "wood.weathered:6E6A4E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t = boardThick, w = size.x - 2 * t, d = size.z - 2 * t
        let bed: Float = 0.08
        let hol = V2(rng.float(-0.2...0.2), rng.float(-0.2...0.2))
        func h(_ p: V2) -> Float {
            let q = (p - hol) * V2(1 / 0.22, 1 / 0.42)
            let r2 = simd_length_squared(q)
            let hollow = -0.05 * exp(-r2 * 1.2)
            let heap = 0.018 * exp(-pow(q.x / 1.6, 2) - pow((abs(q.y) - 1.4) / 0.45, 2))
            return hollow + heap + 0.006 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: 5)
        }
        GTK.field(&m, w: w, d: d, edge: bed, segments: 30, bark, uvScale: 1.0, bump: h)
        GK.poly(&m, (0..<14).map { k in let a = Float(k) / 14 * 2 * .pi; return hol + V2(cos(a) * 0.07, sin(a) * 0.15) },
                top: bed - 0.049, "fabric.burlap:3A342C", thick: 0.002)
        var lite = Model(name: Self.id + "-lite")
        GTK.field(&lite, w: w, d: d, edge: bed, segments: 24, bark, uvScale: 2.0, bump: h)
        GTK.stones(&m, &rng, count: chipCount, hx: w / 2 - 0.01, hz: d / 2 - 0.01, size: 0.03...0.07, flat: 0.12...0.25,
                   keys: chipKeys, exponent: 3.2, sink: 0.3, surface: { bed + h($0) * 0.95 },
                   keep: { simd_length(($0 - hol) * V2(1 / 0.08, 1 / 0.16)) > 1 })
        GTK.edging(&m, &rng, w: size.x, d: size.z, top: size.y, thick: t, board: boardKey, stake: "wood.weathered:5E5A44", screw: "metal.galvanized-aged")
        GTK.edging(&lite, &rng, w: size.x, d: size.z, top: size.y, thick: t, board: boardKey, stake: "wood.weathered:5E5A44", screw: "metal.galvanized-aged")
        return GTK.finish(&m, &lite)
    }
}
