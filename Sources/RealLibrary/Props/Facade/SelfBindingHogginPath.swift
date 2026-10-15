import simd
import Foundation

/// Self-binding hoggin path, 2 x 2 m: a crowned, rolled clay-bound buff gravel path 1.6 m wide running
/// along Z between flat steel edging strips on pins, with grass verges either side. Loose grit and flint
/// chips lie on the surface, larger flints are rolled in, and a barrow rut holds a skim of rainwater.
public struct SelfBindingHogginPath: RealAsset {
    public static let id = "self-binding-hoggin-path"
    public static let summary = "Self-binding hoggin path, 2 x 2 m: crowned, rolled buff hoggin with loose grit and flints between pinned steel edging strips and grass verges."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y height, z length).
    public var size = V3(2.0, 0.1, 2.0)
    /// Path width between the edging strips (m).
    public var pathWidth: Float = 1.6
    /// Crown rise at the centre line (m).
    public var crown: Float = 0.012
    /// Bound hoggin surface.
    public var hoggin: MaterialKey = "ground.gravel:C9B38A"
    /// Loose grit tones.
    public var gritKeys: [MaterialKey] = ["rock.limestone:C9B08A", "rock.limestone:B39468", "rock.river:A88E6A", "rock.limestone:DCCBAA"]
    /// Edging strip material.
    public var steel: MaterialKey = "metal.rust:5A4636"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = pathWidth / 2, hd = size.z / 2, base: Float = 0.05
        let rutX = rng.float(0.2...0.4), ph = rng.float(0...6.28)
        func rut(_ p: V2) -> Float { -0.012 * exp(-pow((p.x - rutX - 0.02 * sin(p.y * 2 + ph)) / 0.05, 2)) }
        func h(_ p: V2) -> Float {
            crown * (1 - pow(p.x / hw, 2)) + rut(p) + 0.0025 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: 11)
        }
        var path = Model(name: "path")
        GTK.field(&path, w: pathWidth, d: size.z, edge: base, nx: 40, nz: 50, hoggin, uvScale: 4, bump: h)
        m.add(path)
        // Rainwater in the deepest stretch of the rut.
        GK.poly(&m, (0..<14).map { k in let a = Float(k) / 14 * 2 * .pi; return V2(rutX + 0.02 * sin(-0.3 * 2 + ph) + cos(a) * 0.032 * (1 + 0.15 * sin(a * 3)), -0.3 + sin(a) * 0.26) },
                top: base + crown * (1 - pow(rutX / hw, 2)) - 0.0105, "ground.puddle:8A8270", thick: 0.0015)
        // Grass verges outside the steel edging.
        let vw = (size.x - pathWidth) / 2 - 0.004
        var lite = m
        for s: Float in [-1, 1] {
            var v = Model(name: "verge")
            GTK.field(&v, w: vw, d: size.z, edge: base + 0.004, nx: 3, nz: 12, "turf.worn:5E7A3A", uvScale: 1.5) { p in 0.004 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), seed: 3) }
            for var sf in v.surfaces { sf.positions = sf.positions.map { $0 + V3(s * (hw + 0.004 + vw / 2), 0, 0) }; m.add(sf); lite.add(sf) }
            // Steel edging strip, 4 mm, top 5 mm proud, pinned every 0.5 m.
            let sh = base + 0.012
            let strip = Prim.roundedBox(V3(0.004, sh, size.z - 0.002), radius: 0.0012, bevelSegments: 1, material: steel)
            m.add(strip, Xform(translation: V3(s * (hw + 0.002), sh / 2, 0))); lite.add(strip, Xform(translation: V3(s * (hw + 0.002), sh / 2, 0)))
            for k in 0..<4 {
                let z = -hd + 0.25 + Float(k) * 0.5
                rivet(&m, at: V3(s * (hw + 0.004), base - 0.02, z), normal: V3(s, 0, 0), radius: 0.006, height: 0.002, material: "metal.rust:4A3A2C")
            }
            // Grass blades leaning over the strip.
            var bl = Surface(material: "plant.stem:5E8A34")
            for k in 0..<120 {
                var r = rng.fork(3000 + k + (s > 0 ? 5000 : 0))
                let x = s * (hw + 0.008 + pow(r.float(), 0.7) * (vw - 0.012)), z = r.float(-hd + 0.01...hd - 0.01)
                let lean = V3(-s * r.float(0...0.02), 0, r.float(-0.012...0.012))
                bl.append(GTK.blade(V3(x, base + 0.003, z), height: r.float(0.02...0.045), lean: lean, width: 0.0018,
                                    material: "plant.stem:5E8A34"))
            }
            m.add(bl)
        }
        // Loose grit and chips, more toward the margins, few in the trafficked centre.
        GTK.stones(&m, &rng, count: 260, hx: hw - 0.01, hz: hd - 0.01, size: 0.006...0.014, flat: 0.4...0.65, keys: gritKeys,
                   exponent: 3, sink: 0.4, surface: { base + h($0) }, keep: { p in abs(p.x) > 0.15 || (sin(p.x * 127.1 + p.y * 311.7) * 43758.5).truncatingRemainder(dividingBy: 1) > 0.5 })
        // Larger flints rolled into the binder.
        GTK.stones(&m, &rng, count: 24, hx: hw - 0.03, hz: hd - 0.03, size: 0.018...0.04, flat: 0.35...0.55,
                   keys: ["rock.limestone:8A8478", "rock.limestone:D8D0C0", "rock.river:6E665C"], subdivisions: 2, exponent: 3, sink: 0.6,
                   surface: { base + h($0) })
        return GTK.finish(&m, &lite)
    }
}
