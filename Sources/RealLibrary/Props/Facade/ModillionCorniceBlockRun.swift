import simd
import Foundation

/// Modillion block cornice run: architectural facade customizer, Baroque. Parts: scrolled modillion blocks, acanthus leaf faces, coffer rosettes, egg-and-dart band, bed mould, deep corona with drip, cyma recta crown, frieze, joint at midspan.
public struct ModillionCorniceBlockRun: RealAsset {
    public static let id = "modillion-cornice-block-run"
    public static let summary = "Baroque modillion cornice run, 2.0 m: carved scrolled modillion blocks with acanthus leaves, rosettes in the coffers, egg-and-dart, deep corona and cyma crown in cast stone."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 0.5, 0.45)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.cast-stone stone.limestone stone.limestone-sooted stone.sandstone. Gate: realityhd gate modillion-cornice-block-run. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.cast-stone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
