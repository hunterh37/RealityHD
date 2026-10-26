import simd
import Foundation

/// Shadowbox fence panel: architectural facade customizer, American Traditional. Parts: posts, post caps, stringers, alternating boards front and back, cap rail, kickboard, nails.
public struct ShadowboxFencePanel: RealAsset {
    public static let id = "shadowbox-fence-panel"
    public static let summary = "American traditional shadowbox fence, boards alternating each side of the rails"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 1.8, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar-weathered wood.pine-aged wood.lumber-pine metal.galvanized. Gate: realityhd gate shadowbox-fence-panel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar-weathered"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
