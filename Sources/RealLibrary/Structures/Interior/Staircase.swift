import simd
import Foundation

/// Straight residential staircase: 16 risers of 187.5 mm and 15 treads of 260 mm climb 3.0 m floor to floor over
/// a 4.0 m run. Oak treads with nosing and scotia, painted risers, a closed skirt stringer on the wall side, a cut
/// stringer and center carriage, turned balusters, an oak handrail at 0.9 m and newels with ball finials on the open
/// side. Origin bottom center; the flight climbs along -Z.
public struct Staircase: RealAsset {
    public static let id = "staircase"
    public static let summary = "Straight staircase, 16 risers, 3.0 m rise over 4.0 m: oak treads, painted risers, skirt and cut stringers, balusters, handrail and newels."
    public static let tags = ["structure", "floorplan", "interior", "stair", "wood"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 18, distance: 1.25, studio: true)

    /// Stair width (m).
    public var width: Float = 1.0
    /// Number of risers (rise 3.0 m at the default 16).
    public var risers = 16
    /// Tread going (m); 15 treads plus a 75 mm landing plate fill the 4.0 m run.
    public var going: Float = 0.26
    public var railMaterial: MaterialKey = "wood.oak:9A6E40"
    public init() {}

    func flight(lod: Int) -> StairFlight {
        var f = StairFlight()
        f.width = width; f.risers = risers; f.rise = 3.0 / Float(risers); f.going = going; f.lod = lod
        f.railMat = railMaterial
        return f
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [flight(lod: 0).build(seed: seed).centeredXZ(), flight(lod: 1).build(seed: seed).centeredXZ()], switchDistances: [8])
    }
}
