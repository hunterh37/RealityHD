import simd
import Foundation

/// Probe core: photoreal aerospace flight hardware, clean with light handling wear. Parts: avionics-ring, foil-blanket, antenna, stack-rings, status-light.
public struct ProbeCore: RealAsset {
    public static let id = "probe-core"
    public static let summary = "Uncrewed probe core, 1.25 m: aluminum avionics ring wrapped in gold MLI foil with access panels, stack rings, whip antenna and status light."
    public static let tags = ["prop", "aerospace", "metal", "electronics"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.25, 0.4, 1.25)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.aluminum-brushed insulation.foil-gold metal.steel plastic.black emissive.led-green. Gate: realityhd gate probe-core. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.aluminum-brushed"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
