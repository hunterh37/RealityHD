import simd
import Foundation

/// Enamel street name sign: architectural facade customizer, Parisian Haussmann. Parts: pressed steel blade, blue enamel field, white raised border, white lettering, corner screws, enamel chips and rust.
public struct EnamelStreetNameSign: RealAsset {
    public static let id = "enamel-street-name-sign"
    public static let summary = "Enamel street name sign, Parisian Haussmann facade prop, 0.6 x 0.15 x 0.03 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 0.15, 0.03)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.enamel metal.rust metal.steel. Gate: realityhd gate enamel-street-name-sign. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.enamel"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
