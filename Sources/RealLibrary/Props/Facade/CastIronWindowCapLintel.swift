import simd
import Foundation

/// Cast iron window cap lintel: architectural facade customizer, Italianate. Parts: flat lintel face, raised panel, console end brackets, dentil band, cap moulding, anthemion crest, bolt bosses, bottom flange, casting seam, rust bleed.
public struct CastIronWindowCapLintel: RealAsset {
    public static let id = "cast-iron-window-cap-lintel"
    public static let summary = "Italianate cast iron window cap, 1.3 m: flat lintel face with raised panel, console brackets, dentil band, anthemion crest, cap moulding, bolt bosses, rust and flaking paint."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.3, 0.35, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.cast-iron metal.painted metal.rust metal.brass-aged. Gate: realityhd gate cast-iron-window-cap-lintel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.cast-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
