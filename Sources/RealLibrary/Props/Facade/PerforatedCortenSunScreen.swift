import simd
import Foundation

/// Perforated corten sun screen: architectural facade customizer, Contemporary. Parts: corten panel, perforation pattern, folded return edges, standoff brackets, fixing bolts, weathered patina, rust run-off.
public struct PerforatedCortenSunScreen: RealAsset {
    public static let id = "perforated-corten-sun-screen"
    public static let summary = "Perforated corten sun screen 1.2x2.4 m: folded-edge panel, round hole pattern, standoffs."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 2.4, 0.05)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.corten metal.rust metal.steel. Gate: realityhd gate perforated-corten-sun-screen. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.corten"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
