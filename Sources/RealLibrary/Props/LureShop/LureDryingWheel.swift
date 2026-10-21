import simd
import Foundation

/// Motorized rotisserie drying wheel for epoxy-coated lures: a powdercoated base box housing the
/// controller (rocker switch on the front, cord out the back) on a thin base plate with rubber feet, an
/// upright post carrying a small gear motor, a horizontal shaft and a white spoked wheel. Spring clips on
/// the rim hold eight crankbait bodies radially, still glossy from the epoxy. Story detail: dried epoxy drips
/// on the base plate under the wheel.
public struct LureDryingWheel: RealAsset {
    public static let id = "lure-drying-wheel"
    public static let summary = "Motorized lure drying wheel: gear motor box on a base, horizontal shaft, spoked disc with clips holding epoxy-coated lures."
    public static let tags = ["prop", "workshop", "tool", "plastic"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.0, studio: true)

    /// Shaft height above the bench (m).
    public var hubHeight: Float = 0.17
    /// Wheel rim radius (m).
    public var rimRadius: Float = 0.07
    /// Number of lures on the wheel.
    public var lureCount: Int = 8
    /// Lure body colors (sRGB hex).
    public var lureColors: [UInt32] = [0xE8C21C, 0x2E8B57, 0xC0262D, 0xF2F0E8, 0x1E5FA8, 0xE8762B, 0x8DBA3A, 0x3A2A22]
    /// Base and motor finish.
    public var housing: MaterialKey = "metal.powdercoat:1E1E1E"
    /// Wheel plastic.
    public var wheel: MaterialKey = "plastic.medical:EEEBE2"
    public init() {}

    /// One crankbait body along +X from x = 0, with a clear lip at the far end.
    func lure(color: UInt32, lite: Bool, rng: inout SeededRNG) -> Model {
        var m = Model(name: "lure")
        let hex = String(format: "%06X", color), len: Float = 0.045
        m.add(Prim.superellipsoid(V3(len, 0.019, 0.013), exponent: 2.1, subdivisions: lite ? 3 : 5, material: "plastic.gloss:" + hex,
                                  bulge: { d in 1 - 0.18 * max(0, -d.x) }), Xform(translation: V3(len / 2, 0, 0)))
        if lite { return m }
        // Epoxy bead gathering at the nose as the wheel turns.
        m.add(Prim.superellipsoid(V3(0.006, 0.0042, 0.0048), exponent: 2, subdivisions: 3, material: "plastic.gloss:" + hex),
              Xform(translation: V3(len - 0.0015, -0.0072, 0)))
        // Darker back stripe and eyes.
        m.add(Prim.superellipsoid(V3(len * 0.8, 0.006, 0.0105), exponent: 2.2, subdivisions: 3, material: "plastic.gloss:2A2A2A"),
              Xform(translation: V3(len * 0.48, 0.0072, 0)))
        for s in [Float(1), -1] {
            m.add(Prim.superellipsoid(V3(0.0045, 0.0045, 0.0016), exponent: 2, subdivisions: 2, material: "plastic.gloss:E8C21C"),
                  Xform(translation: V3(len * 0.8, 0.002, s * 0.0058)))
        }
        // Diving lip.
        m.add(Prim.roundedBox(V3(0.016, 0.0012, 0.011), radius: 0.0005, bevelSegments: 1, material: "plastic.clear"),
              Xform(translation: V3(len + 0.005, -0.003, 0), rotation: simd_quatf(angle: -0.5, axis: V3(0, 0, 1))))
        // Screw eye at the clipped end.
        m.add(Prim.torus(major: 0.0022, minor: 0.0005, segments: 10, sides: 4, material: "metal.steel"),
              Xform(translation: V3(-0.002, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, lite: false), level(seed: seed, lite: true)], switchDistances: [2.5])
    }

    func level(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = hubHeight, zw: Float = 0.03
        // Base plate and rubber feet.
        m.add(Prim.roundedBox(V3(0.18, 0.006, 0.15), radius: 0.002, bevelSegments: 2, material: housing), Xform(translation: V3(0, 0.005, 0)))
        for x in [Float(-0.075), 0.075] { for z in [Float(-0.06), 0.06] {
            m.add(Prim.cylinder(radius: 0.007, height: 0.0025, bevel: 0.0008, segments: 12, bevelSegments: 1, material: "rubber.plate"), Xform(translation: V3(x, 0, z)))
        } }
        // Controller box on the back half, rocker switch, cord.
        m.add(Prim.roundedBox(V3(0.14, 0.045, 0.07), radius: 0.005, bevelSegments: 2, material: housing), Xform(translation: V3(0, 0.008 + 0.0225, -0.035)))
        m.add(Prim.roundedBox(V3(0.022, 0.014, 0.004), radius: 0.0015, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0.04, 0.032, 0.0015)))
        m.add(Prim.roundedBox(V3(0.012, 0.009, 0.004), radius: 0.0012, bevelSegments: 1, material: "plastic.gloss:B3201C"),
              Xform(translation: V3(0.04, 0.032, 0.004), rotation: simd_quatf(angle: 0.18, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.003, height: 0.001, bevel: 0.0002, segments: 10, bevelSegments: 1, material: "glass.led-lens"),
              Xform(translation: V3(-0.04, 0.032, 0.0002), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        let cord = catmull([V3(0.05, 0.02, -0.07), V3(0.055, 0.012, -0.085), V3(0.07, 0.0028, -0.088), V3(0.1, 0.0028, -0.092)], per: 5)
        m.add(Prim.tube(cord, radii: Array(repeating: 0.0028, count: cord.count), sides: 8, seamTile: 0.03, material: "rubber.tubing:1A1A1A"))
        // Upright post and gear motor.
        m.add(Prim.roundedBox(V3(0.03, H - 0.05, 0.02), radius: 0.003, bevelSegments: 2, material: housing), Xform(translation: V3(0, 0.05 + (H - 0.05) / 2 - 0.004, -0.035)))
        m.add(Prim.cylinder(radius: 0.019, height: 0.04, bevel: 0.002, segments: 24, bevelSegments: 2, material: "metal.aluminum-brushed"),
              Xform(translation: V3(0, H, -0.06), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.02, height: 0.012, bevel: 0.0015, segments: 24, bevelSegments: 2, material: housing),
              Xform(translation: V3(0, H, -0.022), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        // Shaft and hub.
        m.add(Prim.cylinder(radius: 0.003, height: 0.05, bevel: 0.0004, segments: 12, bevelSegments: 1, material: "metal.steel"),
              Xform(translation: V3(0, H, -0.022), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.012, height: 0.012, bevel: 0.0015, segments: 20, bevelSegments: 2, material: wheel),
              Xform(translation: V3(0, H, zw - 0.006), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0045, height: 0.004, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "metal.steel"),
              Xform(translation: V3(0, H, zw + 0.006), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        // Wheel: rim ring, six spokes.
        let R = rimRadius
        m.add(Prim.torus(major: R, minor: 0.0045, segments: 44, sides: 8, material: wheel),
              Xform(translation: V3(0, H, zw), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + 0.26
            m.add(Prim.roundedBox(V3(R - 0.012, 0.0045, 0.0035), radius: 0.001, bevelSegments: 1, material: wheel),
                  Xform(translation: V3(cos(a) * (R / 2 + 0.006), H + sin(a) * (R / 2 + 0.006), zw), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))))
        }
        // Clips and lures, radial.
        for i in 0..<lureCount {
            var lr = rng.fork(i)
            let a = Float(i) / Float(lureCount) * 2 * .pi
            let rot = simd_quatf(angle: a, axis: V3(0, 0, 1))
            let d = V3(cos(a), sin(a), 0), c = V3(0, H, zw)
            // Spring clip: two jaws gripping the rim, short shank outward.
            for s in [Float(1), -1] {
                m.add(Prim.roundedBox(V3(0.016, 0.0012, 0.006), radius: 0.0005, bevelSegments: 1, material: "metal.steel"),
                      Xform(translation: c + d * (R + 0.003) + V3(0, 0, s * 0.005), rotation: rot * simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            m.add(Prim.cylinder(radius: 0.0008, height: 0.012, bevel: 0.0002, segments: 6, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: c + d * (R + 0.008), rotation: simd_quatf(from: V3(0, 1, 0), to: d)))
            let body = lure(color: lureColors[i % lureColors.count], lite: lite, rng: &lr)
            m.add(body, Xform(translation: c + d * (R + 0.0155), rotation: rot * simd_quatf(angle: lr.float(-0.2...0.2), axis: V3(1, 0, 0))))
        }
        // Dried epoxy drips on the plate under the wheel.
        for _ in 0..<5 {
            let p = V3(rng.float(-0.07...0.07), 0.0081, rng.float(0.01...0.065))
            let r = rng.float(0.003...0.007)
            m.add(Prim.superellipsoid(V3(r * 2, 0.0012, r * 1.6), exponent: 2, subdivisions: 3, material: "plastic.gloss:C9A04A"), Xform(translation: p))
        }
        groundAO(&m)
        return m
    }
}
