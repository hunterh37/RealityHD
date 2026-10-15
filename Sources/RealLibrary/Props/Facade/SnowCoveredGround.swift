import simd
import Foundation

/// Snow covered ground tile, 2 x 2 m: 80-140 mm of settled snow over frozen soil, wind-scalloped into
/// low drift ridges, crossed by a line of boot prints, thinned to a patch of bare frozen earth with
/// dry grass tips poking through, and a glazed ice crust over a frozen puddle.
public struct SnowCoveredGround: RealAsset {
    public static let id = "snow-covered-ground"
    public static let summary = "Snow covered ground tile, 2 x 2 m: soft drifted snow over frozen soil with boot prints, wind ridges and dry grass tips poking through."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.2, 2.0)
    /// Snow depth at the tile edge (m).
    public var depth: Float = 0.13
    /// Snow material.
    public var snow: MaterialKey = "ground.snow"
    /// Frozen soil material.
    public var soil: MaterialKey = "ground.dirt:4E4034"
    /// Dry grass material.
    public var grass: MaterialKey = "grass.dry"
    /// Grass tufts through the snow.
    public var tufts: Int = 22
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let soilTop: Float = 0.04, edge = soilTop + depth
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let bare = V2(rng.float(0.2...0.5), rng.float(-0.6...(-0.3)))
        let pond = V2(rng.float(-0.6...(-0.3)), rng.float(0.3...0.6))
        // Boot prints: alternating left/right along a slightly curving walk line.
        var prints: [(V2, Float)] = []
        for k in 0..<7 {
            let z = -0.9 + Float(k) * 0.3, side: Float = k % 2 == 0 ? -1 : 1
            prints.append((V2(-0.15 + 0.12 * sin(z * 1.5) + side * 0.09, z), 0.12 * sin(z * 1.5)))
        }
        func h(_ p: V2) -> Float {
            let drift = 0.03 * sin(p.x * 3.1 + 0.8 * sin(p.y * 2.3)) * (0.6 + 0.4 * sin(p.y * 1.7))
            let grain = 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
            var v = drift + grain
            for (c, yaw) in prints {
                var q = p - c
                q = V2(q.x * cos(yaw) - q.y * sin(yaw), q.x * sin(yaw) + q.y * cos(yaw))
                let e = pow(q.x / 0.05, 2) + pow(q.y / 0.14, 2)
                let heel: Float = q.y > 0.07 ? 0.8 : 1
                v -= 0.07 * heel * exp(-pow(e, 3))
                v += 0.008 * exp(-pow((sqrt(e) - 1.15) / 0.18, 2))   // pushed-up rim
            }
            v -= 0.085 * exp(-pow(simd_length((p - bare) * V2(1, 1.3)) / 0.24, 2))
            v -= 0.075 * exp(-pow(simd_length((p - pond) * V2(1, 1.2)) / 0.2, 2))
            return v
        }
        // Frozen soil underneath, lumpy so it breaks through where the snow thins.
        GTK.field(&m, w: size.x, d: size.z, edge: soilTop, segments: 30, soil, uvScale: 1.5) { p in
            0.012 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 2, seed: sd + 3)
                + (0.085 + 0.02 * Noise.fbm(V3(p.x * 14, 0, p.y * 14), octaves: 2, seed: sd + 5)) * exp(-pow(simd_length((p - bare) * V2(1, 1.3)) / 0.2, 2))
        }
        GTK.field(&m, w: size.x, d: size.z, edge: edge, segments: 64, snow, uvScale: 1) { h($0) }
        // Ice crust over the frozen puddle.
        GK.poly(&m, (0..<18).map { k in let a = Float(k) / 18 * 2 * .pi; return pond + V2(cos(a), sin(a)) * (0.13 + 0.015 * sin(a * 4)) },
                top: edge - 0.068, "glass.frosted:8FA4B6", thick: 0.004)
        var lite = m
        // Dry grass tips through the thin snow and around the bare patch.
        for k in 0..<tufts {
            var r = rng.fork(400 + k)
            let a = r.float(0...6.28), rad = r.float(0.08...0.3)
            let p = bare + V2(cos(a) * rad, sin(a) * rad * 0.8)
            let y = min(edge + 0.01, max(soilTop, edge + h(p) - 0.02))
            for _ in 0..<r.int(5...9) {
                let b = V3(p.x + r.float(-0.02...0.02), y, p.y + r.float(-0.02...0.02))
                m.add(GTK.blade(b, height: r.float(0.03...0.06), lean: V3(r.float(-0.03...0.03), 0, r.float(-0.03...0.03)), width: 0.0016, material: grass))
            }
        }
        // Snow clods kicked out of the prints.
        GTK.stones(&m, &rng, count: 30, hx: 0.3, hz: 0.95, size: 0.01...0.025, keys: [snow], sink: 0.3, offset: V3(-0.15, 0, 0),
                   surface: { edge + h($0 + V2(-0.15, 0)) })
        groundAO(&m, height: 0.06, floor: 0.8); groundAO(&lite, height: 0.06, floor: 0.8)
        return LODModel(levels: [m, lite], switchDistances: [6])
    }
}
