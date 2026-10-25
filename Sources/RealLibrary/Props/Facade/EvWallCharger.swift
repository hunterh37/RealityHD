import simd
import Foundation

/// Level 2 EV wall charger: graphite sheet-metal housing on a galvanized mounting plate, glass fascia with an
/// LED status bar, rubber cable gland, looped cable and a J1772 handle docked in a holster cup. Wall plane at z = 0.
public struct EvWallCharger: RealAsset {
    public static let id = "ev-wall-charger"
    public static let summary = "Level 2 EV wall charger: graphite housing on mounting plate, glass fascia with LED bar, gland, coiled cable and docked J1772 handle in holster."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, distance: 1.1)

    /// Housing finish.
    public var housing: MaterialKey = "metal.painted:2E3034"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hy: Float = 0.27, hc: Float = 0.315   // housing height and centre y
        // Galvanized wall plate with slotted screw holes and the housing on top.
        FS.plate(&m, 0.2, 0.25, 0.004, radius: 0.006, at: V3(0, hc, 0.002), "metal.galvanized")
        FS.screws(&m, [V3(-0.085, hc - 0.11, 0.004), V3(0.085, hc - 0.11, 0.004), V3(-0.085, hc + 0.11, 0.004), V3(0.085, hc + 0.11, 0.004)], r: 0.004)
        m.add(Prim.extrude(Shape2D.roundedRect(0.25, hy, radius: 0.028), depth: 0.1, bevel: 0.006, bevelSegments: 2, material: housing),
              Xform(translation: V3(0, hc, 0.056)))
        // Seam reveal around the fascia, glass fascia, LED bar and status dots.
        m.add(Prim.extrude(Shape2D.roundedRect(0.226, hy - 0.024, radius: 0.02), depth: 0.004, bevel: 0.001, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(0, hc, 0.1065)))
        m.add(Prim.extrude(Shape2D.roundedRect(0.218, hy - 0.032, radius: 0.016), depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: "glass.display"),
              Xform(translation: V3(0, hc, 0.1085)))
        FA.box(&m, V3(0.15, 0.008, 0.002), V3(0, hc + 0.075, 0.1112), "emissive.led-green", r: 0.0015)
        for i in 0..<3 {
            FA.cylZ(&m, r: 0.006, h: 0.0015, at: V3(-0.03 + Float(i) * 0.03, hc + 0.02, 0.1105), i == 0 ? "emissive.led-green" : "plastic.black", bevel: 0.0004, segments: 12)
        }
        // Rating label on the lower fascia and a pry-slot at the top seam.
        FA.box(&m, V3(0.1, 0.03, 0.0012), V3(0, hc - 0.06, 0.1112), "metal.painted:7E8183", r: 0.0004)
        FA.box(&m, V3(0.06, 0.003, 0.0012), V3(0, hc - 0.06, 0.1119), "plastic.black", r: 0.0004)
        FA.box(&m, V3(0.04, 0.003, 0.003), V3(0, hc + hy / 2 - 0.004, 0.146), "plastic.black", r: 0.001)
        // Cable gland under the housing, cable loop to the handle.
        let gy = hc - hy / 2
        m.add(Prim.cylinder(radius: 0.017, height: 0.02, bevel: 0.003, segments: 18, material: "rubber.silicone"), Xform(translation: V3(0, gy - 0.016, 0.07)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.01, bevel: 0.002, segments: 6, material: "metal.stainless"), Xform(translation: V3(0, gy - 0.004, 0.07)))
        let cable = catmull([V3(0, gy - 0.014, 0.07), V3(0, gy - 0.026, 0.074), V3(0.022, gy - 0.036, 0.09), V3(0.03, gy - 0.026, 0.11), V3(0.01, gy - 0.02, 0.12), V3(-0.012, gy - 0.034, 0.1), V3(0, gy - 0.052, 0.068)], per: 6)
        FA.path(&m, cable, r: 0.0075, "rubber.tubing", sides: 10)
        // Holster cup on the wall and the docked J1772 handle.
        let cx: Float = 0
        FA.box(&m, V3(0.08, 0.08, 0.012), V3(cx, 0.04, 0.006), "plastic.black", r: 0.004)
        m.add(Prim.cylinder(radius: 0.034, height: 0.05, bevel: 0.004, segments: 22, material: "plastic.black"), Xform(translation: V3(cx, 0.0, 0.062)))
        m.add(Prim.cylinder(radius: 0.031, height: 0.004, bevel: 0.001, segments: 22, material: "metal.stainless"), Xform(translation: V3(cx, 0.05, 0.062)))
        FS.screws(&m, [V3(cx - 0.03, 0.065, 0.012), V3(cx + 0.03, 0.065, 0.012)], r: 0.003)
        // Handle: grip body, thumb latch, plug collar.
        m.add(Prim.superellipsoid(V3(0.058, 0.1, 0.05), exponent: 2.4, subdivisions: 8, material: "plastic.black"), Xform(translation: V3(cx, 0.108, 0.062)))
        FA.box(&m, V3(0.02, 0.04, 0.01), V3(cx, 0.12, 0.09), "plastic.medical-grey", r: 0.003)
        m.add(Prim.cylinder(radius: 0.027, height: 0.03, bevel: 0.003, segments: 22, material: "plastic.medical-grey"), Xform(translation: V3(cx, 0.052, 0.062)))
        m.add(Prim.cylinder(radius: 0.0215, height: 0.012, bevel: 0.001, segments: 22, material: "rubber.silicone"), Xform(translation: V3(cx, 0.044, 0.062)))
        // Weathering: rust streaks under the plate screws, grime at the foot of the housing, dust on the holster.
        FS.streak(&m, x: -0.085, top: hc - 0.11, w: 0.006, h: rng.float(0.03...0.05), z: 0.0046)
        FS.streak(&m, x: 0.085, top: hc - 0.11, w: 0.006, h: rng.float(0.02...0.04), z: 0.0046)
        FA.box(&m, V3(0.24, 0.012, 0.0015), V3(0, gy + 0.012, 0.1002), "metal.painted:4A4B4B", r: 0.0005)
        // Side heat vents, bottom cover screws, strain-relief ribs, dust streaks, scuffed holster lip.
        for i in 0..<6 {
            FA.box(&m, V3(0.002, 0.1, 0.006), V3(0.1255, hc - 0.02, 0.026 + Float(i) * 0.016), "plastic.black", r: 0.0007)
        }
        FS.screws(&m, [V3(-0.07, gy, 0.06), V3(0.07, gy, 0.06)], normal: V3(0, -1, 0), r: 0.0036)
        for i in 0..<3 {
            m.add(Prim.torus(major: 0.0275 - Float(i) * 0.001, minor: 0.0025, segments: 20, sides: 6, material: "rubber.silicone"),
                  Xform(translation: V3(cx, 0.14 + Float(i) * 0.0, 0.062)))
        }
        FA.box(&m, V3(0.012, 0.0012, 0.02), V3(cx + 0.034, 0.0, 0.062), "plastic.black", r: 0.0003)
        // Lighter top cap band, hairline fascia scratches, UV-faded housing top and a scuffed lower corner.
        m.add(Prim.extrude(Shape2D.roundedRect(0.252, 0.03, radius: 0.012), depth: 0.1, bevel: 0.005, bevelSegments: 1, material: "metal.painted:44474B"),
              Xform(translation: V3(0, hc + hy / 2 - 0.014, 0.056 + 0.0004)))
        FA.box(&m, V3(0.03, 0.02, 0.0012), V3(0.105, gy + 0.012, 0.1002), "metal.galvanized-aged", r: 0.0005)
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
