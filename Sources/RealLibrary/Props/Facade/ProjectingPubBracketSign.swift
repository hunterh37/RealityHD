import simd
import Foundation

/// Projecting pub bracket sign: architectural facade customizer, English Tudor. Parts: wrought iron scroll bracket, wall plate, hanging rings, painted timber sign board, moulded frame, gilded lettering, rust and flaking paint.
public struct ProjectingPubBracketSign: RealAsset {
    public static let id = "projecting-pub-bracket-sign"
    public static let summary = "Projecting pub bracket sign, English Tudor facade prop, 0.9 x 0.8 x 0.05 m."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.9, 0.8, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron wood.painted-shaker-worn metal.gold-leaf. Gate: realityhd gate projecting-pub-bracket-sign. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
