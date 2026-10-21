import simd
import Foundation

/// Round wall mirror, 80 cm across and 4 cm deep: stepped aged-brass frame with a beaded inner lip, beveled silvered
/// glass with a darkened edge and a few desilvering spots, plywood backing board, two D-ring hangers with picture wire
/// and three rubber bumpers. Authored with the back face at z = -depth / 2, lowest point at y = 0, front toward +Z.
public struct WallMirror: RealAsset {
    public static let id = "wall-mirror"
    public static let summary = "Round wall mirror, 80 cm: aged-brass stepped frame, beveled silvered glass, backing board with hangers."
    public static let tags = ["prop", "floorplan", "decor", "wall", "metal", "glass", "interior"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 2.2, studio: true)

    /// Overall size in meters (x and y diameter, z depth including bumpers).
    public var size = V3(0.8, 0.8, 0.04)
    /// Frame metal.
    public var frame: MaterialKey = "metal.brass-aged"
    /// Mirror silvering.
    public var silver: MaterialKey = "metal.chrome:E6F0EC"
    public init() {}

    private func disc(_ m: inout Model, r: Float, h: Float, z: Float, _ key: MaterialKey, at xy: V2 = V2(0, 0), bevel: Float = 0.001, seg: Int = 24) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(bevel, h * 0.45, r * 0.45), segments: seg, bevelSegments: 1, material: key),
              Xform(translation: V3(xy.x, xy.y, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = size.x / 2
        let zt: Float = size.z - 0.0036                       // frame depth; wire and ring add the last 6 mm behind the board
        // Frame: stepped moulding, lathe profile (radius, depth) turned about the depth axis.
        let prof: [V2] = Profile.smooth([V2(R - 0.050, 0.0), V2(R - 0.007, 0.0), V2(R, 0.004), V2(R, zt - 0.012), V2(R - 0.004, zt - 0.005), V2(R - 0.012, zt - 0.002),
                                         V2(R - 0.024, zt - 0.003), V2(R - 0.030, zt - 0.009), V2(R - 0.037, zt - 0.011), V2(R - 0.041, zt - 0.007), V2(R - 0.042, zt - 0.003),
                                         V2(R - 0.046, zt), V2(R - 0.050, zt - 0.004), V2(R - 0.050, 0.0)], per: 2)
        m.add(Prim.lathe(prof, segments: 72, seamTile: 0.3, material: frame), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Beaded inner lip: a ring of small domes in the step of the moulding.
        let nBeads = 60
        let bead: [V2] = [V2(0.0050, 0), V2(0.0048, 0.0018), V2(0.0030, 0.0038), V2(0, 0.0046)]
        let beadSurf = Prim.lathe(bead, segments: 6, seamTile: 0.02, material: frame)
        for k in 0..<nBeads {
            let a = Float(k) / Float(nBeads) * 2 * .pi
            let rr = R - 0.0275
            m.add(beadSurf, Xform(translation: V3(cos(a) * rr, sin(a) * rr, zt - 0.0095), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Backing board inside the frame, seen from behind.
        disc(&m, r: R - 0.0505, h: 0.0035, z: 0.0035, "paper.sheet:A07F56", bevel: 0.0008, seg: 72)
        // Mirror: flat face with a 22 mm beveled facet, silvering darkens at the very rim.
        let face: [V2] = [V2(R - 0.056, 0.0140), V2(R - 0.074, 0.0165), V2(0, 0.0165)]       // outer to centre: normals face +Z
        m.add(Prim.lathe(face, segments: 72, seamTile: 0.5, material: silver), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.lathe([V2(R - 0.0535, 0.0120), V2(R - 0.056, 0.0140)], segments: 72, seamTile: 0.5, material: "metal.steel:343836"), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // A few desilvering spots near the rim, where moisture gets behind the glass.
        for _ in 0..<7 {
            let a = rng.float(0...(2 * .pi))
            let rr = rng.float((R - 0.115)...(R - 0.084))
            let sr = rng.float(0.0025...0.008)
            disc(&m, r: sr, h: 0.0003, z: 0.01655, "metal.steel:3B403D", at: V2(cos(a) * rr, sin(a) * rr), bevel: 0.0001, seg: 10)
        }
        // Back hardware, all behind the board face (z < zb): two D-ring plates with screws, picture wire with sag, three bumpers.
        let zb: Float = 0.0035
        let hy: Float = R * 0.52
        let hx: Float = R * 0.32
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.020, 0.028, 0.0026), radius: 0.0011, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(s * hx, hy, zb - 0.0013)))
            m.add(Prim.torus(major: 0.0075, minor: 0.0013, segments: 16, sides: 6, material: "metal.steel"),
                  Xform(translation: V3(s * hx, hy + 0.0045, zb - 0.0026 - 0.0020), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            for sy: Float in [-1, 1] { disc(&m, r: 0.0022, h: 0.0012, z: zb - 0.0026 - 0.0010, "metal.steel", at: V2(s * hx, hy + sy * 0.0105), seg: 8) }
        }
        let wire = catmull([V3(-hx, hy + 0.0105, zb - 0.0046), V3(-hx * 0.5, hy + 0.040, zb - 0.0056), V3(0, hy + 0.054, zb - 0.0062), V3(hx * 0.5, hy + 0.040, zb - 0.0056), V3(hx, hy + 0.0105, zb - 0.0046)], per: 6)
        m.add(Prim.tube(wire, radii: wire.map { _ in 0.0009 }, sides: 5, seamTile: 0.01, material: "metal.steel", capEnd: true))
        for ang: Float in [210, 270, 330] {
            let a = ang * .pi / 180, rr = R - 0.030
            m.add(Prim.cylinder(radius: 0.0075, height: 0.0038, bevel: 0.0012, segments: 12, bevelSegments: 1, material: "rubber.silicone:1E1E20"),
                  Xform(translation: V3(cos(a) * rr, sin(a) * rr, zb), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }
        // Authoring frame: lowest point y = 0, centred on X, hanging wire's back at z = -depth / 2.
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -size.z / 2 - b.min.z)))
        return LODModel(m)
    }
}
