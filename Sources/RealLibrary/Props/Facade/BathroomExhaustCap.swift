import simd
import Foundation

/// Bathroom exhaust wall cap: UV-yellowed ABS round flange 0.2 m across with four screws and a caulk ring, a
/// round body with a rolled rim, nine moulded louver slats, a hinged damper flap on a rod and a dark duct
/// throat behind, with dirt and insect debris. Wall plane at z = 0.
public struct BathroomExhaustCap: RealAsset {
    public static let id = "bathroom-exhaust-cap"
    public static let summary = "Bathroom exhaust wall cap: UV-yellowed ABS round flange, 4 inch body with moulded louver slats, hinged damper behind, caulk ring, screws and dirt."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 0.95)

    /// Cap plastic.
    public var shell: MaterialKey = "plastic.matte:ECE4C4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.1
        // Flange with raised bead, caulk ring and screws on a pitch circle.
        FS.cyl(&m, r: 0.098, h: 0.007, at: V3(0, cy, 0), axis: FA.Z, shell, bevel: 0.003, segments: 44)
        FS.cyl(&m, r: 0.092, h: 0.003, at: V3(0, cy, 0.007), axis: FA.Z, shell, bevel: 0.0012, segments: 44)
        m.add(Prim.torus(major: 0.098, minor: 0.0022, segments: 48, sides: 6, material: "rubber.silicone"), Xform(translation: V3(0, cy, 0.002), rotation: FA.q(90, FA.X)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            FS.screw(&m, at: V3(cos(a) * 0.082, cy + sin(a) * 0.082, 0.01), r: 0.0042, mat: "metal.screw-zinc")
        }
        // Body: cylinder with moulded ribs, rolled front rim, dark throat and damper behind the slats.
        FS.sleeveZ(&m, rOut: 0.083, rIn: 0.0775, z0: 0.008, z1: 0.112, cy: cy, shell, segments: 40)
        m.add(Prim.torus(major: 0.0825, minor: 0.0042, segments: 44, sides: 8, material: shell), Xform(translation: V3(0, cy, 0.1115), rotation: FA.q(90, FA.X)))
        FS.cyl(&m, r: 0.076, h: 0.004, at: V3(0, cy, 0.04), axis: FA.Z, "plastic.black", bevel: 0.0008, segments: 36)
        FS.cyl(&m, r: 0.068, h: 0.003, at: V3(0, cy, 0.062), axis: FA.Z, "plastic.medical-grey", bevel: 0.001, segments: 36)
        FA.cylX(&m, r: 0.0024, h: 0.1, at: V3(-0.05, cy + 0.06, 0.066), "metal.aluminum-brushed", bevel: 0.0005, segments: 8)
        // Nine louver slats clipped to the opening: chord length from the opening radius.
        let ro: Float = 0.077
        for i in 0..<9 {
            let y = -0.0615 + Float(i) * 0.0154
            let half = sqrt(max(ro * ro - y * y, 0.0001))
            FA.box(&m, V3(half * 2, 0.0026, 0.027), V3(0, cy + y, 0.1045), i >= 6 ? "metal.painted:C3BDA4" : shell, r: 0.001, rot: FA.q(-34, FA.X))
        }
        // Weathering: UV yellowing on the rim, dirt ring on the flange, cobweb tuft and mud at the lower slats.
        for _ in 0..<26 {
            let a = rng.float(0...(2 * .pi)), r = rng.float(0.086...0.098)
            FC.bead(&m, r: rng.float(0.001...0.0024), at: V3(cos(a) * r, cy + sin(a) * r * 0.6 - 0.025, 0.0098), "metal.painted:726B58", sub: 2)
        }
        for i in 0..<3 {
            m.add(Prim.superellipsoid(V3(rng.float(0.015...0.03), 0.005, 0.008), exponent: 2, subdivisions: 3, material: "fabric.linen"),
                  Xform(translation: V3(rng.float(-0.04...0.04), cy - 0.05 + Float(i) * 0.004, 0.113), rotation: FA.q(rng.float(-20...20), FA.Z)))
        }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
