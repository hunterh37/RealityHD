import simd
import Foundation

/// Saturn V instrument unit: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: ring, umbilical plate.
public struct SaturnIu: RealAsset {
    public static let id = "saturn-iu"
    public static let summary = "Saturn V instrument unit ring, 6.6 m x 0.91 m, white honeycomb skin with umbilical door."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 6000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.iu(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 0.5, strength: 0.1, grime: 0.08, seed: 6)
        return LODModel(m)
    }
}
