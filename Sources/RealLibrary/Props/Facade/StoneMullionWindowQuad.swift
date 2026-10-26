import simd
import Foundation

/// Stone mullion window quad: architectural facade customizer, Elizabethan. Parts: ashlar jambs, sill, head, hood label moulding, central mullion, transom, four lights, iron glazing bars, leaded quarries, chamfered reveals.
public struct StoneMullionWindowQuad: RealAsset {
    public static let id = "stone-mullion-window-quad"
    public static let summary = "Elizabethan stone mullion and transom window, four lights, label hood, leaded glazing."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.6, 1.4, 0.25)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.sandstone stone.limestone-sooted glass.pane metal.iron. Gate: realityhd gate stone-mullion-window-quad. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.sandstone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
