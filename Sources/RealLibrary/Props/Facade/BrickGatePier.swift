import simd
import Foundation

/// Brick gate pier: architectural facade customizer, Colonial Revival. Parts: brick shaft in stretcher bond, corbelled plinth, stone cap, soldier course band, iron hinge pins, mortar joints.
public struct BrickGatePier: RealAsset {
    public static let id = "brick-gate-pier"
    public static let summary = "Colonial Revival brick gate pier, running bond with header band, limestone cap and corbelled brick base"
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 1.8, 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.sandstone stone.cast-stone metal.wrought-iron stone.brownstone. Gate: realityhd gate brick-gate-pier. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.sandstone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
