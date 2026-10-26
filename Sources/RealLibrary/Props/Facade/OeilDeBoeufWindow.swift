import simd
import Foundation

/// Oeil de boeuf window: architectural facade customizer, French Baroque. Parts: moulded stone surround, four keystones, volute scrolls, reveal, round sash, glazing bars, glass, sill drip, laurel bead.
public struct OeilDeBoeufWindow: RealAsset {
    public static let id = "oeil-de-boeuf-window"
    public static let summary = "French Baroque oeil-de-boeuf, 0.8 m diameter: moulded limestone ring with four scrolled keystones, a painted round sash with glazing bars and glass."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.8, 0.8, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.limestone-sooted wood.painted-exterior glass.pane metal.wrought-iron. Gate: realityhd gate oeil-de-boeuf-window. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
