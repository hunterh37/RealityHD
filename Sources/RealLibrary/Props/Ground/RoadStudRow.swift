import simd
import Foundation

/// Raised pavement markers on a lane line, 0.6 x 3.6 m: three 10 x 10 cm yellow-bodied studs with 2 cm
/// bump height and amber retroreflector lenses, 1.2 m apart over a yellow dashed centerline.
public struct RoadStudRow: RealAsset {
    public static let id = "road-stud-row"
    public static let summary = "Reflective road studs, 0.6 x 3.6 m: three raised pavement markers with amber lenses on a yellow line."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "plastic"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 3, studio: true)

    /// Studs along the road.
    public var studs = 3
    /// Stud spacing (m).
    public var spacing: Float = 1.2
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04, d = Float(studs) * spacing
        GK.slab(&m, w: 0.6, d: d, h: top, "asphalt.road", r: 0.008)
        GK.layer(&m, x: 0, z: 0, w: 0.1, d: d - 0.04, top: top, GK.paintYellow)
        for i in 0..<studs {
            let z = (Float(i) - Float(studs - 1) / 2) * spacing
            let body = Prim.loft([Prim.ring(Shape2D.roundedRect(0.1, 0.1, radius: 0.025), y: 0), Prim.ring(Shape2D.roundedRect(0.085, 0.08, radius: 0.025), y: 0.02)],
                                 capStart: false, capEnd: true, material: "plastic.yellow")
            m.add(body, Xform(translation: V3(0, top, z)))
            // Epoxy bed around the base.
            GK.box(&m, V3(0, top + 0.0015, z), V3(0.13, 0.003, 0.13), "plastic.matte:8E8A80", r: 0.0012)
            // Amber lenses on both faces along the road axis.
            for s: Float in [-1, 1] {
                GK.box(&m, V3(0, top + 0.011, z + s * 0.03), V3(0.05, 0.012, 0.012), "plastic.amber", r: 0.0025, yaw: 0)
            }
            GK.layer(&m, x: rng.float(-0.03...0.03), z: z + rng.float(-0.15...0.15), w: 0.12, d: 0.3, top: top + 0.0015, "asphalt.worn")
        }
        return GK.finish(&m, ao: 0.05)
    }
}
