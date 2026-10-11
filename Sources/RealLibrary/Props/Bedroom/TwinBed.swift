import simd
import Foundation

/// Twin bed, 105 x 95 x 210 cm: painted raised-panel headboard with cap, rails and paneled footboard on tapered legs, 97 x 190 cm mattress with tape-edge piping, blue linen duvet, folded sheet, one pillow with a cushion and a throw. Headboard at -Z.
public struct TwinBed: RealAsset {
    public static let id = "twin-bed"
    public static let summary = "Twin bed: painted white panel headboard and frame, 97 cm mattress, blue linen duvet, one pillow, folded throw."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "fabric", "wood", "interior"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.05, 0.95, 2.1)
    /// Frame wood.
    public var wood: MaterialKey = "wood.painted-shaker"
    /// Duvet cover.
    public var duvet: MaterialKey = "fabric.linen:7C93A6"
    /// Throw blanket.
    public var throwBlanket: MaterialKey = "fabric.wool:C9B38A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = BedSpec(width: size.x, length: size.z, headHeight: size.y, mattressWidth: 0.95, mattressLength: 1.9)
        sp.wood = wood; sp.woodWorn = "wood.painted-shaker-worn"; sp.duvet = duvet; sp.throwBlanket = throwBlanket
        sp.pillowCount = 1; sp.footboardHeight = 0.36; sp.mattressHeight = 0.24; sp.pleat = 0.25
        sp.decor = ["fabric.upholstery:D6A24A"]
        return BedroomKit.bed(sp, seed: seed, detail: detail)
    }
}
