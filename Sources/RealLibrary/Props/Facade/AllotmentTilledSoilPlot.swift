import simd
import Foundation

/// Allotment tilled soil plot: a 2 m square of freshly single-dug soil. Spade-width furrows run
/// across the plot with turned clods lying on each ridge, broken tilth between, flints and stones
/// thrown up by the spade, a few couch-grass tufts missed by the fork, and a trodden margin.
public struct AllotmentTilledSoilPlot: RealAsset {
    public static let id = "allotment-tilled-soil-plot"
    public static let summary = "2 m square allotment plot of freshly dug soil: spade-turned clods in rows, crumbled tilth, stones and a few weeds, on a worn soil base."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Height of the trodden margin (m).
    public var base: Float = 0.025
    /// Spit (spade-width) furrow spacing (m).
    public var spit: Float = 0.24
    /// Ridge height above the margin (m).
    public var ridge: Float = 0.065
    /// Number of turned clods.
    public var clods: Int = 100
    /// Number of stones and flints.
    public var stones: Int = 30
    /// Number of weed tufts.
    public var weeds: Int = 5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func h(_ p: V2) -> Float {
            let ph = (p.y + d / 2) / spit
            let f = ph - floor(ph)
            // Asymmetric spit: steep spade face, gentle back slope.
            let prof = f < 0.25 ? f / 0.25 : 1 - (f - 0.25) / 0.75
            let wob = 0.25 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 2, seed: sd)
            let r = ridge * pow(max(0, min(1, prof + wob * 0.3)), 0.8)
            let lump = 0.012 * Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 4, seed: sd + 1)
                + 0.006 * Noise.ridged(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd + 2)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, (e - 0.08) / 0.1))
            return base + (r + lump + 0.012) * k + lump * 0.3 * (1 - k)
        }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 56, h)
        // Clods: turned spits lying on the ridges, bigger at the crest.
        for i in 0..<clods {
            var r = rng.fork(i)
            let x = r.float(-w / 2 + 0.12...w / 2 - 0.12)
            let row = Float(r.int(0...Int(d / spit) - 1))
            let z = -d / 2 + (row + 0.25 + r.float(-0.12...0.2)) * spit
            guard abs(z) < d / 2 - 0.12 else { continue }
            let p = V2(x, z)
            AK.clod(&m, at: p, y: h(p) - 0.006, size: r.float(0.05...0.11), rng: &r, material: r.chance(0.3) ? AK.dryClod : AK.clod)
        }
        // Crumb: small aggregates everywhere in the dug area.
        for i in 0..<110 {
            var r = rng.fork(5000 + i)
            let p = V2(r.float(-w / 2 + 0.1...w / 2 - 0.1), r.float(-d / 2 + 0.1...d / 2 - 0.1))
            AK.clod(&m, at: p, y: h(p) - 0.003, size: r.float(0.012...0.025), rng: &r, sub: 1)
        }
        for i in 0..<stones {
            var r = rng.fork(9000 + i)
            let p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.stone(&m, at: p, y: h(p) - 0.006, size: r.float(0.018...0.05), rng: &r)
        }
        for i in 0..<weeds {
            var r = rng.fork(12000 + i)
            let p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.weed(&m, at: V3(p.x, h(p) - 0.004, p.y), height: r.float(0.06...0.12), rng: &r, material: r.chance(0.5) ? "grass.lawn" : "grass.dry")
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 40, h)
        return AK.finish(&m, lite: lite, ao: 0.07)
    }
}
