import simd
import Foundation

/// Wetpour rubber safety surface tile, 2 x 2 m: a 15 mm EPDM granule wearing course bound in
/// polyurethane over a 45 mm black SBR shock pad (critical fall height ~1.2 m). Green field with a
/// blue curved inlay band, granule texture modelled at the surface and a scuffed patch where feet
/// land off a slide.
public struct RubberSafetyPlaySurface: RealAsset {
    public static let id = "rubber-safety-play-surface"
    public static let summary = "Wetpour rubber safety surface tile, 2 x 2 m: EPDM granule top course over black SBR shock pad with a coloured inlay band."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.06, 2.0)
    /// EPDM wearing course thickness (m).
    public var wear: Float = 0.015
    /// Field colour.
    public var field: MaterialKey = "ground.sand:3E7A3A"
    /// Inlay band colour.
    public var inlay: MaterialKey = "ground.sand:2F5E9E"
    /// SBR shock pad.
    public var sbr: MaterialKey = "rubber.tire:1C1B1A"
    /// Loose EPDM granules modelled at the surface.
    public var granules: Int = 450
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, hx = size.x / 2, hz = size.z / 2
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let scuff = V2(rng.float(-0.5...0.2), rng.float(0.1...0.5))
        func h(_ p: V2) -> Float {
            let dip = -0.003 * exp(-simd_length_squared((p - scuff) * V2(5, 7)))
            return dip + 0.0015 * Noise.fbm(V3(p.x * 40, 0, p.y * 40), octaves: 2, seed: sd)
        }
        // SBR shock pad (black crumb) under the coloured course.
        GK.slab(&m, w: size.x - 0.002, d: size.z - 0.002, h: top - wear, sbr, r: 0.002)
        GTK.field(&m, w: size.x, d: size.z, edge: top - 0.0015, segments: 50, field, uvScale: 1) { h($0) }
        // Blue inlay band: an S-curve 0.16 m wide crossing the tile, poured flush.
        let n = 40
        var left: [V2] = [], right: [V2] = []
        for i in 0...n {
            let t = Float(i) / Float(n), x = -hx + 0.002 + t * (size.x - 0.004)
            let z = 0.35 * sin(t * .pi * 1.3 - 0.4) - 0.2
            left.append(V2(x, z - 0.08)); right.append(V2(x, z + 0.08))
        }
        for i in 0..<n {
            let q = [left[i], left[i + 1], right[i + 1], right[i]]
            let c = FPK.centroid(q)
            GK.poly(&m, q, top: top - 0.0012 + h(c), inlay, thick: 0.003)
        }
        // Worn, paler patch at the slide run-out.
        GK.poly(&m, (0..<14).map { k in let a = Float(k) / 14 * 2 * .pi; return scuff + V2(cos(a) * 0.17, sin(a) * 0.12) },
                top: top - 0.0008 + h(scuff), "ground.sand:6B8E5A", thick: 0.002)
        var lite = m
        // Proud EPDM granules (1-4 mm) in field green with a few blue strays.
        GTK.stones(&m, &rng, count: granules, hx: hx - 0.004, hz: hz - 0.004, size: 0.003...0.005, flat: 0.6...0.9,
                   keys: [field, field, field, "ground.sand:4C8C44", inlay], subdivisions: 1, exponent: 3, sink: 0.6,
                   surface: { top - 0.0015 + h($0) })
        groundAO(&m, height: 0.03, floor: 0.75); groundAO(&lite, height: 0.03, floor: 0.75)
        return LODModel(levels: [m, lite], switchDistances: [5])
    }
}
