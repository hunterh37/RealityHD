import simd
import Foundation

/// Muddy earth tile, 2 x 2 m: churned mud slab with two deep wheel ruts along X holding rainwater in
/// long pools, two round puddles in trodden hollows, boot prints with squeezed-up rims, pressed
/// stones and a darker wet ring around every pool. Edges fall to a skirt so tiles butt together.
public struct MuddyPuddledDirt: RealAsset {
    public static let id = "muddy-puddled-dirt"
    public static let summary = "Muddy earth tile 2 x 2 m: churned mud with water-filled ruts and puddles, boot prints and stones."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.12, 2.0)
    /// Slab thickness at the edge (m).
    public var thickness: Float = 0.108
    /// Rut depth (m).
    public var rutDepth: Float = 0.04
    /// Mud material.
    public var mud: MaterialKey = "ground.mud"
    /// Standing water material.
    public var water: MaterialKey = "water.puddle"
    /// Stone material.
    public var stone: MaterialKey = "rock.river-wet"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        let ruts: [Float] = [-0.4, 0.36]
        let hollows: [(V2, Float)] = [(V2(rng.float(-0.5...(-0.2)), rng.float(-0.05...0.08)), 0.2), (V2(rng.float(0.35...0.7), rng.float(-0.9...(-0.7)) * 0.9), 0.16)]
        var prints: [(V2, Float)] = []
        for k in 0..<8 {
            let z = -0.85 + Float(k) * 0.23
            prints.append((V2(0.25 + 0.15 * sin(z * 2) + (k % 2 == 0 ? 0.07 : -0.07), z), .pi / 2 + rng.float(-0.2...0.2)))
        }
        func rutZ(_ i: Int, _ x: Float) -> Float { ruts[i] + 0.035 * sin(x * 1.9 + Float(i) * 2) }
        func bump(_ p: V2) -> Float {
            var h = 0.012 * Noise.fbm(V3(p.x * 2.5, 0, p.y * 2.5), octaves: 4, seed: sd)
                + 0.004 * Noise.ridged(V3(p.x * 11, 0, p.y * 11), octaves: 2, seed: sd + 3)
            for i in 0..<2 {
                let t = (p.y - rutZ(i, p.x)) / 0.07
                h -= rutDepth * exp(-t * t * t * t) * (0.75 + 0.25 * Noise.fbm(V3(p.x * 3, 0, Float(i)), octaves: 2, seed: sd + 5))
                let lip = (abs(t) - 1.5) / 0.5
                h += 0.007 * exp(-lip * lip) * (0.6 + 0.4 * Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 2, seed: sd + 6))
                // Tyre tread chevrons in the rut floor.
                h += 0.002 * sin(p.x * 70 + abs(p.y - rutZ(i, p.x)) * 40) * exp(-t * t)
            }
            for (c, r) in hollows {
                let f = simd_length(p - c) / r
                h -= 0.03 * max(0, 1 - f * f)
            }
            for (c, yaw) in prints {
                let l = V2(cos(yaw) * (p.x - c.x) + sin(yaw) * (p.y - c.y), -sin(yaw) * (p.x - c.x) + cos(yaw) * (p.y - c.y))
                let sole = pow(l.x / 0.14, 2) + pow(l.y / 0.05, 2)
                if sole < 1 { h -= 0.014 * (1 - sole * sole) * (0.7 + 0.3 * sin(l.x * 240)) }
                else if sole < 1.6 { h += 0.004 * sin((sole - 1) / 0.6 * .pi) }
            }
            return h
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: thickness, segments: 64, mud, bump: bump)
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return thickness + bump(p) * k * k * (3 - 2 * k)
        }
        // Water: one sheet at the standing level; the mud field hides it except in ruts and hollows,
        // so shorelines follow the terrain contour exactly.
        let level = thickness - 0.006
        m.add(Prim.terrain(size: V2(w - 0.14, d - 0.14), segments: 4, material: water) { _ in level })
        // Stones pressed into the mud, and a few clods thrown up beside the ruts.
        for k in 0..<45 {
            var r = rng.fork(1000 + k)
            let p = V2(r.float(-0.93...0.93), r.float(-0.93...0.93))
            let sz = r.chance(0.2) ? r.float(0.045...0.07) : r.float(0.018...0.035)
            PBK.stone(&m, at: V3(p.x, height(p) - sz * 0.2, p.y), size: sz, stone, rng: &r)
        }
        for k in 0..<30 {
            var r = rng.fork(2000 + k)
            let i = k % 2, x = r.float(-0.9...0.9)
            let z = rutZ(i, x) + (r.chance(0.5) ? 1 : -1) * r.float(0.1...0.16)
            let s = r.float(0.025...0.05)
            let sdc = UInt32(r.int(0...999))
            m.add(Prim.superellipsoid(V3(s, s * 0.5, s * 0.8), exponent: 2.4, subdivisions: 2, material: mud) { dd in 1 + 0.25 * Noise.fbm(dd * 3, octaves: 2, seed: sdc) },
                  Xform(translation: V3(x, height(V2(x, z)) - s * 0.1, z), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.04, floor: 0.6)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: thickness, segments: 20, mud, bump: bump)
        lite = lite.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
