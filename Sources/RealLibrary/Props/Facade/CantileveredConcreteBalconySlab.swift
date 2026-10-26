import simd
import Foundation

/// Brutalist cantilevered concrete balcony slab, 2.4 m wide and 1.2 m proud of the wall: a sloped
/// board-formed slab with a drip groove under the nose, upstand kerbs on three sides, cone-tie holes with
/// rust bleed, a black thermal break strip against the wall, stainless flashing with bolts and a
/// stainless drain scupper. Algae and soot staining. Wall plane at z = 0.
public struct CantileveredConcreteBalconySlab: RealAsset {
    public static let id = "cantilevered-concrete-balcony-slab"
    public static let summary = "Brutalist cantilevered balcony slab, 2.4 m wide, 1.2 m projection: board-formed concrete with drip groove, upstand kerb, tie holes, thermal break strip, stainless flashing and a drain scupper."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 14, distance: 1.1)

    /// Board-formed concrete.
    public var concrete: MaterialKey = "concrete.rough"
    /// Trowelled top surface.
    public var screed: MaterialKey = "concrete.smooth"
    /// Stainless steel fittings.
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 2.4, D: Float = 1.2, tb: Float = 0.05
        let hw = W / 2
        // Slab core: profile (z out, y up) with the drip groove under the nose; falls 1.2% to the front.
        let profile: [V2] = [V2(tb, 0), V2(1.16, 0), V2(1.16, 0.03), V2(1.185, 0.03), V2(1.185, 0), V2(D, 0), V2(D, 0.118), V2(tb, 0.1345)]
        FA.run(&m, profile, length: W, at: .zero, concrete, bevel: 0.002)
        // Trowelled top skin laid on the fall.
        let fall = atan2(0.0165, D - tb) * 180 / .pi
        FA.box(&m, V3(W - 0.02, 0.004, D - tb - 0.02), V3(0, 0.1268, (D + tb) / 2), screed, r: 0.001, rot: FA.q(fall, FA.X))
        // Board-formed marks: three boards a face, each with its own in/out lay.
        let bh: Float = 0.0385
        for b in 0..<3 {
            let y = 0.002 + Float(b) * (bh + 0.002) + bh / 2
            let j = { rng.float(-0.0015...0.0015) }
            FA.box(&m, V3(W, bh, 0.012), V3(0, y, D - 0.006 + j()), concrete, r: 0.0018)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.012, bh, D - tb - 0.01), V3(s * (hw - 0.006) + j() * s, y, (D + tb) / 2), concrete, r: 0.0018)
            }
        }
        for gy in [0.0415, 0.0825] as [Float] {
            FA.box(&m, V3(W, 0.0022, 0.002), V3(0, gy, D + 0.0008), "concrete.sealed-void", r: 0.0004)
            for s: Float in [-1, 1] { FA.box(&m, V3(0.002, 0.0022, D - tb - 0.01), V3(s * (hw + 0.0008), gy, (D + tb) / 2), "concrete.sealed-void", r: 0.0004) }
        }
        // Upstand kerbs: front and both sides.
        FA.box(&m, V3(2.2, 0.088, 0.1), V3(0, 0.157, D - 0.05), concrete, r: 0.004)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.1, 0.088, D - tb - 0.01), V3(s * (hw - 0.05), 0.157 - s * 0.0, (D + tb) / 2), concrete, r: 0.004)
        }
        // Galvanised coping over the kerbs, fixed with bolts.
        FA.box(&m, V3(2.24, 0.003, 0.112), V3(0, 0.2015, D - 0.05), "metal.galvanized", r: 0.0012)
        for sd: Float in [-1, 1] {
            FA.box(&m, V3(0.112, 0.003, D - tb - 0.01), V3(sd * (hw - 0.05), 0.2015, (D + tb) / 2), "metal.galvanized", r: 0.0012)
        }
        for i in 0..<5 { hexBolt(&m, at: V3(-0.9 + Float(i) * 0.45, 0.2035, D - 0.05), normal: FA.Y, size: 0.011, material: steel) }
        // Thermal break strip and stainless flashing with countersunk bolts.
        FA.box(&m, V3(W, 0.1345, tb), V3(0, 0.067, tb / 2), "plastic.black", r: 0.002)
        FA.box(&m, V3(W - 0.04, 0.004, 0.16), V3(0, 0.1375, tb + 0.08), steel, r: 0.0012)
        for i in 0..<6 {
            let x = -1.0 + Float(i) * 0.4
            hexBolt(&m, at: V3(x, 0.1415, 0.09), normal: FA.Y, size: 0.012, material: steel)
        }
        // Cone-tie holes with rust bleed on the nose and flanks.
        for i in 0..<6 {
            let x = -1.0 + Float(i) * 0.4
            FA.cylZ(&m, r: 0.0135, h: 0.004, at: V3(x, 0.06, D), "concrete.sealed-void", bevel: 0.001, segments: 12)
            m.add(Prim.torus(major: 0.0175, minor: 0.0025, segments: 14, sides: 5, material: "concrete.sealed-dim"), Xform(translation: V3(x, 0.06, D + 0.0015), rotation: FA.q(90, FA.X)))
            FA.box(&m, V3(0.012, rng.float(0.03...0.06), 0.0015), V3(x, 0.025, D + 0.002), "metal.rust", r: 0.0005)
        }
        for s: Float in [-1, 1] {
            for z in [0.45, 0.85] as [Float] {
                FA.cylX(&m, r: 0.0135, h: 0.004, at: V3(s > 0 ? hw : -hw - 0.004, 0.06, z), "concrete.sealed-void", bevel: 0.001, segments: 12)
                FA.box(&m, V3(0.0015, rng.float(0.03...0.06), 0.012), V3(s * (hw + 0.002), 0.025, z), "metal.rust", r: 0.0005)
            }
        }
        // Drain scupper through the front kerb with a dark mouth, and the run-off stain below it.
        FA.box(&m, V3(0.13, 0.062, 0.11), V3(0.55, 0.15, D - 0.01), steel, r: 0.003)
        FA.box(&m, V3(0.1, 0.038, 0.01), V3(0.55, 0.15, D + 0.045), "concrete.sealed-void", r: 0.003)
        FA.box(&m, V3(0.06, 0.1, 0.002), V3(0.55, 0.06, D + 0.002 - 0.0), "concrete.sealed-dim", r: 0.0008)
        // Algae and soot: wet patch behind the scupper, dark underside bands.
        for (cx, cz, w, d) in [(0.55, D - 0.2, 0.22, 0.12), (0.5, D - 0.32, 0.4, 0.14), (0.62, D - 0.45, 0.16, 0.1), (0.45, D - 0.55, 0.08, 0.06), (-0.9, 0.35, 0.16, 0.1), (-1.0, 0.5, 0.07, 0.07), (0.1, D - 0.16, 0.1, 0.05)] as [(Float, Float, Float, Float)] {
            m.add(Prim.superellipsoid(V3(w, 0.006, d), exponent: 2.4, subdivisions: 3, material: "concrete.river-algae"),
                  Xform(translation: V3(cx, 0.1262 + (D - cz) * 0.0137, cz), rotation: FA.q(fall, FA.X)))
        }
        for x in [-0.8, 0.3, 0.9] as [Float] {
            FA.box(&m, V3(0.5, 0.002, 0.6), V3(x, -0.0005, 0.7), "concrete.sealed-dim", r: 0.0006)
        }
        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
