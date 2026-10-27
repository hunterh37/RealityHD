import simd
import Foundation

/// Flat stamped-steel bottle opener lying on its side: tapered handle with a hanging hole, oval head
/// with a lift slot, and a formed lip that leans into the slot. Length along Z.
public struct BottleOpener: RealAsset {
    public static let id = "bottle-opener"
    public static let summary = "Stamped steel bottle opener: tapered handle with hanging hole, slotted head, formed lip."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 55, distance: 0.3, studio: true)

    /// Plate finish.
    public var plateMaterial: MaterialKey = "metal.brushed-nickel"
    /// Lip finish (worn bright where caps bite).
    public var lipMaterial: MaterialKey = "metal.nickel-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var upper: [(Float, Float)] = [(-0.06, 0.0075), (-0.035, 0.0072), (0.0, 0.0085), (0.010, 0.0098)]
        for i in 0...16 {
            let t: Float = 2.5 * (1 - Float(i) / 16)
            upper.append((0.036 + 0.0235 * cos(t), 0.015 * pow(sin(max(t, 0.0001)), 0.7)))
        }
        // Inner boundary (right to left): end cap, slot, bridge, hanging hole.
        func inner(_ z0: Float, _ s: Float) -> [(Float, Float)] {
            [(0.0595, z0), (0.050, z0), (0.050, s * 0.0055), (0.022, s * 0.0055), (0.022, z0),
             (-0.0455, z0), (-0.0455, s * 0.0028), (-0.0525, s * 0.0028), (-0.0525, z0), (-0.06, z0)]
        }
        let a = upper.dropLast() + inner(-0.0003, 1)
        let b = (upper.map { ($0.0, -$0.1) }.dropLast()) + inner(0, -1)
        m.add(DD1BKit.flat(Shape2D.rounded(DD1BKit.v2(Array(a)), radius: 0.0005, segments: 2), thick: 0.0030, y: 0.0016, bevel: 0.0003, material: plateMaterial))
        m.add(DD1BKit.flat(Shape2D.rounded(DD1BKit.v2(Array(b)), radius: 0.0005, segments: 2), thick: 0.0028, y: 0.0016, bevel: 0.0003, material: plateMaterial))
        m.add(Prim.roundedBox(V3(0.0035, 0.0072, 0.0125), radius: 0.0012, bevelSegments: 3, material: lipMaterial),
              Xform(translation: V3(0.0205, 0.0058, 0), rotation: simd_quatf(degrees: -8 + rng.float(-1...1), axis: V3(0, 0, 1))))
        return DD1BKit.finish(m, rng: &rng, groundHeight: 0.01)
    }
}
