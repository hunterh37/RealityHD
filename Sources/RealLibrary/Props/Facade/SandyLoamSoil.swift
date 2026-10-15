import simd
import Foundation

/// Sandy loam soil tile, 2 x 2 m: pale crumbly loam 6 cm deep, raked level with a garden rake whose
/// tines left shallow parallel furrows along X, pale sandy crumb
/// aggregates and small rounded pebbles drawn up by the rake, and a heel print where the raker stood.
public struct SandyLoamSoil: RealAsset {
    public static let id = "sandy-loam-soil"
    public static let summary = "Sandy loam soil tile, 2 x 2 m: pale crumbly loam raked smooth with rake tines, small pebbles and dried crust."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Soil depth at the tile edge (m).
    public var depth: Float = 0.068
    /// Rake tine spacing (m).
    public var tinePitch: Float = 0.025
    /// Loam material.
    public var loam: MaterialKey = "soil.potting:8A6C4E"
    /// Sandy crumb material.
    public var sand: MaterialKey = "ground.sand:C2A77E"
    /// Pebble material.
    public var pebble: MaterialKey = "rock.river"
    /// Crumbs and pebbles modelled on the surface.
    public var crumbs: Int = 90
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        let heel = V2(rng.float(0.3...0.6), rng.float(-0.6...(-0.3)))
        func bump(_ p: V2) -> Float {
            var h = 0.012 * Noise.fbm(V3(p.x * 2.5, 0, p.y * 2.5), octaves: 4, seed: sd)
            // Rake furrows, wavering slightly, fading out where the rake was lifted at the end of the stroke.
            let fade = 0.5 + 0.5 * tanh((0.75 - p.x) * 6)
            let ph = (p.y + 0.012 * sin(p.x * 4 + Float(sd % 5)) + 0.01 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), octaves: 2, seed: sd + 9)) / tinePitch * 2 * .pi
            h += 0.004 * fade * (0.6 + 0.4 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 2, seed: sd + 7)) * (cos(ph) * 0.5 + 0.5) - 0.002 * fade
            h += 0.0025 * Noise.fbm(V3(p.x * 22, 0, p.y * 22), octaves: 2, seed: sd + 2)
            let q = (p - heel) * V2(1, 0.75)
            h -= 0.008 * exp(-pow(simd_length(q) / 0.05, 4))
            return h
        }
        var m = Model(name: Self.id)
        GTK.field(&m, w: w, d: d, edge: depth, segments: 64, loam, uvScale: 1, bump: bump)
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return depth + bump(p) * k * k * (3 - 2 * k)
        }
        var lite = Model(name: Self.id + "-lite")
        GTK.field(&lite, w: w, d: d, edge: depth, segments: 24, loam, uvScale: 1, bump: bump)
        // Crumb aggregates and rake-drawn pebbles.
        GTK.stones(&m, &rng, count: crumbs, hx: 0.95, hz: 0.95, size: 0.01...0.028, flat: 0.6...0.9, keys: [loam, sand], sink: 0.4, surface: height)
        GTK.stones(&m, &rng, count: 70, hx: 0.95, hz: 0.95, size: 0.01...0.03, keys: [pebble, "rock.granite-weathered"], subdivisions: 1, sink: 0.35, surface: height)
        return GTK.finish(&m, &lite, ao: 0.03, switchAt: 8)
    }
}
