import simd
import Foundation

/// Canvas awning scalloped: architectural facade customizer, Parisian Haussmann. Parts: wrought iron arms, wall bracket plates, front bar, canvas striped sloped sheet, scalloped valance, seam stitching, piping edge, side triangles, bolts.
public struct CanvasAwningScalloped: RealAsset {
    public static let id = "canvas-awning-scalloped"
    public static let summary = "Parisian scalloped canvas awning 1.6 m: iron frame, striped canvas, scalloped valance."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.6, 0.9, 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: fabric.canvas metal.wrought-iron metal.rust. Gate: realityhd gate canvas-awning-scalloped. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "fabric.canvas"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
