import simd
import Foundation

/// Gothic Revival carved stone stoup niche, 0.6 x 1.1 x 0.3 m: a limestone frame with a gabled head and a
/// two-centre pointed opening, a roll-moulded archivolt and hood mould ending in label stops, crockets up the
/// gable rake, a pinnacle finial, two shafted colonettes with bell capitals, a trefoil carved on the back wall, ashlar
/// joints, and an octagonal stoup basin on a stepped corbel. Soot streaks the head, moss grows at the sill and
/// the basin rim is chipped.
public struct CarvedStoneStoupNiche: RealAsset {
    public static let id = "carved-stone-stoup-niche"
    public static let summary = "Gothic Revival stoup niche, 0.6 x 1.1 m: pointed arch in a gabled limestone frame, hood mould, crockets, finial, colonettes, trefoil and an octagonal basin."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.1)

    /// Limestone ashlar.
    public var stone: MaterialKey = "stone.limestone"
    /// Soot and joint dirt.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Fresher sandstone at chips.
    public var chip: MaterialKey = "stone.sandstone"
    /// Moss at the sill.
    public var moss: MaterialKey = "stone.granite-moss:4F6B2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    /// Two-centre arch path left spring to right spring in the XY plane at depth z.
    func archPath(hw: Float, spring y0: Float, z: Float, n: Int) -> [V3] {
        let R = 2 * hw
        var pts: [V3] = []
        for k in 0...n { let a = Float(k) / Float(n) * .pi / 3; pts.append(V3(hw - R * cos(a), y0 + R * sin(a), z)) }
        for k in (0..<n).reversed() { let a = Float(k) / Float(n) * .pi / 3; pts.append(V3(-hw + R * cos(a), y0 + R * sin(a), z)) }
        return pts
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 5 : 8
        let n = lite ? 6 : 12
        let fz: Float = 0.14
        let hw: Float = 0.16, spring: Float = 0.5, sill: Float = 0.26
        // Base moulding.
        FA.run(&m, [V2(0, 0), V2(0.2, 0), V2(0.2, 0.02), V2(0.215, 0.03), V2(0.215, 0.05), V2(0.2, 0.06), V2(0.2, 0.1), V2(0, 0.1)], length: 0.6, stone, bevel: 0.003)
        // Frame: gabled outline with the pointed opening cut through.
        let outer: [V2] = [V2(-0.3, 0.1), V2(0.3, 0.1), V2(0.3, 0.78), V2(0, 0.95), V2(-0.3, 0.78)]
        let hole = FO9.pointedArch(hw: hw, spring: spring, rise: 0, base: sill, n: n)
        m.add(HTKit.plate(outer: outer, holes: [hole], depth: fz, bevel: 0.004, segments: 1, material: stone), Xform(translation: V3(0, 0, fz / 2)))
        // Back wall of the recess and the carved trefoil on it.
        let back = FO9.pointedArch(hw: hw - 0.001, spring: spring, rise: 0, base: sill - 0.002, n: n)
        m.add(Prim.extrude(back, depth: 0.03, bevel: 0.0005, bevelSegments: 1, material: soot), Xform(translation: V3(0, 0, 0.012)))
        for (cx, cy) in [(Float(0), Float(0.71)), (-0.04, 0.65), (0.04, 0.65)] {
            m.add(Prim.torus(major: 0.036, minor: 0.0055, segments: lite ? 10 : 18, sides: 5, material: stone), Xform(translation: V3(cx, cy, 0.031), rotation: FA.q(90, FA.X)))
        }
        FC.bead(&m, r: 0.008, at: V3(0, 0.66, 0.036), stone, sub: 2)
        // Archivolt roll mould on the opening and hood mould outside it with label stops.
        m.add(Prim.tube(archPath(hw: hw + 0.003, spring: spring, z: fz - 0.002, n: n), radii: Array(repeating: 0.0095, count: 2 * n + 1), sides: sides, seamTile: 0.1, material: stone, capEnd: true))
        let hood = archPath(hw: 0.215, spring: 0.5, z: fz + 0.006, n: n)
        m.add(Prim.tube(hood, radii: Array(repeating: 0.0165, count: 2 * n + 1), sides: sides, seamTile: 0.1, material: stone, capEnd: true))
        for s: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.034), exponent: 2, subdivisions: lite ? 2 : 3, material: stone), Xform(translation: V3(s * 0.215, 0.495, fz + 0.012)))
        }
        // Rake crockets up both gable edges (leaf lozenges leaning out) and the pinnacle.
        for s: Float in [-1, 1] {
            for k in 0..<4 {
                let t = (Float(k) + 0.55) / 4.2
                let p = V2(s * 0.3 * (1 - t), 0.78 + 0.17 * t)
                let theta: Float = atan2(0.17, 0.3) * 180 / .pi
                let rot: simd_quatf = FA.q(-s * theta, FA.Z) * FA.q(30, FA.X)
                let pos = V3(p.x, p.y, fz - 0.003)
                let leaf = turned([(0, 0), (0.007, 0.006), (0.016, 0.024), (0.011, 0.046), (0.004, 0.056), (0, 0.06)], segments: lite ? 4 : 6, material: stone, seamTile: 0.1)
                m.add(leaf, Xform(translation: pos, rotation: rot, scale: V3(1, 1, 0.55)))
            }
            // Rake moulding along the gable edge.
            FA.rod(&m, V3(s * 0.3, 0.78, fz - 0.002), V3(0, 0.95, fz - 0.002), r: 0.009, stone, sides: sides)
        }
        m.add(turned([(0, 0), (0.026, 0), (0.026, 0.015), (0.015, 0.03), (0.013, 0.06), (0.022, 0.075), (0.028, 0.1), (0.02, 0.125), (0.012, 0.14), (0.004, 0.15), (0, 0.152)], segments: lite ? 8 : 12, material: stone, seamTile: 0.1),
              Xform(translation: V3(0, 0.948, fz * 0.5)))
        // Colonettes with base rings, shafts and bell capitals at the jambs.
        for s: Float in [-1, 1] {
            m.add(turned([(0, 0), (0.024, 0), (0.024, 0.01), (0.02, 0.018), (0.0165, 0.026), (0.0165, 0.195), (0.02, 0.205), (0.026, 0.21), (0.03, 0.222), (0.03, 0.24), (0, 0.24)], segments: lite ? 8 : 14, material: stone, seamTile: 0.1),
                  Xform(translation: V3(s * (hw - 0.012), sill, 0.098)))
        }
        // Stepped corbel and the octagonal stoup basin.
        let cz: Float = 0.17
        m.add(turned([(0, 0.1), (0.05, 0.1), (0.05, 0.13), (0.07, 0.15), (0.07, 0.17), (0.09, 0.195), (0.1, 0.23), (0.115, 0.26),
                      (0.125, 0.27), (0.125, 0.29), (0.113, 0.296), (0.108, 0.287), (0.098, 0.276), (0.07, 0.267), (0, 0.264)], segments: 8, material: stone, seamTile: 0.2),
              Xform(translation: V3(0, 0, cz), rotation: FA.q(22.5, FA.Y)))
        // Stone shelf joining the basin to the wall.
        FA.box(&m, V3(0.24, 0.032, cz), V3(0, 0.248 + 0.0, cz / 2), stone, r: 0.003)
        // Ashlar joints on the frame face (dark grooves proud by a hair).
        if !lite {
            for y: Float in [0.38, 0.62, 0.84] { for s: Float in [-1, 1] { FA.box(&m, V3(0.14 - (y > 0.7 ? 0.04 : 0), 0.0026, 0.0012), V3(s * 0.23, y, fz + 0.0006), soot, r: 0.0005) } }
            for (x, y) in [(Float(0.24), Float(0.5)), (-0.26, 0.5), (0.26, 0.73), (-0.24, 0.73), (0.25, 0.3), (-0.25, 0.3)] { FA.box(&m, V3(0.0026, 0.24, 0.0012), V3(x, y, fz + 0.0006), soot, r: 0.0005) }
            // Wear: soot runs below the hood mould, moss on the sill and basin corbel, chips on the rim and hood.
            for _ in 0..<7 { FO9.patch(&m, cx: rng.float(-0.28...0.28), cy: rng.float(0.8...0.95), rx: rng.float(0.01...0.04), ry: rng.float(0.03...0.08), z: fz + 0.0008, soot, rng: &rng, depth: 0.0006) }
            for _ in 0..<9 { FO9.patch(&m, cx: rng.float(-0.28...0.28), cy: rng.float(0.11...0.25), rx: rng.float(0.025...0.06), ry: rng.float(0.015...0.04), z: fz + 0.0008, moss, rng: &rng, depth: 0.0007) }
            for _ in 0..<7 { FO9.patchTop(&m, cx: rng.float(-0.09...0.09), cz: rng.float(0.06...0.24), rx: rng.float(0.015...0.04), rz: rng.float(0.01...0.03), y: 0.2649 + 0.0, moss, rng: &rng, depth: 0.0006) }
            for k in 0..<6 {
                let a = Float(k) * 1.1
                m.add(Prim.superellipsoid(V3(0.02, 0.008, 0.014), exponent: 2, subdivisions: 2, material: chip), Xform(translation: V3(cos(a) * 0.113, 0.2955, cz + sin(a) * 0.113), rotation: FA.q(-a * 180 / .pi, FA.Y)))
            }
            for s: Float in [-1, 1] { for _ in 0..<3 { FO9.patch(&m, cx: s * rng.float(0.01...0.2), cy: rng.float(0.5...0.84), rx: 0.005, ry: 0.007, z: fz + 0.0235, chip, rng: &rng, depth: 0.0005, n: 6) } }
            // Soot band at the corbel underside and drip stain down the face under the basin.
            FO9.patch(&m, cx: 0, cy: 0.19, rx: 0.07, ry: 0.07, z: 0.0305, soot, rng: &rng, depth: 0.0005)
        }
        groundAO(&m, height: 0.18, floor: 0.82)
        return FC.place(m)
    }
}
