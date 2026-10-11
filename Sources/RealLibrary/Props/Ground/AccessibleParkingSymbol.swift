import simd
import Foundation

/// Accessible parking bay, 3.6 x 5.5 m: blue 1.0 m square stencil with a white wheelchair pictogram,
/// outlined bay lines and a hatched access aisle on the left.
public struct AccessibleParkingSymbol: RealAsset {
    public static let id = "accessible-parking-symbol"
    public static let summary = "Accessible parking bay, 3.6 x 5.5 m: blue square with white wheelchair symbol, bay lines, hatched aisle."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 4500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 55, distance: 6, studio: true)

    /// Symbol square (m).
    public var square: Float = 1.0
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, w: Float = 3.6, d: Float = 5.5
        GK.slab(&m, w: w, d: d, h: top, "asphalt.road", r: 0.01)
        let bayX: Float = 0.9, lw: Float = 0.1
        for x: Float in [-w / 2 + lw / 2, -0.3, w / 2 - lw / 2] { GK.layer(&m, x: x, z: 0, w: lw, d: d - 0.02, top: top, GK.paintWhite) }
        GK.layer(&m, x: 0, z: d / 2 - lw / 2, w: w, d: lw, top: top, GK.paintWhite)
        // Hatched access aisle (x from -1.8 to -0.3).
        for i in 0..<8 {
            let z = -2.2 + Float(i) * 0.55
            GK.layer(&m, x: -1.05, z: z, w: 1.45, d: 0.1, top: top, GK.paintWhite, yaw: 45)
        }
        // Blue square and the pictogram, in the bay (x center bayX).
        GK.layer(&m, x: bayX, z: -0.6, w: square, d: square, top: top, "paint.lane-white:1F5FA8")
        let c = V3(bayX, top + 0.0025, -0.6), wm = GK.paintWhite
        m.add(Prim.cylinder(radius: 0.07, height: 0.003, bevel: 0.001, segments: 14, material: wm), Xform(translation: c + V3(0.0, 0, -0.24)))
        GK.layer(&m, x: bayX, z: -0.6 - 0.07, w: 0.07, d: 0.3, top: top + 0.0005, wm)
        GK.layer(&m, x: bayX + 0.12, z: -0.6 + 0.07, w: 0.3, d: 0.07, top: top + 0.0005, wm)
        GK.layer(&m, x: bayX + 0.25, z: -0.6 + 0.2, w: 0.07, d: 0.3, top: top + 0.0005, wm)
        m.add(Prim.torus(major: 0.2, minor: 0.032, segments: 20, sides: 6, arc: 4.4, minorY: 0.0016, material: wm),
              Xform(translation: c + V3(0, 0, 0.02), rotation: simd_quatf(angle: 3.3, axis: .up)))
        GK.layer(&m, x: bayX + rng.float(-0.3...0.3), z: 1.4, w: 0.25, d: 0.8, top: top + 0.0015, "asphalt.worn")
        return GK.finish(&m, ao: 0.03)
    }
}
