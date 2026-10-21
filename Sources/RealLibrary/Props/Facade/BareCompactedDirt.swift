import simd
import Foundation

/// Bare compacted earth tile, 2 x 2 m: trodden dirt slab 7 cm thick with two shallow cart ruts along
/// X, a line of boot prints across them, half-buried river pebbles and flint, and a scuffed lighter
/// crust where the ground is driest. Edges fall to a vertical skirt so tiles butt together.
public struct BareCompactedDirt: RealAsset {
    public static let id = "bare-compacted-dirt"
    public static let summary = "Bare compacted earth tile 2 x 2 m: trodden dirt with shallow ruts, embedded pebbles and boot prints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.1, 2.0)
    /// Slab thickness at the edge (m).
    public var thickness: Float = 0.088
    /// Rut depth (m).
    public var rutDepth: Float = 0.026
    /// Number of embedded stones.
    public var stones: Int = 80
    /// Dirt material.
    public var dirt: MaterialKey = "ground.dirt"
    /// Dry crust material on the high spots.
    public var crust: MaterialKey = "ground.site"
    /// Stone material.
    public var stone: MaterialKey = "rock.river"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        var prints: [(V2, Float, Bool)] = []
        for k in 0..<9 {
            let x = -0.85 + Float(k) * 0.21 + rng.float(-0.02...0.02)
            let z = 0.18 * sin(x * 1.3) + (k % 2 == 0 ? 0.07 : -0.07)
            prints.append((V2(x, z), 0.15 + rng.float(-0.12...0.12), k % 2 == 0))
        }
        func bump(_ p: V2) -> Float {
            var h = 0.008 * Noise.fbm(V3(p.x * 2.2, 0, p.y * 2.2), octaves: 4, seed: sd)
                + 0.002 * Noise.fbm(V3(p.x * 18, 0, p.y * 18), octaves: 2, seed: sd + 3)
            for zc: Float in [-0.42, 0.38] {
                let zr = zc + 0.03 * sin(p.x * 2.1 + Float(sd % 7))
                let t = (p.y - zr) / 0.065
                h -= rutDepth * exp(-t * t) * (0.8 + 0.2 * Noise.fbm(V3(p.x * 4, 0, 0), octaves: 2, seed: sd + 5))
                let lip = (abs(p.y - zr) - 0.1) / 0.03
                h += 0.004 * exp(-lip * lip)
            }
            for (c, yaw, _) in prints {
                let l = V2(cos(yaw) * (p.x - c.x) + sin(yaw) * (p.y - c.y), -sin(yaw) * (p.x - c.x) + cos(yaw) * (p.y - c.y))
                let sole = pow(l.x / 0.14, 2) + pow(l.y / 0.048, 2)
                let heel = pow((l.x + 0.1) / 0.045, 2) + pow(l.y / 0.04, 2)
                let tread = 0.6 + 0.4 * sin(l.x * 260)
                if sole < 1 { h -= 0.005 * (1 - sole) * tread }
                if heel < 1 { h -= 0.006 * (1 - heel) }
            }
            return h
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: thickness, segments: 60, dirt, bump: bump)
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return thickness + bump(p) * k * k * (3 - 2 * k)
        }
        // Dry crust patches on the high ground between ruts, draped on the field.
        for k in 0..<5 {
            var r = rng.fork(100 + k)
            let c = V2(r.float(-0.7...0.7), r.float(-0.2...0.2) + (k % 2 == 0 ? 0.0 : 0.75 * (k < 3 ? 1 : -1)))
            let rad = r.float(0.12...0.25)
            var s = Prim.terrain(size: V2(rad * 2, rad * 2), segments: 12, material: crust) { _ in 0 }
            s.positions = s.positions.map { q in
                let l = V2(q.x, q.z), f = simd_length(l) / rad
                let wob = 1 + 0.25 * Noise.fbm(V3(q.x * 9, 0, q.z * 9), octaves: 2, seed: sd + UInt32(k))
                let pull = f > 0.75 * wob ? 0.75 * wob / f : 1
                let g = c + l * pull
                return V3(g.x, height(g) + 0.0012, g.y)
            }
            s.uvs = s.positions.map { V2($0.x, $0.z) }
            s.recomputeNormals(weldSeams: true); s.computeTangents()
            m.add(s)
        }
        // Embedded pebbles and flints, more of them in the ruts where they get pressed in.
        for k in 0..<stones {
            var r = rng.fork(1000 + k)
            let p = V2(r.float(-0.94...0.94), r.float(-0.94...0.94))
            let sz = r.chance(0.15) ? r.float(0.05...0.08) : r.float(0.02...0.04)
            PBK.stone(&m, at: V3(p.x, height(p) - sz * 0.18, p.y), size: sz, r.chance(0.3) ? "rock.granite-weathered" : stone, rng: &r)
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: thickness, segments: 20, dirt, bump: bump)
        lite = lite.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
