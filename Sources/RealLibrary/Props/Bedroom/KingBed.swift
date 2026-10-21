import simd
import Foundation

/// Made king bed, 205 x 115 x 220 cm: walnut raised-panel headboard with cap, walnut rails and paneled footboard on tapered legs, 193 x 203 cm mattress with tape-edge piping, slate linen duvet, folded sheet, king pillows with cushions and a wool throw. Headboard at -Z.
public struct KingBed: RealAsset {
    public static let id = "king-bed"
    public static let summary = "Made king bed: walnut panel headboard and frame, 193 cm mattress, slate linen duvet, king pillows and a wool throw."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "fabric", "wood", "interior"]
    public static let budget = 10800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.05, 1.15, 2.2)
    /// Frame wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Duvet cover.
    public var duvet: MaterialKey = "fabric.linen:6C7580"
    /// Throw blanket.
    public var throwBlanket: MaterialKey = "fabric.wool:B8A98C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = BedSpec(width: size.x, length: size.z, headHeight: size.y, mattressWidth: 1.93, mattressLength: 2.03)
        sp.wood = wood; sp.duvet = duvet; sp.throwBlanket = throwBlanket
        sp.pillowMaxWidth = 0.9; sp.footboardHeight = 0.42
        sp.decor = ["fabric.upholstery:B9553B", "fabric.upholstery:D8C9A8", "fabric.upholstery:5C6B58"]
        return BedroomKit.bed(sp, seed: seed, detail: detail)
    }
}
