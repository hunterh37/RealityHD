import simd
import Foundation

/// River birch (Betula nigra), ~15 m: leaning trunk over the water with salmon to cinnamon papery bark,
/// irregular open crown of arching branches, small toothed leaves. 3 LODs.
public struct RiverBirch: RealAsset {
    public static let id = "river-birch"
    public static let summary = "River birch, ~15 m: leaning trunk with salmon papery bark, arching open crown of small toothed leaves, 3 LODs."
    public static let tags = ["nature", "tree", "deciduous", "river"]
    public static let budget = 45_000
    public static let author = "realityhd"

    /// Total height in meters.
    public var height: Float = 15
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let k = height / TreeSpecies.riverBirch.height
        return Tree(TreeSpecies.riverBirch.with { $0.height = height; $0.trunkRadius *= k }).build(seed: seed)
    }
}
