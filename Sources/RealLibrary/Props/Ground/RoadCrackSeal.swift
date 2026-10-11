import simd
import Foundation

/// Sealed road cracks, 1.5 x 0.8 m: a wandering main crack and two branches filled with hot-poured
/// black sealant, with a hairline crack beside them left open.
public struct RoadCrackSeal: RealAsset {
    public static let id = "road-crack-seal"
    public static let summary = "Sealed road cracks, 1.5 x 0.8 m: wandering hot-poured sealant lines with branches on worn asphalt."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 1.6, studio: true)

    /// Slab size X, Z (m).
    public var slab = V2(1.5, 0.8)
    /// Road thickness (m).
    public var thickness: Float = 0.04
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        GK.slab(&m, w: slab.x, d: slab.y, h: thickness, "asphalt.road")
        // Worn tyre track patch across the middle.
        GK.layer(&m, x: 0, z: 0.05, w: slab.x - 0.1, d: 0.22, top: thickness, "asphalt.worn")
        citySealedCrack(&m, start: V2(-0.7, rng.float(-0.1...0.1)), angle: rng.float(-0.15...0.15), length: 1.45, y: thickness, bounds: 0.72, rng: &rng)
        for s: Float in [-1, 1] {
            citySealedCrack(&m, start: V2(rng.float(-0.3...0.3), 0), angle: s * rng.float(1.0...1.3), length: 0.45, y: thickness, bounds: 0.38, rng: &rng)
        }
        // Open hairline beside the sealed crack.
        citySealedCrack(&m, start: V2(-0.55, -0.22), angle: 0.05, length: 0.9, y: thickness, bounds: 0.36, material: "asphalt.worn", rng: &rng)
        return GK.finish(&m)
    }
}
