import simd
import Foundation

/// Horizontal slat fence panel: architectural facade customizer, Contemporary. Parts: steel posts, horizontal cedar slats with gaps, top cap, back channel, fixing screws, base plate.
public struct HorizontalSlatFencePanel: RealAsset {
    public static let id = "horizontal-slat-fence-panel"
    public static let summary = "Contemporary horizontal cedar slat screen in powder-coated posts"
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.8, 1.8, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar wood.cedar-weathered metal.powdercoat-worn metal.galvanized. Gate: realityhd gate horizontal-slat-fence-panel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
