import simd
import Foundation

/// Resin-bound gravel tile, 2 x 2 m: an 18 mm layer of 2-5 mm golden quartz and flint aggregate
/// mixed in clear UV-stable polyurethane resin, hand-trowelled over a concrete base. The surface is
/// flat but porous, with stones standing proud of the binder and faint arcing trowel laps.
public struct ResinBoundGravel: RealAsset {
    public static let id = "resin-bound-gravel"
    public static let summary = "Resin-bound gravel tile, 2 x 2 m: 18 mm layer of 2-5 mm golden quartz aggregate in clear resin over concrete, trowelled flat and porous."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.7, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.05, 2.0)
    /// Resin layer thickness (m).
    public var layer: Float = 0.018
    /// Aggregate stones modelled individually on the surface.
    public var stoneCount: Int = 560
    /// Aggregate tones: golden quartz, buff flint, white quartz, amber.
    public var stoneKeys: [MaterialKey] = ["rock.river:C9A86A", "rock.river:B8975C", "rock.river:D8C9A6", "rock.river:A9824E", "rock.river:E2D8C2", "rock.river:8F7452"]
    /// Bound aggregate matrix.
    public var matrix: MaterialKey = "ground.gravel:BFA477"
    /// Concrete base.
    public var base: MaterialKey = "concrete.rough:8E8A84"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, hx = size.x / 2, hz = size.z / 2, ph = rng.float(0...6.28)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        func h(_ p: V2) -> Float {
            // Trowel laps: shallow arcs from sweeping the float.
            let lap = 0.0008 * sin(simd_length(p - V2(-1.4, -1.1)) * 2 * .pi / 0.32 + ph)
            return lap + 0.0012 * Noise.fbm(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd)
        }
        GK.slab(&m, w: size.x - 0.002, d: size.z - 0.002, h: top - layer, base, r: 0.002)
        GTK.field(&m, w: size.x, d: size.z, edge: top - 0.002, segments: 50, matrix, uvScale: 1) { h($0) }
        var lite = m
        GTK.stones(&m, &rng, count: stoneCount, hx: hx - 0.004, hz: hz - 0.004, size: 0.004...0.0075, flat: 0.5...0.75,
                   keys: stoneKeys, subdivisions: 1, sink: 0.55, surface: { top - 0.002 + h($0) })
        groundAO(&m, height: 0.03, floor: 0.75)
        groundAO(&lite, height: 0.03, floor: 0.75)
        return LODModel(levels: [m, lite], switchDistances: [4])
    }
}
