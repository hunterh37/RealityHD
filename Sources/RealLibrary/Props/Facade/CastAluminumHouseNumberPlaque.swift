import simd
import Foundation

/// Cast aluminum house number plaque: architectural facade customizer, Mid-Century Modern. Parts: cast plate, raised numerals, stud mounts, beveled border, oxidation.
public struct CastAluminumHouseNumberPlaque: RealAsset {
    public static let id = "cast-aluminum-house-number-plaque"
    public static let summary = "Cast aluminum house number plaque, Mid-Century Modern facade prop, 0.3 x 0.15 x 0.02 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 0.15, 0.02)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.aluminum-cast metal.anodized-black metal.satin-aluminum. Gate: realityhd gate cast-aluminum-house-number-plaque. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.aluminum-cast"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
