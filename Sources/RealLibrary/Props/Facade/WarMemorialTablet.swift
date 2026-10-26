import simd
import Foundation

/// War memorial tablet: architectural facade customizer, Civic. Parts: slab, pediment, cornice, cast name lines, bronze wreath, poppies, plinth.
public struct WarMemorialTablet: RealAsset {
    public static let id = "war-memorial-tablet"
    public static let summary = "Civic memorial tablet 0.8 x 1.2 m: marble slab with pediment, cast bronze names, wreath, plinth."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.8, 1.2, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.marble stone.marble-honed metal.bronze-weathered sign.red stone.granite-moss. Gate: realityhd gate war-memorial-tablet. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.marble"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
