import simd
import Foundation

/// Saturn V S-IC first stage: photoreal 1967-1973 Apollo flight hardware, clean painted finish, slight launch-pad grime. Parts: kerosene and LOX tank barrel, corrugated intertank, black roll pattern, UNITED STATES lettering, flag, 4 fins, 4 engine fairings, 5 F-1 engines, thrust structure, heat shield.
public struct SaturnS1c: RealAsset {
    public static let id = "saturn-s1c"
    public static let summary = "Saturn V first stage, 10.06 m x 42.1 m: white skin, black roll pattern, corrugated intertank, four finned fairings, five F-1 engines."
    public static let tags = ["prop", "vehicle", "metal", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"

    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0, studio: true)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        SatK.sIC(&m)
        groundAO(&m)
        SatK.soot(&m, fade: 14, strength: 0.6, grime: 0.12, seed: 3)
        return LODModel(m)
    }
}
