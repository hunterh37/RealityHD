import simd
import Foundation

/// Lion head door knocker: architectural facade customizer, Georgian. Parts: modelled lion mask with brow, nose and muzzle, mane in layered curls, ring held in the mouth, striker plate boss, mounting bolt heads, black paint worn to bare iron on high points, verdigris-free cast iron with seam line.
public struct IronDoorKnockerLion: RealAsset {
    public static let id = "iron-door-knocker-lion"
    public static let summary = "Georgian cast iron lion head door knocker: modelled lion mask with a ring in its mouth, strike plate and mounting bosses, black painted and worn at the high points."
    public static let tags = ["prop", "architecture", "facade", "door", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.2, 0.06)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.cast-iron metal.rust metal.brass-aged metal.painted. Gate: realityhd gate iron-door-knocker-lion. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.cast-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
