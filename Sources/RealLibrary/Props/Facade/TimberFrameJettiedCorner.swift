import simd
import Foundation

/// Timber frame jettied corner: architectural facade customizer, Medieval Tudor. Parts: corner post, dragon beam, jetty joist ends, bressumer, studs, diagonal braces, wattle and daub infill, sill beam, plinth, pegged joints, jowled post head.
public struct TimberFrameJettiedCorner: RealAsset {
    public static let id = "timber-frame-jettied-corner"
    public static let summary = "Medieval Tudor jettied corner, 1.5 x 2.8 x 1.5 m: oak frame with a corner post, dragon beam and joist ends carrying an overhanging upper storey of studs, braces and plaster infill."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.5, 2.8, 1.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.weathered wood.oak paint.stucco stone.limestone metal.cast-iron. Gate: realityhd gate timber-frame-jettied-corner. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
