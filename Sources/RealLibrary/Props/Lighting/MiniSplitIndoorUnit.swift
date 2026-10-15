import simd
import Foundation

/// Wall-mounted ductless mini-split indoor head, 900 x 290 x 200 mm. Authored with its lowest point at y = 0 and
/// its back face at z = -0.1 (the planner lifts it to 2.1 m). Curved white case extruded from a side profile,
/// top intake grille slots, dark lower discharge opening with a louver flap and deflector vanes, status window
/// with an LED, panel seam lines and a pipe cover stub on the left end.
public struct MiniSplitIndoorUnit: RealAsset {
    public static let id = "mini-split-indoor-unit"
    public static let summary = "Wall-mounted ductless mini-split indoor head: white curved case, top intake grille, louvered discharge, status LED."
    public static let tags = ["prop", "floorplan", "interior", "hvac", "appliance", "plastic", "wall"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: -14, distance: 1.7, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.9, 0.29, 0.2)
    /// Case color.
    public var caseMaterial: MaterialKey = "plastic.gloss:F3F3F0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let W = size.x, H = size.y, D = size.z
        let back = -D / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            // Side profile (world z, y): flat back, sloped top, bulged front, rounded underside.
            let prof: [V2] = [V2(back, 0.004), V2(back, H - 0.006), V2(back + 0.03, H - 0.002), V2(back + 0.13, H - 0.006), V2(0.062, H - 0.022),
                              V2(0.093, H - 0.07), V2(D / 2, H - 0.14), V2(D / 2, 0.075), V2(D / 2 - 0.012, 0.035), V2(0.05, 0.01), V2(back + 0.06, 0.0)]
            let body = Shape2D.rounded(prof, radius: 0.03, segments: lod == 0 ? 5 : 3)
            // extrude: local x -> -z world after a 90 degree turn about Y.
            m.add(Prim.extrude(body.map { V2(-$0.x, $0.y) }, depth: W, bevel: 0.006, bevelSegments: lod == 0 ? 2 : 1, material: caseMaterial),
                  Xform(rotation: simd_quatf(degrees: 90, axis: .up)))
            // Top intake grille: dark slots on the upper surface.
            let slots = lod == 0 ? 11 : 6
            for k in 0..<slots {
                let t = Float(k) / Float(slots - 1)
                let z = back + 0.052 + t * 0.07
                let yy = H - 0.002 - (z - back - 0.03) * 0.04 + 0.0004
                m.add(cuboid(V3(W - 0.12, 0.0014, 0.0055), material: "plastic.black"), Xform(translation: V3(0, yy, z)))
            }
            // Discharge opening on the underside front: dark recess, louver flap, deflector vanes.
            let oz: Float = 0.052
            m.add(cuboid(V3(W - 0.07, 0.003, 0.05), material: "plastic.black"), Xform(translation: V3(0, 0.0045, oz)))
            m.add(cuboid(V3(W - 0.07, 0.003, 0.012), material: "plastic.matte"), Xform(translation: V3(0, 0.0035, oz + 0.032)))
            if lod == 0 {
                m.add(Prim.roundedBox(V3(W - 0.09, 0.0025, 0.046), radius: 0.0008, bevelSegments: 1, material: caseMaterial),
                      Xform(translation: V3(0, 0.0065, oz + 0.004), rotation: simd_quatf(degrees: -18, axis: V3(1, 0, 0))))
                for k in 0..<8 {
                    let x = -W / 2 + 0.1 + Float(k) * (W - 0.2) / 7
                    m.add(cuboid(V3(0.0018, 0.012, 0.042), material: "plastic.matte"), Xform(translation: V3(x, 0.01, oz - 0.002)))
                }
            }
            // Status window with LED on the right of the front face, and a thin panel seam line.
            let fz = D / 2
            m.add(Prim.roundedBox(V3(0.07, 0.022, 0.003), radius: 0.001, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(W / 2 - 0.1, H - 0.115, fz - 0.0004), rotation: simd_quatf(degrees: 0, axis: .up)))
            m.add(Prim.cylinder(radius: 0.0025, height: 0.0015, bevel: 0.0004, segments: 8, bevelSegments: 1, material: "emissive.led-green"), Xform(translation: V3(W / 2 - 0.115, H - 0.115, fz + 0.001), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(cuboid(V3(W - 0.04, 0.0012, 0.0012), material: "plastic.matte"), Xform(translation: V3(0, H - 0.075, fz - 0.007)))
            // Front seams at both ends, brand badge, indicator lamps.
            for sx in [-1, 1] as [Float] {
                m.add(cuboid(V3(0.0012, 0.07, 0.0012), material: "plastic.matte"), Xform(translation: V3(sx * (W / 2 - 0.035), 0.115, fz - 0.0006)))
            }
            m.add(cuboid(V3(0.05, 0.007, 0.001), material: "metal.aluminum-brushed"), Xform(translation: V3(-W / 2 + 0.14, H - 0.115, fz - 0.0003)))
            for (k, mat) in ["emissive.led-green", "emissive.signal-orange"].enumerated() {
                m.add(Prim.cylinder(radius: 0.0022, height: 0.0012, bevel: 0.0003, segments: 8, bevelSegments: 1, material: MaterialKey(mat)), Xform(translation: V3(W / 2 - 0.082 + Float(k) * 0.0085, H - 0.1195, fz + 0.001), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // Pipe cover stub on the left end.
            m.add(Prim.roundedBox(V3(0.012, 0.02, 0.05), radius: 0.003, bevelSegments: 1, material: "plastic.matte"), Xform(translation: V3(-W / 2 + 0.01, 0.01, back + 0.03)))
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
