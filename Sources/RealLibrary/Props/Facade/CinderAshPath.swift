import simd
import Foundation

/// Victorian cinder and ash path tile, 2 x 2 m: a cambered bed of black boiler ash raked over
/// broken furnace clinker, porous clinker lumps and glassy slag beads proud of the surface, a worn
/// trodden line down the centre with flattened fines, and rust-brown burnt-shale specks.
public struct CinderAshPath: RealAsset {
    public static let id = "cinder-ash-path"
    public static let summary = "Victorian cinder path tile 2 x 2 m: cambered black ash with porous clinker lumps, slag beads and a trodden centre line."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Bed height at the border (m).
    public var base: Float = 0.056
    /// Number of clinker lumps.
    public var clinker: Int = 760
    /// Ash fines material.
    public var ash: MaterialKey = "ground.gravel:34312E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func bump(_ p: V2) -> Float {
            // Shallow camber across X with a trodden dip along the centre line.
            let camber = 0.012 * cos(p.x / 1.0 * .pi / 2)
            let tread = -0.006 * exp(-pow(p.x / 0.18, 2))
            return camber + tread + 0.005 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd)
                + 0.002 * Noise.ridged(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd + 1)
        }
        func hgt(_ p: V2) -> Float { LGK.height(p, w: w, d: d, edge: base, bump) }
        let mats: [MaterialKey] = ["rock.basalt:2A2826", "rock.basalt:3B3632", "rock.basalt:1C1B1A", "rock.redstone:5A3A2A", "rock.basalt:4A4440"]
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: base, segments: 44, ash, bump: bump)
        for i in 0..<clinker {
            var r = rng.fork(i)
            let p = V2(r.float(-0.97...0.97), r.float(-0.97...0.97))
            // Fewer, flatter lumps on the trodden line.
            let trod = exp(-pow(p.x / 0.2, 2))
            if trod > 0.5 && r.chance(0.5) { continue }
            let s = r.float(0.012...0.032) * (r.chance(0.06) ? 1.8 : 1)
            LGK.lump(&m, at: V3(p.x, hgt(p) - s * (0.15 + 0.2 * trod), p.y), size: s, mats[r.int(0...mats.count - 1)], pit: 0.35, rng: &r)
        }
        // Glassy slag beads.
        for i in 0..<60 {
            var r = rng.fork(5000 + i)
            let p = V2(r.float(-0.95...0.95), r.float(-0.95...0.95))
            LGK.pebble(&m, at: V3(p.x, hgt(p) - 0.003, p.y), size: r.float(0.008...0.014), flat: 0.8, "rock.slate:1A1D22", rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: base + 0.006, segments: 24, ash, bump: bump)
        return LGK.finish(&m, lite: lite, ao: 0.025)
    }
}
