import simd
import Foundation

/// Allotment dug-over clods: a 2 m square of heavy clay soil rough-dug in autumn. Each spit is
/// turned and left as whole clods for the winter frost to break, so the plot reads as ridges of
/// large spade-cut lumps over open trenches, with flints thrown up, couch-grass roots and a
/// trodden margin that meets neighbouring tiles at a constant height.
public struct AllotmentDugOverClods: RealAsset {
    public static let id = "allotment-dug-over-clods"
    public static let summary = "2 m square allotment plot rough-dug in autumn: large spade-turned clods left whole for the frost to break, open trenches between spits, flints and couch roots."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Height of the trodden margin (m).
    public var base: Float = 0.03
    /// Spit (spade-width trench) spacing (m).
    public var spit: Float = 0.3
    /// Ridge height above the margin (m).
    public var ridge: Float = 0.075
    /// Number of large turned clods.
    public var clods: Int = 120
    /// Number of flints and stones.
    public var stones: Int = 34
    /// Number of couch-grass tufts.
    public var weeds: Int = 6
    /// Wet clay soil colour.
    public var soil: MaterialKey = "ground.dirt:4A3622"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func h(_ p: V2) -> Float {
            let ph = (p.y + d / 2) / spit + 0.35 * Noise.fbm(V3(p.x * 1.5, 0, 0), octaves: 2, seed: sd + 5)
            let f = ph - floor(ph)
            // Spade face steep, trench at f ~ 0, turned spit heaped behind it.
            let prof = f < 0.2 ? f / 0.2 : 1 - pow((f - 0.2) / 0.8, 1.6)
            let r = ridge * max(0, prof)
            let lump = 0.018 * Noise.fbm(V3(p.x * 7, 0, p.y * 7), octaves: 4, seed: sd + 1)
                + 0.008 * Noise.ridged(V3(p.x * 22, 0, p.y * 22), octaves: 2, seed: sd + 2)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, (e - 0.07) / 0.12))
            return base + (r + lump + 0.015) * k + lump * 0.25 * (1 - k)
        }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 46, material: soil, h)
        // Large clods: whole spits lying on the ridge crests, some split into two.
        let rows = Int(d / spit)
        for i in 0..<clods {
            var r = rng.fork(i)
            let x = r.float(-w / 2 + 0.14...w / 2 - 0.14)
            let row = Float(r.int(0...rows - 1))
            let z = -d / 2 + (row + 0.35 + r.float(-0.12...0.25)) * spit
            guard abs(z) < d / 2 - 0.14 else { continue }
            let p = V2(x, z)
            let big = r.chance(0.55)
            AK.clod(&m, at: p, y: h(p) - 0.01, size: big ? r.float(0.1...0.17) : r.float(0.05...0.09), rng: &r,
                    material: r.chance(0.35) ? AK.dryClod : "soil.potting:3E2C1C")
        }
        // Small crumb fallen into the trenches.
        for i in 0..<60 {
            var r = rng.fork(5000 + i)
            let p = V2(r.float(-w / 2 + 0.1...w / 2 - 0.1), r.float(-d / 2 + 0.1...d / 2 - 0.1))
            AK.clod(&m, at: p, y: h(p) - 0.004, size: r.float(0.015...0.035), rng: &r, sub: 1)
        }
        for i in 0..<stones {
            var r = rng.fork(9000 + i)
            let p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.stone(&m, at: p, y: h(p) - 0.008, size: r.float(0.02...0.06), rng: &r)
        }
        // Couch-grass roots left on the surface: pale wiry runners.
        for i in 0..<10 {
            var r = rng.fork(11000 + i)
            let a = V2(r.float(-w / 2 + 0.2...w / 2 - 0.2), r.float(-d / 2 + 0.2...d / 2 - 0.2))
            let dir = r.float(0...(2 * .pi))
            var pts: [V3] = []
            for k in 0..<5 {
                let t = Float(k) * 0.05
                let q = a + V2(cos(dir), sin(dir)) * t + V2(r.float(-0.01...0.01), r.float(-0.01...0.01))
                pts.append(V3(q.x, h(q) + 0.002, q.y))
            }
            m.add(Prim.tube(catmull(pts, per: 3), radii: Array(repeating: 0.0015, count: 13), sides: 4, seamTile: 0.05, material: "plant.stem:CDBF97", capEnd: true))
        }
        for i in 0..<weeds {
            var r = rng.fork(12000 + i)
            let p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.weed(&m, at: V3(p.x, h(p) - 0.004, p.y), height: r.float(0.05...0.1), rng: &r, material: r.chance(0.5) ? "grass.lawn" : "grass.dry")
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 40, material: soil, h)
        return AK.finish(&m, lite: lite, ao: 0.08)
    }
}
