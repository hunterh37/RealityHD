import simd
import Foundation

/// Gravel road shoulder, 1.5 x 1.0 m: a crumbling asphalt edge with a white fog line beside a raked
/// crushed-stone shoulder that ripples gently, dotted with larger stones and washed-out ruts.
public struct GravelShoulder: RealAsset {
    public static let id = "gravel-shoulder"
    public static let summary = "Gravel road shoulder, 1.5 x 1 m: rippled crushed stone beside an asphalt edge with fog line and loose stones."
    public static let tags = ["prop", "street", "road", "outdoor", "ground", "farm"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.9, studio: true)

    /// Overall size X (across, asphalt at -X), Z (m).
    public var size = V2(1.5, 1.0)
    /// Asphalt width (m).
    public var asphalt: Float = 0.5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...6.28), top: Float = 0.045
        // Asphalt part with its crumbled edge strip.
        GK.box(&m, V3(-size.x / 2 + asphalt / 2, top / 2, 0), V3(asphalt, top, size.y), "asphalt.worn", r: 0.005)
        GK.layer(&m, x: -size.x / 2 + 0.18, z: 0, w: 0.1, d: size.y - 0.04, top: top, GK.paintWhite)
        for _ in 0..<8 {
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.07), 0.025, rng.float(0.03...0.06)), exponent: 3, subdivisions: 3, material: "asphalt.worn"),
                  Xform(translation: V3(-size.x / 2 + asphalt + rng.float(-0.04...0.03), top - 0.012, rng.float(-0.45...0.45)), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        // Gravel field, lower than the asphalt.
        let gw = size.x - asphalt
        let gx = size.x / 2 - gw / 2
        var g = Model(name: "gravel")
        GK.field(&g, w: gw, d: size.y, edge: 0.03, segments: 48, "ground.gravel") { p in
            0.008 * sin(p.y * 9 + ph) + 0.006 * sin(p.x * 14 + p.y * 5) - 0.012 * exp(-pow((p.x + 0.15) / 0.12, 2))
        }
        m.add(g, Xform(translation: V3(gx, 0, 0)))
        for _ in 0..<16 {
            let p = V3(gx + rng.float(-gw / 2 + 0.06...gw / 2 - 0.06), 0.034, rng.float(-0.45...0.45))
            m.add(Prim.superellipsoid(V3(rng.float(0.025...0.06), rng.float(0.02...0.04), rng.float(0.025...0.05)), exponent: 3, subdivisions: 3,
                                      material: "stone.cast-grey"),
                  Xform(translation: p, rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        return GK.finish(&m, ao: 0.06)
    }
}
