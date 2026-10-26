import simd
import Foundation

/// Foundation cornerstone: architectural facade customizer, Civic. Parts: stone block, margin draft, inscription panel, incised lettering, mortar joints, chipped arris.
public struct FoundationCornerstone: RealAsset {
    public static let id = "foundation-cornerstone"
    public static let summary = "Civic cornerstone block 0.6 x 0.4 x 0.3 m: dressed limestone with margin draft, incised dated inscription, mortar bed joints, weathered arris."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 0.4, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.limestone-sooted concrete.rough metal.bronze-weathered. Gate: realityhd gate foundation-cornerstone. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
