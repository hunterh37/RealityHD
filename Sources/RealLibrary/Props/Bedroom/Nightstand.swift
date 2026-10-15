import simd
import Foundation

/// Nightstand, 50 x 60 x 40 cm: overhanging top, one raised-panel drawer with a brass knob over an open shelf, tapered square legs, plywood back and shelf.
public struct Nightstand: RealAsset {
    public static let id = "nightstand"
    public static let summary = "Walnut nightstand: one raised-panel drawer with a brass knob above an open shelf, on tapered legs."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth), pulls included.
    public var size = V3(0.5, 0.6, 0.4)
    /// Case and drawer front wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Pull hardware.
    public var hardware: MaterialKey = "metal.brass"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var sp = CaseSpec(width: size.x, height: size.y, depth: size.z, bays: [Bay(kind: .drawers(1), height: 0.15), Bay(kind: .open, height: 0.265)], legHeight: 0.16, wood: wood)
        sp.pull = .knob; sp.pullMaterial = hardware
        return CaseworkKit.cabinet(sp, seed: seed, detail: detail)
    }
}
