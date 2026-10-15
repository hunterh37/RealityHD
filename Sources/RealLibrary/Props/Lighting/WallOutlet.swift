import simd
import Foundation

/// Duplex 15 A wall outlet on a satin white plate, 70 x 115 x 15 mm. Authored with its lowest point at y = 0 and
/// its back face at z = -0.0075 (the planner lifts it to 0.4 m). Bevelled plate, dark opening recess, raised
/// receptacle body with two socket faces (hot and neutral slots plus a ground hole each), a split groove and a
/// brass center screw.
public struct WallOutlet: RealAsset {
    public static let id = "wall-outlet"
    public static let summary = "Duplex 15 A wall outlet: white decorator plate, receptacle body with two grounded socket faces and center screw."
    public static let tags = ["prop", "floorplan", "interior", "electrical", "plastic", "wall"]
    public static let budget = 1800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.1, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.07, 0.115, 0.015)
    /// Plate and receptacle plastic.
    public var plastic: MaterialKey = "plastic.matte:F3F1EA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let W = size.x, H = size.y, back = -size.z / 2, front = size.z / 2, cy = H / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let t: Float = 0.0055
            m.add(Prim.extrude(Shape2D.roundedRect(W, H, radius: 0.006, segments: lod == 0 ? 4 : 2), depth: t, bevel: 0.0015, bevelSegments: lod == 0 ? 2 : 1, material: plastic),
                  Xform(translation: V3(0, cy, back + t / 2)))
            let pf = back + t
            // Opening recess and the raised receptacle body.
            m.add(Prim.extrude(Shape2D.roundedRect(0.044, 0.0885, radius: 0.003, segments: 2), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0, cy, pf + 0.0002)))
            let bodyDepth = front - (pf - 0.0005)
            m.add(Prim.extrude(Shape2D.roundedRect(0.039, 0.083, radius: 0.0035, segments: lod == 0 ? 3 : 2), depth: bodyDepth, bevel: 0.0028, bevelSegments: lod == 0 ? 2 : 1, material: plastic),
                  Xform(translation: V3(0, cy, pf - 0.0005 + bodyDepth / 2)))
            let fz = front                                    // face plane
            for s in [-1, 1] as [Float] {
                let fy = cy + s * 0.0215
                // Hot (narrow, right) and neutral (wide, left) slots, ground hole below; ground is down on both faces.
                m.add(cuboid(V3(0.0034, 0.0078, 0.0007), material: "plastic.black"), Xform(translation: V3(0.0063, fy + 0.0035, fz - 0.0001)))
                m.add(cuboid(V3(0.0046, 0.0078, 0.0007), material: "plastic.black"), Xform(translation: V3(-0.0063, fy + 0.0035, fz - 0.0001)))
                m.add(Prim.cylinder(radius: 0.0029, height: 0.0007, bevel: 0.0002, segments: lod == 0 ? 14 : 8, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: V3(0, fy - 0.0078, fz - 0.0004), rotation: .identity))
                // Thin brass contact visible inside each slot.
                if lod == 0 {
                    m.add(cuboid(V3(0.0007, 0.005, 0.0004), material: "metal.brass-aged"), Xform(translation: V3(0.0063, fy + 0.0035, fz + 0.0001)))
                    m.add(cuboid(V3(0.0007, 0.005, 0.0004), material: "metal.brass-aged"), Xform(translation: V3(-0.0063, fy + 0.0035, fz + 0.0001)))
                }
            }
            // Split groove between the two faces and the brass center screw.
            m.add(cuboid(V3(0.039, 0.0011, 0.0007), material: "plastic.black"), Xform(translation: V3(0, cy, fz - 0.0001)))
            m.add(Prim.cylinder(radius: 0.0034, height: 0.0012, bevel: 0.0004, segments: lod == 0 ? 16 : 8, bevelSegments: 1, material: "metal.brass-aged"),
                  Xform(translation: V3(0, cy, fz - 0.0012), rotation: .identity))
            if lod == 0 {
                m.add(cuboid(V3(0.0054, 0.0007, 0.0004), material: "plastic.black"), Xform(translation: V3(0, cy, fz + 0.0002), rotation: simd_quatf(degrees: 20, axis: V3(0, 0, 1))))
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
