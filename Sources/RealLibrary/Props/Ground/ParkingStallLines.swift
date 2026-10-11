import simd
import Foundation

/// Two parking stalls, 5.4 x 5.5 m: 2.7 x 5.5 m bays outlined in 10 cm white stripes on asphalt, with
/// an oil stain, tyre marks and a sealed crack running through one bay.
public struct ParkingStallLines: RealAsset {
    public static let id = "parking-stall-lines"
    public static let summary = "Two parking stalls, 5.4 x 5.5 m: white painted bay lines on asphalt with oil stain and tyre marks."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 6, studio: true)

    /// Stall width and depth (m).
    public var stall = V2(2.7, 5.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, w = stall.x * 2, d = stall.y, lw: Float = 0.1
        GK.slab(&m, w: w, d: d, h: top, "asphalt.road", r: 0.01)
        for i in 0...2 {
            let x = -w / 2 + Float(i) * stall.x + (i == 0 ? lw / 2 : i == 2 ? -lw / 2 : 0)
            GK.layer(&m, x: x, z: 0, w: lw, d: d - 0.02 - rng.float(0...0.05), top: top, GK.paintWhite)
        }
        GK.layer(&m, x: 0, z: d / 2 - lw / 2, w: w, d: lw, top: top, GK.paintWhite)
        // Oil stain under the engine bay of the left stall, tyre marks in the right.
        m.add(Prim.superellipsoid(V3(0.55, 0.002, 0.4), exponent: 2, subdivisions: 6, material: "asphalt.sealant"),
              Xform(translation: V3(-stall.x / 2, top + 0.0012, 0.8), rotation: simd_quatf(angle: 0.3, axis: .up)))
        for s: Float in [-1, 1] {
            GK.layer(&m, x: stall.x / 2 + s * 0.8 + 0.05, z: -1.1, w: 0.22, d: 0.9, top: top + 0.0015, "asphalt.worn")
        }
        citySealedCrack(&m, start: V2(-0.2, -d / 2 + 0.2), angle: 1.35, length: 2.0, y: top, bounds: 2.6, rng: &rng)
        return GK.finish(&m, ao: 0.03)
    }
}
