import simd
import Foundation

/// Rippled beach sand, 2 x 2 m: a slab of dune-foot sand with wind ripples (asymmetric crests ~8 cm
/// apart, bending around a damp hollow), scattered cockle and razor shells, beach pebbles, a bleached
/// driftwood stick with a strand of wrack caught on it, a marram tuft and a single footprint.
public struct RippledBeachSand: RealAsset {
    public static let id = "rippled-beach-sand"
    public static let summary = "Rippled beach sand, 2 x 2 m: wind ripple-marked sand slab with damp low patch, scattered shells, pebbles, driftwood stick and marram tufts."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y height incl. tuft, z depth).
    public var size = V3(2.0, 0.15, 2.0)
    /// Ripple wavelength (m) and height (m).
    public var rippleSpacing: Float = 0.08
    public var rippleHeight: Float = 0.007
    /// Dry and damp sand.
    public var sand: MaterialKey = "ground.sand:C9B38C"
    public var dampSand: MaterialKey = "ground.sand:A69070"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, base: Float = 0.06
        let hollow = V2(rng.float(0.2...0.45), rng.float(-0.5...(-0.2))), ph = rng.float(0...6.28)
        let foot = V2(rng.float(-0.5...(-0.2)), rng.float(0.1...0.4))
        func hollowK(_ p: V2) -> Float { exp(-pow(simd_length((p - hollow) * V2(1, 1.5)) / 0.28, 2)) }
        func h(_ p: V2) -> Float {
            // Crest line bends with a slow wobble; asymmetric profile (gentle stoss, steep lee).
            let phase = (p.y + 0.06 * sin(p.x * 2.1 + ph) + 0.02 * sin(p.x * 7)) / rippleSpacing
            let f = phase - floor(phase)
            let prof = f < 0.72 ? f / 0.72 : (1 - f) / 0.28
            let ripple = rippleHeight * (smoothstep(0, 1, prof) - 0.5) * (1 - 0.85 * hollowK(p))
            let heel = -0.012 * exp(-pow((p.x - foot.x) / 0.045, 2) - pow((p.y - foot.y + 0.07) / 0.05, 2))
            let toe = -0.010 * exp(-pow((p.x - foot.x) / 0.05, 2) - pow((p.y - foot.y - 0.07) / 0.07, 2))
            return ripple - 0.018 * hollowK(p) + heel + toe + 0.006 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 2, seed: 4)
        }
        GTK.field(&m, w: size.x, d: size.z, edge: base, nx: 26, nz: 120, sand, uvScale: 1, bump: h)
        // Damp sand lining the hollow, following its floor.
        m.add(Prim.terrain(size: V2(0.6, 0.45), segments: 14, material: dampSand) { q in
            let p = q + hollow
            return base + h(p) + 0.0012 - 0.02 * max(0, 1 - hollowK(p) * 2.2 + 0.35 * Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 3, seed: 31))
        }, Xform(translation: V3(hollow.x, 0, hollow.y)))
        var lite = m
        // Pebbles and shells.
        GTK.stones(&m, &rng, count: 30, hx: hx - 0.05, hz: hx - 0.05, size: 0.012...0.035, flat: 0.45...0.65,
                   keys: ["rock.river:8A847C", "rock.river:5E5A56", "rock.river:A89C8C"], subdivisions: 1, exponent: 2.2, sink: 0.45,
                   surface: { base + h($0) })
        var shells = Surface(material: "stone.limestone:EDE2CE"), dark = Surface(material: "stone.limestone:8C7A6C")
        for k in 0..<28 {
            var r = rng.fork(100 + k)
            let p = V2(r.float(-0.92...0.92), r.float(-0.92...0.92))
            let y = base + h(p)
            if r.chance(0.8) {
                // Cockle: ribbed half dome, some upside-down.
                let rad = r.float(0.012...0.022), ss = r.int(0...1000)
                var c = Prim.superellipsoid(V3(rad * 2, rad * 0.9, rad * 1.8), exponent: 2, subdivisions: 3, material: shells.material) { d in
                    1 + 0.06 * sin(atan2(d.z, d.x) * 18 + Float(ss))
                }
                c.positions = c.positions.map { V3($0.x, max(0, $0.y), $0.z) }
                c.recomputeNormals(weldSeams: true)
                GTK.normalizeTexel(&c)
                let flip = r.chance(0.35)
                let xf = Xform(translation: V3(p.x, y - 0.002, p.y),
                    rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: flip ? 180 : r.float(-10...10), axis: V3(1, 0, 0)))
                if r.chance(0.3) { dark.append(c, xf) } else { shells.append(c, xf) }
            } else {
                // Razor shell: long thin tube section.
                let len = r.float(0.08...0.13)
                var s = Prim.superellipsoid(V3(len, 0.006, 0.016), exponent: 3, subdivisions: 4, material: shells.material)
                GTK.normalizeTexel(&s)
                dark.append(s, Xform(translation: V3(p.x, y + 0.001, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
            }
        }
        m.add(shells); m.add(dark)
        // Driftwood stick, silver and checked, half sunk; wrack strands draped over it.
        let a = V3(-0.55, base + 0.004, -0.35), b = V3(0.15, base + 0.01, -0.62)
        let mid = (a + b) / 2 + V3(0.02, 0.008, 0.05)
        var drift = Prim.tube([a, mid, b], radii: [0.022, 0.026, 0.016], sides: 12, seamTile: 0.15, material: "wood.deadwood:B4ADA2")
        drift.uvs = drift.uvs.map { V2($0.y, $0.x) }; drift.computeTangents()
        m.add(drift); lite.add(drift)
        for k in 0..<4 {
            var r = rng.fork(300 + k)
            // Wrack ribbon lying on the sand, one end draped over the stick.
            let start = a + (b - a) * r.float(0.25...0.75)
            let dir = simd_normalize(V3(r.float(-1...1), 0, r.float(0.4...1)))
            let pts = (0..<9).map { i -> V3 in
                let u = Float(i) / 8
                let q = start + dir * (u * 0.28) + V3(0.015 * sin(u * 9 + Float(k)), 0, 0)
                let ground = base + h(V2(q.x, q.z)) + 0.002
                return V3(q.x, i == 0 ? start.y + 0.024 : max(ground, start.y + 0.024 - u * 0.25), q.z)
            }
            m.add(Prim.tube(pts, radii: [0.004, 0.005, 0.005, 0.005, 0.005, 0.004, 0.004, 0.003, 0.002], sides: 5, seamTile: 0.05, material: "plastic.matte:3A3418"))
        }
        // Marram tuft near the back edge.
        var marram = Surface(material: "plant.stem:9AA06A")
        let tc = V2(-0.6, 0.7)
        for k in 0..<60 {
            var r = rng.fork(500 + k)
            let ang = r.float(0...6.28), rad = pow(r.float(), 0.6) * 0.09
            let p = tc + V2(cos(ang), sin(ang)) * rad
            let lean = V3(cos(ang), 0, sin(ang)) * r.float(0.01...0.04) + V3(0.02, 0, 0)
            marram.append(GTK.blade(V3(p.x, base + h(p) - 0.004, p.y), height: r.float(0.06...0.095), lean: lean, width: 0.0018,
                                    material: marram.material))
        }
        m.add(marram)
        // Wind-blown sand piled in the lee of the tuft.
        m.add(Prim.superellipsoid(V3(0.3, 0.02, 0.2), exponent: 2, subdivisions: 4, material: sand),
              Xform(translation: V3(tc.x + 0.12, base + h(tc) - 0.004, tc.y)))
        return GTK.finish(&m, &lite)
    }
}
