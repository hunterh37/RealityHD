import simd
import Foundation

/// Roughcast lime render panel, Arts and Crafts: thrown lime render with pebble aggregate on a scratch
/// coat, smooth trowelled margins, a stainless bell-cast bead over a smooth plinth. Wall plane at z = 0.
public struct RoughcastLimeRenderPanel: RealAsset {
    public static let id = "roughcast-lime-render-panel"
    public static let summary = "Roughcast lime render panel: thrown pebble-aggregate lime render with smooth margins and a bell-cast bead at the base."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 3.2)

    /// Panel width (m).
    public var width: Float = 1.2
    /// Panel height (m).
    public var height: Float = 2.4
    /// Lime-washed roughcast.
    public var render: MaterialKey = "paint.stucco:D6CCB6"
    /// Pebble-dash field (thrown aggregate).
    public var dash: MaterialKey = "concrete.exposed-aggregate:D4CBB6"
    /// Soiled dash in the splash zone.
    public var splashDash: MaterialKey = "concrete.exposed-aggregate:A99F8A"
    /// Pebble aggregate.
    public var pebble: MaterialKey = "paint.stucco:CDBB9A"
    /// Scratch coat showing at the chip.
    public var scratch: MaterialKey = "concrete.rough"
    /// Beads.
    public var bead: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let margin: Float = 0.06, plinthH: Float = 0.18, back: Float = 0.013
        let fw = width - 2 * margin, fh = height - plinthH - margin - 0.02
        let fy0 = plinthH + 0.02
        // scratch coat backing
        FA.box(&m, V3(width - 0.004, height, back), V3(0, height / 2, back / 2), scratch, r: 0.003)
        // smooth trowelled margins (sides and head) and plinth
        FA.box(&m, V3(margin, height - plinthH, 0.012), V3(-width / 2 + margin / 2, plinthH + (height - plinthH) / 2, back + 0.006), render, r: 0.004)
        FA.box(&m, V3(margin, height - plinthH, 0.012), V3(width / 2 - margin / 2, plinthH + (height - plinthH) / 2, back + 0.006), render, r: 0.004)
        FA.box(&m, V3(width - 2 * margin, margin, 0.012), V3(0, height - margin / 2, back + 0.006), render, r: 0.004)
        FA.box(&m, V3(width, plinthH, 0.014), V3(0, plinthH / 2, back + 0.007), "paint.stucco:D3CBB8", r: 0.004)
        // bell-cast bead: stainless drip nosing kicked out over the plinth
        FA.run(&m, [V2(0, 0), V2(0.026, -0.006), V2(0.027, 0.0), V2(0.004, 0.012), V2(0, 0.012)], length: width,
               at: V3(0, plinthH, back), bead, bevel: 0.0008)
        // thrown roughcast field: heightfield with chip exposing the scratch coat
        let chip = V2(fw * 0.28, 0.55)
        // height of the dash at (x, y above the field base)
        let hf: (Float, Float) -> Float = { gx, gy in
            var h: Float = 0.006
            h += 0.0035 * Noise.fbm(V3(gx * 90, gy * 90, 0.3), octaves: 4)
            let w = Noise.worley(V3(gx * 160, gy * 160, 1.7))
            h += 0.0028 * max(0, 0.45 - w.f1) / 0.45
            let dv = V2(gx, gy) - chip
            let d = simd_length(dv) * (1 + 0.45 * Noise.fbm(V3(atan2(dv.y, dv.x) * 1.3, 0.5, 2.1), octaves: 3))
            if d < 0.11 { h -= 0.014 * min(1, (1 - d / 0.11) * 3) }
            return h
        }
        // splash zone: lower 300 mm of dash soiled by rain back-splash
        let splash: Float = 0.3
        for (y0, hh, mat, seg) in [(splash, fh - splash, dash, 66), (splash * 0.55, splash * 0.45, "concrete.exposed-aggregate:BFB6A0", 12), (Float(0), splash * 0.55, splashDash, 14)] {
            let f = Prim.terrain(size: V2(fw, hh), segments: seg, material: mat) { p in hf(p.x, y0 + hh / 2 - p.y) }
            m.add(f, Xform(translation: V3(0, fy0 + y0 + hh / 2, back), rotation: FA.q(90, FA.X)))
        }
        // stainless angle beads on the vertical arrises
        for sx in [Float(-1), 1] {
            FA.box(&m, V3(0.006, height - plinthH - 0.004, 0.006), V3(sx * (width / 2 - 0.003), plinthH + (height - plinthH) / 2, back + 0.009), bead, r: 0.0015)
        }
        // pebble aggregate thrown into the wet coat: a few larger stones proud of the dash
        for k in 0..<40 {
            var r = rng.fork(1000 + k)
            let x = r.float(-fw / 2 + 0.02...fw / 2 - 0.02), yy = r.float(fy0 + 0.02...fy0 + fh - 0.02)
            if simd_length(V2(x, yy - fy0) - chip) < 0.09 { continue }
            let s = r.float(0.012...0.02)
            let surf = Prim.superellipsoid(V3(s, s * r.float(0.7...1), s * 0.6), exponent: 2.4, subdivisions: 1,
                                           material: dash)
            m.add(surf, Xform(translation: V3(x, yy, back + 0.008)))
        }
        // green algae streak under the head margin run-off point
        for k in 0..<6 { let ky = height - margin - 0.12 - Float(k) * 0.11; FA.box(&m, V3(0.05 - Float(k) * 0.006, 0.12, 0.003), V3(width / 2 - margin - 0.06 + Float(k % 2) * 0.006, ky, back + 0.0155), "paint.stucco:7F8A62", r: 0.0012) }
        groundAO(&m, height: 0.15, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
