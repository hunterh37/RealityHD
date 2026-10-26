import simd
import Foundation

/// Steel Crittall window panel: architectural facade customizer, Industrial. Parts: rolled steel outer frame, T-section glazing bars, opening vent with butt hinges, cockspur fastener, stay arm, glass panes, putty bead, corner welds, rust wear.
public struct SteelCrittallWindowPanel: RealAsset {
    public static let id = "steel-crittall-window-panel"
    public static let summary = "Crittall steel window 1.2x1.5 m: slim T-section bars, opening vent, fastener, stay."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 1.5, 0.08)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.painted metal.rust metal.steel glass.pane. Gate: realityhd gate steel-crittall-window-panel. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.painted"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
