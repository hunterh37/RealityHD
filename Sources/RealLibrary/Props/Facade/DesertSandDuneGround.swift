import simd
import Foundation

/// Desert sand dune ground tile, 2 x 2 m: the toe of a barchan dune rising from a gravel-lag
/// interdune flat to a sharp crest 0.33 m high, with wind ripples on the gentle stoss slope, a steep
/// avalanche slip face on the lee, a dry desert grass tuft and a line of small animal tracks.
public struct DesertSandDuneGround: RealAsset {
    public static let id = "desert-sand-dune-ground"
    public static let summary = "Desert sand dune ground tile, 2 x 2 m: a low dune crest with steep slip face, wind ripples on the stoss slope and a dry grass tuft."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.4, 2.0)
    /// Crest height above the interdune flat (m).
    public var crestHeight: Float = 0.34
    /// Ripple spacing (m) and height (m).
    public var rippleSpacing: Float = 0.07
    public var rippleHeight: Float = 0.006
    /// Dune sand.
    public var sand: MaterialKey = "ground.sand:D2A26A"
    /// Coarser, darker interdune sand.
    public var flatSand: MaterialKey = "ground.sand:B48A5C"
    /// Dry grass.
    public var grass: MaterialKey = "grass.dry"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, base: Float = 0.05, H = crestHeight
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000)), ph = rng.float(0...6.28)
        // Crest line runs along X, curving into a barchan horn; stoss rises from -z, slip face falls to +z.
        func crestZ(_ x: Float) -> Float { 0.3 - 0.22 * x * x + 0.03 * sin(x * 2.3 + ph) }
        func window(_ v: Float, _ half: Float) -> Float { let k = max(0, min(1, (half - abs(v)) / 0.35)); return k * k * (3 - 2 * k) }
        func dune(_ p: V2) -> Float {
            let cz = crestZ(p.x), d = p.y - cz
            let hgt = H * (0.85 + 0.15 * cos(p.x * 1.4))
            let s: Float
            if d < 0 { let u = max(0, 1 + d / 1.05); s = u * u * (1.6 - 0.6 * u) }   // stoss: gentle, convex near the crest
            else { let u = max(0, 1 - d / 0.42); s = pow(u, 1.15) }                 // slip face ~34 degrees
            return hgt * s * window(p.x, hx) * window(p.y, hz)
        }
        func ripples(_ p: V2) -> Float {
            let d = p.y - crestZ(p.x)
            guard d < -0.04 else { return 0 }
            let phase = (p.y + 0.05 * sin(p.x * 3.1 + ph)) / rippleSpacing
            let f = phase - floor(phase)
            let prof = f < 0.7 ? f / 0.7 : (1 - f) / 0.3
            return rippleHeight * (prof - 0.5) * min(1, -d / 0.15) * (0.4 + 0.6 * dune(p) / H + 0.3)
        }
        let tracks = (0..<12).map { k -> V2 in
            let t = Float(k) / 11
            return V2(-0.85 + t * 1.2 + (k % 2 == 0 ? 0.012 : -0.012), -0.75 + 0.35 * t + 0.08 * sin(t * 5))
        }
        func h(_ p: V2) -> Float {
            var v = dune(p) + ripples(p) + 0.004 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 2, seed: sd)
            for c in tracks { v -= 0.011 * exp(-simd_length_squared(p - c) / (0.012 * 0.012)) }
            return v
        }
        GTK.field(&m, w: size.x, d: size.z, edge: base, nx: 48, nz: 96, sand, uvScale: 1, bump: h)
        // Interdune flat: darker coarse sand film where the dune thins out.
        m.add(Prim.terrain(size: V2(size.x - 0.12, 0.5), segments: 20, material: flatSand) { q in
            let p = q + V2(0, -0.68)
            return base + h(p) + 0.0008 - 0.03 * min(1, max(0, dune(p) / 0.02 - 0.2))
        }, Xform(translation: V3(0, 0, -0.68)))
        var lite = m
        // Gravel lag on the interdune flat.
        GTK.stones(&m, &rng, count: 50, hx: hx - 0.08, hz: 0.25, size: 0.02...0.05, flat: 0.5...0.75,
                   keys: ["rock.river:8A6A50", "rock.river:6A5446", "rock.river:A08468", "rock.river:4E4038"], subdivisions: 1, exponent: 2.3, sink: 0.4,
                   offset: V3(0, 0, -0.68), surface: { base + h($0 + V2(0, -0.68)) }, keep: { dune($0 + V2(0, -0.68)) < 0.02 })
        // Animal tracks: paired paw dimples, damp-dark where they broke the crust.
        for (k, c) in tracks.enumerated() {
            let yaw: Float = 0.3
            GK.poly(&m, (0..<8).map { i in let a = Float(i) / 8 * 2 * .pi; return c + V2(cos(a + yaw) * 0.014, sin(a + yaw) * 0.019) },
                    top: base + h(c) - 0.002, k % 3 == 0 ? flatSand : "ground.sand:BF905E", thick: 0.0015)
        }
        // Sun-bleached twig blown onto the flat.
        let t0 = V2(-0.35, -0.82), t1 = V2(0.05, -0.7)
        var twig = Prim.tube([V3(t0.x, base + h(t0) + 0.004, t0.y), V3((t0.x + t1.x) / 2, base + h((t0 + t1) / 2) + 0.006, (t0.y + t1.y) / 2 + 0.02), V3(t1.x, base + h(t1) + 0.003, t1.y)],
                             radii: [0.007, 0.006, 0.003], sides: 7, seamTile: 0.08, material: "wood.deadwood:B8AE9C")
        twig.uvs = twig.uvs.map { V2($0.y, $0.x) }; twig.computeTangents()
        m.add(twig)
        // Dry desert grass tuft on the stoss slope, a small sand shadow behind it.
        let tc = V2(0.5, -0.25)
        var tuft = Surface(material: grass)
        for k in 0..<70 {
            var r = rng.fork(300 + k)
            let a = r.float(0...6.28), rad = pow(r.float(), 0.7) * 0.07
            let p = tc + V2(cos(a), sin(a)) * rad
            tuft.append(GTK.blade(V3(p.x, base + h(p) - 0.006, p.y), height: r.float(0.08...0.16),
                                  lean: V3(cos(a), 0, sin(a)) * r.float(0.02...0.07), width: 0.0016, material: grass))
        }
        m.add(tuft)
        m.add(Prim.superellipsoid(V3(0.16, 0.03, 0.3), exponent: 2, subdivisions: 4, material: sand),
              Xform(translation: V3(tc.x, base + h(tc + V2(0, 0.15)) - 0.012, tc.y + 0.15)))
        // Slip-face avalanche lobes: low tongues of sand at the toe.
        for k in 0..<5 {
            var r = rng.fork(600 + k)
            let x = -0.7 + Float(k) * 0.35 + r.float(-0.08...0.08), z = crestZ(x) + 0.4
            guard abs(z) < hz - 0.12 else { continue }
            m.add(Prim.superellipsoid(V3(r.float(0.12...0.2), 0.02, r.float(0.14...0.22)), exponent: 2, subdivisions: 3, material: sand),
                  Xform(translation: V3(x, base + h(V2(x, z)) - 0.01, z)))
        }
        return GTK.finish(&m, &lite, ao: 0.015, switchAt: 8)
    }
}
