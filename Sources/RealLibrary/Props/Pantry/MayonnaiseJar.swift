import simd
import Foundation

/// Mayonnaise jar: 8 cm wide, 13 cm tall glass jar with a moulded heel, threaded neck, blue enamel lid with a safety button and rolled
/// edge, wrapped label with lap seam, mould seams, scuffed heel and a smear of mayonnaise on the lid rim.
public struct MayonnaiseJar: RealAsset {
    public static let id = "mayonnaise-jar"
    public static let summary = "Glass mayonnaise jar, 13 cm: threaded neck, blue enamel lid with safety button, wrapped label, mayo smear."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal", "paper", "container", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.13, 0.08)
    /// Mayonnaise level as a height above the base (m).
    public var fillY: Float = 0.1
    /// Glass, fill, lid and label keys.
    public var glass: MaterialKey = "glass.clear"
    public var fillMaterial: MaterialKey = "food.cream:F0E7C4"
    public var lid: MaterialKey = "metal.enamel:1F4FA0"
    public var labelPaper: MaterialKey = "plastic.white:F2EEE2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.0398
        let outer: [V2] = [V2(0.0362, 0.0015), V2(0.0388, 0.005), V2(r, 0.011), V2(r, 0.0935), V2(0.0386, 0.1005), V2(0.0352, 0.1075),
                           V2(0.0338, 0.1125), V2(0.0334, 0.1155), V2(0.0334, 0.1215), V2(0.0342, 0.1225)]
        DD1KPantry.shell(&m, outer: outer, wall: 0.0029, baseThick: 0.008, material: glass, seg: 56)
        DD1KPantry.fill(&m, outer: outer, wall: 0.0029, baseThick: 0.008, fillY: fillY, material: fillMaterial, seg: 56)
        DD1KPantry.mouldSeam(&m, profile: outer, y0: 0.012, y1: 0.108, material: glass)
        m.add(Prim.lathe([V2(r + 0.0002, 0.006), V2(r + 0.0004, 0.0075), V2(r + 0.0004, 0.0135), V2(r + 0.0002, 0.0145)], segments: 56, seamTile: 0.1, material: "glass.frosted"))
        DD1KPantry.threads(&m, r: 0.0337, y: 0.1125, turns: 1.6, pitch: 0.0046, wire: 0.0009, material: glass)
        DD1KPantry.label(&m, r: r, y0: 0.018, y1: 0.088, material: labelPaper,
                         bands: [(0.018, 0.026, "plastic.white:1F4FA0"), (0.080, 0.088, "plastic.white:1F4FA0")],
                         panel: (0.053, 0.0175, "plastic.white:E6B912"), seg: 56)
        // Enamel lid: shallow skirt, rolled lower edge, safety button dimple.
        DD1KPantry.cap(&m, r: 0.0368, y: 0.1135, h: 0.0165, ribs: 72, ribDepth: 0.0004, material: lid)
        m.add(Prim.torus(major: 0.0368, minor: 0.0007, segments: 56, sides: 6, minorY: 0.0007, material: "metal.nickel-worn"), Xform(translation: V3(0, 0.1141, 0)))
        m.add(Prim.cylinder(radius: 0.0085, height: 0.0008, bevel: 0.0003, segments: 24, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, 0.1298, 0)))
        // Smear of mayonnaise along the lid skirt where a knife was wiped.
        m.add(Prim.torus(major: 0.0372, minor: 0.0014, segments: 28, sides: 6, arc: 1.3, minorY: 0.0014, material: "food.cream:F0E7C4"),
              Xform(translation: V3(0, 0.1160, 0), rotation: simd_quatf(degrees: 25, axis: .up)))
        m.add(Prim.superellipsoid(V3(0.006, 0.004, 0.003), exponent: 2.4, subdivisions: 3, material: "food.cream:F0E7C4"),
              Xform(translation: V3(0.0374 * cos(0.35), 0.1115, -0.0374 * sin(0.35)), rotation: simd_quatf(degrees: 20, axis: .up)))
        // Rust bloom: orange-brown pitting along the rolled lower edge of the lid where condensation sits.
        for (i, deg) in [Float(-70), -38, 12, 55, 100, 150, 205].enumerated() {
            let a = deg * .pi / 180, rr: Float = 0.0372
            let sz = 0.0028 + 0.0012 * Float(i % 3)
            m.add(Prim.superellipsoid(V3(sz * 1.5, 0.0030, 0.0009), exponent: 2.4, subdivisions: 2, material: "metal.rust-grime"),
                  Xform(translation: V3(sin(a) * rr, 0.1150, cos(a) * rr), rotation: simd_quatf(angle: a, axis: .up)))
        }
        DD1KPantry.grounded(&m)
        groundAO(&m)
        _ = rng.float()
        return LODModel(m)
    }
}
