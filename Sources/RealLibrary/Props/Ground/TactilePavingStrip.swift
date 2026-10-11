import simd
import Foundation

/// Tactile paving strip, 1.2 x 0.6 m: eight 30 cm yellow truncated-dome warning tiles (25 domes of
/// 25 mm diameter, 5 mm high, 60 mm pitch each) set in a concrete sidewalk surround.
public struct TactilePavingStrip: RealAsset {
    public static let id = "tactile-paving-strip"
    public static let summary = "Tactile paving strip, 1.2 x 0.6 m: eight yellow truncated-dome warning tiles in a concrete surround."
    public static let tags = ["prop", "street", "urban", "outdoor", "ground", "concrete", "tile"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 1.7, studio: true)

    /// Tile size (m).
    public var tile: Float = 0.3
    /// Domes per tile edge.
    public var domes = 5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.06, w: Float = 1.2 + 0.2, d: Float = 0.6 + 0.2
        GK.slab(&m, w: w, d: d, h: top, "concrete.sidewalk", r: 0.005)
        let pitch: Float = 0.06
        for j in 0..<2 { for i in 0..<4 {
            let cx = (Float(i) - 1.5) * (tile + 0.004), cz = (Float(j) - 0.5) * (tile + 0.004)
            let tint = rng.pick([0xE0B81C, 0xD9AE14, 0xE6C02A])
            GK.box(&m, V3(cx, top + 0.003, cz), V3(tile, 0.006, tile), "plastic.yellow:" + String(format: "%06X", tint), r: 0.002)
            for a in 0..<domes { for b in 0..<domes {
                let p = V3(cx + (Float(a) - Float(domes - 1) / 2) * pitch, top + 0.006, cz + (Float(b) - Float(domes - 1) / 2) * pitch)
                m.add(Prim.lathe([V2(0.0125, 0), V2(0.0095, 0.0036), V2(0.0035, 0.005), V2(0, 0.005)], segments: 6, material: "plastic.yellow:" + String(format: "%06X", tint)),
                      Xform(translation: p))
            }}
        }}
        // Worn dome tops: a dust band along one edge.
        GK.layer(&m, x: 0, z: -d / 2 + 0.05, w: w - 0.04, d: 0.06, top: top + 0.006, "concrete.rough:8A8374")
        return GK.finish(&m, ao: 0.06)
    }
}
