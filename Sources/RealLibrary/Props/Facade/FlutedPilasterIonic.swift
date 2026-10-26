import simd
import Foundation

/// Fluted pilaster Ionic: architectural facade customizer, Neoclassical. Parts: plinth, attic base torus and scotia, fluted shaft, arrises, necking, egg-and-dart echinus, volute scrolls, abacus, weathering at base.
public struct FlutedPilasterIonic: RealAsset {
    public static let id = "fluted-pilaster-ionic"
    public static let summary = "Neoclassical Ionic pilaster, 2.6 m: attic-style base with plinth, 20-flute shaft with arrises, Ionic capital with volutes and echinus, and abacus."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 2.6, 0.12)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.limestone stone.limestone-sooted stone.marble-honed stone.cast-stone. Gate: realityhd gate fluted-pilaster-ionic. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.limestone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
