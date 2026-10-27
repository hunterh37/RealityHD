import simd
import Foundation

/// Yogurt cup: 7 cm wide, 8 cm tall tapered plastic cup with a rolled rim, stacking ring, printed wrap with lap seam, and a crimped foil
/// lid with a lifted pull tab, a printed centre disc and a streak of yogurt running down the outside.
public struct YogurtCup: RealAsset {
    public static let id = "yogurt-cup"
    public static let summary = "Plastic yogurt cup, 8 cm: rolled rim, printed wrap, foil lid with pull tab, printed disc, yogurt streak."
    public static let tags = ["prop", "interior", "pantry", "plastic", "metal", "container", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.07, 0.08, 0.07)
    /// Cup plastic, yogurt, foil and print colour keys.
    public var plastic: MaterialKey = "plastic.white:F2F2EE"
    public var yogurt: MaterialKey = "food.cream:F6EEDD"
    public var foil: MaterialKey = "plastic.gloss:C9CDD0"
    public var print: MaterialKey = "plastic.white:D6336C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let outer: [V2] = [V2(0.0260, 0.0015), V2(0.0272, 0.0050), V2(0.0300, 0.0300), V2(0.0338, 0.0690), V2(0.0348, 0.0770), V2(0.0352, 0.0790)]
        DD1MPantry.shell(&m, outer: outer, wall: 0.0009, baseThick: 0.003, material: plastic, seg: 56, tile: 0.1)
        // Rolled rim bead and stacking ring.
        m.add(Prim.torus(major: 0.0356, minor: 0.0014, segments: 56, sides: 8, minorY: 0.0016, material: plastic), Xform(translation: V3(0, 0.0786, 0)))
        m.add(Prim.torus(major: 0.0348, minor: 0.0008, segments: 56, sides: 6, minorY: 0.0008, material: plastic), Xform(translation: V3(0, 0.0705, 0)))
        // Base stacking foot.
        m.add(Prim.torus(major: 0.0258, minor: 0.0010, segments: 40, sides: 6, minorY: 0.0014, material: plastic), Xform(translation: V3(0, 0.0014, 0)))
        // Printed wrap: tapered band with a lap seam and a fruit disc.
        let w0: Float = 0.012, w1: Float = 0.062
        let rw0 = DD1MPantry.radius(outer, at: w0) + 0.0003, rw1 = DD1MPantry.radius(outer, at: w1) + 0.0003
        m.add(Prim.lathe([V2(rw0, w0), V2(rw0 + 0.0004, w0 + 0.0003), V2(rw1 + 0.0004, w1 - 0.0003), V2(rw1, w1)], segments: 56, seamTile: 0.1, material: print))
        m.add(Prim.lathe([V2(rw0 + 0.0004, w0 + 0.034), V2(rw0 + 0.0010, w0 + 0.0345), V2(rw1 + 0.0010, w1 - 0.0005), V2(rw1 + 0.0004, w1)], segments: 56, seamTile: 0.1, material: "plastic.white:F7F4EA"))
        m.add(Prim.roundedBox(V3(0.0055, 0.050, 0.0005), radius: 0.00015, bevelSegments: 1, material: print), Xform(translation: V3(0, 0.037, -(DD1MPantry.radius(outer, at: 0.037) + 0.0006))))
        // Yogurt surface just below the rim.
        m.add(Prim.lathe([V2(0, 0.0705), V2(0.0318, 0.0707), V2(0.0338, 0.0715), V2(0, 0.0713)], segments: 56, seamTile: 0.1, material: yogurt))
        // Foil lid: sealed disc crimped to the rim, with a lifted pull tab and a printed centre disc.
        var lid = Prim.extrude(Shape2D.circle(0.0368, ry: 0.0368, segments: 64), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: foil)
        lid.displace { p, _ in 0.00028 * sin(atan2(p.z, p.x) * 28) * min(1, hypot(p.x, p.z) / 0.030) + 0.0004 * sin(p.x * 140) * sin(p.y * 120) }
        m.add(lid, Xform(translation: V3(0, 0.0802, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0225, height: 0.0004, bevel: 0.0001, segments: 40, bevelSegments: 1, material: print), Xform(translation: V3(0, 0.0805, 0)))
        m.add(Prim.cylinder(radius: 0.0150, height: 0.0004, bevel: 0.0001, segments: 40, bevelSegments: 1, material: "plastic.white:F7F4EA"), Xform(translation: V3(0, 0.0809, 0)))
        // Pull tab: a rounded foil ear hinged on the rim, lifted about 10 degrees, with a finger hole.
        m.add(Prim.roundedBox(V3(0.018, 0.0004, 0.012), radius: 0.0003, bevelSegments: 1, material: foil),
              Xform(translation: V3(0, 0.0814, 0.0318), rotation: simd_quatf(degrees: 10, axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: 0.0032, minor: 0.0005, segments: 20, sides: 5, minorY: 0.0005, material: "plastic.gloss:B9BDC0"),
              Xform(translation: V3(0, 0.0821, 0.0334), rotation: simd_quatf(degrees: 10, axis: V3(1, 0, 0))))
        // Yogurt crusted on the underside of the tab where it was pulled through the pot.
        m.add(Prim.superellipsoid(V3(0.010, 0.0006, 0.0050), exponent: 2, subdivisions: 3, material: yogurt), Xform(translation: V3(0.002, 0.0803, 0.0290)))
        // Yogurt streak running down the outside from the rim, flush with the tapered wall.
        let ys: Float = 0.0640
        let ang: Float = 0.30
        let rr = DD1MPantry.radius(outer, at: ys) + 0.0003
        m.add(Prim.superellipsoid(V3(0.0046, 0.0300, 0.0013), exponent: 2, subdivisions: 3, material: yogurt),
              Xform(translation: V3(sin(ang) * rr, ys, cos(ang) * rr), rotation: simd_quatf(angle: ang, axis: .up) * simd_quatf(degrees: -6, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(0.0062, 0.0058, 0.0030), exponent: 2, subdivisions: 3, material: yogurt),
              Xform(translation: V3(sin(ang) * (rr + 0.0004), ys - 0.0155, cos(ang) * (rr + 0.0004)), rotation: simd_quatf(angle: ang, axis: .up)))
        // Uniform trim so the cup with its lid lands on the brief envelope.
        DD1MPantry.grounded(&m)
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 * 0.95 } }
        groundAO(&m)
        return LODModel(m)
    }
}
