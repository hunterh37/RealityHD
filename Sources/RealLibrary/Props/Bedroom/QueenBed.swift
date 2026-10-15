import simd
import Foundation

/// Made queen bed, 165 x 110 x 218 cm: upholstered channel headboard on oak legs, oak side rails and low
/// footboard, 152 x 203 cm mattress with tape-edge piping, rumpled linen duvet hanging over the sides and foot,
/// folded top sheet, two pillows, two accent cushions and a wool throw. Headboard at -Z, foot at +Z.
public struct QueenBed: RealAsset {
    public static let id = "queen-bed"
    public static let summary = "Made queen bed: upholstered headboard, oak frame, mattress, rumpled duvet over the sides, pillows and a folded throw."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "fabric", "wood", "interior"]
    public static let budget = 10800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.65, 1.1, 2.18)
    /// Frame wood.
    public var wood: MaterialKey = "wood.oak"
    /// Headboard upholstery.
    public var headboard: MaterialKey = "fabric.upholstery:9A9590"
    /// Duvet cover.
    public var duvet: MaterialKey = "fabric.linen:D9D2C3"
    /// Throw blanket.
    public var throwBlanket: MaterialKey = "fabric.wool:6F7A70"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = BedSpec(width: size.x, length: size.z, headHeight: size.y, mattressWidth: 1.52, mattressLength: 2.03)
        sp.wood = wood; sp.upholstery = headboard; sp.duvet = duvet; sp.throwBlanket = throwBlanket
        sp.decor = ["fabric.upholstery:B48A5A", "fabric.upholstery:5E6F7A"]
        return BedroomKit.bed(sp, seed: seed, detail: detail)
    }
}
