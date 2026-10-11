import simd
import Foundation

/// Steel trench plate, 1.2 x 1.2 m x 25 mm, laid over a road excavation: weathered plate with welded
/// anti-skid bead lines, two lift holes, and cold-patch asphalt ramps feathered up to all four edges.
public struct SteelRoadPlate: RealAsset {
    public static let id = "steel-road-plate"
    public static let summary = "Steel road plate, 1.2 x 1.2 m x 25 mm: weathered trench plate with weld beads, lift holes and asphalt ramps."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "metal", "construction"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 2.4, studio: true)

    /// Plate size (m).
    public var plate: Float = 1.2
    /// Plate thickness (m).
    public var thickness: Float = 0.025
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ramp: Float = 0.3, total = plate + 2 * ramp, base: Float = 0.02
        GK.slab(&m, w: total, d: total, h: base, "asphalt.road", r: 0.004)
        let top = base + thickness
        GK.box(&m, V3(0, base + thickness / 2, 0), V3(plate, thickness, plate), "metal.rust", r: 0.003)
        GK.layer(&m, x: 0, z: 0, w: plate - 0.02, d: plate - 0.02, top: top, "metal.rust")
        // Cold-patch ramps: wedges on the four sides.
        let wedge = [V2(0, 0), V2(ramp, 0), V2(0, thickness)]
        for k in 0..<4 {
            let q = simd_quatf(degrees: Float(k) * 90, axis: .up)
            let s = Prim.extrude(wedge, depth: plate, bevel: 0.002, bevelSegments: 1, material: "asphalt.patch")
            m.add(s, Xform(translation: q.act(V3(plate / 2, base, 0)), rotation: q))
        }
        // Weld bead anti-skid lines across the plate.
        for i in 0..<7 {
            let z = -plate / 2 + 0.1 + Float(i) * (plate - 0.2) / 6
            GK.box(&m, V3(0, top + 0.002, z), V3(plate - 0.12, 0.004, 0.012), "metal.steel", r: 0.002)
        }
        // Lift holes.
        for s: Float in [-1, 1] {
            m.add(Prim.torus(major: 0.032, minor: 0.008, segments: 16, sides: 6, material: "metal.steel"), Xform(translation: V3(s * 0.45, top + 0.002, -0.5)))
            m.add(Prim.cylinder(radius: 0.03, height: 0.001, bevel: 0.0005, segments: 14, material: "asphalt.sealant"), Xform(translation: V3(s * 0.45, top + 0.0005, -0.5)))
        }
        // Rust streaks and chalk number.
        GK.layer(&m, x: rng.float(-0.3...0.3), z: 0.25, w: 0.5, d: 0.12, top: top + 0.004, "plastic.matte:D9D6CC", yaw: rng.float(-8...8))
        return GK.finish(&m, ao: 0.06)
    }
}
