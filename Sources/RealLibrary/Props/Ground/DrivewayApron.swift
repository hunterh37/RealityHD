import simd
import Foundation

/// Concrete driveway apron, 4.2 x 1.2 m: a 2.4 m wide ramp dropping 12 cm from the sidewalk to the street,
/// flanked by 40 cm flared wings and granite curb stubs, with a control joint down the middle.
public struct DrivewayApron: RealAsset {
    public static let id = "driveway-apron"
    public static let summary = "Driveway apron, 4.2 x 1.2 m: concrete ramp with flared wings, curb stubs and a control joint."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "concrete"]
    public static let budget = 4500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 4, studio: true)

    /// Ramp width (m).
    public var ramp: Float = 2.4
    /// Drop from sidewalk to street (m).
    public var drop: Float = 0.12
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let depth: Float = 1.2, wing: Float = 0.4, curb: Float = 0.5, h: Float = 0.15
        // Ramp slopes from sidewalk level (z = +) down to the gutter (z = -).
        let side = [V2(-depth / 2, 0), V2(depth / 2, 0), V2(depth / 2, h), V2(-depth / 2, h - drop)]
        m.add(Prim.extrude(side, depth: ramp, bevel: 0.004, bevelSegments: 1, material: "concrete.sidewalk"), Xform(rotation: simd_quatf(degrees: -90, axis: .up)))
        for s: Float in [-1, 1] {
            // Flared wing: a wedge that falls away along the ramp slope.
            let wedge = [V2(-depth / 2, 0), V2(depth / 2, 0), V2(depth / 2, h), V2(-depth / 2, h - drop)]
            m.add(Prim.extrude(wedge, depth: wing, bevel: 0.004, bevelSegments: 1, material: "concrete.sidewalk:A9A59C"),
                  Xform(translation: V3(s * (ramp / 2 + wing / 2 + 0.004), 0, 0), rotation: simd_quatf(degrees: -90, axis: .up)))
            // Granite curb stub beyond each wing.
            GK.box(&m, V3(s * (ramp / 2 + wing + curb / 2 + 0.01), 0.23, -depth / 2 + 0.075), V3(curb, 0.46, 0.15), "stone.granite-curb", r: 0.01)
            GK.box(&m, V3(s * (ramp / 2 + wing + curb / 2 + 0.01), 0.23 - 0.0, 0.1 + 0.0), V3(curb, 0.01, 0.0), "concrete.sidewalk", r: 0)
        }
        // Control joint and tooled edge.
        GK.layer(&m, x: 0, z: 0, w: 0.006, d: depth - 0.02, top: h - drop / 2, "asphalt.sealant")
        GK.layer(&m, x: 0, z: 0.45, w: ramp - 0.02, d: 0.006, top: h - 0.015, "asphalt.sealant")
        // Tyre dirt in the middle.
        GK.layer(&m, x: rng.float(-0.4...0.4), z: -0.1, w: 0.5, d: 0.7, top: h - drop / 2 + 0.002, "ground.mud")
        return GK.finish(&m, ao: 0.08)
    }
}
