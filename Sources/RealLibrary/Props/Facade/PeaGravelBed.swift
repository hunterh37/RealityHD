import simd
import Foundation

/// Pea gravel bed, 2 x 2 m: 6-10 mm rounded flint pea shingle laid ~40 mm deep over weed membrane,
/// held by treated timber edging boards on square pegs with screws. Rake lines run across the bed,
/// a boot scuff has pushed the shingle aside to show membrane, and a few dry leaves have blown in.
public struct PeaGravelBed: RealAsset {
    public static let id = "pea-gravel-bed"
    public static let summary = "Pea gravel bed, 2 x 2 m: 6-10 mm rounded flint pea shingle laid 40 mm deep over membrane, retained by treated timber edging boards on pegs."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y edging top, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Edging board thickness (m).
    public var boardThick: Float = 0.025
    /// Loose surface stones modelled individually.
    public var pebbleCount: Int = 340
    /// Shingle tones: buff, grey and rust flint.
    public var pebbleKeys: [MaterialKey] = ["rock.river:B9A88C", "rock.river:9C9488", "rock.river:C7B79A", "rock.river:8E7A62", "rock.river:A89878"]
    /// Bed material under the loose stones.
    public var gravel: MaterialKey = "ground.gravel:B8AA90"
    /// Edging board material.
    public var boardKey: MaterialKey = "wood.weathered:7A6A55"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t = boardThick, w = size.x - 2 * t, d = size.z - 2 * t
        let bed: Float = 0.072, ph = rng.float(0...6.28)
        let scuff = V2(rng.float(-0.4...0.4), rng.float(-0.4...0.4))
        func h(_ p: V2) -> Float {
            let rake = 0.0035 * sin(p.y * 2 * .pi / 0.06 + 0.4 * sin(p.x * 3 + ph))
            let foot = -0.022 * exp(-pow((p.x - scuff.x) / 0.07, 2) - pow((p.y - scuff.y) / 0.13, 2))
            return rake + foot + 0.004 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 2, seed: 7)
        }
        GTK.field(&m, w: w, d: d, edge: bed, nx: 24, nz: 110, gravel, uvScale: 3.5, bump: h)
        // Weed membrane showing in the scuff and lapped up the inside of the boards.
        GK.poly(&m, (0..<12).map { k in let a = Float(k) / 12 * 2 * .pi; return scuff + V2(cos(a) * 0.045, sin(a) * 0.08) },
                top: bed - 0.024, "plastic.matte:1E1E1C", thick: 0.002)
        for s: Float in [-1, 1] {
            GK.box(&m, V3(s * (w / 2 - 0.001), bed + 0.006, 0), V3(0.0015, 0.012, d * 0.96), "plastic.matte:1E1E1C", r: 0.0005)
        }
        var lite = m
        GTK.stones(&m, &rng, count: pebbleCount, hx: w / 2 - 0.006, hz: d / 2 - 0.006, size: 0.010...0.017, keys: pebbleKeys,
                   surface: { bed + h($0) * 0.9 }, keep: { simd_length(($0 - scuff) * V2(1, 0.55)) > 0.06 })
        // Scuffed-out shingle piled at the heel of the scuff.
        GTK.stones(&m, &rng, count: 40, hx: 0.09, hz: 0.06, size: 0.008...0.013, keys: pebbleKeys, sink: 0.1,
                   surface: { _ in bed + 0.006 }, keep: { _ in true })
        GTK.edging(&m, &rng, w: size.x, d: size.z, top: size.y, thick: t, board: boardKey, stake: "wood.weathered:6A5A48", screw: "metal.galvanized-aged")
        for k in 0..<6 {
            var r = rng.fork(800 + k)
            let p = V2(r.float(-0.85...0.85), r.float(-0.85...0.85)), len = r.float(0.07...0.11)
            m.add(Prim.superellipsoid(V3(len, 0.003, len * 0.5), exponent: 2.2, subdivisions: 2, material: "leather.oxblood-worn:6A4424") { d in 1 + 0.4 * d.x * d.x },
                  Xform(translation: V3(p.x, bed + 0.012, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-15...15), axis: V3(1, 0, 0))))
        }
        GTK.edging(&lite, &rng, w: size.x, d: size.z, top: size.y, thick: t, board: boardKey, stake: "wood.weathered:6A5A48", screw: "metal.galvanized-aged")
        return GTK.finish(&m, &lite)
    }
}
