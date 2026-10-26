import simd
import Foundation

/// Craftsman pergola rafter, 100 mm wide, 200 mm deep, 1.2 m long: a cedar rafter cut with a seat notch (birdsmouth) where it
/// lands on the beam, a 5 degree sawn top bevel, an ogee-cut tail with a chamfered top corner, a drip kerf across the
/// underside, a carriage bolt (domed head, square neck, recessed washer and nut) through the notch and two galvanized
/// structural screws near the wall end. Eased arrises throughout. Wear: silvered top and sun face, checks along the grain,
/// a split in the end grain, rust and water stain under the fasteners, mildew speckle at the notch, one dark knot.
public struct TimberPergolaRafterEnd: RealAsset {
    public static let id = "timber-pergola-rafter-end"
    public static let summary = "Craftsman pergola rafter tail 0.1x0.2x1.2 m: shaped end, bolted, weathered."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 242, elevation: 12, distance: 2.6)

    /// Body timber.
    public var timber: MaterialKey = "wood.cedar"
    /// Silvered surfaces.
    public var silver: MaterialKey = "wood.weathered"
    /// Fasteners.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let T: Float = 0.1, H: Float = 0.2, L: Float = 1.2
        let nz0: Float = 0.52, nz1: Float = 0.66, nd: Float = 0.055                      // seat notch
        let tz0: Float = 0.93                                                            // ogee starts
        func smooth(_ t: Float) -> Float { t * t * (3 - 2 * t) }

        // Side profile (z, y): top, chamfered corner, end, ogee underside up the tail, notch, wall end.
        var prof: [V2] = [V2(0, 0), V2(nz0, 0), V2(nz0, nd), V2(nz1, nd), V2(nz1, 0)]
        let steps = 12
        // Underside ogee: stays at y = 0 until tz0, then sweeps up an S-curve to the end.
        for k in 0...steps {
            let t = Float(k) / Float(steps)
            prof.append(V2(tz0 + (L - tz0) * t, 0.092 * smooth(t) - 0.012 * sin(t * .pi) * 0))
        }
        prof += [V2(L, H - 0.03), V2(L - 0.03, H), V2(0, H)]
        FO5.colX(&m, prof, x0: -T / 2, x1: T / 2, timber, bevel: 0.003)
        // Top bevel: a slight sawn wash along the top, as a thin cap tilted 5 degrees.
        FO5.colX(&m, [V2(0.02, H - 0.0016), V2(L - 0.04, H - 0.0016), V2(L - 0.04, H + 0.0008), V2(0.02, H + 0.0008)], x0: -T / 2 + 0.003, x1: T / 2 - 0.003, silver, bevel: 0.0005)

        // End grain of the tail (vertical cut) and the nose chamfer, as slabs on the cut faces.
        FJ.slab(&m, V3(T - 0.002, H - 0.03 - 0.092, 0.0016), V3(0, 0.092 + (H - 0.03 - 0.092) / 2, L + 0.0004), "wood.endgrain-weathered")
        FJ.slab(&m, V3(T - 0.002, 0.0016, 0.004), V3(0, 0.0005, 0.5), "wood.deadwood")                          // sawn underside line at notch seat start
        // Notch seat: dark crush line and the beam bearing mark.
        FJ.slab(&m, V3(T - 0.004, 0.0012, nz1 - nz0 - 0.006), V3(0, nd + 0.0004, (nz0 + nz1) / 2), "wood.deadwood")
        // Drip kerf across the underside near the tail: a 4 mm saw cut.
        FJ.slab(&m, V3(T - 0.004, 0.0014, 0.004), V3(0, 0.0004, 0.86), "wood.charred")

        // Carriage bolt through the notch: domed head on the +X face, square neck, washer; nut recessed on the -X face.
        let by: Float = 0.1, bz: Float = (nz0 + nz1) / 2
        m.add(Prim.cylinder(radius: 0.0055, height: T, bevel: 0.0008, segments: 8, bevelSegments: 1, material: zinc),
              Xform(translation: V3(T / 2 - 0.0015, by, bz), rotation: FA.q(90, FA.Z)))
        FA.cylX(&m, r: 0.019, h: 0.0012, at: V3(T / 2 - 0.0002, by, bz), zinc, bevel: 0.0004, segments: 14)            // washer
        m.add(Prim.superellipsoid(V3(0.0046, 0.026, 0.026), exponent: 2, subdivisions: 4, material: zinc),
              Xform(translation: V3(T / 2 + 0.0002, by, bz)))                                                         // domed head
        // Square neck shoulders under the head.
        FA.box(&m, V3(0.004, 0.014, 0.014), V3(T / 2 - 0.0014, by, bz), zinc, r: 0.0008)
        // Counterbored pocket, washer and hex nut flush on the -X face.
        m.add(Prim.cylinder(radius: 0.022, height: 0.0008, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "wood.charred"),
              Xform(translation: V3(-T / 2 + 0.0002, by, bz), rotation: FA.q(-90, FA.Z)))
        m.add(Prim.cylinder(radius: 0.0165, height: 0.0014, bevel: 0.0003, segments: 12, bevelSegments: 1, material: zinc),
              Xform(translation: V3(-T / 2 + 0.0008, by, bz), rotation: FA.q(-90, FA.Z)))
        m.add(Prim.cylinder(radius: 0.0125, height: 0.005, bevel: 0.0008, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"),
              Xform(translation: V3(-T / 2 + 0.0022, by, bz), rotation: FA.q(-90, FA.Z)))
        // Rust and water stain under the bolt head.
        FO5.patchSide(&m, V2(0.022, 0.06), V2(bz, by - 0.045), x: T / 2, "metal.rust")
        FO5.patchSide(&m, V2(0.05, 0.05), V2(bz, by - 0.02), x: T / 2 - 0.001, "wood.deadwood")

        // Two structural screws near the wall end, low-profile washer heads on the top.
        for (z, x) in [(0.14, -0.018), (0.26, 0.016)] as [(Float, Float)] {
            m.add(Prim.cylinder(radius: 0.0085, height: 0.0024, bevel: 0.0007, segments: 10, bevelSegments: 1, material: zinc), Xform(translation: V3(x, H + 0.0006, z)))
            FJ.slab(&m, V3(0.008, 0.0006, 0.0012), V3(x, H + 0.0033, z), "metal.tool-ground", rot: FA.q(rng.float(0...90), FA.Y))
            FJ.slab(&m, V3(0.012, 0.0008, 0.07), V3(x, H + 0.0013, z - 0.04), "metal.rust")
        }

        // Wear: silvered top and sun face, checks, end-grain split, mildew, a knot.
        for _ in 0..<6 {
            let x = rng.float(-0.04...0.04), len = rng.float(0.1...0.35), z0 = rng.float(len / 2 + 0.02...L - len / 2 - 0.05)
            FJ.slab(&m, V3(rng.float(0.006...0.02), 0.0012, len), V3(x, H + 0.0012, z0), silver)
        }
        for fx: Float in [-1, 1] {
            // Dark water staining running down from the top edge and from the notch seat: soft blobs, not hard slabs.
            for _ in 0..<5 {
                let z0 = rng.float(0.1...1.1), len = rng.float(0.05...0.14)
                m.add(Prim.superellipsoid(V3(0.0014, len, rng.float(0.012...0.03)), exponent: 2, subdivisions: 3, material: "wood.deadwood"),
                      Xform(translation: V3(fx * (T / 2 + 0.0002), H - 0.03 - len / 2, z0)))
            }
            m.add(Prim.superellipsoid(V3(0.0014, 0.05, 0.16), exponent: 2, subdivisions: 3, material: "wood.deadwood"),
                  Xform(translation: V3(fx * (T / 2 + 0.0002), nd + 0.04, (nz0 + nz1) / 2)))
            // Grime band along the lower arris and a damp stain at the wall end.
            for z0 in [0.27, 0.78] as [Float] {
                let len = rng.float(0.2...0.3)
                m.add(Prim.superellipsoid(V3(0.0012, 0.016, len), exponent: 2, subdivisions: 3, material: "wood.deadwood"),
                      Xform(translation: V3(fx * (T / 2 + 0.0001), 0.014, z0)))
            }
            m.add(Prim.superellipsoid(V3(0.0014, 0.15, 0.08), exponent: 2, subdivisions: 3, material: "wood.deadwood"), Xform(translation: V3(fx * (T / 2 + 0.0002), 0.1, 0.06)))
            // Knot with a dark core and swirl ring.
            let kz: Float = fx > 0 ? 0.9 : 0.35
            m.add(Prim.superellipsoid(V3(0.0016, 0.034, 0.05), exponent: 2, subdivisions: 3, material: "wood.walnut"), Xform(translation: V3(fx * (T / 2 + 0.0002), 0.13, kz)))
            m.add(Prim.superellipsoid(V3(0.0018, 0.018, 0.028), exponent: 2, subdivisions: 3, material: "wood.charred"), Xform(translation: V3(fx * (T / 2 + 0.0004), 0.13, kz)))
        }
        for _ in 0..<6 {                                                                                     // checks
            let fx: Float = rng.chance(0.5) ? 1 : -1
            let len = rng.float(0.08...0.3)
            FO5.patchSide(&m, V2(len, 0.0016), V2(rng.float(len / 2 + 0.05...L - len / 2 - 0.05), rng.float(0.1...0.18)), x: fx * T / 2, "wood.charred")
        }
        FJ.slab(&m, V3(0.0016, 0.07, 0.0012), V3(0.008, 0.14, L + 0.0012), "wood.charred")                    // split in end grain
        FJ.slab(&m, V3(0.0012, 0.0016, 0.12), V3(0.01, 0.15, L - 0.06), "wood.charred", rot: FA.q(0, FA.Y))
        for _ in 0..<7 {
            m.add(Prim.superellipsoid(V3(0.0012, rng.float(0.004...0.01), rng.float(0.004...0.01)), exponent: 2, subdivisions: 1, material: "plastic.black"),
                  Xform(translation: V3(-T / 2 - 0.0002, rng.float(0.02...0.1), rng.float(nz0 - 0.1...nz1 + 0.1))))                         // mildew speckle
        }

        // Bird droppings and green algae on the top face.
        for _ in 0..<4 {
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.03), 0.0016, rng.float(0.02...0.05)), exponent: 2, subdivisions: 2, material: "stone.limestone"),
                  Xform(translation: V3(rng.float(-0.03...0.03), H + 0.0016, rng.float(0.2...1.0)), rotation: FA.q(rng.float(0...90), FA.Y)))
        }
        for _ in 0..<3 {
            m.add(Prim.superellipsoid(V3(0.05, 0.002, rng.float(0.08...0.18)), exponent: 2, subdivisions: 2, material: "stone.granite-moss"),
                  Xform(translation: V3(rng.float(-0.02...0.02), H + 0.0016, rng.float(0.1...1.0))))
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
