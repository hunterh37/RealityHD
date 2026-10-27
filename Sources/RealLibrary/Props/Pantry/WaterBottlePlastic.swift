import simd
import Foundation

/// Plastic water bottle: 7 cm wide, 22 cm tall half-litre PET bottle with ribbed grip bands, wrapped label with lap seam,
/// threaded neck, white sport cap with tamper band, water fill, scuffed heel and condensation beads.
public struct WaterBottlePlastic: RealAsset {
    public static let id = "water-bottle-plastic"
    public static let summary = "Half-litre PET water bottle, 22 cm: ribbed grip, blue label, threaded neck, white cap, condensation."
    public static let tags = ["prop", "interior", "pantry", "plastic", "container"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.07, 0.22, 0.07)
    /// Water level as a height above the base (m).
    public var fillY: Float = 0.165
    /// Bottle, water, cap and label colour keys.
    public var pet: MaterialKey = "plastic.clear"
    public var water: MaterialKey = "glass.water-clear"
    public var cap: MaterialKey = "plastic.gloss:E8EEF2"
    public var label: MaterialKey = "plastic.white:2468B8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var outer: [V2] = [V2(0.0255, 0.008), V2(0.0325, 0.014), V2(0.0345, 0.026), V2(0.0348, 0.034)]
        // Ribbed grip zone: alternating ring radii.
        for k in 0..<8 { let y = 0.040 + Float(k) * 0.0075; outer.append(V2(k % 2 == 0 ? 0.0348 : 0.0332, y)) }
        outer += [V2(0.0348, 0.103), V2(0.0348, 0.130), V2(0.0338, 0.146), V2(0.0290, 0.160), V2(0.0200, 0.174), V2(0.0130, 0.184),
                  V2(0.0103, 0.190), V2(0.0099, 0.1965), V2(0.0099, 0.2035)]
        var shell = Model(name: "shell")
        DD1MPantry.shell(&shell, outer: outer, wall: 0.0006, baseThick: 0.007, material: pet, seg: 48, tile: 0.12)
        for s in shell.surfaces { m.add(s) }
        DD1MPantry.fill(&m, outer: outer, wall: 0.0006, baseThick: 0.007, fillY: fillY, material: water, seg: 48)
        // Moulded grooves around the shoulder and label seam.
        for y in [Float(0.103), 0.134] {
            m.add(Prim.torus(major: 0.0349, minor: 0.0005, segments: 48, sides: 6, minorY: 0.0005, material: pet), Xform(translation: V3(0, y, 0)))
        }
        // Neck support ring and thread.
        m.add(Prim.lathe([V2(0.0099, 0.1835), V2(0.0124, 0.1838), V2(0.0126, 0.1846), V2(0.0124, 0.1858), V2(0.0099, 0.1862)], segments: 32, seamTile: 0.06, material: pet))
        DD1MPantry.threads(&m, r: 0.0100, y: 0.1885, turns: 1.3, pitch: 0.0030, wire: 0.0006, material: pet)
        DD1MPantry.cap(&m, r: 0.0122, y: 0.1860, h: 0.0178, ribs: 48, ribDepth: 0.0004, material: cap, seg: 40)
        DD1MPantry.tamperRing(&m, r: 0.0118, y: 0.1850, h: 0.0028, material: cap)
        // Sport-cap nozzle on top (pull-up spout) with a worn rim.
        m.add(Prim.cylinder(radius: 0.0052, height: 0.0045, bevel: 0.0012, segments: 24, bevelSegments: 2, material: "plastic.white:D8DEE2"), Xform(translation: V3(0, 0.2038, 0)))
        // Label ring around the tall blue band.
        m.add(Prim.lathe([V2(0.0351, 0.040), V2(0.0354, 0.0405), V2(0.0354, 0.099), V2(0.0351, 0.0995)], segments: 48, seamTile: 0.1, material: "plastic.white:2468B8"))
        m.add(Prim.lathe([V2(0.0354, 0.058), V2(0.0357, 0.0583), V2(0.0357, 0.082), V2(0.0354, 0.0823)], segments: 48, seamTile: 0.1, material: "plastic.white:F4F6F8"))
        m.add(Prim.roundedBox(V3(0.007, 0.059, 0.0004), radius: 0.00012, bevelSegments: 1, material: "plastic.white:2468B8"), Xform(translation: V3(0, 0.0695, -0.0354)))
        // Scuffed heel: frosted flecks.
        for _ in 0..<24 {
            let y = rng.float(0.014...0.032), ang = rng.float(0...(2 * .pi))
            let rr = DD1MPantry.radius(outer, at: y) + 0.0001
            m.add(Prim.superellipsoid(V3(rng.float(0.0012...0.0030), rng.float(0.0004...0.0010), 0.0002), exponent: 2, subdivisions: 1, material: "plastic.frosted"),
                  Xform(translation: V3(cos(ang) * rr, y, sin(ang) * rr), rotation: simd_quatf(angle: -ang + .pi / 2, axis: .up) * simd_quatf(degrees: rng.float(-50...50), axis: V3(0, 0, 1))))
        }
        // Story detail: label corner torn and curling off at the lower edge.
        m.add(Prim.roundedBox(V3(0.016, 0.011, 0.0004), radius: 0.00012, bevelSegments: 1, material: "plastic.white:2468B8"),
              Xform(translation: V3(0.0272, 0.0455, 0.0236), rotation: simd_quatf(degrees: 38, axis: .up) * simd_quatf(degrees: -16, axis: V3(1, 0, 0))))
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.045, y1: 0.098, count: 14, size: 0.002...0.005, material: "plastic.frosted", lift: 0.0005)
        DD1MPantry.mouldSeam(&m, profile: outer, y0: 0.128, y1: 0.176, material: pet)
        DD1MPantry.droplets(&m, rng: &rng, profile: outer, y0: 0.02, y1: 0.16, count: 36, size: 0.0011...0.0026)
        DD1MPantry.grounded(&m)
        DD1MPantry.stretchY(&m, 1.055)
        groundAO(&m)
        return LODModel(m)
    }
}
