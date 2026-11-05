import simd
import Foundation

/// Fortune-teller's crystal ball, 12 cm clear glass sphere with a glowing nebula core, on a turned brass
/// stand: pedestal, base ring and three curved claws. About 14.5 cm tall, 13 cm across the claws.
public struct CrystalBall: RealAsset {
    public static let id = "crystal-ball"
    public static let summary = "Crystal ball: 12 cm clear glass sphere with a glowing nebula core on a turned brass claw stand."
    public static let tags = ["prop", "decor", "fantasy", "glass", "metal", "handheld"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14)

    /// Sphere radius in meters (12 cm diameter).
    public var radius: Float = 0.06
    /// Radial segments of the glass sphere.
    public var segments = 64
    /// Outer glass material key.
    public var glass = "glass.clear"
    /// Stand metal material key.
    public var brass = "metal.brass-aged"
    /// Core glow material key.
    public var coreMaterial = "emissive.flux-coil"
    public init() {}

    static func sphere(_ r: Float, segments: Int, material: String) -> Surface {
        let n = max(24, segments / 2)
        var pts: [V2] = []
        for i in 0...n {
            let a = Float.pi * Float(i) / Float(n)
            pts.append(V2(max(0.0004, r * sin(a)), -r * cos(a)))
        }
        return Prim.lathe(pts, segments: segments, seamTile: 1, material: material)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yc = radius + 0.024                      // sphere centre, rests on the pedestal cap
        // Turned pedestal and base: foot flare, ogee stem, cup.
        m.add(turned([(0.0, 0.0), (0.047, 0.0), (0.050, 0.002), (0.049, 0.005), (0.040, 0.008), (0.032, 0.011),
                      (0.020, 0.015), (0.016, 0.018), (0.019, 0.021), (0.027, 0.025), (0.0285, 0.0275),
                      (0.026, 0.0295), (0.0, 0.0295)], material: brass),
              Xform())
        // Base ring and bead ring.
        m.add(Prim.torus(major: 0.046, minor: 0.0042, segments: 48, sides: 12, material: brass),
              Xform(translation: V3(0, 0.0072, 0)))
        m.add(Prim.torus(major: 0.0285, minor: 0.0024, segments: 40, sides: 8, material: brass),
              Xform(translation: V3(0, 0.0285, 0)))
        // Three curved claws: foot at the ring, S-curve out, then an arc hugging the glass, tapering to talons.
        let rc = radius + 0.0018
        let phase = rng.float(0...(2 * Float.pi / 3))
        for k in 0..<3 {
            let th = phase + Float(k) * 2 * Float.pi / 3
            let dirv = V3(cos(th), 0, sin(th))
            var pts: [V3] = [V3(0, 0.0072, 0) + dirv * 0.0455, V3(0, 0.013, 0) + dirv * 0.054,
                             V3(0, 0.021, 0) + dirv * 0.0635]
            for j in 0...8 {
                let el = (-48 + 54 * Float(j) / 8) * Float.pi / 180
                pts.append(V3(0, yc, 0) + dirv * (rc * cos(el) + 0.0016) + V3(0, rc * sin(el), 0))
            }
            let path = catmull(pts, per: 2)
            let radii = (0..<path.count).map { i -> Float in
                let t = Float(i) / Float(path.count - 1)
                return 0.0046 * (1 - t) + 0.0016 * t
            }
            m.add(Prim.tube(path, radii: radii, sides: 10, seamTile: 1, material: brass, capEnd: true), Xform())
            m.add(Prim.superellipsoid(V3(0.0085, 0.0085, 0.0085), exponent: 2, subdivisions: 3, material: brass),
                  Xform(translation: pts[0]))
        }
        // Glass sphere and thin inner shell for depth.
        m.add(Self.sphere(radius, segments: segments, material: glass), Xform(translation: V3(0, yc, 0)))
        m.add(Self.sphere(radius * 0.93, segments: 32, material: "glass.quartz").flipped(), Xform(translation: V3(0, yc, 0)))
        // Nebula: overlapping translucent, noise-bulged ellipsoid sheets tilted around the centre. Each sheet is a
        // different tint, so the colors blend into swirling fog; a small hot core sits inside.
        let sheets: [(Float, Float, Float, Float, String)] = [   // size, tilt x, tilt z, twist, material
            (0.104, 0.0, 0.0, 0.0, "emissive.nebula-blue"), (0.098, 1.1, 0.5, 1.7, "emissive.nebula-violet"),
            (0.090, 0.4, 1.2, 3.1, "emissive.nebula-magenta"), (0.080, 1.8, 0.9, 4.4, "emissive.nebula-teal"),
            (0.066, 0.7, 2.1, 5.6, "emissive.nebula-violet")]
        for (k, (size, tx, tz, tw, mat)) in sheets.enumerated() {
            let ph = tw + Float(k)
            let bulge: (V3) -> Float = { d in
                let a = sin(d.x * 4.1 + ph) * sin(d.y * 3.3 - ph * 0.7) + sin(d.z * 5.2 + d.x * 2.1 + ph * 1.3) * 0.6
                return 0.82 + 0.16 * a
            }
            m.add(Prim.superellipsoid(V3(size, size * 0.78, size * 0.92), exponent: 2, subdivisions: 7, material: mat, bulge: bulge),
                  Xform(translation: V3(0, yc, 0), rotation: simd_quatf(angle: tx, axis: V3(1, 0, 0)) * simd_quatf(angle: tz, axis: V3(0, 0, 1))))
        }
        m.add(Self.sphere(0.0065, segments: 24, material: coreMaterial), Xform(translation: V3(0, yc, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
