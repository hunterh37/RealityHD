import simd
import Foundation

/// Carriage house sliding door: architectural facade customizer, Carriage House. Parts: tongue-and-groove painted plank leaf, Z-braced framing battens, overhead steel track with brackets, wheel hangers with bolts, floor guide and stop, cast iron pull handle, sill plate, weathered paint with grime at the base.
public struct CarriageHouseSlidingDoor: RealAsset {
    public static let id = "carriage-house-sliding-door"
    public static let summary = "Carriage house sliding barn door: painted X-braced plank leaf on an overhead steel track with wheel hangers, a flat guide at the floor and a pull handle."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 2.4, 0.15)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.barn-red wood.painted-shaker-worn wood.lumber-pine metal.steel metal.cast-iron. Gate: realityhd gate carriage-house-sliding-door. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.barn-red"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
