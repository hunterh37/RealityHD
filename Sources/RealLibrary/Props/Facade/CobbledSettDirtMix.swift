import simd
import Foundation

/// Old granite sett paving half lost to dirt, 2 x 2 m: rows of worn setts laid in courses across X
/// with staggered joints, earth-filled joints with moss, missing setts leaving dirt hollows, and a
/// few lifted and tilted stones. The dirt bed edges fall to a vertical skirt so tiles butt.
public struct CobbledSettDirtMix: RealAsset {
    public static let id = "cobbled-sett-dirt-mix"
    public static let summary = "Old granite sett paving 2 x 2 m half lost to dirt: rows of worn setts, gaps, tilted stones and earth-filled joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.12, 2.0)
    /// Dirt bed thickness at the edge (m).
    public var thickness: Float = 0.072
    /// Sett length along the course, width across, depth (m).
    public var sett = V3(0.2, 0.1, 0.06)
    /// Joint width (m).
    public var joint: Float = 0.014
    /// Fraction of setts missing.
    public var missing: Float = 0.12
    /// Dirt material.
    public var dirt: MaterialKey = "ground.dirt"
    /// Sett stone materials.
    public var stones: [MaterialKey] = ["stone.granite-paver", "stone.granite-curb"]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        func bump(_ p: V2) -> Float {
            0.008 * Noise.fbm(V3(p.x * 2.4, 0, p.y * 2.4), octaves: 4, seed: sd)
                + 0.002 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 1)
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: thickness, segments: 36, dirt, bump: bump)
        func height(_ p: V2) -> Float { FLK.height(p, w: w, d: d, edge: thickness, bump: bump) }
        // Patch of surviving paving: setts kept where a low-frequency mask is high.
        let pitchZ = sett.y + joint
        let rows = Int((d - 0.04) / pitchZ)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: thickness, segments: 20, dirt, bump: bump)
        for row in 0..<rows {
            let z = -d / 2 + 0.02 + pitchZ * (Float(row) + 0.5)
            var x = -w / 2 + 0.01 + (row % 2 == 0 ? 0 : -sett.x * 0.5)
            var i = 0
            while x < w / 2 - 0.01 {
                var r = rng.fork(row * 100 + i); i += 1
                let len = sett.x * r.float(0.8...1.15)
                let x0 = max(x, -w / 2 + 0.01), x1 = min(x + len, w / 2 - 0.01)
                x += len + joint
                guard x1 - x0 > 0.05 else { continue }
                let c = V2((x0 + x1) / 2, z)
                let mask = Noise.fbm(V3(c.x * 1.3, 0, c.y * 1.3), octaves: 2, seed: sd + 9)
                if r.float(0...1) < missing + max(0, -mask - 0.15) * 0.8 { continue }
                let lifted = r.chance(0.07)
                let top = height(c) + (lifted ? r.float(0.025...0.04) : r.float(0.008...0.02))
                let sz = V3(x1 - x0 - 0.002, sett.z, sett.y * r.float(0.92...1.0))
                let rot = simd_quatf(degrees: r.float(-3...3), axis: .up)
                    * simd_quatf(degrees: lifted ? r.float(-9...9) : r.float(-2...2), axis: V3(1, 0, 0))
                    * simd_quatf(degrees: r.float(-2...2), axis: V3(0, 0, 1))
                let mat = r.chance(0.3) ? stones[1] : stones[0]
                let sdk = UInt32(r.int(0...9999))
                let s = Prim.superellipsoid(sz, exponent: r.float(6...9), subdivisions: 2, material: mat) { dd in
                    1 + 0.03 * Noise.fbm(dd * 3, octaves: 2, seed: sdk) + (dd.y > 0 ? -0.02 * (dd.x * dd.x + dd.z * dd.z) : 0)
                }
                let xf = Xform(translation: V3(c.x, top - sz.y / 2, c.y), rotation: rot)
                m.add(s, xf)
                lite.add(Prim.superellipsoid(sz, exponent: 8, subdivisions: 1, material: mat), xf)
                // Moss creeping along the joint on the shaded side.
                if r.chance(0.25) {
                    m.add(Prim.superellipsoid(V3(sz.x * r.float(0.4...0.9), 0.008, 0.016), exponent: 2.4, subdivisions: 2, material: "moss.cushion"),
                          Xform(translation: V3(c.x, height(c) + 0.002, c.y - sz.z / 2 - joint * 0.4)))
                }
            }
        }
        // Loose kicked-out grit and a broken sett fragment.
        for k in 0..<16 {
            var r = rng.fork(5000 + k)
            let p = V2(r.float(-0.92...0.92), r.float(-0.92...0.92))
            let sz = r.float(0.015...0.035)
            FLK.stone(&m, at: V3(p.x, height(p) - sz * 0.2, p.y), size: sz, "rock.granite-weathered", rng: &r)
        }
        let b = m.bounds
        let shift = Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2))
        m = m.transformed(shift)
        groundAO(&m, height: 0.04, floor: 0.7)
        lite = lite.transformed(shift)
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
