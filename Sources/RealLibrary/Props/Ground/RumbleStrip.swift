import simd
import Foundation

/// Milled rumble strip, 3.0 x 1.0 m: asphalt shoulder with sixteen 18 cm-pitch transverse grooves, 30 cm
/// long and 12 mm wide, milled beside a white edge line; grooves hold dust.
public struct RumbleStrip: RealAsset {
    public static let id = "rumble-strip"
    public static let summary = "Rumble strip, 3 x 1 m: asphalt shoulder with milled transverse grooves beside a white edge line."
    public static let tags = ["prop", "street", "road", "outdoor", "ground", "farm"]
    public static let budget = 6500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 3.2, studio: true)

    /// Grooves along the road.
    public var grooves = 16
    /// Groove pitch (m).
    public var pitch: Float = 0.18
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.05, d = Float(grooves) * pitch + 0.1
        GK.slab(&m, w: 1.0, d: d, h: top, "asphalt.worn", r: 0.008)
        GK.layer(&m, x: -0.28, z: 0, w: 0.1, d: d - 0.02, top: top, GK.paintWhite)
        for i in 0..<grooves {
            let z = -d / 2 + 0.08 + Float(i) * pitch
            // Each groove: dark floor with raised dust lip at the ends.
            GK.box(&m, V3(0.15, top - 0.003, z), V3(0.3, 0.007, 0.05), "asphalt.sealant", r: 0.001)
            GK.box(&m, V3(0.15, top - 0.0006, z + rng.float(-0.003...0.003)), V3(0.3 - rng.float(0...0.02), 0.0014, 0.012), "ground.dirt", r: 0.0005)
        }
        // Gravel kicked out onto the shoulder edge.
        for _ in 0..<10 {
            m.add(Prim.superellipsoid(V3(0.015, 0.01, 0.015), exponent: 3, subdivisions: 2, material: "stone.cast-grey"),
                  Xform(translation: V3(rng.float(0.35...0.48), top + 0.004, rng.float(-d / 2 + 0.1...d / 2 - 0.1))))
        }
        return GK.finish(&m, ao: 0.05)
    }
}
