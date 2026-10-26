import simd
import Foundation

/// Slate hung wall panel: architectural facade customizer, Cornish Vernacular. Parts: slate courses, staggered joints, battens, underlay, copper nails, lead verge flashing, timber edge trim, head lap.
public struct SlateHungWallPanel: RealAsset {
    public static let id = "slate-hung-wall-panel"
    public static let summary = "Cornish slate-hung wall panel, 1.2 x 2.0 m: staggered courses of riven slate over battens and underlay, copper nailed, lead verge flashing and timber edge trim."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 2.0, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.slate stone.slate-aged wood.trim-weathered metal.copper metal.rust. Gate: realityhd gate slate-hung-wall-panel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.slate"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
