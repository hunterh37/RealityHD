import simd
import Foundation

/// Pawnbroker hanging balls: architectural facade customizer, Victorian Commercial. Parts: wall plate, scroll arm, hanger rings, brass balls, seam bands, brace.
public struct PawnbrokerHangingBalls: RealAsset {
    public static let id = "pawnbroker-hanging-balls"
    public static let summary = "Three brass balls on a wrought iron bracket 0.6 m: seamed spheres, scroll arm, hanger rings."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 0.6, 0.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron metal.brass-aged metal.brass. Gate: realityhd gate pawnbroker-hanging-balls. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
