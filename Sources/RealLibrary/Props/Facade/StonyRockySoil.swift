import simd
import Foundation

/// Stony rocky soil tile, 2 x 2 m: thin dry soil packed with half-buried boulders, angular flint and
/// slate scree, a pebble scatter and fine grit washed into the hollows. Edges fall to a skirt.
public struct StonyRockySoil: RealAsset {
    public static let id = "stony-rocky-soil"
    public static let summary = "Stony rocky soil tile 2 x 2 m: thin dry soil packed with half-buried boulders, angular flints and pebble scatter."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.15, 2.0)
    /// Soil thickness at the edge (m).
    public var thickness: Float = 0.075
    /// Boulder count.
    public var boulders: Int = 12
    /// Stone count (flints, scree, pebbles).
    public var stones: Int = 100
    /// Soil material.
    public var soil: MaterialKey = "ground.dirt"
    /// Grit wash material.
    public var grit: MaterialKey = "ground.gravel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        func bump(_ p: V2) -> Float {
            0.016 * Noise.fbm(V3(p.x * 1.8, 0, p.y * 1.8), octaves: 4, seed: sd)
                + 0.004 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 3, seed: sd + 2)
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: thickness, segments: 36, soil, bump: bump)
        func height(_ p: V2) -> Float { FLK.height(p, w: w, d: d, edge: thickness, bump: bump) }
        var placed: [(V2, Float)] = []
        for k in 0..<boulders {
            var r = rng.fork(500 + k)
            let p = V2(r.float(-0.78...0.78), r.float(-0.78...0.78))
            let sz = r.float(0.12...0.2)
            placed.append((p, sz))
            FLK.stone(&m, at: V3(p.x, height(p) + sz * 0.08, p.y), size: sz, flat: 0.45...0.6,
                      r.chance(0.5) ? "rock.granite-weathered" : "rock.limestone", rng: &r)
        }
        var n = 0, tries = 0
        while n < stones && tries < stones * 4 {
            tries += 1
            var r = rng.fork(1000 + tries)
            let p = V2(r.float(-0.93...0.93), r.float(-0.93...0.93))
            if placed.contains(where: { simd_length($0.0 - p) < $0.1 * 0.45 }) { continue }
            n += 1
            let roll = r.float(0...1)
            if roll < 0.25 {
                // Angular slate or flint shard, tilted.
                let sz = r.float(0.03...0.07)
                m.add(Prim.roundedBox(V3(sz, sz * 0.25, sz * r.float(0.5...0.8)), radius: 0.002, bevelSegments: 1,
                                      material: r.chance(0.5) ? "rock.slate" : "rock.granite-weathered"),
                      Xform(translation: V3(p.x, height(p) + sz * 0.05, p.y),
                            rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-25...25), axis: V3(1, 0, 0))))
            } else {
                let sz = roll < 0.55 ? r.float(0.05...0.1) : r.float(0.015...0.035)
                FLK.stone(&m, at: V3(p.x, height(p) - sz * 0.05, p.y), size: sz,
                          r.chance(0.5) ? "rock.river" : "rock.granite-weathered", rng: &r)
            }
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.05, floor: 0.65)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: thickness, segments: 24, soil, bump: bump)
        lite = lite.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
