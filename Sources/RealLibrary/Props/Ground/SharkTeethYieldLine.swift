import simd
import Foundation

/// Yield line of "shark teeth", 3.6 x 1.2 m: a row of eight white isosceles triangles, 40 cm base by
/// 60 cm tall, pointing toward approaching traffic, on asphalt with a worn centre.
public struct SharkTeethYieldLine: RealAsset {
    public static let id = "shark-teeth-yield-line"
    public static let summary = "Yield line, 3.6 x 1.2 m: row of white triangular shark-teeth paint on asphalt."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 3.6, studio: true)

    /// Triangle count.
    public var teeth = 8
    /// Triangle base and height (m).
    public var base: Float = 0.4
    public var height: Float = 0.6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, pitch = base + 0.05, w = Float(teeth) * pitch + 0.2
        GK.slab(&m, w: w, d: 1.2, h: top, "asphalt.road", r: 0.01)
        for i in 0..<teeth {
            let x = (Float(i) - Float(teeth - 1) / 2) * pitch, j = rng.float(-0.01...0.01)
            GK.poly(&m, [V2(x - base / 2, -height / 2 + j), V2(x + base / 2, -height / 2 + j), V2(x, height / 2)], top: top, GK.paintWhite)
        }
        GK.layer(&m, x: rng.float(-0.4...0.4), z: rng.float(-0.2...0.2), w: 0.5, d: 0.3, top: top + 0.0015, "asphalt.worn")
        return GK.finish(&m, ao: 0.03)
    }
}
