import simd
import Foundation

/// Shortleaf pine (Pinus echinata), ~22 m, the native pine of the Ozark and Ouachita uplands: straight
/// clear bole with reddish brown plated bark, small open oval crown, needle tufts. 3 LODs.
public struct ShortleafPine: RealAsset {
    public static let id = "shortleaf-pine"
    public static let summary = "Shortleaf pine, ~22 m: straight clear bole, reddish plated bark, small open oval crown of needle tufts, 3 LODs."
    public static let tags = ["nature", "tree", "conifer", "river"]
    public static let budget = 45_000
    public static let author = "realityhd"

    /// Total height in meters.
    public var height: Float = 22
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let k = height / TreeSpecies.shortleafPine.height
        return ConiferBuild.lods(TreeSpecies.shortleafPine.with { $0.height = height; $0.trunkRadius *= k }, seed: seed)
    }
}
