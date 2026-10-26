import simd
import Foundation

/// Crittall steel window: architectural facade customizer, Art Deco. Parts: thin Z-section steel outer frame with welded corners, grid of 3 x 4 glazed lights, two opening casement sashes, espagnolette rod, handle and keeper, butt hinges with pins, putty glazing beads around each pane, cast concrete sill with drip, paint flaking and rust at the sill.
public struct CrittallSteelWindow: RealAsset {
    public static let id = "crittall-steel-window"
    public static let summary = "Art Deco Crittall steel casement window: slim painted steel frame in a grid of lights, two opening casements with espagnolette fasteners, putty-glazed glass and a concrete sill."
    public static let tags = ["prop", "architecture", "facade", "window", "metal", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.4, 1.6, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.painted metal.rust metal.steel glass.clear concrete.smooth. Gate: realityhd gate crittall-steel-window. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.painted"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
