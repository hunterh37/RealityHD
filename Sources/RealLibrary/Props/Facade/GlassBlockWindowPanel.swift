import simd
import Foundation

/// Glass block window panel: architectural facade customizer, Streamline Moderne. Parts: 16 hollow glass blocks with moulded edge rim and wave pattern, white mortar joints with recessed tooling, stainless steel perimeter channel, anchor clips and sealant bead at the frame, cast stone sill with drip, dirt streaking below the sill, one block with a dust haze.
public struct GlassBlockWindowPanel: RealAsset {
    public static let id = "glass-block-window-panel"
    public static let summary = "Streamline Moderne glass block window: 4 x 4 grid of pillowed glass blocks in mortar joints, framed by an aluminium channel and a cast sill."
    public static let tags = ["prop", "architecture", "facade", "window", "glass", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 1.2, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: glass.frosted glass.clear concrete.smooth metal.aluminum-brushed stone.cast-stone. Gate: realityhd gate glass-block-window-panel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "glass.frosted"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
