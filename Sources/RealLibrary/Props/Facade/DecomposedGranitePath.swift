import simd
import Foundation

/// Decomposed granite path, 2 x 2 m: a 1.5 m band of stabilized tan DG fines running along Z, rolled
/// flat with a slight cross-fall, set between 6 mm weathering-steel edging bands staked from behind.
/// Gravel margins either side carry a granite accent boulder; crushed grit and fines lie loose on top,
/// with shallow wash lines where sprinkler runoff has crossed the path.
public struct DecomposedGranitePath: RealAsset {
    public static let id = "decomposed-granite-path"
    public static let summary = "Decomposed granite path, 2 x 2 m: stabilized tan DG fines and granite grit between staked Cor-ten edging, with gravel margins and a boulder."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y height, z length).
    public var size = V3(2.0, 0.1, 2.0)
    /// Width of the DG band between the edging (m).
    public var pathWidth: Float = 1.5
    /// Compacted DG surface.
    public var fines: MaterialKey = "ground.gravel:D2B282"
    /// Loose grit tones (granite crush: tan, pink feldspar, grey quartz, black mica flecks).
    public var gritKeys: [MaterialKey] = ["rock.granite:C8A880", "rock.granite:B89070", "rock.granite:A8A098", "rock.granite:5A524A", "rock.granite:D8C0A0"]
    /// Margin gravel.
    public var margin: MaterialKey = "ground.gravel:8A8072"
    /// Edging steel.
    public var steel: MaterialKey = "metal.rust:6A4028"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = pathWidth / 2, hd = size.z / 2, base: Float = 0.055
        let ph = rng.float(0...6.28)
        func h(_ p: V2) -> Float {
            let fall = -0.004 * p.x / hw
            let wash = -0.0025 * pow(max(0, sin(p.y * 7 + 2 * sin(p.x * 3 + ph))), 12)
            return fall + wash + 0.0018 * Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 3, seed: 21)
        }
        GTK.field(&m, w: pathWidth, d: size.z, edge: base, nx: 30, nz: 60, fines, uvScale: 2.4, bump: h)
        var lite = m
        let mw = (size.x - pathWidth) / 2 - 0.006
        for s: Float in [-1, 1] {
            let cx = s * (hw + 0.006 + mw / 2)
            var g = Model(name: "margin")
            GTK.field(&g, w: mw, d: size.z, edge: base + 0.004, nx: 4, nz: 16, margin, uvScale: 2) { p in 0.006 * Noise.fbm(V3(p.x * 7, 0, p.y * 7), seed: 5) }
            for var sf in g.surfaces { sf.positions = sf.positions.map { $0 + V3(cx, 0, 0) }; m.add(sf); lite.add(sf) }
            var r = rng.fork(s > 0 ? 41 : 42)
            GTK.stones(&m, &r, count: 70, hx: mw / 2 - 0.01, hz: hd - 0.01, size: 0.02...0.045, flat: 0.45...0.7,
                       keys: ["rock.river:7E766C", "rock.river:948A7C", "rock.granite:6E6660"], subdivisions: 1, exponent: 2.6, sink: 0.4, offset: V3(cx, 0, 0),
                       surface: { _ in base + 0.006 }, keep: { _ in true })
            // Weathering-steel edging band, 6 mm, top 8 mm proud of the DG.
            let eh = base + 0.008
            let band = Prim.roundedBox(V3(0.006, eh, size.z - 0.002), radius: 0.0015, bevelSegments: 1, material: steel)
            m.add(band, Xform(translation: V3(s * (hw + 0.003), eh / 2, 0))); lite.add(band, Xform(translation: V3(s * (hw + 0.003), eh / 2, 0)))
            for k in 0..<4 {
                let z = -hd + 0.25 + Float(k) * 0.5 + r.float(-0.03...0.03)
                // Tapered stake welded behind the band, its top tab and two bolts visible.
                GK.box(&m, V3(s * (hw + 0.009), eh - 0.016, z), V3(0.006, 0.03, 0.04), "metal.rust:5A3420", r: 0.001)
                for dz: Float in [-0.01, 0.01] {
                    rivet(&m, at: V3(s * (hw + 0.012), eh - 0.012, z + dz), normal: V3(s, 0, 0), radius: 0.005, height: 0.003, segments: 6, material: "metal.rust:4A2C1C")
                }
            }
        }
        // Granite accent boulder half-set into the margin.
        var r = rng.fork(77)
        var boulder = Prim.superellipsoid(V3(0.2, 0.08, 0.16), exponent: 3.2, subdivisions: 6, material: "rock.granite-weathered:B8A894") { d in
            1 + 0.08 * Noise.fbm(d * 1.4, octaves: 4, seed: 9)
        }
        boulder.recomputeNormals(weldSeams: true)
        let bx = -(hw + 0.006 + mw / 2), bz = r.float(0.3...0.6)
        m.add(boulder, Xform(translation: V3(bx, base - 0.002, bz), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        lite.add(boulder, Xform(translation: V3(bx, base - 0.002, bz), rotation: simd_quatf(degrees: 20, axis: .up)))
        // Loose crushed grit on the DG, thickest along the edging where traffic throws it.
        GTK.stones(&m, &rng, count: 300, hx: hw - 0.008, hz: hd - 0.01, size: 0.004...0.011, flat: 0.4...0.65, keys: gritKeys,
                   exponent: 3, sink: 0.35, surface: { base + h($0) },
                   keep: { p in abs(p.x) > hw - 0.25 || (sin(p.x * 127.1 + p.y * 311.7) * 43758.5).truncatingRemainder(dividingBy: 1) > 0.45 })
        return GTK.finish(&m, &lite)
    }
}
