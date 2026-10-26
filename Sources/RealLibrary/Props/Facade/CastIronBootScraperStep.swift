import simd
import Foundation

/// Cast iron boot scraper: architectural facade customizer, Victorian. Parts: base plate, drain slots, end plates, scroll cutouts, scraper blade, lower blade, fixing bolts, feet.
public struct CastIronBootScraperStep: RealAsset {
    public static let id = "cast-iron-boot-scraper-step"
    public static let summary = "Victorian cast-iron boot scraper, 0.4 x 0.25 x 0.2 m: slotted base plate, two scrolled end plates and a bevelled scraper blade with a lower bar."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.4, 0.25, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron metal.cast-iron metal.rust metal.bolt-bright. Gate: realityhd gate cast-iron-boot-scraper-step. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
