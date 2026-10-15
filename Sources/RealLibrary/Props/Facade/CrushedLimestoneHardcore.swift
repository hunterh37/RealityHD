import simd
import Foundation

/// Crushed limestone hardcore tile, 2 x 2 m: a rolled Type 1 sub-base of angular 40 mm-down
/// limestone with dusty fines packed between, larger fractured lumps proud of the surface,
/// shallow roller and tyre compaction tracks and a pale dust bloom where it has dried.
public struct CrushedLimestoneHardcore: RealAsset {
    public static let id = "crushed-limestone-hardcore"
    public static let summary = "Crushed limestone hardcore tile 2 x 2 m: compacted angular Type 1 aggregate with fines, roller tracks and proud lumps."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Bed height at the border (m).
    public var base: Float = 0.097
    /// Number of surface fragments.
    public var fragments: Int = 720
    /// Fines material.
    public var fines: MaterialKey = "ground.gravel:BDB6A6"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        let tracks: [Float] = [-0.45, 0.42]
        func bump(_ p: V2) -> Float {
            var h = 0.006 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 3, seed: sd)
                + 0.003 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 1)
            for z in tracks { let t = (p.y - z) / 0.12; h -= 0.006 * exp(-t * t * t * t) }
            return h
        }
        func hgt(_ p: V2) -> Float { LGK.height(p, w: w, d: d, edge: base, bump) }
        let mats: [MaterialKey] = ["rock.limestone", "rock.limestone:CFC8B8", "rock.limestone:A9A190", "stone.limestone:DAD4C6", "rock.limestone:BBB09A"]
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: base, segments: 40, fines, bump: bump)
        for i in 0..<fragments {
            var r = rng.fork(i)
            let p = V2(r.float(-0.97...0.97), r.float(-0.97...0.97))
            let inTrack = tracks.contains { abs(p.y - $0) < 0.12 }
            let s = r.float(0.012...0.03) * (r.chance(0.05) ? 2.2 : 1)
            // Rolled tracks press stones flush with the fines.
            let sink: Float = inTrack ? 0.55 : 0.35
            LGK.shard(&m, at: V3(p.x, hgt(p) - s * sink, p.y), size: s, mats[r.int(0...mats.count - 1)], rng: &r, sub: s > 0.045 ? 2 : 1)
        }
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: base + 0.008, segments: 24, fines, bump: bump)
        return LGK.finish(&m, lite: lite, ao: 0.03)
    }
}
