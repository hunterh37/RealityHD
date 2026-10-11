import simd
import Foundation

/// Zebra crosswalk, 4.5 x 3.0 m: five 50 cm white thermoplastic bars on 100 cm centers across a travel
/// lane, edges chipped and one bar scuffed by tyres.
public struct ZebraCrosswalk: RealAsset {
    public static let id = "zebra-crosswalk"
    public static let summary = "Zebra crosswalk, 4.5 x 3 m: five 50 cm white paint bars on 1 m centers over asphalt, worn ends."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 50, distance: 4.5, studio: true)

    /// Number of bars.
    public var bars = 5
    /// Bar width across the walking direction (m).
    public var barWidth: Float = 0.5
    /// Bar length along the walking direction (m).
    public var barLength: Float = 3.0
    /// Bar pitch (m).
    public var pitch: Float = 1.0
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = Float(bars - 1) * pitch + barWidth + 0.4, top: Float = 0.04
        GK.slab(&m, w: w, d: barLength + 0.2, h: top, "asphalt.road", r: 0.01)
        for i in 0..<bars {
            let x = (Float(i) - Float(bars - 1) / 2) * pitch
            let l0 = rng.float(0...0.04), l1 = rng.float(0...0.04)
            GK.layer(&m, x: x, z: (l0 - l1) / 2, w: barWidth - rng.float(0...0.02), d: barLength - l0 - l1, top: top, GK.paintWhite)
        }
        // Tyre scuffs on two bars.
        for i in [1, 3] where i < bars {
            let x = (Float(i) - Float(bars - 1) / 2) * pitch
            GK.layer(&m, x: x + rng.float(-0.1...0.1), z: rng.float(-0.9...0.9), w: 0.3, d: 0.5, top: top + 0.0015, "asphalt.worn")
        }
        return GK.finish(&m, ao: 0.03)
    }
}
