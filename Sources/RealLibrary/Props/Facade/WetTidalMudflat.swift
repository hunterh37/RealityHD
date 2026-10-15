import simd
import Foundation

/// Wet tidal mudflat tile, 2 x 2 m: glossy estuarine silt with wave ripple marks, a meandering ebb
/// runnel holding seawater, shallow pools in the ripple troughs, lugworm casts and blow holes,
/// cockle and mussel shells and strands of wrack weed.
public struct WetTidalMudflat: RealAsset {
    public static let id = "wet-tidal-mudflat"
    public static let summary = "Tidal mudflat tile 2 x 2 m: rippled wet silt, ebb runnel with seawater, lugworm casts, shells and wrack."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Silt slab height at the border (m).
    public var base: Float = 0.08
    /// Ripple wavelength (m).
    public var ripple: Float = 0.08
    /// Mud material.
    public var mud: MaterialKey = "ground.mud:5A5044"
    /// Seawater material.
    public var water: MaterialKey = "water.puddle"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func runnel(_ x: Float) -> Float { 0.15 + 0.22 * sin(x * 1.7 + 0.4) }
        func bump(_ p: V2) -> Float {
            let warp = 0.09 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 2, seed: sd)
            let ph = (p.x + p.y * 0.25 + warp) / ripple * 2 * .pi
            // Asymmetric current ripples: steep lee face.
            let amp = 0.0035 * (0.6 + 0.4 * Noise.fbm(V3(p.x * 1.5, 0, p.y * 1.5), octaves: 2, seed: sd + 4))
            let rip = amp * (sin(ph) + 0.3 * sin(2 * ph)) + 0.0012 * sin((p.y - p.x * 0.3) / 0.11 * 2 * .pi)
            var h = rip + 0.008 * Noise.fbm(V3(p.x * 2.5, 0, p.y * 2.5), octaves: 3, seed: sd + 1)
            let t = (p.y - runnel(p.x)) / 0.12
            h -= 0.028 * exp(-t * t)
            h *= 1 - 0.7 * exp(-t * t)
            return h
        }
        func hgt(_ p: V2) -> Float { LGK.height(p, w: w, d: d, edge: base, bump) }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: base, segments: 60, mud, bump: bump)
        m.add(Prim.terrain(size: V2(w - 0.13, d - 0.13), segments: 4, material: water) { _ in base - 0.003 })
        // Lugworm casts: coiled sand ropes, each with a blow hole nearby.
        for i in 0..<16 {
            var r = rng.fork(100 + i)
            let c = V2(r.float(-0.85...0.85), r.float(-0.85...0.85))
            guard abs(c.y - runnel(c.x)) > 0.15 else { continue }
            let y = hgt(c)
            for k in 0..<9 {
                let a = Float(k) * 0.9, rr = 0.012 + Float(k) * 0.002
                let q = c + V2(cos(a), sin(a)) * rr
                m.add(LGK.metric(Prim.superellipsoid(V3(0.007, 0.006, 0.007), exponent: 2, subdivisions: 1, material: "ground.sand:6E6252")),
                      Xform(translation: V3(q.x, y + 0.002 + Float(9 - k) * 0.0012, q.y)))
            }
            let hole = c + V2(r.float(-0.1...0.1), r.float(0.06...0.12))
            m.add(Prim.lathe([V2(0.0001, -0.006), V2(0.006, -0.001), V2(0.011, 0.001), V2(0.015, 0)], segments: 12, material: mud),
                  Xform(translation: V3(hole.x, hgt(hole), hole.y)))
        }
        // Cockle and mussel shells.
        for i in 0..<20 {
            var r = rng.fork(400 + i)
            let p = V2(r.float(-0.9...0.9), r.float(-0.9...0.9))
            let cockle = r.chance(0.55)
            let s: Float = cockle ? r.float(0.018...0.028) : r.float(0.03...0.05)
            let mat: MaterialKey = cockle ? "stone.marble:D8CDB8" : "rock.slate:1E2230"
            m.add(Prim.superellipsoid(cockle ? V3(s, s * 0.45, s * 0.95) : V3(s, s * 0.28, s * 0.45), exponent: 2.2, subdivisions: 2, material: mat),
                  Xform(translation: V3(p.x, hgt(p) - 0.001, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        // Bladder wrack strands draped on the silt.
        for i in 0..<5 {
            var r = rng.fork(700 + i)
            var p = V2(r.float(-0.75...0.75), r.float(-0.75...0.75))
            var yaw = r.float(0...(2 * .pi))
            for _ in 0..<7 {
                let q = p + V2(cos(yaw), sin(yaw)) * 0.04
                m.add(Prim.roundedBox(V3(0.045, 0.004, 0.016), radius: 0.0018, bevelSegments: 1, material: "moss.cushion:4A4320"),
                      Xform(translation: V3((p.x + q.x) / 2, hgt((p + q) / 2) + 0.001, (p.y + q.y) / 2), rotation: simd_quatf(angle: -yaw, axis: .up)))
                p = q; yaw += r.float(-0.5...0.5)
            }
        }
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: base, segments: 30, mud, bump: bump)
        return LGK.finish(&m, lite: lite, ao: 0.02)
    }
}
