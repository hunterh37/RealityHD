import simd
import Foundation

/// Tallboy chest, 80 x 130 x 45 cm: five graduated sage painted drawers with raised beaded panels, brushed nickel bar pulls, overhanging top, tapered legs.
public struct TallboyChest: RealAsset {
    public static let id = "tallboy-chest"
    public static let summary = "Five-drawer painted tallboy chest of drawers with raised panels, nickel bar pulls and tapered legs."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth), pulls included.
    public var size = V3(0.8, 1.3, 0.45)
    /// Case and drawer front wood.
    public var wood: MaterialKey = "wood.painted-shaker:B7C4BC"
    /// Pull hardware.
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = CaseSpec(width: size.x, height: size.y, depth: size.z, bays: [Bay(kind: .drawers(1), height: 0.18), Bay(kind: .drawers(1), height: 0.2), Bay(kind: .drawers(1), height: 0.23), Bay(kind: .drawers(1), height: 0.26), Bay(kind: .drawers(1), height: 0.285)], legHeight: 0.12, wood: wood)
        sp.pull = .bar; sp.pullMaterial = hardware
        sp.topWood = "wood.painted-shaker-worn:B7C4BC"
        return CaseworkKit.cabinet(sp, seed: seed, detail: detail)
    }
}
