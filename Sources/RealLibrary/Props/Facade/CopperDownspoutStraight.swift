import simd
import Foundation

/// Copper downspout: architectural facade customizer, Georgian, copper round downspout with wall straps, joints and patina. Parts: round tube, wall straps, sleeve joints, top collar, bottom shoe, fasteners.
public struct CopperDownspoutStraight: RealAsset {
    public static let id = "copper-downspout-straight"
    public static let summary = "Copper downspout, 0.1 x 3.0 x 0.1 m: round copper tube with straps, sleeve joints and patina."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Tube radius in meters.
    public var radius: Float = 0.034
    /// Strap heights above the floor in meters.
    public var strapHeights: [Float] = [0.42, 1.0, 1.55, 2.1, 2.6]
    /// Tube metal.
    public var copper: MaterialKey = "metal.copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pat: MaterialKey = "metal.copper-patina", brass: MaterialKey = "metal.brass-aged", zinc: MaterialKey = "metal.screw-zinc", sol: MaterialKey = "metal.solder"
        let R = radius, zc: Float = 0.043
        let at = Xform(translation: V3(0, 0, zc))
        // Tube with a flared top collar and a kicked shoe at the foot.
        m.add(Prim.lathe([V2(R - 0.0012, 0.1), V2(R, 0.1), V2(R, 2.9), V2(R + 0.004, 2.92), V2(R + 0.012, 2.965), V2(R + 0.014, 3.0), V2(R + 0.0125, 3.0), V2(R + 0.0105, 2.97), V2(R - 0.0012, 2.92)], segments: 28, seamTile: 0.3, material: copper), at)
        m.add(Prim.torus(major: R + 0.0138, minor: 0.0019, segments: 28, sides: 6, material: brass), Xform(translation: V3(0, 2.998, zc)))
        // Shoe: short bend kicking out from the wall.
        FA.path(&m, [V3(0, 0.12, zc), V3(0, 0.07, zc + 0.002), V3(0, 0.035, zc + 0.012), V3(0, 0.018, zc + 0.018)], r: R - 0.002, copper, sides: 20)
        m.add(Prim.torus(major: R, minor: 0.002, segments: 28, sides: 6, material: brass), Xform(translation: V3(0, 0.1, zc)))
        // Lock seam running up the tube front-right, soldered.
        let sa: Float = 0.6
        FA.rod(&m, V3(R * sin(sa), 0.1, zc + R * cos(sa)), V3(R * sin(sa), 2.9, zc + R * cos(sa)), r: 0.0018, sol, sides: 5)
        // Slip-sleeve joints with soldered bead rings and rivets.
        for y: Float in [1.28, 2.33] {
            m.add(Prim.lathe([V2(R - 0.001, y - 0.035), V2(R + 0.0038, y - 0.035), V2(R + 0.0038, y + 0.035), V2(R - 0.001, y + 0.035)], segments: 28, seamTile: 0.3, material: copper), at)
            for d: Float in [-0.035, 0.035] { m.add(Prim.torus(major: R + 0.0038, minor: 0.0016, segments: 28, sides: 5, material: sol), Xform(translation: V3(0, y + d, zc))) }
            for k in 0..<6 {
                let a = Float(k) / 6 * 2 * .pi + 0.3
                m.add(Prim.superellipsoid(V3(0.0035, 0.0035, 0.0035), exponent: 2, subdivisions: 3, material: brass), Xform(translation: V3((R + 0.0042) * sin(a), y, zc + (R + 0.0042) * cos(a))))
            }
        }
        // Wall straps: ear bands on spacers screwed to the wall.
        for (i, y) in strapHeights.enumerated() {
            m.add(Prim.lathe([V2(R, y - 0.012), V2(R + 0.0032, y - 0.012), V2(R + 0.0032, y + 0.012), V2(R, y + 0.012)], segments: 28, seamTile: 0.2, material: i % 2 == 0 ? brass : "metal.painted:2E2A26"), at)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.016, 0.024, 0.0035), V3(s * (R + 0.0098), y, 0.0018 + 0.0), brass, r: 0.0007)
                FA.box(&m, V3(0.012, 0.0035, zc - 0.0035), V3(s * (R + 0.003), y, (zc + 0.0035) / 2), brass, r: 0.0007)
                FA.cylZ(&m, r: 0.0042, h: 0.0028, at: V3(s * (R + 0.0098), y, -0.001), (i + (s > 0 ? 1 : 0)) % 4 == 3 ? pat : zinc, bevel: 0.0007, segments: 8)
            }
        }
        // Patina: green bloom under the collar, at joints and heavy at the foot, plus runs.
        for (y, h) in [(Float(2.82), Float(0.14)), (1.28, 0.04), (2.33, 0.04), (0.2, 0.2), (0.62, 0.05)] {
            m.add(Prim.lathe([V2(R + 0.0003, y - h / 2), V2(R + 0.0013, y - h / 2 + 0.01), V2(R + 0.0013, y + h / 2 - 0.01), V2(R + 0.0003, y + h / 2)], segments: 28, seamTile: 0.3, material: pat), at)
        }
        for _ in 0..<5 {
            let a = rng.float(0...6.28), y = rng.float(0.5...2.7)
            FA.box(&m, V3(0.008, rng.float(0.1...0.3), 0.0012), V3((R + 0.0016) * sin(a), y, zc + (R + 0.0016) * cos(a)), pat, r: 0.0003, rot: FA.q(a * 180 / .pi, FA.Y))
        }
        // Round 1: cast splash block under the shoe, bolted shoe flange, offset elbow ears, hanger bolts, dent and drip stains.
        m.add(Prim.roundedBox(V3(0.096, 0.03, 0.095), radius: 0.005, bevelSegments: 2, material: "stone.cast-stone"), Xform(translation: V3(0, 0.0, zc + 0.012)))
        m.add(Prim.torus(major: R - 0.002, minor: 0.0025, segments: 20, sides: 6, material: brass), Xform(translation: V3(0, 0.13, zc), rotation: simd_quatf(degrees: 0, axis: FA.Y)))
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.01, 0.14, 0.005), V3(s * (R + 0.012), 2.88, 0.002), brass, r: 0.001)
            FA.cylZ(&m, r: 0.006, h: 0.004, at: V3(s * (R + 0.012), 2.92, -0.001), zinc, bevel: 0.001, segments: 8)
            FA.cylZ(&m, r: 0.006, h: 0.004, at: V3(s * (R + 0.012), 2.84, -0.001), zinc, bevel: 0.001, segments: 8)
        }
        for y: Float in [0.28, 1.05, 1.9] {
            FA.box(&m, V3(0.05, 0.1, 0.002), V3(0, y, zc + R + 0.0012), pat, r: 0.0006)
        }
        m.add(Prim.superellipsoid(V3(0.05, 0.07, 0.01), exponent: 2, subdivisions: 8, material: copper), Xform(translation: V3(-0.02, 0.78, zc + R - 0.004), rotation: FA.q(20, FA.Z)))
        for _ in 0..<4 {
            FA.box(&m, V3(0.004, rng.float(0.2...0.5), 0.0012), V3(rng.float(-0.025...0.025), rng.float(0.3...1.4), zc + R + 0.0018), "metal.rust-grime", r: 0.0003)
        }
        // Round 2: verdigris sleeves at strap contact points, bloom ring bands, curved patina runs, wider collar bloom.
        for y in strapHeights {
            m.add(Prim.lathe([V2(R + 0.0003, y - 0.05), V2(R + 0.0011, y - 0.04), V2(R + 0.0011, y + 0.04), V2(R + 0.0003, y + 0.05)], segments: 28, seamTile: 0.3, material: pat), at)
        }
        for (y, h) in [(Float(2.55), Float(0.3)), (1.7, 0.2), (0.95, 0.25), (0.4, 0.3)] {
            m.add(Prim.lathe([V2(R + 0.0003, y - h / 2), V2(R + 0.0009, y - h / 2 + 0.02), V2(R + 0.0009, y + h / 2 - 0.02), V2(R + 0.0003, y + h / 2)], segments: 28, seamTile: 0.5, material: "metal.copper-patina:5E9C86"), at)
        }
        for k in 0..<8 {
            let a = Float(k) * 0.8 + 0.2, y = rng.float(0.3...2.7)
            FA.box(&m, V3(rng.float(0.006...0.014), rng.float(0.25...0.6), 0.0012), V3((R + 0.0016) * sin(a), y, zc + (R + 0.0016) * cos(a)), pat, r: 0.0003, rot: FA.q(a * 180 / .pi, FA.Y))
        }
        FA.box(&m, V3(0.006, 0.4, 0.002), V3(R * sin(0.6) + 0.004, 0.5, zc + R * cos(0.6) + 0.0006), sol, r: 0.0004)
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
