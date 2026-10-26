import simd
import Foundation

/// Concrete planter barrier: architectural facade customizer, Contemporary. Precast box on forklift feet with
/// a chamfered rim, lifting loops, drain weeps and a low planting of shrubs and grasses.
public struct PlanterBarrierConcrete: RealAsset {
    public static let id = "planter-barrier-concrete"
    public static let summary = "Concrete planter barrier 1.5 m: precast box with chamfered rim, forklift pockets and lifting loops, planted with low shrubs and grasses."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, distance: 3.2)

    /// Precast concrete.
    public var concrete: MaterialKey = "concrete.smooth"
    /// Weathered concrete at the base.
    public var weathered: MaterialKey = "concrete.rough"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 1.5, D: Float = 0.6, wall: Float = 0.1, feetH: Float = 0.12, slabH: Float = 0.1, rimTop: Float = 0.62
        // Three foot blocks leave two forklift pockets through the base.
        for x in [-0.6, 0.0, 0.6] as [Float] {
            FA.box(&m, V3(0.3, feetH, D), V3(x, feetH / 2, 0), weathered, r: 0.008)
        }
        FA.box(&m, V3(L, slabH, D), V3(0, feetH + slabH / 2, 0), concrete, r: 0.01)
        let wy0 = feetH + slabH, wh = rimTop - wy0
        // Walls with a board-formed horizontal joint line, set 2 mm proud of the slab.
        for sz: Float in [-1, 1] {
            FA.box(&m, V3(L - 0.004, wh, wall), V3(0, wy0 + wh / 2, sz * (D / 2 - wall / 2)), weathered, r: 0.008)
            FA.box(&m, V3(L - 0.01, 0.003, wall + 0.002), V3(0, wy0 + wh * 0.5, sz * (D / 2 - wall / 2)), "concrete.sealed-dark", r: 0.001)
        }
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(wall, wh, D - 2 * wall + 0.006), V3(sx * (L / 2 - wall / 2), wy0 + wh / 2, 0), weathered, r: 0.008)
        }
        // Chamfered rim: a 45 degree arris cap around the top edge.
        let rim: [V2] = [V2(0, 0), V2(wall + 0.006, 0), V2(wall + 0.006, 0.012), V2(wall - 0.006, 0.03), V2(0.006, 0.03), V2(0, 0.012)]
        for sz: Float in [-1, 1] {
            FA.run(&m, rim.map { V2($0.x - (wall + 0.006) / 2, $0.y) }, length: L, at: V3(0, rimTop - 0.002, sz * (D / 2 - wall / 2)), concrete, bevel: 0.002)
        }
        for sx: Float in [-1, 1] {
            m.add(Prim.extrude(rim.map { V2($0.x - (wall + 0.006) / 2, $0.y) }, depth: D - 2 * wall + 0.012, bevel: 0.002, bevelSegments: 1, material: concrete),
                  Xform(translation: V3(sx * (L / 2 - wall / 2), rimTop - 0.002, 0), rotation: FA.q(0, FA.Y)))
        }
        // Planting soil, dark mulched, set 5 cm below the rim.
        let soilTop = rimTop - 0.07
        FA.box(&m, V3(L - 2 * wall - 0.01, soilTop - wy0, D - 2 * wall - 0.01), V3(0, wy0 + (soilTop - wy0) / 2, 0), "soil.potting", r: 0.01)
        // Shrub clumps (boxwood, lavender) built from overlapping irregular lobes, with grass tufts between.
        for (x, s) in [(-0.46, Float(0.3)), (0.0, 0.36), (0.46, 0.3)] as [(Float, Float)] {
            let mat: MaterialKey = x > 0.2 ? "leaf.lavender-mass" : "leaf.boxwood-mass"
            for _ in 0..<7 {
                let lr = s * rng.float(0.42...0.62)
                let off = V3(rng.float(-s * 0.3...s * 0.3), 0, rng.float(-0.07...0.07))
                m.add(Prim.superellipsoid(V3(lr, lr * rng.float(0.7...0.95), lr * rng.float(0.8...1.1)), exponent: rng.float(2.0...2.6), subdivisions: 3, material: mat),
                      Xform(translation: V3(x, soilTop + lr * 0.34 + rng.float(0...0.03), 0) + off, rotation: FA.q(rng.float(0...180), FA.Y)))
            }
        }
        for _ in 0..<46 {
            let x = rng.float(-0.62...0.62), z = rng.float(-0.14...0.14)
            let h = rng.float(0.12...0.24), lean = rng.float(-0.07...0.07)
            FA.path(&m, [V3(x, soilTop, z), V3(x + lean * 0.3, soilTop + h * 0.6, z), V3(x + lean, soilTop + h, z + lean * 0.4)], r: 0.0035, "grass.plume", sides: 4)
        }
        // Lifting loops: recessed pockets with stainless steel lugs on the rim ends.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.05, 0.004, 0.07), V3(sx * (L / 2 - wall / 2), rimTop + 0.027, 0), "concrete.sealed-dark", r: 0.001)
            m.add(Prim.torus(major: 0.022, minor: 0.0065, segments: 20, sides: 8, arc: 180, material: "metal.steel"),
                  Xform(translation: V3(sx * (L / 2 - wall / 2), rimTop + 0.029, 0), rotation: FA.q(90, FA.Z) * FA.q(0, FA.X)))
        }
        // Drain weeps at the base of the long walls and a forklift pocket guide rail in dark steel.
        for sz: Float in [-1, 1] { for x in [-0.55, 0.0, 0.55] as [Float] {
            m.add(Prim.cylinder(radius: 0.018, height: 0.008, bevel: 0.002, segments: 12, bevelSegments: 1, material: "concrete.sealed-void"),
                  Xform(translation: V3(x, wy0 + 0.04, sz * (D / 2 - 0.004)), rotation: FA.q(90 * sz, FA.X)))
        }}
        // Precast form-tie cones in a regular grid and extra shadow-line joints on both long faces.
        for sz: Float in [-1, 1] {
            for x in [-0.55, -0.18, 0.18, 0.55] as [Float] { for y in [wy0 + 0.13, wy0 + 0.33] as [Float] {
                m.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.0015, segments: 10, bevelSegments: 1, material: "concrete.sealed-void"),
                      Xform(translation: V3(x, y, sz * (D / 2 - 0.0035)), rotation: FA.q(90 * sz, FA.X)))
            }}
            for y in [wy0 + 0.17, wy0 + 0.38] as [Float] {
                FA.box(&m, V3(L - 0.01, 0.003, 0.003), V3(0, y, sz * (D / 2 - 0.0008)), "concrete.sealed-dark", r: 0.0008)
            }
            // Vertical rust and damp streaks under the form ties.
            for x in [-0.55, 0.18] as [Float] {
                FA.box(&m, V3(0.012, 0.18, 0.0012), V3(x, wy0 + 0.22, sz * (D / 2 + 0.0004)), "concrete.river-algae", r: 0.0004)
            }
        }
        // Tyre scuffs and efflorescence on the lower wall, chipped corners.
        for k in 0..<3 {
            FE.stain(&m, V3(rng.float(-0.55...0.55), wy0 + 0.05, -D / 2 - 0.0005), w: rng.float(0.12...0.22), d: 0.0016, "concrete.sealed-dark")
            _ = k
        }
        for (x, z) in [(L / 2 - 0.015, D / 2 - 0.015), (-L / 2 + 0.015, -D / 2 + 0.015)] as [(Float, Float)] {
            FA.box(&m, V3(0.03, 0.03, 0.03), V3(x, feetH + slabH - 0.012, z), "concrete.rough", r: 0.004, rot: FA.q(rng.float(10...60), FA.Y))
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.08, floor: 0.55)
        return LODModel(m)
    }
}
