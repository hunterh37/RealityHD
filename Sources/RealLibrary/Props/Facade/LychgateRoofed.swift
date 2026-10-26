import simd
import Foundation

/// Lychgate roofed: architectural facade customizer, English Churchyard. Parts: four oak posts, tie beams, king post truss, ridge beam, roof rafters, clay or slate roof, bargeboards, coffin rest bench, stone sill plinth, swing gates.
public struct LychgateRoofed: RealAsset {
    public static let id = "lychgate-roofed"
    public static let summary = "English churchyard timber lychgate, oak frame on stone sills, steep gabled roof with coffin rest"
    public static let tags = ["prop", "architecture", "facade", "wood", "trim"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 2.8, 3.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar-weathered wood.oak wood.weathered metal.wrought-iron stone.slate. Gate: realityhd gate lychgate-roofed. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar-weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
