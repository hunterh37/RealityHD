import simd
import Foundation

/// Apollo command and service module: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: service module barrel, RCS quads, radiator panels, command module cone, boost protective cover.
public struct ApolloCsm: RealAsset {
    public static let id = "apollo-csm"
    public static let summary = "Apollo CSM, 3.9 m: silver service module with four RCS quads and radiators under a white boost protective cover over the command module cone."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 8000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.csm(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 1.2, strength: 0.25, grime: 0.08, seed: 8)
        return LODModel(m)
    }
}
