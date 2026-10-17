import simd
import Foundation

/// Allotment rhubarb crown bed: a raised scaffold-board bed of three established rhubarb crowns with
/// knobbly pink buds, red leaf stalks and big crinkled leaves, mulched with well-rotted manure; a fourth
/// crown sits under an Edwardian terracotta forcing pot with its lid.
public struct AllotmentRhubarbCrownBed: RealAsset {
    public static let id = "allotment-rhubarb-crown-bed"
    public static let summary = "Rhubarb crown bed tile, 2 x 2 m: three red-stalked crowns in a manure-mulched board bed, a fourth under a terracotta forcing pot."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.5, 2.0)
    /// Leaf stalk material (red rhubarb petiole).
    public var stalk: MaterialKey = "food.stem-green:8E1A2A"
    /// Leaf material.
    public var leafMaterial: MaterialKey = "leaf.plain:3A5F26"
    /// Forcing pot material.
    public var pot: MaterialKey = "ceramic.terracotta"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, pathH: Float = 0.02, bh: Float = 0.16
        let bw: Float = 1.8, bd: Float = 1.8, y0 = pathH - 0.015, fillTop = y0 + bh - 0.035
        var m = Model(name: Self.id)
        ACK.field(&m, w: w, d: d, base: pathH, segments: 14, material: "ground.dirt:5C4734") { p in
            pathH + 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
        }
        let iw = bw - 0.08, id = bd - 0.08
        func fill(_ p: V2) -> Float { fillTop + 0.012 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd + 5) }
        m.add(Prim.terrain(size: V2(iw, id), segments: 28, material: "soil.potting:3A2A1C", height: fill))
        ACK.frame(&m, bw: bw, bd: bd, y0: y0, height: bh, rng: &rng)
        let crowns: [V2] = [V2(-0.42, -0.4), V2(0.42, -0.38), V2(-0.4, 0.42)]
        let potAt = V2(0.42, 0.42)
        // Manure mulch rings: dark crumbly clods round each crown.
        for (ci, c) in (crowns + [potAt]).enumerated() {
            for k in 0..<6 {
                var r = rng.fork(300 + ci * 20 + k)
                let a = r.float(0...6.28), rr = r.float(0.14...0.28)
                let p = c + V2(cos(a), sin(a)) * rr
                ACK.clod(&m, at: p, y: fill(p) - 0.006, size: r.float(0.04...0.07), rng: &r, material: "soil.potting:2B1E14", sub: 2)
            }
        }
        for (ci, c) in crowns.enumerated() {
            var r = rng.fork(ci)
            let base = V3(c.x, fill(c), c.y)
            // Crown: knobbly pink-red buds.
            for k in 0..<4 {
                let a = Float(k) * 1.57 + r.float(0...0.5)
                m.add(Prim.superellipsoid(V3(0.05, 0.04, 0.045), exponent: 2.4, subdivisions: 2, material: "plant.stem:8A3A3A"),
                      Xform(translation: base + V3(cos(a) * 0.04, 0.01, sin(a) * 0.04)))
            }
            let n = r.int(7...9)
            for k in 0..<n {
                let yaw = Float(k) / Float(n) * 2 * .pi + r.float(-0.2...0.2)
                let out = V3(cos(yaw), 0, sin(yaw))
                let len = r.float(0.22...0.32), rise = r.float(0.15...0.25)
                let tip = base + out * len * 0.75 + V3(0, rise, 0)
                m.add(Prim.tube([base + out * 0.03 + V3(0, 0.01, 0), base + out * len * 0.3 + V3(0, rise * 0.65, 0), tip],
                                radii: [0.016, 0.013, 0.009], sides: 7, seamTile: 0.1, material: stalk))
                let ldir = simd_normalize(out + V3(0, r.float(-0.25...0.15), 0))
                let lw = r.float(0.3...0.4)
                m.add(ACK.broadLeaf(tip - ldir * 0.02, dir: ldir, length: lw * 0.95, width: lw, lobes: 5, lobeDepth: 0.1, ruffle: 0.035, cup: 0.04, spokes: 12,
                                    seed: UInt32(ci * 16 + k), material: k % 3 == 0 ? "leaf.plain:4E7230" : leafMaterial))
                // Pale veins fanning from the stalk.
                for v: Float in [-0.5, 0, 0.5] {
                    let side = simd_normalize(simd_cross(ldir, .up))
                    let e = tip + ldir * lw * 0.75 + side * v * lw * 0.45 + V3(0, 0.012, 0)
                    m.add(Prim.tube([tip + V3(0, 0.006, 0), e], radii: [0.0022, 0.0008], sides: 3, seamTile: 0.1, material: "plant.stem:7C8E4A"))
                }
            }
            // One pulled stalk lying on the mulch.
            if ci == 1 {
                let a = base + V3(0.12, 0.012, 0.2)
                m.add(Prim.tube([a, a + V3(0.28, 0.004, 0.05)], radii: [0.014, 0.01], sides: 7, seamTile: 0.1, material: stalk))
            }
        }
        // Forcing pot over the fourth crown: tall terracotta bell with a lidded top.
        let py = fill(potAt) - 0.01
        var pr = rng.fork(900)
        let profile: [V2] = [V2(0.0, 0.0), V2(0.165, 0.0), V2(0.17, 0.02), V2(0.16, 0.16), V2(0.148, 0.27), V2(0.13, 0.29),
                             V2(0.085, 0.295), V2(0.08, 0.305)]
        m.add(Prim.lathe(profile, segments: 32, seamTile: 1, material: pot), Xform(translation: V3(potAt.x, py, potAt.y)))
        m.add(Prim.lathe([V2(0, 0), V2(0.1, 0), V2(0.1, 0.012), V2(0.04, 0.02), V2(0.035, 0.045), V2(0, 0.05)], segments: 24, seamTile: 1, material: pot),
              Xform(translation: V3(potAt.x, py + 0.303, potAt.y), rotation: simd_quatf(degrees: pr.float(-4...4), axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: 0.168, minor: 0.008, segments: 32, sides: 6, material: "ceramic.terracotta:8A5638"),
              Xform(translation: V3(potAt.x, py + 0.02, potAt.y)))
        for i in 0..<3 {
            var r = rng.fork(800 + i)
            let along = r.float(-0.8...0.8), side: Float = r.chance(0.5) ? -1 : 1
            ACK.weed(&m, at: V3(along, pathH - 0.003, side * (bd / 2 + 0.02)), height: r.float(0.05...0.1), count: 10, rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        ACK.field(&lite, w: w, d: d, base: pathH, segments: 8, material: "ground.dirt:5C4734") { _ in pathH }
        lite.add(Prim.roundedBox(V3(bw, bh, bd), radius: 0.004, bevelSegments: 1, material: ACK.board), Xform(translation: V3(0, y0 + bh / 2, 0)))
        return ACK.finish(&m, lite: lite, ao: 0.12)
    }
}
