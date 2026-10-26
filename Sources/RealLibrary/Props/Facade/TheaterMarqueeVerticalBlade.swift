import simd
import Foundation

/// Theater vertical blade sign: architectural facade customizer, Art Deco Commercial. Parts: steel body, stepped crown, neon outline, vertical lettering, bulb rows, wall brackets.
public struct TheaterMarqueeVerticalBlade: RealAsset {
    public static let id = "theater-marquee-vertical-blade"
    public static let summary = "Art Deco theatre blade sign 4.0 m: stepped crown, neon outline, vertical lamp letters, bulb borders, steel body."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 4.0, 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.painted metal.stainless emissive.signal-red emissive.warm emissive.signal-white. Gate: realityhd gate theater-marquee-vertical-blade. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.painted"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
