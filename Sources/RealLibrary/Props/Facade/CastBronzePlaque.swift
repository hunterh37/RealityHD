import simd
import Foundation

/// Cast bronze plaque: architectural facade customizer, Civic. Parts: plaque plate, raised border, bead moulding, raised lettering, seal roundel, cap screws.
public struct CastBronzePlaque: RealAsset {
    public static let id = "cast-bronze-plaque"
    public static let summary = "Civic cast bronze plaque 0.6 x 0.4 m: raised border with bead, cast lettering, dedication seal, domed cap screws."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 0.4, 0.03)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.bronze-cast metal.bronze-weathered metal.brass. Gate: realityhd gate cast-bronze-plaque. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.bronze-cast"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
