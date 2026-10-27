import simd
import Foundation

/// Cheese block: 12 cm long, 5 cm tall, 8 cm deep cheddar block sealed in red wax, with a cut end showing the yellow paste and knife drag
/// marks, a chipped wax corner, a moulding seam, wax drips pooled at the base and a thumbprint dent.
public struct CheeseBlock: RealAsset {
    public static let id = "cheese-block"
    public static let summary = "Wax-rind cheddar block, 12 cm: red wax coat, cut end with knife marks, chipped corner, wax drips, dent."
    public static let tags = ["prop", "interior", "pantry", "food", "container"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -35, elevation: 24, distance: 0.95, studio: true)

    /// Overall size in meters (x length, y height, z depth).
    public var size = V3(0.12, 0.05, 0.08)
    /// Wax coat, worn wax and cheese paste colour keys.
    public var wax: MaterialKey = "plastic.gloss:A9171B"
    public var waxWorn: MaterialKey = "plastic.matte:8E1B1E"
    public var cheese: MaterialKey = "food.cream:F5BE45"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cut: Float = 0.014  // length of the cut end
        let bodyL = size.x - cut
        // Wax-coated body: rounded block with slightly bulged faces from the wax dip.
        var body = Prim.roundedBox(V3(bodyL, size.y, size.z), radius: 0.0045, bevelSegments: 3, material: wax).subdivided()
        let k = rng.float(0...6)
        body.displace { p, n in 0.00035 * sin(p.x * 160 + p.z * 90 + k) * sin(p.y * 120 + k) }
        m.add(body, Xform(translation: V3(-cut / 2, size.y / 2, 0)))
        // Wax lip around the cut end.
        let xCut = size.x / 2 - cut
        m.add(Prim.roundedBox(V3(0.0030, size.y - 0.001, size.z - 0.001), radius: 0.0014, bevelSegments: 2, material: waxWorn),
              Xform(translation: V3(xCut + 0.0010, size.y / 2, 0)))
        // Cheese paste at the cut end, inset behind the wax lip, with knife drag marks.
        m.add(Prim.roundedBox(V3(cut, size.y - 0.0070, size.z - 0.0070), radius: 0.0008, bevelSegments: 2, material: cheese),
              Xform(translation: V3(size.x / 2 - cut / 2 - 0.0008, size.y / 2, 0)))
        for i in 0..<9 {
            let z = -0.032 + Float(i) * 0.008 + rng.float(-0.0012...0.0012)
            m.add(Prim.roundedBox(V3(0.0004, size.y - 0.012 - rng.float(0...0.008), 0.0007), radius: 0.0002, bevelSegments: 1, material: "food.cream:D69828"),
                  Xform(translation: V3(size.x / 2 - 0.0007, size.y / 2, z)))
        }
        // Cut face crumble: small flakes under the end.
        for _ in 0..<7 {
            let s = rng.float(0.0016...0.0032)
            m.add(Prim.superellipsoid(V3(s, s * 0.7, s), exponent: 3, subdivisions: 1, material: cheese),
                  Xform(translation: V3(size.x / 2 - rng.float(0.001...0.012), s * 0.35, rng.float(-0.03...0.03)), rotation: simd_quatf(degrees: rng.float(0...90), axis: .up)))
        }
        // Mould seam: a ridge where the wax dip met, around the middle of the block.
        m.add(Prim.roundedBox(V3(bodyL + 0.0003, 0.0005, size.z + 0.0003), radius: 0.0002, bevelSegments: 1, material: waxWorn),
              Xform(translation: V3(-cut / 2, size.y * 0.5, 0)))
        // Paper label sticker on top with printed lines.
        m.add(Prim.roundedBox(V3(0.044, 0.0006, 0.026), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:EFE6CE"),
              Xform(translation: V3(-0.020, size.y + 0.0004, 0.010), rotation: simd_quatf(degrees: 4, axis: .up)))
        m.add(Prim.roundedBox(V3(0.044, 0.0007, 0.007), radius: 0.0001, bevelSegments: 1, material: "plastic.white:1F3F8A"),
              Xform(translation: V3(-0.020, size.y + 0.0007, 0.0185), rotation: simd_quatf(degrees: 4, axis: .up)))
        for r in 0..<3 {
            m.add(Prim.roundedBox(V3(0.030 - Float(r) * 0.006, 0.0007, 0.0013), radius: 0.0001, bevelSegments: 1, material: "plastic.white:2A2420"),
                  Xform(translation: V3(-0.026 - Float(r) * 0.003, size.y + 0.0007, 0.008 - Float(r) * 0.0035), rotation: simd_quatf(degrees: 4, axis: .up)))
        }
        // Story detail: chipped wax corner exposing cheese.
        m.add(Prim.superellipsoid(V3(0.016, 0.0035, 0.012), exponent: 2.6, subdivisions: 2, material: cheese),
              Xform(translation: V3(-bodyL / 2 - cut / 2 + 0.006, size.y - 0.0012, size.z / 2 - 0.006), rotation: simd_quatf(degrees: 35, axis: .up)))
        for i in 0..<5 {
            let a = Float(i) * 1.2
            m.add(Prim.superellipsoid(V3(0.0035, 0.0006, 0.0025), exponent: 2.4, subdivisions: 1, material: waxWorn),
                  Xform(translation: V3(-bodyL / 2 - cut / 2 + 0.006 + cos(a) * 0.006, size.y + 0.0001, size.z / 2 - 0.004 - sin(a) * 0.005), rotation: simd_quatf(angle: a, axis: .up)))
        }
        // Thumbprint dent: darker worn wax pad on the top.
        m.add(Prim.superellipsoid(V3(0.020, 0.0012, 0.016), exponent: 2, subdivisions: 2, material: waxWorn), Xform(translation: V3(0.010 - cut / 2, size.y - 0.0004, -0.012)))
        // Handling wear: dull abraded patches on the top edges and corners, and crumb pits on the cut face.
        for _ in 0..<18 {
            let side: Float = rng.chance(0.5) ? 1 : -1
            let x = rng.float((-bodyL / 2 - cut / 2 + 0.006)...(bodyL / 2 - cut / 2 - 0.006))
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.016), 0.0004, rng.float(0.003...0.008)), exponent: 2.2, subdivisions: 1, material: waxWorn),
                  Xform(translation: V3(x, size.y + 0.0002, side * (size.z / 2 - 0.0045)), rotation: simd_quatf(degrees: rng.float(-10...10), axis: .up)))
        }
        for _ in 0..<14 {
            let s = rng.float(0.0010...0.0022)
            m.add(Prim.superellipsoid(V3(0.0006, s, s * 1.3), exponent: 2, subdivisions: 1, material: "food.cream:A87218"),
                  Xform(translation: V3(size.x / 2 - 0.0004, rng.float(0.010...0.040), rng.float(-0.030...0.030))))
        }
        // Wax drips pooled along the bottom edge.
        for i in 0..<7 {
            let x = -bodyL / 2 - cut / 2 + 0.006 + Float(i) * 0.0125 + rng.float(-0.002...0.002)
            let s = rng.float(0.004...0.008)
            m.add(Prim.superellipsoid(V3(s, 0.0035, 0.004), exponent: 2, subdivisions: 1, material: wax),
                  Xform(translation: V3(x, 0.0012, size.z / 2 + 0.0004 - rng.float(0...0.003))))
        }
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
