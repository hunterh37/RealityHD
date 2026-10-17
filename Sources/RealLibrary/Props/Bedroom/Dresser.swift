import simd
import Foundation

/// Six-drawer dresser, 150 x 80 x 50 cm: overhanging top, two columns of three raised-panel drawers with beaded panels, brass cup pulls, short tapered feet.
public struct Dresser: RealAsset {
    public static let id = "dresser"
    public static let summary = "Six-drawer oak dresser in two columns with an overhanging top, raised drawer panels, brass cup pulls and short tapered feet."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth), pulls included.
    public var size = V3(1.5, 0.8, 0.5)
    /// Case and drawer front wood.
    public var wood: MaterialKey = "wood.oak"
    /// Pull hardware.
    public var hardware: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = CaseSpec(width: size.x, height: size.y, depth: size.z, bays: [Bay(kind: .drawers(2), height: 0.2173), Bay(kind: .drawers(2), height: 0.2173), Bay(kind: .drawers(2), height: 0.2174)], legHeight: 0.12, wood: wood)
        sp.pull = .cup; sp.pullMaterial = hardware
        return CaseworkKit.cabinet(sp, seed: seed, detail: detail)
    }
}
