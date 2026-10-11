import simd
import Foundation

/// Embedded tram rail, 2.0 x 0.9 m: one grooved girder rail 6 cm wide with a 4 cm flangeway, set flush
/// in the pavement with granite setts on the field side and asphalt on the other, rusty at the groove.
public struct TramRailInsert: RealAsset {
    public static let id = "tram-rail-insert"
    public static let summary = "Embedded tram rail, 2 x 0.9 m: grooved steel rail flush in asphalt on one side and granite setts on the other."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "metal", "stone"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Length along the track (m).
    public var length: Float = 2.0
    /// Rail head height above the base (m).
    public var top: Float = 0.1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Rail profile in (across, up): head with groove, web and foot, centered on x = 0.
        let rail = Shape2D.rounded([V2(-0.07, 0), V2(0.07, 0), V2(0.07, 0.02), V2(0.03, 0.03), V2(0.03, top), V2(0.0, top), V2(0.0, top - 0.04),
                                    V2(-0.02, top - 0.04), V2(-0.02, top), V2(-0.03, top), V2(-0.03, 0.03), V2(-0.07, 0.02)], radius: 0.003, segments: 2)
        m.add(Prim.extrude(rail, depth: length, bevel: 0.002, bevelSegments: 1, material: "metal.steel"))
        // Rust in the flangeway.
        GK.box(&m, V3(-0.005, top - 0.039, 0), V3(0.012, 0.002, length - 0.02), "metal.rust", r: 0.0005)
        // Asphalt side.
        GK.box(&m, V3(-0.07 - 0.2 + 0.0, (top - 0.004) / 2, 0), V3(0.4, top - 0.004, length), "asphalt.road", r: 0.004)
        // Setts side: two rows.
        let n = Int(length / 0.105)
        for r in 0..<2 {
            for i in 0..<n {
                let z = -length / 2 + 0.05 + Float(i) * 0.105 + (r == 1 ? 0.05 : 0)
                guard z < length / 2 - 0.04 else { continue }
                let h = (top - 0.004) * rng.float(0.96...1.0)
                m.add(Prim.roundedBox(V3(0.1, h, 0.1), radius: 0.014, bevelSegments: 1, material: "stone.granite-paver:" + String(format: "%06X", rng.pick([0x8A8A8C, 0x77777A, 0x9A9690]))),
                      Xform(translation: V3(0.07 + 0.055 + Float(r) * 0.105, h / 2, z), rotation: simd_quatf(degrees: rng.float(-2...2), axis: .up)))
            }
        }
        GK.layer(&m, x: 0.18, z: 0, w: 0.2, d: length, top: top - 0.004, "ground.dirt")
        return GK.finish(&m, ao: 0.06)
    }
}
