import simd
import Foundation

/// Victorian turned newel post: moulded plinth, square base block with raised panels and chamfer stops, lathe-turned
/// vase shaft with beads, fillets and cove rings, square neck block, chamfered cap with a pyramid top and a turned ball
/// finial. Rail ends are mortised into the neck block on two faces and pegged with oak dowels. White lead paint,
/// flaked and greyed on the cap top, damp-stained foot, one bare chipped patch on the base block.
public struct TurnedNewelPost: RealAsset {
    public static let id = "turned-newel-post"
    public static let summary = "Victorian turned newel post, 1.1 m: square base block, lathe-turned vase shaft with bead and ring mouldings, chamfered cap and ball finial."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.8)

    /// Painted wood.
    public var paint: MaterialKey = "wood.painted-exterior:E3DDCB"
    /// Bare weathered wood showing through flaked paint.
    public var bare: MaterialKey = "wood.weathered"
    /// Dowel pegs.
    public var peg: MaterialKey = "wood.oak:8A6642"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let tint2: MaterialKey = "wood.painted-exterior:D8D1BC"
        let seg = lite ? 16 : 40
        // Plinth and base moulding (ogee-ish stepped profile, square).
        FA.box(&m, V3(0.15, 0.05, 0.15), V3(0, 0.025, 0), paint, r: 0.004)
        FA.box(&m, V3(0.141, 0.012, 0.141), V3(0, 0.056, 0), paint, r: 0.004)
        FA.box(&m, V3(0.132, 0.012, 0.132), V3(0, 0.068, 0), paint, r: 0.005)
        // Square base block 0.12 wide, 0.075..0.30, with chamfer-stop corner strips and raised panels.
        let bw: Float = 0.12, b0: Float = 0.074, b1: Float = 0.30
        FA.box(&m, V3(bw, b1 - b0, bw), V3(0, (b0 + b1) / 2, 0), paint, r: 0.004)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.014, b1 - b0 - 0.05, 0.014), V3(sx * (bw / 2 - 0.002), (b0 + b1) / 2, sz * (bw / 2 - 0.002)), paint, r: 0.005, rot: FA.q(45, FA.Y))
        }}
        if !lite {
            for k in 0..<4 {
                let rot = FA.q(Float(k) * 90, FA.Y)
                let o = rot.act(V3(0, 0, bw / 2 + 0.0015))
                FA.box(&m, V3(0.07, 0.15, 0.004), V3(o.x, 0.186, o.z), paint, r: 0.0015, rot: rot)
                let o2 = rot.act(V3(0, 0, bw / 2 + 0.0035))
                FA.box(&m, V3(0.052, 0.12, 0.003), V3(o2.x, 0.186, o2.z), tint2, r: 0.001, rot: rot)
            }
        }
        // Top moulding of the base block: step then bead.
        FA.box(&m, V3(0.128, 0.008, 0.128), V3(0, b1 + 0.004, 0), paint, r: 0.003)
        // Turned shaft, 0.308 to 0.868 (0.56 m). (r, y local).
        let prof: [(Float, Float)] = [
            (0, 0), (0.030, 0), (0.030, 0.004), (0.040, 0.010), (0.040, 0.020), (0.032, 0.026), (0.030, 0.034),     // foot fillet, bead, cove
            (0.034, 0.044), (0.040, 0.060), (0.046, 0.085), (0.049, 0.115), (0.0485, 0.140), (0.044, 0.165),       // vase belly
            (0.036, 0.195), (0.029, 0.225), (0.025, 0.250), (0.024, 0.270),                                       // waist
            (0.028, 0.282), (0.034, 0.292), (0.036, 0.300), (0.034, 0.308), (0.027, 0.316), (0.025, 0.322),       // swell, bead
            (0.026, 0.330), (0.034, 0.340), (0.040, 0.352), (0.041, 0.362), (0.036, 0.372), (0.029, 0.378),       // second ball
            (0.030, 0.384), (0.039, 0.390), (0.039, 0.398), (0.030, 0.404),                                       // ring
            (0.0295, 0.412), (0.0295, 0.424), (0.034, 0.434), (0.034, 0.444), (0.030, 0.450), (0.030, 0.456),     // fillet, cove
            (0.040, 0.466), (0.046, 0.476), (0.046, 0.490), (0.040, 0.500), (0.036, 0.506), (0.036, 0.520),       // collar
            (0.040, 0.528), (0.040, 0.545), (0.0355, 0.552), (0.0355, 0.560), (0, 0.560),
        ]
        m.add(turned(prof, segments: seg, material: paint, seamTile: 0.2, grainVertical: true), Xform(translation: V3(0, 0.308, 0)))
        // Square neck block 0.108 wide, 0.868..0.98, rails mortised in on +X and +Z faces.
        let n0: Float = 0.868, n1: Float = 0.976, nw: Float = 0.108
        FA.box(&m, V3(0.12, 0.01, 0.12), V3(0, n0 + 0.005, 0), paint, r: 0.004)
        FA.box(&m, V3(nw, n1 - n0 - 0.01, nw), V3(0, (n0 + n1) / 2 + 0.005, 0), paint, r: 0.004)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.012, n1 - n0 - 0.03, 0.012), V3(sx * (nw / 2 - 0.001), (n0 + n1) / 2 + 0.005, sz * (nw / 2 - 0.001)), paint, r: 0.004, rot: FA.q(45, FA.Y))
        }}
        // Rail stubs with shoulders into the neck block (+X and +Z) and dowel pegs.
        for face in 0..<2 {
            let rot = FA.q(face == 0 ? 90 : 0, FA.Y)
            func put(_ s: V3, _ c: V3, _ r: Float, _ mat: MaterialKey) { let o = rot.act(c); FA.box(&m, s, o, mat, r: r, rot: rot) }
            put(V3(0.05, 0.062, 0.012), V3(0, 0.935, nw / 2 + 0.006), 0.003, paint)       // handrail end
            put(V3(0.056, 0.008, 0.016), V3(0, 0.9, nw / 2 + 0.007), 0.002, paint)         // shoulder line
            if !lite {
                for px: Float in [-0.016, 0.016] {
                    let o = rot.act(V3(px, 0.935, nw / 2 + 0.0125))
                    m.add(Prim.cylinder(radius: 0.0045, height: 0.0026, bevel: 0.0009, segments: 8, bevelSegments: 1, material: peg),
                          Xform(translation: o, rotation: rot * FA.q(90, FA.X)))
                }
            }
        }
        // Cap: overhanging chamfered slab, then pyramid, then ball finial on a turned stem.
        FA.box(&m, V3(0.15, 0.018, 0.15), V3(0, 0.989, 0), paint, r: 0.005)
        FA.box(&m, V3(0.142, 0.012, 0.142), V3(0, 1.004, 0), paint, r: 0.004)
        m.add(turned([(0, 1.008), (0.0636, 1.008), (0.0636 * 0.9, 1.0125), (0.0636 * 0.62, 1.026), (0.0636 * 0.34, 1.040), (0.015, 1.050), (0, 1.052)],
                     segments: 4, material: paint, seamTile: 0.2), Xform(rotation: FA.q(45, FA.Y)))
        let fin: [(Float, Float)] = [(0, 1.048), (0.020, 1.048), (0.019, 1.054), (0.012, 1.059), (0.011, 1.064), (0.017, 1.069), (0.0285, 1.0775),
                                     (0.0335, 1.0875), (0.0335, 1.0925), (0.029, 1.1025), (0.019, 1.1085), (0.008, 1.1115), (0, 1.1125)]
        m.add(turned(fin, segments: lite ? 12 : 28, material: paint, seamTile: 0.2, grainVertical: true), Xform())
        // Weathering.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cz + sin(a) * rz * rng.float(0.6...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<4 { flat(rng.float(-0.04...0.04), rng.float(-0.04...0.04), rng.float(0.012...0.03), rng.float(0.01...0.025), y: 1.0125, rng.chance(0.7) ? bare : "wood.deadwood") }
            // Flaked paint on block faces: irregular bare and grey-weathered patches, heavier near the foot and the neck.
            func facePatch(_ face: Int, _ cx: Float, _ cy: Float, _ rx: Float, _ ry: Float, half: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<10 { let a = Float(j) / 10 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.5...1.15), cy + sin(a) * ry * rng.float(0.5...1.15))) }
                let rot = FA.q(Float(face) * 90, FA.Y)
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: rot.act(V3(0, 0, half - 0.0006)), rotation: rot))
            }
            for face in 0..<4 {
                for _ in 0..<5 { facePatch(face, rng.float(-0.045...0.045), rng.float(0.08...0.28), rng.float(0.010...0.024), rng.float(0.014...0.045), half: bw / 2 + 0.0016, rng.chance(0.6) ? bare : "wood.deadwood") }
                for _ in 0..<3 { facePatch(face, rng.float(-0.04...0.04), rng.float(0.89...0.96), rng.float(0.010...0.02), rng.float(0.010...0.03), half: nw / 2, rng.chance(0.6) ? bare : "wood.deadwood") }
            }
            // Sooty grime band on the lower block faces and a dark rain streak below each cap overhang.
            for face in 0..<4 {
                facePatch(face, 0, 0.098, 0.052, 0.02, half: bw / 2 + 0.0016, "stone.limestone-sooted")
                facePatch(face, rng.float(-0.03...0.03), 0.975, 0.03, 0.006, half: nw / 2 + 0.0004, "wood.deadwood")
            }
            for _ in 0..<7 { flat(rng.float(-0.05...0.05), rng.float(-0.05...0.05), rng.float(0.015...0.035), rng.float(0.012...0.03), y: 1.0126, rng.chance(0.6) ? bare : "wood.deadwood") }
            // Damp-stained foot and a bare chipped patch low on the base block.
            FA.box(&m, V3(0.1505, 0.03, 0.1505), V3(0, 0.015, 0), "wood.deadwood", r: 0.004)
            FA.box(&m, V3(0.1506, 0.006, 0.1506), V3(0, 0.003, 0), "stone.limestone-sooted", r: 0.002)
            FA.box(&m, V3(0.034, 0.05, 0.0014), V3(0.02, 0.12, bw / 2 + 0.0005), bare, r: 0.0005)
            FA.box(&m, V3(0.0012, 0.04, 0.025), V3(-bw / 2 - 0.0004, 0.2, -0.015), bare, r: 0.0004)
        }
        groundAO(&m, height: 0.2, floor: 0.75)
        return FC.place(m)
    }
}
