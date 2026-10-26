import simd
import Foundation

/// Blade neon sign frame: architectural facade customizer, Art Deco. Parts: steel box spine, wall bracket, neon tube channels, tube supports, transformer box, stepped Deco crown, chrome trim.
public struct BladeNeonSignFrame: RealAsset {
    public static let id = "blade-neon-sign-frame"
    public static let summary = "Blade neon sign frame, Art Deco facade prop, 0.5 x 1.2 x 0.1 m."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 1.2, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powder-white metal.anodized-black emissive.warm. Gate: realityhd gate blade-neon-sign-frame. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powder-white"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
