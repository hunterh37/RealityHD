import simd
import Foundation

/// Coursed rubble stone panel: architectural facade customizer, Cotswold Vernacular. Roughly squared
/// honey-coloured oolitic limestone rubble laid in irregular courses 70-170 mm high on a recessed lime
/// mortar bed, with pinning spalls in the wider joints, a through-stone end, and lichen and soot on the
/// weathered stones. 300 mm wall thickness.
public struct CoursedRubbleStonePanel: RealAsset {
    public static let id = "coursed-rubble-stone-panel"
    public static let summary = "Cotswold coursed rubble wall panel, 1.2 m: roughly squared honey oolitic limestone in irregular courses, recessed lime mortar, through-stones and lichen."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.4)

    /// Overall size in meters (x width, y height, z wall thickness).
    public var size = V3(1.2, 1.2, 0.3)
    /// Course height range (m).
    public var courseRange: ClosedRange<Float> = 0.075...0.17
    /// Stone length range (m).
    public var lengthRange: ClosedRange<Float> = 0.16...0.42
    /// Mortar joint width (m).
    public var joint: Float = 0.014
    /// Stone tones (sRGB hex): honey, buff, grey-weathered, rust-stained oolite.
    public var tones: [UInt32] = [0xC9A46A, 0xBF9B63, 0xD2B27A, 0xA99472, 0xB88E58, 0x9E9584]
    /// Stone material.
    public var stone: MaterialKey = "rock.limestone"
        /// Lime mortar.
    public var mortar: MaterialKey = "concrete.rough:A89A80"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let D = size.z, face: Float = D - 0.03
        SWK.mortar(&m, w: size.x, y0: 0, y1: size.y, face: face, key: mortar, core: SWK.tint(stone, 0x9E8C6C), rough: 0.004)
        let rows = SWK.courses(&rng, w: size.x, y0: 0, y1: size.y, heights: courseRange, lengths: lengthRange, joint: joint)
        var n = 0
        for (ri, row) in rows.enumerated() {
            for u in row {
                n += 1
                var r = rng.fork(n)
                let w = u.x1 - u.x0, h = u.y1 - u.y0
                let shrinkH = r.float(0.0...0.012)
                let dz = r.float(0.10...0.14)
                // Squared rubble: a crisp-ish superellipsoid with a split, bumpy face, 8-26 mm proud of the mortar.
                let proud = r.float(0.008...0.02)
                var tone = r.pick(tones)
                // Rain-splash zone: the bottom courses weather darker and greyer.
                if u.y1 < 0.22 { tone = r.chance(0.6) ? 0x8A8070 : 0x9C8D70 }
                let key: MaterialKey = r.chance(0.12) ? SWK.tint(stone, 0x8F8B7C) : SWK.tint(stone, tone)
                SWK.stone(&m, V3((u.x0 + u.x1) / 2, (u.y0 + u.y1) / 2 - shrinkH / 3, face + proud - dz / 2),
                          V3(w, h - shrinkH, dz), exponent: r.float(7...10), sub: 4, relief: r.float(0.035...0.06), key: key,
                          roll: r.float(-1.5...1.5), yaw: r.float(-2...2), pitch: r.float(-3...3), seed: UInt32(n * 31 + ri), face: 0.85)
                // Pinning spall in the lower joint under long stones.
                if w > 0.3 && r.chance(0.5) {
                    let px = r.float(u.x0 + 0.05...u.x1 - 0.05)
                    SWK.stone(&m, V3(px, u.y0 - 0.002, face + 0.002), V3(r.float(0.04...0.07), 0.014, 0.03), exponent: 3, sub: 2,
                              relief: 0.15, key: SWK.tint(stone, 0x9C8A6A), roll: r.float(-8...8), seed: UInt32(n + 900))
                }
            }
        }
        // Lichen cushion and moss tufts on a few upper course ledges.
        for i in 0..<5 {
            var r = rng.fork(5000 + i)
            let x = r.float(-0.5...0.5), y = r.float(0.03...0.5)
            SWK.stone(&m, V3(x, y, face + 0.004), V3(r.float(0.05...0.09), 0.02, 0.03), exponent: 2.4, sub: 3, relief: 0.4,
                      key: "moss.cushion", seed: UInt32(i + 77))
        }
        return SWK.finish(&m, id: Self.id, cap: SWK.tint(stone, tones[0]))
    }
}
