import simd
import Foundation

/// Cast iron balconette window guard: architectural facade customizer, Haussmann. Parts: top handrail, bottom rail, balusters, scroll panel, lozenge rosettes, end posts, finials, side returns, wall fixing pins.
public struct CastIronBalconetteWindowGuard: RealAsset {
    public static let id = "cast-iron-balconette-window-guard"
    public static let summary = "Haussmann cast-iron balconette guard, 1.4 x 0.9 m: handrail, scrolled balusters, central scroll panel and side returns pinned into the stone."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.4, 0.9, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron metal.cast-iron metal.rust metal.bolt-bright. Gate: realityhd gate cast-iron-balconette-window-guard. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
