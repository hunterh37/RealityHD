import simd
import Foundation

/// Awning valance board: architectural facade customizer, Commercial. Parts: moulded board, gilt lettering, shadow letters, top channel, clips, screws.
public struct AwningSignValanceBoard: RealAsset {
    public static let id = "awning-sign-valance-board"
    public static let summary = "Shopfront awning valance board 2.0 m: moulded timber board, gilt lettering with shadow, aluminium channel, clips."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 0.3, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.painted-exterior metal.gold-leaf metal.aluminum-brushed plastic.black. Gate: realityhd gate awning-sign-valance-board. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.painted-exterior"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
