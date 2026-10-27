import simd
import Foundation

/// loaf-pan: rounded-corner tray with flared walls, floor fillet and a rolled wire rim.
public struct LoafPan: RealAsset {
    public static let id = "loaf-pan"
    public static let summary = "loaf-pan: flared walls, rolled wire rim, baked-in patina."
    public static let tags = ["prop", "interior", "kitchen", "metal"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 38, distance: 0.8, studio: true)

    /// Overall size (m).
    public var size = V3(0.26, 0.07, 0.13)
    /// Sheet thickness (m).
    public var wall: Float = 0.0008
    /// Corner radius at the rim (m).
    public var corner: Float = 0.012
    /// Wall flare per side from base to rim (m).
    public var flare: Float = 0.014
    /// Inner surface.
    public var interior: MaterialKey = "metal.sheet-pan"
    /// Outer surface.
    public var exterior: MaterialKey = "metal.sheet-pan"
    /// Rolled rim.
    public var rim: MaterialKey = "metal.nickel-worn"
    public init() {}

    func model(detail: Bool) -> Model {
        var m = Model(name: Self.id)
        DD1AKit.tray(&m, w: size.x, d: size.z, h: size.y, wall: wall, corner: corner, flare: flare, bead: 0.0026,
                     interior: interior, exterior: exterior, rim: rim, detail: detail)
        groundAO(&m, height: 0.02, floor: 0.55)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(detail: true), model(detail: false)], switchDistances: [3])
    }
}
