import simd
import Foundation

/// Fieldstone veneer panel: architectural facade customizer, Craftsman. Rounded glacial fieldstones and
/// split-face stones of mixed granite tones laid random-rubble (uncoursed) in a grey cement-lime mortar
/// with raked joints, small chinking stones filling the gaps, over a 100 mm veneer backing that sits on a
/// galvanized weep screed with weep slots at the base.
public struct FieldstoneVeneerPanel: RealAsset {
    public static let id = "fieldstone-veneer-panel"
    public static let summary = "Craftsman fieldstone veneer panel, 1.2 m: rounded and split glacial fieldstones of mixed granite tones laid random-rubble in raked grey mortar."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 1.2, 0.15)
    /// Band height range for the random rubble layout (m).
    public var bandRange: ClosedRange<Float> = 0.13...0.24
    /// Stone length range (m).
    public var lengthRange: ClosedRange<Float> = 0.15...0.34
    /// Mortar joint width (m).
    public var joint: Float = 0.018
    /// Fieldstone tones (sRGB hex): grey granite, pink granite, buff, rust-stained, dark basalt, tan.
    public var tones: [UInt32] = [0x7E7C78, 0x8E766A, 0x98896E, 0x86634C, 0x55534F, 0xA0957E, 0x6C665C]
    /// Fieldstone material.
    public var stone: MaterialKey = "rock.granite-bare"
    /// Rounded river-worn stone material.
    public var rounded: MaterialKey = "rock.river"
    /// Grey cement-lime mortar.
    public var mortar: MaterialKey = "concrete.rough:7E7A72"
    /// Weep screed metal.
    public var screed: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let D = size.z, face: Float = D - 0.042, base: Float = 0.03
        SWK.mortar(&m, w: size.x, y0: base, y1: size.y, face: face, key: mortar, core: mortar, rough: 0.005, seed: 11)
        let rows = SWK.courses(&rng, w: size.x, y0: base, y1: size.y, heights: bandRange, lengths: lengthRange, joint: joint)
        var n = 0
        for row in rows {
            for u in row {
                n += 1
                var r = rng.fork(n)
                let w = u.x1 - u.x0, h = u.y1 - u.y0
                // Random rubble: each stone shrinks and slides inside its cell so the bed joints wander.
                let sw = w * r.float(0.93...1.02), sh = h * r.float(0.86...1.02)
                let cx = (u.x0 + u.x1) / 2 + r.float(-1...1) * (w - sw) / 2
                let cy = (u.y0 + u.y1) / 2 + r.float(-1...1) * (h - sh) / 2
                let split = r.chance(0.65)
                let tone = r.pick(tones)
                let key: MaterialKey = split ? SWK.tint(stone, tone) : SWK.tint(rounded, tone)
                // Widest section sits at the mortar face so the joints stay tight; the bulk is buried.
                let proud = r.float(0.018...0.034)
                let dz = proud * 2.6
                SWK.stone(&m, V3(cx, cy, face + proud - dz / 2), V3(sw, sh, dz), exponent: split ? r.float(3.6...5) : r.float(2.8...3.6), sub: 4,
                          relief: split ? r.float(0.04...0.07) : r.float(0.05...0.1), key: key,
                          roll: r.float(-12...12), yaw: r.float(-4...4), pitch: r.float(-4...4), seed: UInt32(n * 13), face: split ? 0.3 : 0.7, freq: split ? 3.2 : 1.6)
                // Chinking stones in the gaps left by shrunk stones.
                if (w - sw) + (h - sh) > 0.03 && r.chance(0.5) {
                    let gx = cx + (cx > (u.x0 + u.x1) / 2 ? -1 : 1) * (sw / 2 + 0.02)
                    let gy = cy + (cy > (u.y0 + u.y1) / 2 ? -1 : 1) * (sh / 2 - 0.01)
                    SWK.stone(&m, V3(min(max(gx, -size.x / 2 + 0.03), size.x / 2 - 0.03), min(max(gy, base + 0.03), size.y - 0.03), face + 0.004),
                              V3(r.float(0.035...0.06), r.float(0.025...0.045), 0.03), exponent: 2.6, sub: 2, relief: 0.15,
                              key: SWK.tint(rounded, r.pick(tones)), roll: r.float(0...180), seed: UInt32(n + 700))
                }
            }
        }
        // Galvanized weep screed: L-angle under the veneer with a drip leg and weep slots.
        FA.box(&m, V3(size.x, 0.003, D - 0.004), V3(0, base - 0.0015, (D - 0.004) / 2), screed, r: 0.001)
        FA.box(&m, V3(size.x, base, 0.003), V3(0, base / 2, D - 0.0055), screed, r: 0.001)
        for x in stride(from: -0.45 as Float, through: 0.46, by: 0.3) {
            FA.box(&m, V3(0.035, 0.01, 0.006), V3(x, base / 2, D - 0.004), "metal.iron:1A1A1A", r: 0.001)
        }
        return SWK.finish(&m, id: Self.id, cap: SWK.tint(stone, tones[0]))
    }
}
