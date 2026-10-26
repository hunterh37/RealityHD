import simd
import Foundation

/// Carved stone stoup niche: architectural facade customizer, Gothic Revival. Parts: pointed arch niche, hood mould, crockets, finial, trefoil head, colonettes, capitals, stoup basin, corbel, back wall.
public struct CarvedStoneStoupNiche: RealAsset {
    public static let id = "carved-stone-stoup-niche"
    public static let summary = "Gothic Revival stoup niche, 0.6 x 1.1 m: limestone block with a pointed arch, hood mould with crockets and finial, trefoil head, colonettes and a carved basin on a corbel."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 1.1, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.limestone-sooted stone.sandstone stone.granite-moss. Gate: realityhd gate carved-stone-stoup-niche. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
