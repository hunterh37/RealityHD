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
    public var segments = 96
    /// Outer glass material key.
    public var glass = "glass.clear"
    /// Stand metal material key.
    public var brass = "metal.brass-aged"
    /// Core glow material key.
    public var coreMaterial = "emissive.flux-coil"
    public init() {}

    static func sphere(_ r: Float, segments: Int, material: String) -> Surface {
        let n = max(32, segments / 2)
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
        m.add(Prim.torus(major: 0.046, minor: 0.0042, segments: 72, sides: 24, material: brass),
              Xform(translation: V3(0, 0.0072, 0)))
        m.add(Prim.torus(major: 0.0285, minor: 0.0024, segments: 64, sides: 16, material: brass),
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
            let path = catmull(pts, per: 8)
            let radii = (0..<path.count).map { i -> Float in
                let t = Float(i) / Float(path.count - 1)
                return 0.0046 * (1 - t) + 0.0016 * t
            }
            m.add(Prim.tube(path, radii: radii, sides: 24, seamTile: 1, material: brass, capEnd: true), Xform())
            m.add(Prim.superellipsoid(V3(0.0085, 0.0085, 0.0085), exponent: 2, subdivisions: 4, material: brass),
                  Xform(translation: pts[0]))
        }
        // Glass sphere and thin inner shell for depth.
        m.add(Self.sphere(radius, segments: segments, material: glass), Xform(translation: V3(0, yc, 0)))
        m.add(Self.sphere(radius * 0.93, segments: segments, material: "glass.quartz").flipped(), Xform(translation: V3(0, yc, 0)))
        // Nebula: bright core with off-centre lobes of different colors.
        m.add(Self.sphere(0.012, segments: 48, material: coreMaterial), Xform(translation: V3(0, yc, 0)))
        let lobes: [(V3, Float, String)] = [(V3(0.014, 0.008, 0.004), 0.008, "emissive.holo-grid"),
                                           (V3(-0.016, -0.006, 0.01), 0.008, "emissive.signal-orange"),
                                           (V3(0.004, -0.012, -0.015), 0.007, "emissive.amber"),
                                           (V3(-0.006, 0.017, -0.01), 0.006, "emissive.signal-red")]
        for (o, r, mat) in lobes {
            m.add(Self.sphere(r, segments: 32, material: mat), Xform(translation: V3(0, yc, 0) + o))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
