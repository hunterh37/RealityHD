import simd
import Foundation

/// Sidewalk slab pair, 3.0 x 1.5 m: two 10 cm poured concrete panels with a 12 mm black expansion joint,
/// tooled score lines every 75 cm, rounded edges, a small spall and a few flattened gum spots.
public struct SidewalkSlabPanel: RealAsset {
    public static let id = "sidewalk-slab-panel"
    public static let summary = "Sidewalk slabs, 3 x 1.5 m: two poured concrete panels, expansion joint, tooled score lines, gum spots."
    public static let tags = ["prop", "street", "urban", "outdoor", "ground", "concrete"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 3, studio: true)

    /// Panel size X, Z (m).
    public var panel = V2(1.5, 1.5)
    /// Panel thickness (m).
    public var thickness: Float = 0.1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let joint: Float = 0.012, w = panel.x * 2 + joint
        for s: Float in [-1, 1] {
            let tone = s < 0 ? 0xA9A59C : 0xB4B0A7
            GK.box(&m, V3(s * (panel.x + joint) / 2, thickness / 2, 0), V3(panel.x, thickness, panel.y), "concrete.sidewalk:" + String(format: "%06X", tone), r: 0.006)
            // Tooled score lines at the quarter points.
            GK.layer(&m, x: s * (panel.x + joint) / 2 + s * 0.375, z: 0, w: 0.004, d: panel.y - 0.02, top: thickness, "asphalt.sealant")
            GK.layer(&m, x: s * (panel.x + joint) / 2 - s * 0.375, z: 0, w: 0.004, d: panel.y - 0.02, top: thickness, "asphalt.sealant")
            GK.layer(&m, x: s * (panel.x + joint) / 2, z: 0, w: panel.x - 0.02, d: 0.004, top: thickness, "asphalt.sealant")
        }
        // Expansion joint filler, recessed 6 mm.
        GK.box(&m, V3(0, thickness - 0.011, 0), V3(joint, 0.02, panel.y - 0.01), "rubber.tire", r: 0.001)
        // Spalled corner on the right panel and gum spots.
        GK.layer(&m, x: w / 2 - 0.12, z: panel.y / 2 - 0.1, w: 0.14, d: 0.1, top: thickness, "concrete.rough:6E6B64", yaw: 20)
        for _ in 0..<7 {
            m.add(Prim.superellipsoid(V3(0.018, 0.002, 0.016), exponent: 2, subdivisions: 2, material: "plastic.matte:5C5852"),
                  Xform(translation: V3(rng.float(-w / 2 + 0.1...w / 2 - 0.1), thickness + 0.001, rng.float(-0.65...0.65))))
        }
        return GK.finish(&m, ao: 0.08)
    }
}
