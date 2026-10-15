import simd
import Foundation

/// Peat bog tile, 2 x 2 m: dark fibrous peat raised into sphagnum hummocks with wet hollows of
/// standing bog water between, cushions of red and green sphagnum moss, cotton-grass tufts and
/// crumbled peat at the hollow edges. Border settles to a common height so tiles butt together.
public struct PeatBogMoss: RealAsset {
    public static let id = "peat-bog-moss"
    public static let summary = "Peat bog tile 2 x 2 m: sphagnum moss hummocks, wet peat hollows with bog water, cotton-grass tufts."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 34, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Peat slab height at the border (m).
    public var base: Float = 0.02
    /// Peat material.
    public var peat: MaterialKey = "ground.dirt:2B1E15"
    /// Green sphagnum material.
    public var moss: MaterialKey = "moss.cushion:6E8A3A"
    /// Red sphagnum material.
    public var redMoss: MaterialKey = "moss.cushion:8A4A32"
    /// Bog water material.
    public var water: MaterialKey = "water.puddle"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        var hummocks: [(V2, Float)] = []
        for i in 0..<13 {
            var r = rng.fork(i)
            hummocks.append((V2(r.float(-0.75...0.75), r.float(-0.75...0.75)), r.float(0.24...0.4)))
        }
        func bump(_ p: V2) -> Float {
            var h = -0.02 + 0.012 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 4, seed: sd)
                + 0.004 * Noise.ridged(V3(p.x * 14, 0, p.y * 14), octaves: 2, seed: sd + 1)
            for (c, r) in hummocks {
                let f = simd_length(p - c) / r
                h += 0.025 * exp(-f * f * 1.6)
            }
            return h
        }
        func hgt(_ p: V2) -> Float { LGK.height(p, w: w, d: d, edge: base, bump) }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: base, segments: 50, peat, bump: bump)
        // Bog water standing in the hollows.
        m.add(Prim.terrain(size: V2(w - 0.14, d - 0.14), segments: 4, material: water) { _ in base - 0.008 })
        // Sphagnum carpet over the hummock crowns; hidden under the peat elsewhere so its edge follows the contour.
        func crown(_ p: V2) -> Float {
            var c: Float = 0
            for (q, r) in hummocks { let f = simd_length(p - q) / r; c = max(c, exp(-f * f * 1.6)) }
            return c + 0.15 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 2, seed: sd + 7)
        }
        m.add(Prim.terrain(size: V2(w - 0.1, d - 0.1), segments: 46, material: moss) { p in
            let c = crown(p)
            return hgt(p) + (c > 0.4 ? 0.006 + 0.004 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 8) : -0.008)
        })
        // Sphagnum cushions clustered on the hummocks.
        for i in 0..<130 {
            var r = rng.fork(1000 + i)
            let (c, rad) = hummocks[i % hummocks.count]
            let a = r.float(0...(2 * .pi)), t = sqrt(r.float(0...1)) * rad * 1.1
            let p = V2(c.x + cos(a) * t, c.y + sin(a) * t)
            guard abs(p.x) < w / 2 - 0.04, abs(p.y) < d / 2 - 0.04 else { continue }
            let y = hgt(p)
            guard y > base - 0.004 else { continue }
            let s = r.float(0.06...0.095)
            LGK.lump(&m, at: V3(p.x, y - s * 0.45, p.y), size: s, r.chance(0.3) ? redMoss : moss, pit: 0.12, rng: &r)
        }
        // Peat crumbs at the hollow margins.
        for i in 0..<40 {
            var r = rng.fork(3000 + i)
            let p = V2(r.float(-0.92...0.92), r.float(-0.92...0.92))
            let y = hgt(p)
            guard abs(y - base) < 0.012 else { continue }
            LGK.lump(&m, at: V3(p.x, y - 0.004, p.y), size: r.float(0.015...0.035), peat, rng: &r, sub: 1)
        }
        // Cotton-grass and sedge tufts.
        for i in 0..<14 {
            var r = rng.fork(5000 + i)
            let (c, _) = hummocks[i % hummocks.count]
            let p = c + V2(r.float(-0.12...0.12), r.float(-0.12...0.12))
            var t = PlantKit.Tuft()
            t.count = 18; t.height = r.float(0.035...0.05); t.radius = 0.03
            t.width = 0.0015...0.003; t.lean = 0.1...0.45
            m.add(PlantKit.tuft(t, at: V3(p.x, hgt(p) - 0.01, p.y), rng: &r, material: r.chance(0.5) ? "grass.dry" : "grass.meadow"))
            if r.chance(0.6) {
                m.add(Prim.superellipsoid(V3(0.012, 0.016, 0.012), exponent: 2, subdivisions: 2, material: "grass.seedhead:EDEBE2"),
                      Xform(translation: V3(p.x, hgt(p) + t.height * 0.9, p.y)))
            }
        }
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: base, segments: 24, moss, bump: bump)
        return LGK.finish(&m, lite: lite)
    }
}
