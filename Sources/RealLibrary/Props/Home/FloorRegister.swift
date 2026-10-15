import simd
import Foundation

/// Floor register: Dark cast-iron grate finish, worn at the edges, one fin bent. Parts: cast-iron frame with rolled edge, angled louver fins, slide damper lever on the front bar, galvanized duct sleeve below the grille, four mounting screws.
public struct FloorRegister: RealAsset {
    public static let id = "floor-register"
    public static let summary = "Flush floor heating register: cast-iron frame, angled louver fins with one bent, damper slide, galvanized sleeve and corner screws."
    public static let tags = ["prop", "floorplan", "home", "hvac", "metal", "interior"]
    public static let budget = 2500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.3, 0.02, 0.15)
    /// Louver fin count.
    public var fins = 7
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let paint: MaterialKey = "metal.cast-iron-worn"
                let W = size.x, D = size.z, H = size.y
        let bar: Float = 0.03, hf: Float = 0.018
        let ix = W / 2 - bar, iz = D / 2 - bar   // opening half extents
        // Frame: four box bars with rolled outer edges, full height to the floor.
        m.add(Prim.roundedBox(V3(W, hf, bar), radius: 0.0032, bevelSegments: 2, material: paint), Xform(translation: V3(0, hf / 2, D / 2 - bar / 2)))
        m.add(Prim.roundedBox(V3(W, hf, bar), radius: 0.0032, bevelSegments: 2, material: paint), Xform(translation: V3(0, hf / 2, -D / 2 + bar / 2)))
        for sx in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(bar, hf, 2 * iz + 0.004), radius: 0.0032, bevelSegments: 2, material: paint), Xform(translation: V3(sx * (W / 2 - bar / 2), hf / 2, 0)))
        }
        // Duct sleeve walls inside the opening and the dark duct below.
        let sleeve: MaterialKey = "metal.galvanized-aged"
        for sz in [Float(-1), 1] { m.add(cuboid(V3(2 * ix, hf - 0.002, 0.002), material: sleeve), Xform(translation: V3(0, (hf - 0.002) / 2 + 0.001, sz * (iz - 0.001)))) }
        for sx in [Float(-1), 1] { m.add(cuboid(V3(0.002, hf - 0.002, 2 * iz), material: sleeve), Xform(translation: V3(sx * (ix - 0.001), (hf - 0.002) / 2 + 0.001, 0))) }
        m.add(cuboid(V3(2 * ix - 0.004, 0.001, 2 * iz - 0.004), material: "metal.painted:1E1E20"), Xform(translation: V3(0, 0.003, 0)))
        // Louver fins tilted about X, running along the length.
        let n = fins
        let span = 2 * iz - 0.004
        for k in 0..<n {
            let z = -span / 2 + (Float(k) + 0.5) * span / Float(n)
            let tilt: Float = k == 2 ? 26 : 50 + rng.float(-1.5...1.5)   // one fin bent by a heel
            m.add(cuboid(V3(2 * ix - 0.004, 0.0022, 0.0085), material: paint),
                  Xform(translation: V3(0, hf - 0.0045, z), rotation: simd_quatf(degrees: tilt, axis: V3(1, 0, 0))))
        }
        // Stamped bead around the opening.
        m.add(Prim.roundedBox(V3(2 * ix + 0.016, 0.0014, 0.003), radius: 0.0005, bevelSegments: 1, material: paint), Xform(translation: V3(0, hf, iz + 0.008)))
        m.add(Prim.roundedBox(V3(2 * ix + 0.016, 0.0014, 0.003), radius: 0.0005, bevelSegments: 1, material: paint), Xform(translation: V3(0, hf, -iz - 0.008)))
        for sx in [Float(-1), 1] { m.add(Prim.roundedBox(V3(0.003, 0.0014, 2 * iz + 0.016), radius: 0.0005, bevelSegments: 1, material: paint), Xform(translation: V3(sx * (ix + 0.008), hf, 0))) }
        // Cross webs under the fins.
        for sx in [Float(-0.06), 0.06] {
            m.add(cuboid(V3(0.004, 0.006, 2 * iz - 0.002), material: paint), Xform(translation: V3(sx, hf - 0.011, 0)))
        }
        // Damper slide lever on the front bar.
        m.add(cuboid(V3(0.07, 0.0008, 0.005), material: "metal.painted:1E1E20"), Xform(translation: V3(0.06, hf + 0.0004, D / 2 - bar / 2)))
        m.add(Prim.roundedBox(V3(0.02, 0.002, 0.01), radius: 0.0008, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(0.075, hf + 0.001, D / 2 - bar / 2)))
        // Corner screws.
        for (sx, sz) in [(Float(-1), Float(-1)), (-1, 1), (1, -1), (1, 1)] {
            m.add(Prim.cylinder(radius: 0.0038, height: 0.0016, bevel: 0.0005, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                  Xform(translation: V3(sx * (W / 2 - 0.015), hf - 0.0004, sz * (D / 2 - 0.015))))
        }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(m)
    }
}
