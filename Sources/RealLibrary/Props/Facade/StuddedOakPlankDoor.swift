import simd
import Foundation

/// Studded oak plank door: architectural facade customizer, Medieval Tudor. Parts: vertical oak planks with chamfered edges, three oak ledgers behind, diagonal brace, forged rose-head nail studs in rows, long strap hinges on pintles, iron ring pull with backplate, stone jambs with chamfer, iron lock plate and keyhole, worn oak grain with dark stains.
public struct StuddedOakPlankDoor: RealAsset {
    public static let id = "studded-oak-plank-door"
    public static let summary = "Tudor studded oak plank door: vertical oak planks on oak ledgers, rows of forged nail heads, strap hinges, a ring pull and a pointed oak frame."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.1, 2.2, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.oak wood.weathered metal.wrought-iron metal.rust stone.limestone. Gate: realityhd gate studded-oak-plank-door. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.oak"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
