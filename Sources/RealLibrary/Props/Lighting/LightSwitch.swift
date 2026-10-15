import simd
import Foundation

/// Decorator rocker light switch on a satin white wall plate, 80 x 120 x 12 mm. Authored with its lowest point at
/// y = 0 and its back face at z = -0.006 (the planner lifts it to 1.2 m). Bevelled plate, dark opening recess,
/// tilted rocker paddle with a finger groove and two slotted screws.
public struct LightSwitch: RealAsset {
    public static let id = "light-switch"
    public static let summary = "Decorator rocker light switch on a white wall plate with two screws."
    public static let tags = ["prop", "floorplan", "interior", "electrical", "plastic", "wall"]
    public static let budget = 1500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.1, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.12, 0.012)
    /// Plate and paddle plastic.
    public var plastic: MaterialKey = "plastic.matte:F3F1EA"
    /// Paddle tilt in degrees about X (positive pushes the top in, the "off" pose).
    public var tilt: Float = 6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let W = size.x, H = size.y, back = -size.z / 2, cy = H / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let t: Float = 0.0045
            // Plate: bevelled rounded rectangle.
            m.add(Prim.extrude(Shape2D.roundedRect(W, H, radius: 0.006, segments: lod == 0 ? 4 : 2), depth: t, bevel: 0.0014, bevelSegments: lod == 0 ? 2 : 1, material: plastic),
                  Xform(translation: V3(0, cy, back + t / 2)))
            let pf = back + t                                   // front face of the plate
            // Opening: dark recess with a slim bevel frame, paddle sits inside.
            m.add(Prim.extrude(Shape2D.roundedRect(0.0365, 0.0695, radius: 0.0025, segments: 2), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0, cy, pf + 0.0002)))
            // Rocker paddle, pivoting at its middle: tilt about X, front face proud of the plate.
            let q = simd_quatf(degrees: tilt, axis: V3(1, 0, 0))
            let paddle = Prim.extrude(Shape2D.roundedRect(0.0335, 0.066, radius: 0.0022, segments: lod == 0 ? 3 : 2), depth: 0.0042, bevel: 0.0013, bevelSegments: lod == 0 ? 2 : 1, material: plastic)
            m.add(paddle, Xform(translation: V3(0, cy, pf + 0.002), rotation: q))
            if lod == 0 {
                // Finger groove across the paddle: a thin dark line following the tilt.
                m.add(cuboid(V3(0.026, 0.0006, 0.0004), material: "plastic.black"), Xform(translation: V3(0, cy, pf + 0.002) + q.act(V3(0, 0.0, 0.0021 + 0.0002)), rotation: q))
                // Two slotted screws, plate-colour heads.
                for s in [-1, 1] as [Float] {
                    let p = V3(0, cy + s * 0.0485, pf)
                    m.add(Prim.cylinder(radius: 0.0034, height: 0.0011, bevel: 0.0004, segments: 14, bevelSegments: 1, material: plastic),
                          Xform(translation: p, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))) )
                    m.add(cuboid(V3(0.0052, 0.0006, 0.0003), material: "plastic.black"), Xform(translation: p + V3(0, 0, 0.0011 + 0.0001), rotation: simd_quatf(degrees: 20, axis: V3(0, 0, 1))))
                }
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
