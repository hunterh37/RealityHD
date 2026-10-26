import simd
import Foundation

/// Cast iron hitching post: architectural facade customizer, Victorian. Stepped base, tapered shaft with
/// collar mouldings, a hitching ring on a lug and an acorn finial, with paint chipped to rust at the foot.
public struct CastIronHitchingPost: RealAsset {
    public static let id = "cast-iron-hitching-post"
    public static let summary = "Cast iron hitching post 1.0 m: stepped base, tapered shaft with collar mouldings, a hitching ring on a lug and an acorn finial."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 2.2)

    /// Painted iron on the upper post.
    public var paint: MaterialKey = "metal.wrought-iron"
    /// Weathered cast iron on the lower post.
    public var castIron: MaterialKey = "metal.cast-iron-street"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Lower casting: stepped plinth, flared base with flutes, and the start of the shaft.
        let lower: [V2] = [V2(0, 0), V2(0.1, 0), V2(0.1, 0.016), V2(0.093, 0.022), V2(0.099, 0.03), V2(0.099, 0.042), V2(0.085, 0.05), V2(0.072, 0.07),
                           V2(0.062, 0.12), V2(0.056, 0.2), V2(0.053, 0.3), V2(0.051, 0.4), V2(0, 0.4)]
        FE.turnDisp(&m, lower, castIron, segments: 72) { p in
            // Eight shallow flutes around the flared base only.
            if p.y < 0.06 || p.y > 0.3 { return 0 }
            let a = atan2(p.z, p.x)
            return -0.0035 * (0.5 + 0.5 * cos(8 * a)) * min(1, (p.y - 0.06) / 0.04)
        }
        let upper: [V2] = [V2(0, 0.4), V2(0.051, 0.4), V2(0.05, 0.5), V2(0.047, 0.6), V2(0.046, 0.65), V2(0.058, 0.655), V2(0.064, 0.665), V2(0.058, 0.675), V2(0.05, 0.68),
                           V2(0.05, 0.69), V2(0.062, 0.7), V2(0.066, 0.712), V2(0.056, 0.722), V2(0.045, 0.728), V2(0.043, 0.75), V2(0.052, 0.77), V2(0.066, 0.8), V2(0.074, 0.84),
                           V2(0.07, 0.88), V2(0.056, 0.925), V2(0.034, 0.96), V2(0.016, 0.985), V2(0.007, 1.0), V2(0, 1.0)]
        FE.turnDisp(&m, upper, paint, segments: 72) { p in
            // Acorn cap texture: shallow diamond scales on the finial.
            if p.y < 0.86 || p.y > 0.99 { return 0 }
            let a = atan2(p.z, p.x)
            return -0.0018 * abs(sin(10 * a) * sin(70 * p.y))
        }
        // Chipped paint at the collar edges: rust flecks.
        for k in 0..<10 {
            let a = Float(k) * 0.63 + rng.float(0...0.3)
            let y: Float = k % 2 == 0 ? 0.665 : 0.712
            let r: Float = k % 2 == 0 ? 0.064 : 0.066
            FA.box(&m, V3(0.014, 0.008, 0.006), V3((r + 0.0005) * cos(a), y, (r + 0.0005) * sin(a)), "metal.rust", r: 0.002, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        // Hitching ring: cast lug on the shaft and a hanging ring through it.
        FA.box(&m, V3(0.034, 0.04, 0.022), V3(0.055, 0.52, 0), castIron, r: 0.005)
        FA.cylZ(&m, r: 0.009, h: 0.03, at: V3(0.066, 0.52, -0.015), castIron, bevel: 0.002, segments: 12)
        m.add(Prim.torus(major: 0.031, minor: 0.007, segments: 32, sides: 10, material: "metal.wrought-iron"),
              Xform(translation: V3(0.067, 0.482, 0), rotation: FA.q(90, FA.X)))
        // Rust streaks running down the shaft from the collars, the lug and the upper casting joint.
        for k in 0..<9 {
            let a = Float(k) * 0.7 + rng.float(0...0.3)
            let hgt = rng.float(0.05...0.16), top: Float = k % 3 == 0 ? 0.52 : (k % 3 == 1 ? 0.645 : 0.42)
            let r: Float = 0.0505 - (top - 0.4) * 0.01
            FA.box(&m, V3(rng.float(0.008...0.016), hgt, 0.0012), V3((r + 0.0004) * cos(a), top - hgt / 2, (r + 0.0004) * sin(a)), "metal.rust", r: 0.0004, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        // Founder's brass plate on the plinth.
        FA.box(&m, V3(0.006, 0.026, 0.05), V3(-0.0995, 0.028, 0), "metal.brass-aged", r: 0.001)
        // Rust bloom and mortar at the foot.
        FE.stain(&m, V3(0, 0.0185, 0), w: 0.17, d: 0.17, "metal.rust")
        m = FE.seat(m)
        groundAO(&m, height: 0.08, floor: 0.6)
        return LODModel(m)
    }
}
