import simd
import Foundation

/// Apollo spacecraft LM adapter: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: truncated cone, panel seams, SPS bell inside.
public struct ApolloSla: RealAsset {
    public static let id = "apollo-sla"
    public static let summary = "Apollo spacecraft lunar module adapter, truncated cone 6.6 to 3.9 m, 8.5 m tall, white panels with seams."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 6000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.sla(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 3, strength: 0.25, grime: 0.1, seed: 7)
        return LODModel(m)
    }
}
