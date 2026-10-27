import simd
import Foundation

/// Frozen pizza box: 32 cm square, 3 cm deep printed cardboard carton with a glued lap seam, tuck flaps, a tear strip with perforations,
/// a printed top panel showing a pepperoni pizza, a crushed corner, frost patches and a scuffed edge.
public struct FrozenPizzaBox: RealAsset {
    public static let id = "frozen-pizza-box"
    public static let summary = "Printed cardboard frozen pizza box, 32 cm: pepperoni print, tear strip, glued seam, crushed corner, frost."
    public static let tags = ["prop", "interior", "pantry", "paper", "container", "food"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -32, elevation: 40, distance: 1.3, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.32, 0.03, 0.32)
    /// Carton board, edge board, print and frost colour keys.
    public var board: MaterialKey = "paper.sheet:E9E1CF"
    public var edge: MaterialKey = "paper.screwbox-kraft"
    public var red: MaterialKey = "plastic.white:B71C1C"
    public var frost: MaterialKey = "plastic.white:DCE6EC"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y - 0.0035, d = size.z
        // Carton shell, slight bow in the top and bottom panels.
        var box = Prim.roundedBox(V3(w, h, d), radius: 0.0018, bevelSegments: 2, material: board).subdivided()
        let k = rng.float(0...6)
        box.displace { p, n in
            let bow = n.y > 0.5 ? 0.0006 * (1 - (p.x * p.x + p.z * p.z) / 0.05) : 0
            return bow + 0.00015 * sin(p.x * 180 + k) * sin(p.z * 140)
        }
        m.add(box, Xform(translation: V3(0, h / 2, 0)))
        // Crushed corner: the +x +z top corner pressed down.
        m.add(Prim.roundedBox(V3(0.026, 0.0045, 0.026), radius: 0.0012, bevelSegments: 1, material: "paper.screwbox-kraft"),
              Xform(translation: V3(w / 2 - 0.012, h + 0.0003, d / 2 - 0.012), rotation: simd_quatf(degrees: 8, axis: V3(1, 0, 1)) * simd_quatf(degrees: 45, axis: .up)))
        // Top printed panel: red field with border, inset 0.3 mm proud.
        m.add(Prim.roundedBox(V3(w - 0.020, 0.0006, d - 0.020), radius: 0.0003, bevelSegments: 1, material: red), Xform(translation: V3(0, h + 0.0007, 0)))
        m.add(Prim.roundedBox(V3(w - 0.034, 0.0008, d - 0.034), radius: 0.0003, bevelSegments: 1, material: "plastic.white:F3E9CF"), Xform(translation: V3(0, h + 0.0010, 0)))
        // Pizza print: crust ring, sauce, cheese, pepperoni discs.
        let pr: Float = 0.118
        m.add(Prim.cylinder(radius: pr, height: 0.0008, bevel: 0.0003, segments: 56, bevelSegments: 1, material: "plastic.white:D9A55B"), Xform(translation: V3(0, h + 0.0013, -0.012)))
        m.add(Prim.cylinder(radius: pr - 0.012, height: 0.0008, bevel: 0.0003, segments: 56, bevelSegments: 1, material: "plastic.white:E7C34C"), Xform(translation: V3(0, h + 0.0019, -0.012)))
        for i in 0..<14 {
            let a = rng.float(0...(2 * .pi)), rr = rng.float(0.010...0.092), s = rng.float(0.0105...0.0135)
            m.add(Prim.cylinder(radius: s, height: 0.0006, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "plastic.white:A82A20"),
                  Xform(translation: V3(cos(a) * rr, h + 0.0027, -0.012 + sin(a) * rr)))
            if i % 3 == 0 {
                m.add(Prim.cylinder(radius: s * 0.35, height: 0.0004, bevel: 0.0001, segments: 10, bevelSegments: 1, material: "plastic.white:6E1A14"),
                      Xform(translation: V3(cos(a) * rr, h + 0.0032, -0.012 + sin(a) * rr)))
            }
        }
        // Brand banner at the front of the panel and a small starburst.
        m.add(Prim.roundedBox(V3(0.200, 0.0008, 0.030), radius: 0.0003, bevelSegments: 1, material: "plastic.white:F6F1E2"), Xform(translation: V3(0, h + 0.0013, 0.1385)))
        m.add(Prim.roundedBox(V3(0.150, 0.0006, 0.012), radius: 0.0002, bevelSegments: 1, material: "plastic.white:B71C1C"), Xform(translation: V3(0, h + 0.0019, 0.1385)))
        // Glued lap seam along the back edge, tear strip along the front: perforation dots.
        m.add(Prim.roundedBox(V3(w - 0.006, h - 0.002, 0.0008), radius: 0.0003, bevelSegments: 1, material: edge), Xform(translation: V3(0, h / 2, -d / 2 - 0.0002)))
        m.add(Prim.roundedBox(V3(0.022, 0.0016, d - 0.014), radius: 0.0004, bevelSegments: 1, material: edge), Xform(translation: V3(-w / 2 + 0.011, h + 0.0006, 0)))
        m.add(Prim.roundedBox(V3(w - 0.004, 0.0020, 0.0009), radius: 0.0003, bevelSegments: 1, material: "plastic.white:B71C1C"), Xform(translation: V3(0, h - 0.0090, d / 2 + 0.0002)))
        for i in 0..<36 {
            let x = -w / 2 + 0.012 + Float(i) * ((w - 0.024) / 35)
            m.add(Prim.cylinder(radius: 0.0007, height: 0.0010, bevel: 0.0002, segments: 8, bevelSegments: 1, material: "paper.screwbox-kraft"),
                  Xform(translation: V3(x, h - 0.0140, d / 2 + 0.0003), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Tear strip pulled out at one end: story detail.
        m.add(Prim.roundedBox(V3(0.050, 0.0014, 0.0060), radius: 0.0004, bevelSegments: 1, material: "plastic.white:B71C1C"),
              Xform(translation: V3(-w / 2 + 0.030, h - 0.0140, d / 2 + 0.0028), rotation: simd_quatf(degrees: 14, axis: .up) * simd_quatf(degrees: 18, axis: V3(1, 0, 0))))
        // Side print: windowless strip with a frozen badge on each side.
        for s in [Float(1), -1] {
            m.add(Prim.roundedBox(V3(0.0007, 0.014, d * 0.55), radius: 0.0002, bevelSegments: 1, material: "plastic.white:B71C1C"), Xform(translation: V3(s * (w / 2 + 0.0002), h * 0.5, 0)))
        }
        // Frost: scattered fine crystals plus a thin rime band along the front edge and sides.
        for _ in 0..<70 {
            let x = rng.float(-0.150...0.150), z = rng.float(-0.150...0.150)
            m.add(Prim.superellipsoid(V3(rng.float(0.003...0.009), 0.0003, rng.float(0.003...0.008)), exponent: 2.2, subdivisions: 1, material: frost),
                  Xform(translation: V3(x, h + 0.0036, z), rotation: simd_quatf(degrees: rng.float(0...180), axis: .up)))
        }
        for s in [Float(1), -1] {
            m.add(Prim.superellipsoid(V3(0.0007, 0.010, 0.150), exponent: 2.2, subdivisions: 2, material: frost), Xform(translation: V3(s * (w / 2 + 0.0004), 0.008, 0.010)))
        }
        m.add(Prim.superellipsoid(V3(0.220, 0.0004, 0.014), exponent: 2.2, subdivisions: 2, material: frost), Xform(translation: V3(0, h + 0.0034, d / 2 - 0.016)))
        // Barcode and legal text blocks on the top panel back corner.
        m.add(Prim.roundedBox(V3(0.050, 0.0006, 0.022), radius: 0.0002, bevelSegments: 1, material: "plastic.white:F6F1E2"), Xform(translation: V3(0.100, h + 0.0013, -0.130)))
        for i in 0..<14 {
            m.add(Prim.roundedBox(V3(0.0010 + Float(i % 3) * 0.0006, 0.0006, 0.016), radius: 0.0001, bevelSegments: 1, material: "plastic.white:1E1B19"),
                  Xform(translation: V3(0.081 + Float(i) * 0.0027, h + 0.0017, -0.130)))
        }
        for r in 0..<3 {
            m.add(Prim.roundedBox(V3(0.060 - Float(r) * 0.012, 0.0006, 0.0018), radius: 0.0001, bevelSegments: 1, material: "plastic.white:3A3532"),
                  Xform(translation: V3(-0.085, h + 0.0014, -0.134 + Float(r) * 0.006)))
        }
        // Scuffed bottom edge: worn board showing.
        m.add(Prim.roundedBox(V3(0.080, 0.0050, 0.0010), radius: 0.0003, bevelSegments: 1, material: edge), Xform(translation: V3(0.05, 0.0035, d / 2 + 0.0002)))
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
