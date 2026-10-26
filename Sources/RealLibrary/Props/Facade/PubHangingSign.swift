import simd
import Foundation

/// Pub hanging sign: architectural facade customizer, English Vernacular. Parts: iron frame, scroll crest, hanging links, painted board, roundel, lettering, finials.
public struct PubHangingSign: RealAsset {
    public static let id = "pub-hanging-sign"
    public static let summary = "English pub swinging sign 0.8 x 1.0 m: wrought iron frame with scroll crest, painted board, gilt lettering, hanging links."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.8, 1.0, 0.1)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.wrought-iron wood.painted-shaker-worn metal.gold-leaf sign.white. Gate: realityhd gate pub-hanging-sign. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.wrought-iron"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
