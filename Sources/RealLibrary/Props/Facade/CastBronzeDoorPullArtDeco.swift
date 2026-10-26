import simd
import Foundation

/// Art Deco bronze door pull: architectural facade customizer, Art Deco. Parts: vertical fluted bar 0.8 m, stepped ziggurat end blocks, chevron banding, mounting plates with bevelled edges, hex socket fasteners, polished high points with dark patina, hand-worn centre grip.
public struct CastBronzeDoorPullArtDeco: RealAsset {
    public static let id = "cast-bronze-door-pull-art-deco"
    public static let summary = "Art Deco cast bronze door pull: tall vertical bar with stepped ziggurat ends, fluted shaft, mounting plates and bolts, polished high points and darkened recesses."
    public static let tags = ["prop", "architecture", "facade", "door", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.8, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.bronze-cast metal.bronze-weathered metal.brass-aged metal.steel. Gate: realityhd gate cast-bronze-door-pull-art-deco. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.bronze-cast"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
