import simd
import Foundation

/// Saturn V S-IVB third stage: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: S-II/S-IVB conical interstage, LH2 tank barrel, APS modules, black roll pattern, J-2 engine.
public struct SaturnS4b: RealAsset {
    public static let id = "saturn-s4b"
    public static let summary = "Third stage of the Saturn V: 10.06 to 6.6 m conical interstage, 6.6 m white barrel with black aft skirt band and two auxiliary propulsion modules."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 10000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.sIVB(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 5, strength: 0.4, grime: 0.1, seed: 5)
        return LODModel(m)
    }
}
