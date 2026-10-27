import simd
import Foundation

/// Silicone spatula lying flat: thin flexible head with a beveled working edge over a stiffer center
/// rib, a stainless collar where the head meets the handle, a ribbed grip with a hanging eye. Length along Z.
public struct Spatula: RealAsset {
    public static let id = "spatula"
    public static let summary = "Silicone spatula: beveled flexible head with center rib, stainless collar, ribbed grip, hanging eye."
    public static let tags = ["prop", "interior", "kitchen", "plastic", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, distance: 0.6, studio: true)

    /// Head silicone (hex tint after the colon).
    public var headMaterial: MaterialKey = "rubber.silicone:B5301E"
    /// Handle silicone.
    public var handleMaterial: MaterialKey = "rubber.silicone:2A2A2E"
    /// Collar metal.
    public var collarMaterial: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yc: Float = 0.0030
        let head = Shape2D.rounded(DD1BKit.symmetric([(0.034, 0.0105), (0.050, 0.0200), (0.075, 0.0285), (0.150, 0.0300), (0.160, 0.0290)]), radius: 0.007, segments: 5)
        m.add(DD1BKit.flat(head, thick: 0.0032, y: yc, bevel: 0.0014, material: headMaterial))
        let rib = Shape2D.rounded(DD1BKit.symmetric([(0.034, 0.0085), (0.075, 0.0150), (0.140, 0.0150), (0.146, 0.0120)]), radius: 0.006, segments: 4)
        m.add(DD1BKit.flat(rib, thick: 0.0060, y: yc, bevel: 0.0024, material: headMaterial))
        let grip = Shape2D.rounded(DD1BKit.symmetric([(-0.160, 0.0075), (-0.120, 0.0095), (-0.060, 0.0105), (0.000, 0.0088), (0.036, 0.0070)]), radius: 0.004, segments: 5)
        m.add(DD1BKit.flat(grip, thick: 0.0095, y: 0.00475, bevel: 0.0036, material: handleMaterial))
        m.add(Prim.roundedBox(V3(0.013, 0.0072, 0.0152), radius: 0.0025, bevelSegments: 3, material: collarMaterial), Xform(translation: V3(0.040, 0.00475, 0)))
        for x: Float in [-0.060, -0.072, -0.084, -0.096, -0.108] {
            let w = 0.0104 - abs(x + 0.06) * 0.07
            m.add(Prim.roundedBox(V3(0.0022, 0.0100, w * 2 + 0.0004), radius: 0.0009, bevelSegments: 2, material: handleMaterial), Xform(translation: V3(x, 0.00475, 0)))
        }
        m.add(Prim.torus(major: 0.0048, minor: 0.0017, segments: 20, sides: 8, material: handleMaterial), Xform(translation: V3(-0.1635, 0.0016, 0)))
        return DD1BKit.finish(m, rng: &rng)
    }
}
