import simd
import Foundation

/// Cedar window box planter: architectural facade customizer, Alpine Chalet. Parts: cedar front board, fretwork cutouts, end boards, bottom slats with drain gaps, iron brackets, screws, soil, geranium foliage and blooms, weathering.
public struct CedarWindowBoxPlanter: RealAsset {
    public static let id = "cedar-window-box-planter"
    public static let summary = "Alpine Chalet cedar window box, 1.0 m: tongue-and-groove cedar planks with heart-cut front fretwork, iron brackets, screw heads, soil and trailing geraniums."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 0.25, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.cedar wood.cedar-weathered metal.iron metal.galvanized. Gate: realityhd gate cedar-window-box-planter. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.cedar"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
