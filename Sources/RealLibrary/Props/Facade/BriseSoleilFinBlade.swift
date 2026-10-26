import simd
import Foundation

/// Brutalist concrete brise-soleil fin, 100 mm thick, 2.4 m tall, 600 mm projection: sixteen 150 mm shuttering-board
/// lifts stacked into a blade whose leading edge slopes back 80 mm toward the head, each lift with its own thickness and
/// lateral offset so the board joints read as steps with soft arrises, form-tie cone holes with grout plugs on a 300 mm
/// grid, two steel anchor plates with four nuts each at the wall root, a cast-in lifting socket in the head, and
/// weathering: rain streaks under the ties, efflorescence, a rock pocket, rust weeping from the anchor plates, sooted top.
public struct BriseSoleilFinBlade: RealAsset {
    public static let id = "brise-soleil-fin-blade"
    public static let summary = "Brutalist concrete brise-soleil fin 0.1x2.4x0.6 m: tapered board-marked blade, anchor plates."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 250, elevation: 9, distance: 3.6)

    /// Concrete.
    public var concrete: MaterialKey = "concrete.smooth"
    /// Darker, older concrete.
    public var aged: MaterialKey = "concrete.sidewalk"
    /// Steel.
    public var steel: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H: Float = 2.4, T: Float = 0.093, Dz: Float = 0.6, back: Float = 0.08
        let lifts = 16, lh = H / Float(lifts)
        func lead(_ y: Float) -> Float { Dz - back * y / H }                    // leading edge z at height y

        // Shuttering-board lifts: each its own thickness, offset and bevelled arrises.
        for i in 0..<lifts {
            let y0 = Float(i) * lh + 0.0006, y1 = Float(i + 1) * lh - 0.0006
            let t = T + rng.float(-0.0016...0.0016), off = rng.float(-0.0009...0.0009)
            let mat = rng.chance(0.22) ? aged : concrete
            let outline: [V2] = [V2(0, y0), V2(lead(y0) - 0.004, y0), V2(lead(y0), y0 + 0.004), V2(lead(y1), y1 - 0.004), V2(lead(y1) - 0.004, y1), V2(0, y1)]
            FO5.colX(&m, outline, x0: off - t / 2, x1: off + t / 2, mat, bevel: 0.0013)
        }
        // Leading-edge arris: a soft chamfer strip down the nose.
        // (Provided by the per-lift bevels; add a faint grout line along the nose for the board-end joint.)

        // Form-tie cone holes: recessed dark discs with a grout plug, both faces, on a 300 mm grid.
        for fx: Float in [-1, 1] {
            for (ri, y) in stride(from: Float(0.3), through: 2.1, by: 0.3).enumerated() {
                for z in [0.15, 0.42] as [Float] {
                    if z > lead(y) - 0.08 { continue }
                    let p = V3(fx * (T / 2 + 0.0006), y, z)
                    m.add(Prim.cylinder(radius: 0.0125, height: 0.0016, bevel: 0.0004, segments: 10, bevelSegments: 1, material: "plastic.black"),
                          Xform(translation: p - V3(fx * 0.0005, 0, 0), rotation: FA.q(-90 * fx, FA.Z)))
                    m.add(Prim.cylinder(radius: 0.009, height: 0.0012, bevel: 0.0004, segments: 10, bevelSegments: 1, material: ri % 3 == 0 ? "stone.limestone" : "concrete.sidewalk"),
                          Xform(translation: p + V3(fx * 0.0004, 0, 0), rotation: FA.q(-90 * fx, FA.Z)))
                    // Rain streak below the tie.
                    FO5.patchSide(&m, V2(0.012 + rng.float(0...0.01), rng.float(0.1...0.28)), V2(z, y - 0.12), x: fx * (T / 2), "stone.limestone-sooted")
                }
            }
        }

        // Steel anchor plates at the wall root, one each side near top and bottom, four nuts each, rust weeping below.
        for y in [0.38, 2.02] as [Float] {
            for fx: Float in [-1, 1] {
                let x = fx * (T / 2 - 0.0005)
                FA.box(&m, V3(0.004, 0.2, 0.2), V3(x, y, 0.1), steel, r: 0.0012)
                for (dz, dy) in [(-0.07, -0.07), (0.07, -0.07), (-0.07, 0.07), (0.07, 0.07)] as [(Float, Float)] {
                    FA.cylX(&m, r: 0.015, h: 0.001, at: V3(x + fx * 0.0015, y + dy, 0.1 + dz), steel, bevel: 0.0004, segments: 12)   // washer
                    m.add(Prim.cylinder(radius: 0.0095, height: 0.0026, bevel: 0.0008, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"),
                          Xform(translation: V3(x + fx * 0.0024, y + dy, 0.1 + dz), rotation: FA.q(-90 * fx, FA.Z)))                        // hex nut
                }
                let weep = min(0.3, y - 0.12)
                FO5.patchSide(&m, V2(0.05, weep), V2(0.08, y - 0.1 - weep / 2), x: fx * (T / 2 + 0.0004), "metal.rust")
                FO5.patchSide(&m, V2(0.012, weep * 0.8), V2(0.14, y - 0.1 - weep * 0.4), x: fx * (T / 2 + 0.0004), "metal.rust-grime")
            }
        }
        // Cast-in lifting socket in the head, and a steel cap plate on it.
        m.add(Prim.cylinder(radius: 0.03, height: 0.004, bevel: 0.0012, segments: 14, bevelSegments: 1, material: steel), Xform(translation: V3(0, H - 0.0005, 0.22)))
        m.add(Prim.cylinder(radius: 0.014, height: 0.002, bevel: 0.0006, segments: 10, bevelSegments: 1, material: "metal.rust"), Xform(translation: V3(0, H + 0.0035, 0.22)))

        // Surface defects: efflorescence, rock pocket, bug-hole cluster, soot on the top.
        for fx: Float in [-1, 1] {
            FO5.patchSide(&m, V2(0.22, 0.08), V2(0.3, 2.28), x: fx * T / 2, "stone.limestone")
            for _ in 0..<4 {
                FO5.patchSide(&m, V2(rng.float(0.01...0.03), rng.float(0.2...0.5)), V2(rng.float(0.05...lead(1) - 0.1), rng.float(1.5...2.1)), x: fx * T / 2, "stone.limestone")
            }
        }
        for _ in 0..<14 {                                                     // rock pocket near the foot
            let z = rng.float(0.1...0.28), y = rng.float(0.05...0.2)
            m.add(Prim.superellipsoid(V3(0.0035, rng.float(0.01...0.03), rng.float(0.01...0.03)), exponent: 2, subdivisions: 1, material: "plastic.black"),
                  Xform(translation: V3(T / 2 + 0.0004, y, z)))
        }
        for _ in 0..<40 {                                                     // bug holes
            let fx: Float = rng.chance(0.5) ? 1 : -1
            let y = rng.float(0.2...2.3), z = rng.float(0.04...lead(y) - 0.04)
            m.add(Prim.superellipsoid(V3(0.0012, 0.004, 0.004), exponent: 2, subdivisions: 1, material: "plastic.black"),
                  Xform(translation: V3(fx * (T / 2 + 0.0002), y, z)))
        }
        FJ.slab(&m, V3(T - 0.01, 0.0012, Dz - back - 0.04), V3(0, H + 0.0006, (Dz - back + 0.02) / 2), "stone.limestone-sooted")
        // Wall-root stain where the wall meets the foot, and a damp rise.
        for fx: Float in [-1, 1] { FO5.patchSide(&m, V2(0.5, 0.35), V2(0.3, 0.17), x: fx * T / 2, "stone.limestone-sooted") }

        groundAO(&m, height: 0.4, floor: 0.6)
        return LODModel(FC.place(m))
    }
}
