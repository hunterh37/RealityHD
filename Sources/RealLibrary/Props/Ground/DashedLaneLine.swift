import simd
import Foundation

/// Dashed lane line, 1.2 x 7.2 m: two 1.2 m white dashes 10 cm wide on 3.6 m centers, with a double
/// yellow centerline along one edge, on asphalt with worn paint.
public struct DashedLaneLine: RealAsset {
    public static let id = "dashed-lane-line"
    public static let summary = "Lane markings, 1.2 x 7.2 m: dashed white lane line beside a solid double-yellow centerline on asphalt."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 6.5, studio: true)

    /// Slab length along the road (m).
    public var length: Float = 7.2
    /// Dash length (m).
    public var dash: Float = 1.2
    /// Dash pitch (m).
    public var pitch: Float = 3.6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, w: Float = 1.2
        GK.slab(&m, w: w, d: length, h: top, "asphalt.road", r: 0.01)
        // Double yellow along the -X edge.
        for s: Float in [-1, 1] {
            GK.layer(&m, x: -w / 2 + 0.2 + s * 0.065, z: 0, w: 0.1, d: length - 0.04, top: top, GK.paintYellow)
        }
        // Dashed white line.
        var z = -length / 2 + 0.6
        while z + dash <= length / 2 {
            GK.layer(&m, x: 0.2, z: z + dash / 2, w: 0.1, d: dash - rng.float(0...0.05), top: top, GK.paintWhite)
            z += pitch
        }
        // Reflective wear patch on the lane.
        GK.layer(&m, x: 0.2, z: rng.float(-1...1), w: 0.4, d: 0.8, top: top + 0.0015, "asphalt.worn")
        return GK.finish(&m, ao: 0.03)
    }
}
