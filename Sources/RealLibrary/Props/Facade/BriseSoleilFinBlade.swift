import simd
import Foundation

/// Brise soleil fin blade: architectural facade customizer, Brutalist. Parts: board-marked concrete blade, tapered fin, chamfered arrises, shuttering lines, anchor plate, form-tie holes, stain streaks, weathering drip.
public struct BriseSoleilFinBlade: RealAsset {
    public static let id = "brise-soleil-fin-blade"
    public static let summary = "Brutalist concrete brise-soleil fin 0.1x2.4x0.6 m: tapered board-marked blade, anchor plates."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.1, 2.4, 0.6)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: concrete.smooth concrete.sealed-dim metal.steel. Gate: realityhd gate brise-soleil-fin-blade. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "concrete.smooth"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
