import simd
import Foundation

/// Cattle guard grate: architectural facade customizer, Rural. Parts: pipe rails, end frames, concrete footings, wing rails, weld beads, support beams, pit.
public struct CattleGuardGrate: RealAsset {
    public static let id = "cattle-guard-grate"
    public static let summary = "Rural cattle guard, welded steel pipe rails spanning a pit on concrete footings"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 0.2, 2.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.galvanized-aged metal.rust concrete.rough metal.steel. Gate: realityhd gate cattle-guard-grate. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.galvanized-aged"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
