import simd
import Foundation

/// Dentil cornice run: architectural facade customizer, Neoclassical. Parts: frieze board, bed mould, dentil course, ovolo, corona with drip groove, cyma recta crown, fascia, scarf joint, nail heads, end return.
public struct DentilCorniceRun: RealAsset {
    public static let id = "dentil-cornice-run"
    public static let summary = "Neoclassical dentil cornice run, 2.0 m: frieze board, bed mould, dentil course at 60 mm pitch, ovolo, corona with drip, cyma recta crown and fascia, painted wood with weathering."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 0.4, 0.35)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.barn-white wood.trim-weathered wood.painted-exterior metal.galvanized-aged. Gate: realityhd gate dentil-cornice-run. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.barn-white"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
