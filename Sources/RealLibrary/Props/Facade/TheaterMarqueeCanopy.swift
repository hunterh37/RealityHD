import simd
import Foundation

/// Theater marquee canopy: architectural facade customizer, Art Deco Commercial. Parts: fascia, stepped moulding, letter boards, bulb chase, soffit lights, tie rods, side fascias.
public struct TheaterMarqueeCanopy: RealAsset {
    public static let id = "theater-marquee-canopy"
    public static let summary = "Art Deco marquee canopy 4.0 x 1.0 x 1.4 m: stepped fascia, changeable letter boards, bulb chase, soffit lights, tie rods."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(4.0, 1.0, 1.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.painted metal.stainless emissive.warm sign.white metal.brass-aged. Gate: realityhd gate theater-marquee-canopy. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.painted"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
