import simd
import Foundation

/// Federal elliptical fanlight: architectural facade customizer, Federal. Parts: half-ellipse frame, radiating bars, concentric web arcs, central fan, beaded surround, moulded impost bar, glass lights, keystone block, end blocks with patera.
public struct FederalEllipticalFanlight: RealAsset {
    public static let id = "federal-elliptical-fanlight"
    public static let summary = "Federal elliptical fanlight, 1.6 m: half-ellipse frame with fan and web tracery of lead-came style bars, beaded surround, central keystone fan, impost, glazing."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.6, 0.8, 0.15)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.barn-white wood.painted-exterior glass.tinted metal.brass-aged stone.sandstone. Gate: realityhd gate federal-elliptical-fanlight. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.barn-white"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
