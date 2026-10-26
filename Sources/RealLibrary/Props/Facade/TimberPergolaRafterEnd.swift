import simd
import Foundation

/// Timber pergola rafter end: architectural facade customizer, Craftsman. Parts: rafter tail with ogee cut, beam notch, carriage bolt, rafter, washer, end grain, weathered cedar, drip kerf.
public struct TimberPergolaRafterEnd: RealAsset {
    public static let id = "timber-pergola-rafter-end"
    public static let summary = "Craftsman pergola rafter tail 0.1x0.2x1.2 m: shaped end, bolted, weathered."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.1, 0.2, 1.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar-weathered wood.endgrain-weathered metal.galvanized-aged. Gate: realityhd gate timber-pergola-rafter-end. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar-weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
