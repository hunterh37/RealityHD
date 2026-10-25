import simd
import Foundation

/// Craftsman square newel post, 1.1 m: tapered oak shaft with applied frame-and-panel faces and chamfer stops, stepped
/// foot, neck moulding, overhanging cap slab on a bracket step and a low hipped pyramid top. Oak plugs cover the cap
/// screws. Dark stain worn to bare grey oak on the pyramid ridges and cap top, end-grain checks, a rain streak under the
/// overhang and sooty damp at the foot.
public struct SquareNewelPostCap: RealAsset {
    public static let id = "square-newel-post-cap"
    public static let summary = "Craftsman square newel post, 1.1 m: tapered oak shaft with recessed panels, overhanging cap slab and low pyramid top."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.9)

    /// Stained oak.
    public var stain: MaterialKey = "wood.oak:5C3D22"
    /// Slightly lighter oak for applied panel fields.
    public var field: MaterialKey = "wood.oak:6A4728"
    /// Sun-bleached, bare weathered oak.
    public var bare: MaterialKey = "wood.oak:866244"
    /// Plug and dowel oak.
    public var plug: MaterialKey = "wood.oak:9A7248"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Stepped foot and base moulding.
        FA.box(&m, V3(0.18, 0.05, 0.18), V3(0, 0.025, 0), stain, r: 0.005)
        FA.box(&m, V3(0.166, 0.016, 0.166), V3(0, 0.058, 0), stain, r: 0.004)
        FA.box(&m, V3(0.158, 0.014, 0.158), V3(0, 0.073, 0), stain, r: 0.005)
        // Tapered shaft 0.08 .. 0.895: 0.15 at the base to 0.138 at the top, softened corners.
        let s0: Float = 0.08, s1: Float = 0.955
        let rb = Shape2D.roundedRect(0.15, 0.15, radius: 0.005), rt = Shape2D.roundedRect(0.138, 0.138, radius: 0.005)
        var shaft = Prim.loft([Prim.ring(rb, y: s0), Prim.ring(rt, y: s1)], capStart: false, capEnd: false, material: stain)
        shaft.uvs = shaft.positions.map { V2($0.x + $0.z, $0.y) }
        shaft.computeTangents()
        m.add(shaft, Xform())
        // Frame-and-panel on each face: stiles, rails and a recessed-look field, all proud of the taper.
        func faceBox(_ face: Int, _ size0: V3, _ x: Float, _ y: Float, _ out: Float, _ mat: MaterialKey, r: Float) {
            let vert = size0.y > size0.x * 2
            let size = vert ? V3(size0.y, size0.x, size0.z) : size0
            let t = (y - s0) / (s1 - s0), half = 0.075 - 0.006 * t
            let rot = FA.q(Float(face) * 90, FA.Y)
            FA.box(&m, size, rot.act(V3(x, y, half + out)), mat, r: r, rot: vert ? rot * FA.q(90, FA.Z) : rot)
        }
        for face in 0..<4 {
            for sx: Float in [-1, 1] { faceBox(face, V3(0.016, 0.76, 0.006), sx * 0.049, 0.51, 0.001, stain, r: 0.0018) }     // stiles
            faceBox(face, V3(0.114, 0.018, 0.006), 0, 0.885, 0.001, stain, r: 0.0018)                                      // top rail
            faceBox(face, V3(0.114, 0.026, 0.006), 0, 0.155, 0.001, stain, r: 0.0018)                                      // bottom rail
            faceBox(face, V3(0.082, 0.69, 0.003), 0, 0.52, 0.0005, field, r: 0.001)                                        // recessed-look field
            if !lite {
                for sx: Float in [-1, 1] { faceBox(face, V3(0.004, 0.69, 0.005), sx * 0.0405, 0.52, 0.0035, stain, r: 0.0012) }   // panel bead
                for sy: Float in [-1, 1] { faceBox(face, V3(0.082, 0.004, 0.005), 0, 0.52 + sy * 0.343, 0.0035, stain, r: 0.0012) }
            }
        }
        // Neck moulding and cap bracket step.
        FA.box(&m, V3(0.152, 0.012, 0.152), V3(0, 0.961, 0), stain, r: 0.004)
        FA.box(&m, V3(0.162, 0.014, 0.162), V3(0, 0.974, 0), stain, r: 0.005)
        // Cap: undercut slab with rounded nose, then step and pyramid.
        FA.box(&m, V3(0.18, 0.026, 0.18), V3(0, 0.994, 0), stain, r: 0.006)
        FA.box(&m, V3(0.17, 0.010, 0.17), V3(0, 1.012, 0), stain, r: 0.004)
        let rBase: Float = 0.082 * 1.4142
        m.add(turned([(0, 1.015), (rBase, 1.015), (rBase * 0.97, 1.0215), (rBase * 0.80, 1.035), (rBase * 0.55, 1.05), (rBase * 0.30, 1.062), (0.016, 1.07), (0.0135, 1.075), (0, 1.0755)],
                     segments: 4, material: stain, seamTile: 0.2), Xform(rotation: FA.q(45, FA.Y)))
        m.add(turned([(0, 1.073), (0.011, 1.073), (0.0135, 1.080), (0.0135, 1.089), (0.0105, 1.096), (0, 1.1)], segments: lite ? 8 : 16, material: stain, seamTile: 0.2, grainVertical: true), Xform())
        // Oak plugs over the cap screws (cap corners) and neck dowels.
        if !lite {
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0065, height: 0.0024, bevel: 0.0008, segments: 10, bevelSegments: 1, material: plug),
                      Xform(translation: V3(sx * 0.067, 1.0068, sz * 0.067)))
            }}
            for face in 0..<4 { for sx: Float in [-1, 1] {
                let rot = FA.q(Float(face) * 90, FA.Y)
                m.add(Prim.cylinder(radius: 0.0045, height: 0.0024, bevel: 0.0008, segments: 8, bevelSegments: 1, material: plug),
                      Xform(translation: rot.act(V3(sx * 0.056, 0.968, 0.0762)), rotation: rot * FA.q(90, FA.X)))
            }}
        }
        // Weathering.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<10 { let a = Float(j) / 10 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.5...1.15), cz + sin(a) * rz * rng.float(0.5...1.15))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            // Cap slab top: bleached grey with stained edges.
            for _ in 0..<9 { flat(rng.float(-0.065...0.065), rng.float(-0.065...0.065), rng.float(0.014...0.034), rng.float(0.012...0.03), y: 1.0175, rng.chance(0.65) ? bare : "wood.weathered:6E6050") }
            func facePatch(_ face: Int, _ cx: Float, _ cy: Float, _ rx: Float, _ ry: Float, half: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<10 { let a = Float(j) / 10 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.5...1.15), cy + sin(a) * ry * rng.float(0.5...1.15))) }
                let rot = FA.q(Float(face) * 90, FA.Y)
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: rot.act(V3(0, 0, half - 0.0006)), rotation: rot))
            }
            for face in 0..<4 {
                // Rain streaks below the cap overhang and worn bare stain on the field, heavier near the foot.
                for _ in 0..<3 { facePatch(face, rng.float(-0.055...0.055), rng.float(0.91...0.95), rng.float(0.004...0.008), rng.float(0.02...0.05), half: 0.0725, "wood.oak:3E2916") }
                for _ in 0..<3 { facePatch(face, rng.float(-0.03...0.03), rng.float(0.2...0.8), rng.float(0.01...0.02), rng.float(0.03...0.07), half: 0.0795, rng.chance(0.7) ? bare : "wood.weathered:6E6050") }
                facePatch(face, 0, 0.1, 0.05, 0.02, half: 0.0768, "stone.limestone-sooted")
            }
            // End-grain checks and a bare chipped corner on the cap nose.
            for _ in 0..<5 { FA.box(&m, V3(rng.float(0.03...0.08), 0.0012, 0.0016), V3(rng.float(-0.04...0.04), 1.0175 + 0.0003, rng.float(-0.08...0.08)), "wood.deadwood", r: 0.0003) }
            FA.box(&m, V3(0.012, 0.014, 0.012), V3(0.0755, 0.994, 0.0755), bare, r: 0.002, rot: FA.q(45, FA.Y))
            // Damp foot.
            FA.box(&m, V3(0.1805, 0.014, 0.1805), V3(0, 0.007, 0), "stone.limestone-sooted", r: 0.003)
        }
        groundAO(&m, height: 0.2, floor: 0.75)
        return FC.place(m)
    }
}
