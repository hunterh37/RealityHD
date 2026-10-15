import simd
import Foundation

/// Red laterite dirt tile, 2 x 2 m: iron-red compacted earth 7 cm deep, sun-baked into a hard crust,
/// cut by branching erosion rills that run downslope toward one edge, studded with dark ironstone
/// (murram) nodules washed out of the rills, crossed by a single tyre track with chevron tread, and a
/// scatter of loose red crumbs over the crust.
public struct RedLateriteDirt: RealAsset {
    public static let id = "red-laterite-dirt"
    public static let summary = "Red laterite dirt tile, 2 x 2 m: iron-red compacted earth with erosion rills, ironstone nodules and a tyre track."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Earth depth at the tile edge (m).
    public var depth: Float = 0.065
    /// Laterite material.
    public var earth: MaterialKey = "ground.dirt:A4472A"
    /// Loose crumb material.
    public var dust: MaterialKey = "ground.sand:B4603A"
    /// Ironstone nodule material.
    public var ironstone: MaterialKey = "rock.redstone:5A2E1E"
    /// Nodules on the surface.
    public var nodules: Int = 110
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        // Rills: meandering channels along -Z with side branches.
        var rills: [[V2]] = []
        for k in 0..<3 {
            var r = rng.fork(10 + k)
            var x = -0.6 + Float(k) * 0.55 + r.float(-0.1...0.1)
            var pts: [V2] = []
            for j in 0...24 { let z = 1.0 - Float(j) / 24 * 2.0; x += r.float(-0.035...0.035); pts.append(V2(x, z)) }
            rills.append(pts)
        }
        func segDist(_ p: V2, _ a: V2, _ b: V2) -> Float {
            let ab = b - a, t = max(0, min(1, simd_dot(p - a, ab) / simd_dot(ab, ab)))
            return simd_length(p - (a + ab * t))
        }
        let tyreX: Float = rng.float(0.15...0.35)
        func bump(_ p: V2) -> Float {
            var h = 0.007 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 4, seed: sd) - 0.006 * p.y * -1
            h += 0.0018 * Noise.ridged(V3(p.x * 16, 0, p.y * 16), octaves: 2, seed: sd + 1)
            for (i, pts) in rills.enumerated() {
                var dm: Float = 9
                for j in 0..<(pts.count - 1) { dm = min(dm, segDist(p, pts[j], pts[j + 1])) }
                let wdt: Float = 0.02 + 0.015 * (1 - p.y) / 2 + 0.004 * Float(i)
                h -= 0.014 * exp(-pow(dm / wdt, 2))
            }
            // Tyre track along Z with chevron tread.
            let tx = abs(p.x - tyreX)
            if tx < 0.11 {
                let edge = 1 - pow(tx / 0.11, 6)
                let chev = sin((p.y + abs(p.x - tyreX) * 0.8) * 70)
                h -= edge * (0.005 + 0.0015 * max(0, chev))
            }
            return h
        }
        var m = Model(name: Self.id)
        GTK.field(&m, w: w, d: d, edge: depth, segments: 72, earth, uvScale: 1, bump: bump)
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return depth + bump(p) * k * k * (3 - 2 * k)
        }
        var lite = Model(name: Self.id + "-lite")
        GTK.field(&lite, w: w, d: d, edge: depth, segments: 24, earth, uvScale: 1, bump: bump)
        GTK.stones(&m, &rng, count: nodules, hx: 0.95, hz: 0.95, size: 0.008...0.035, keys: [ironstone, ironstone, dust, "rock.granite-weathered"], subdivisions: 1, exponent: 2.2, sink: 0.4, surface: height)
        return GTK.finish(&m, &lite, ao: 0.03, switchAt: 8)
    }
}
