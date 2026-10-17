import simd
import Foundation

/// Apollo launch escape system: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: truss tower, escape motor, canard section, Q-ball nose.
public struct ApolloLes: RealAsset {
    public static let id = "apollo-les"
    public static let summary = "Apollo launch escape tower: orange-red truss, escape motor with four nozzles, pitch motor, canards and Q-ball nose."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 6000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.les(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 4.5, strength: 0.5, grime: 0.08, seed: 9)
        return LODModel(m)
    }
}
