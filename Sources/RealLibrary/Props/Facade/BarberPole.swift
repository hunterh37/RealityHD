import simd
import Foundation

/// Barber pole: architectural facade customizer, Victorian Commercial. Parts: glass cylinder, spiral stripes, top cap, base cap, finial, wall brackets.
public struct BarberPole: RealAsset {
    public static let id = "barber-pole"
    public static let summary = "Victorian barber pole 1.0 m: glass cylinder with red, white and blue spiral, cast iron caps, finial and wall brackets."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.2, 1.0, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: glass.pane sign.white sign.red metal.cast-iron metal.brass-aged metal.painted. Gate: realityhd gate barber-pole. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "glass.pane"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
