import simd
import Foundation

/// Ozark river bluff section, 16 m long and 14 m high, 3 m deep: grey bedded limestone over sandstone with
/// protruding hard ledges, undercut soft beds, vertical joints and a rounded wooded lip, like the bluffs
/// along the Mulberry River pools. Face is +Z, tiles along X with `endTaper = 0`. 3 LODs.
public struct LimestoneBluff: RealAsset {
    public static let id = "limestone-bluff"
    public static let summary = "Ozark river bluff, 16 x 14 m: grey bedded limestone ledges, undercut soft beds, vertical joints, rounded lip; tiles along X, 3 LODs."
    public static let tags = ["nature", "rock", "terrain", "river"]
    public static let budget = 34_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8)

    public var length: Float = 16
    public var height: Float = 14
    public var depth: Float = 3
    /// Mean bed thickness and ledge overhang in meters.
    public var bedHeight: Float = 0.9
    public var ledgeDepth: Float = 0.45
    public var material: MaterialKey = "rock.ozark-limestone"
    /// Free-end taper length in meters (0 for tiling).
    public var endTaper: Float = 3.5
    public var lodDistances: [Float] = [40, 110]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let lm = CliffFace().with {
            $0.length = length; $0.height = height; $0.depth = depth
            $0.bedHeight = bedHeight; $0.ledgeDepth = ledgeDepth; $0.material = material
            $0.endTaper = endTaper; $0.endBulge = 0.5
            $0.spacing = [0.16, 0.34, 0.8]; $0.lodDistances = lodDistances
        }.build(seed: seed)
        // CliffFace starts its beds 0.3 m below ground; lift so the base sits at y = 0.
        let up = Xform(translation: V3(0, 0.3, 0))
        return LODModel(levels: lm.levels.map { $0.transformed(up) }, switchDistances: lm.switchDistances)
    }
}
