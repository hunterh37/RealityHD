import simd
import Foundation

/// Travertine tile paving, 2 x 2 m: tumbled travertine 30 mm thick in a modular French (Versailles)
/// pattern of 200x200, 200x400, 400x400 and 400x600 mm tiles, on a sand and screed bed with sand-
/// swept joints. Faces carry the open pits of natural travertine; arrises are rounded by tumbling.
/// One tile is cracked across and a little moss grows in a shaded joint.
public struct TravertineTilePaving: RealAsset {
    public static let id = "travertine-tile-paving"
    public static let summary = "Travertine tile paving, 2 x 2 m: tumbled ivory and walnut travertine in a French pattern, pitted faces, sand joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.8, studio: true)

    /// Overall size in meters.
    public var size = V3(2.0, 0.05, 2.0)
    /// Tile thickness (m).
    public var thickness: Float = 0.03
    /// Joint width (m).
    public var joint: Float = 0.004
    /// Travertine tones: ivory, light walnut, honey, cream.
    public var tones: [UInt32] = [0xE4D6BC, 0xD2BE9C, 0xDCC8A6, 0xC9B08A, 0xE8DDC8]
    /// Tile material.
    public var stone: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y - 0.002, g = joint, u: Float = 0.2
        let keys = tones.map { "\(stone):\(String(format: "%06X", $0))" }
        // Modular grid of 0.2 m cells filled greedily with the four module sizes (in cells).
        let n = Int(size.x / u)
        var used = Array(repeating: Array(repeating: false, count: n), count: n)
        let shapes: [(Int, Int)] = [(3, 2), (2, 3), (2, 2), (2, 1), (1, 2), (1, 1)]
        var tiles: [(Int, Int, Int, Int)] = []
        for j in 0..<n { for i in 0..<n where !used[j][i] {
            var opts = shapes.filter { s in
                i + s.0 <= n && j + s.1 <= n && (0..<s.1).allSatisfy { dj in (0..<s.0).allSatisfy { di in !used[j + dj][i + di] } }
            }
            if opts.count > 1 && rng.chance(0.25) { opts.removeFirst() }
            let s = opts.count > 2 && rng.chance(0.3) ? opts[1] : opts[0]
            for dj in 0..<s.1 { for di in 0..<s.0 { used[j + dj][i + di] = true } }
            tiles.append((i, j, s.0, s.1))
        }}
        let crackIdx = rng.int(0...(tiles.count - 1))
        for (k, t) in tiles.enumerated() {
            let x0 = -size.x / 2 + Float(t.0) * u + g / 2, z0 = -size.z / 2 + Float(t.1) * u + g / 2
            let x1 = x0 + Float(t.2) * u - g, z1 = z0 + Float(t.3) * u - g
            let key = rng.pick(keys)
            let ty = top + rng.float(-0.0015...0.0015)
            if k == crackIdx {
                let a = rng.float(0.3...0.7), b = rng.float(0.3...0.7)
                let za = z0 + (z1 - z0) * a, zb = z0 + (z1 - z0) * b
                FPK.piece(&m, [V2(x0, z0), V2(x1, z0), V2(x1, zb - 0.001), V2(x0, za - 0.001)], top: ty, thick: thickness, bevel: 0.006, key, tilt: 0.3, rng: &rng)
                FPK.piece(&m, [V2(x0, za + 0.001), V2(x1, zb + 0.001), V2(x1, z1), V2(x0, z1)], top: ty - 0.0015, thick: thickness, bevel: 0.006, key, tilt: 0.3, rng: &rng)
            } else {
                FPK.piece(&m, FPK.rect((x0 + x1) / 2, (z0 + z1) / 2, x1 - x0, z1 - z0), top: ty, thick: thickness, bevel: 0.007, key, tilt: 0.25, rng: &rng)
            }
            // Bedding-plane banding: long faint streaks along the tile's long side.
            let alongX = (x1 - x0) >= (z1 - z0)
            for q in 0..<rng.int(2...4) {
                var r = rng.fork(5000 + k * 10 + q)
                let c = V2(r.float((x0 + 0.03)...(x1 - 0.03)), r.float((z0 + 0.03)...(z1 - 0.03)))
                let L = (alongX ? x1 - x0 : z1 - z0) * r.float(0.3...0.45), wd = r.float(0.002...0.006)
                let lim = alongX ? min(L, min(c.x - x0, x1 - c.x) - 0.01) : min(L, min(c.y - z0, z1 - c.y) - 0.01)
                guard lim > 0.03 else { continue }
                GK.poly(&m, (0..<10).map { i in let t = Float(i) / 10 * 2 * .pi; let a = cos(t) * lim, b = sin(t) * wd * (1 + 0.4 * sin(t * 3)); return c + (alongX ? V2(a, b) : V2(b, a)) },
                        top: ty - 0.0002, "\(stone):\(String(format: "%06X", tones[1]))", thick: 0.0005)
            }
            // Open pits: shallow dark ovals, more on the walnut tones.
            let area = (x1 - x0) * (z1 - z0)
            for q in 0..<Int(area * rng.float(6...14)) {
                var r = rng.fork(2000 + k * 100 + q)
                let c = V2(r.float((x0 + 0.015)...(x1 - 0.015)), r.float((z0 + 0.015)...(z1 - 0.015)))
                let a = r.float(0.004...0.014), bb = a * r.float(0.3...0.7), yaw = r.float(0...6.28)
                GK.poly(&m, (0..<7).map { i in let t = Float(i) / 7 * 2 * .pi; let v = V2(cos(t) * a, sin(t) * bb); return c + V2(v.x * cos(yaw) - v.y * sin(yaw), v.x * sin(yaw) + v.y * cos(yaw)) },
                        top: ty - 0.0002, "ground.dirt:4E4232", thick: 0.0006)
            }
        }
        // Moss in one shaded joint run.
        for k in 0..<6 {
            FPK.moss(&m, at: V2(-size.x / 2 + 0.2 * Float(rng.int(1...9)) + 0.0, -size.z / 2 + 0.2 * Float(rng.int(1...9)) + rng.float(-0.05...0.05) * 0 + Float(k) * 0.0), y: top - 0.009, len: rng.float(0.03...0.07), alongX: rng.chance(0.5))
        }
        // Sand swept joints and screed bed.
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.007, "ground.sand:CDBB98", r: 0.002)
        GK.box(&m, V3(0, 0.005, 0), V3(size.x - 0.002, 0.01, size.z - 0.002), "concrete.rough:9A968E", r: 0.002)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: keys[0]), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
