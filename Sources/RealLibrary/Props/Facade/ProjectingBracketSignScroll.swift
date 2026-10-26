import simd
import Foundation

/// Projecting bracket sign, scroll: architectural facade customizer, Georgian Commercial. Parts: wall plates, scroll brackets, head rail, S-hooks, sign board, gilded border, lettering.
public struct ProjectingBracketSignScroll: RealAsset {
    public static let id = "projecting-bracket-sign-scroll"
    public static let summary = "Georgian trade sign on twin scroll iron brackets 0.9 m: rail, S-hooks, painted board with gilded border."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.9, 0.7, 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron wood.paint wood.painted-shaker-worn metal.gold-leaf. Gate: realityhd gate projecting-bracket-sign-scroll. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
