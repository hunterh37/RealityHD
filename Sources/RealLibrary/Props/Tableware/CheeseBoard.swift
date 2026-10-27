import simd
import Foundation

/// Cheese board: everyday tableware, slate. 35 x 22 cm slate slab, 16 mm thick, with chamfered edges, a
/// knocked-off corner, four rubber feet, chalk labels as thin strips, hairline scratches from knives, a
/// cheddar wedge with a rind and cut face, a few crumbs and a cheese knife with a walnut handle.
public struct CheeseBoard: RealAsset {
    public static let id = "cheese-board"
    public static let summary = "Slate cheese board with chamfered edge, rubber feet, chalk marks and a wedge of cheese."
    public static let tags = ["prop", "interior", "tableware", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.62, studio: true)

    /// Slate.
    public var slate: MaterialKey = "stone.slate"
    /// Chalk.
    public var chalk: MaterialKey = "plastic.matte:E9E9E4"
    /// Cheese body.
    public var cheese: MaterialKey = "food.cheddar:E3B450"
    /// Rind.
    public var rind: MaterialKey = "food.bread-crust-toasted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let T: Float = 0.016, feet: Float = 0.004
        var outline: [V2] = [V2(-0.175, -0.11), V2(0.175, -0.11), V2(0.175, 0.083), V2(0.1665, 0.092), V2(0.159, 0.102), V2(0.151, 0.11), V2(-0.175, 0.11)]
        outline = Shape2D.rounded(outline, radius: 0.007)
        var slab = Prim.extrude(outline, depth: T, bevel: 0.0028, bevelSegments: 2, material: slate)
        slab.recomputeNormals()
        m.add(slab, Xform(translation: V3(0, feet + T / 2, 0), rotation: DD1ITableware.lay))
        // Rubber feet.
        for (x, z) in [(-0.15, -0.085), (0.15, -0.085), (-0.15, 0.085), (0.15, 0.085)] as [(Float, Float)] {
            m.add(Prim.cylinder(radius: 0.0085, height: feet + 0.0008, bevel: 0.0012, segments: 14, bevelSegments: 2, material: "rubber.silicone-gray"), Xform(translation: V3(x, 0, z)))
        }
        let top = feet + T
        // Chalk labels: three short words as strokes.
        let starts: [Float] = [-0.11, -0.015, 0.08]
        for wi in 0..<3 {
            var x = starts[wi]; let wz: Float = -0.075
            for _ in 0..<(4 + wi) {
                let h = rng.float(0.006...0.011), w = rng.float(0.0016...0.0045)
                let tilt = rng.float(-25...25)
                m.add(Prim.roundedBox(V3(w, 0.0004, h), radius: 0.00012, bevelSegments: 1, material: chalk),
                      Xform(translation: V3(x, top + 0.0002, wz), rotation: simd_quatf(degrees: tilt, axis: .up)))
                x += rng.float(0.0045...0.007)
            }
        }
        // Knife scratches: thin pale grooves.
        for _ in 0..<12 {
            let cx = rng.float(-0.1...0.1), cz = rng.float(-0.03...0.075), ang = rng.float(-40...40), ln = rng.float(0.02...0.06)
            m.add(Prim.roundedBox(V3(ln, 0.0003, 0.00035), radius: 0.0001, bevelSegments: 1, material: "stone.limestone"),
                  Xform(translation: V3(cx, top + 0.00015, cz), rotation: simd_quatf(degrees: ang, axis: .up)))
        }
        // Cheddar wedge: rounded triangle, rind band around the round edge.
        let wedge = Shape2D.rounded([V2(-0.04, -0.03), V2(0.052, -0.03), V2(0.052, 0.01), V2(0.0, 0.032)].map { $0 }, radius: 0.004)
        var w = Prim.extrude(wedge, depth: 0.02, bevel: 0.0022, bevelSegments: 2, material: cheese)
        w.recomputeNormals()
        let wx: Float = 0.085, wz: Float = 0.04
        // Wedge stands on the slate: outline z becomes world y after the turn, so lay it with the thickness up.
        m.add(w, Xform(translation: V3(wx, top + 0.01, wz), rotation: simd_quatf(degrees: -20, axis: .up) * DD1ITableware.lay))
        var rindBand = Prim.extrude(Shape2D.rounded([V2(0.052, -0.03), V2(0.0535, -0.03), V2(0.0535, 0.01), V2(0.052, 0.01)], radius: 0.0006), depth: 0.0205, bevel: 0.0005, bevelSegments: 1, material: rind)
        rindBand.recomputeNormals()
        m.add(rindBand, Xform(translation: V3(wx, top + 0.01, wz), rotation: simd_quatf(degrees: -20, axis: .up) * DD1ITableware.lay))
        // A cut slice leaning against the wedge and crumbs.
        var slice = Prim.extrude(Shape2D.rounded([V2(-0.02, -0.015), V2(0.025, -0.015), V2(0.025, 0.012), V2(-0.01, 0.014)], radius: 0.003), depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: cheese)
        slice.recomputeNormals()
        m.add(slice, Xform(translation: V3(-0.065, top + 0.0022, 0.055), rotation: simd_quatf(degrees: 25, axis: .up) * DD1ITableware.lay))
        for _ in 0..<8 {
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.004), 0.002, rng.float(0.002...0.004)), exponent: 3, subdivisions: 2, material: cheese),
                  Xform(translation: V3(rng.float(-0.03...0.12), top + 0.001, rng.float(0.0...0.085)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        // Cheese knife: stainless blade with a hole and a walnut handle.
        let kx: Float = -0.01, kz: Float = -0.035
        var blade = Prim.extrude(Shape2D.rounded([V2(-0.07, -0.011), V2(0.07, -0.011), V2(0.088, 0.0), V2(0.07, 0.011), V2(-0.07, 0.011)], radius: 0.002), depth: 0.0012, bevel: 0.0004, bevelSegments: 1, material: "metal.stainless")
        blade.recomputeNormals()
        let kr = simd_quatf(degrees: 8, axis: .up) * DD1ITableware.lay
        m.add(blade, Xform(translation: V3(kx + 0.0, top + 0.0008, kz), rotation: kr))
        m.add(Prim.roundedBox(V3(0.052, 0.012, 0.016), radius: 0.003, bevelSegments: 2, material: "wood.walnut-oiled"),
              Xform(translation: V3(kx - 0.1, top + 0.0065, kz + 0.0145), rotation: simd_quatf(degrees: 8, axis: .up)))
        for dx in [-0.012, 0.012] as [Float] {
            m.add(Prim.cylinder(radius: 0.0022, height: 0.0132, bevel: 0.0004, segments: 8, bevelSegments: 1, material: "metal.brass"),
                  Xform(translation: V3(kx - 0.1 + dx, top + 0.0005, kz + 0.0145)))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
