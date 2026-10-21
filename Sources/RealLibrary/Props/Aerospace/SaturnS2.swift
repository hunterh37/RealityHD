import simd
import Foundation

/// Saturn V S-II second stage: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: S-IC/S-II interstage with ullage motors, LH2 tank barrel, LOX tank, black roll pattern, systems tunnel, 5 J-2 engines.
public struct SaturnS2: RealAsset {
    public static let id = "saturn-s2"
    public static let summary = "Second stage of the Saturn V, 10.06 m x 24.9 m: white skin, interstage ring with eight ullage fairings and black bands, cable tunnel, five J-2 engines."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.sII(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 6, strength: 0.45, grime: 0.1, seed: 4)
        return LODModel(m)
    }
}
