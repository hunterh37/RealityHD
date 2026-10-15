import simd
import Foundation

/// Cobble wall chimney base: architectural facade customizer, Arts and Crafts. The base of an exterior
/// chimney breast faced in rounded river cobbles on the front and both returns, set in deep-struck lime
/// mortar with larger cobbles wrapping the corners. A sloped dressed sandstone weathering caps the base
/// with a throated drip, and a cast iron ash cleanout door with frame, hinge pins and latch sits low on
/// the front, sooted around its frame.
public struct CobbleWallChimneyBase: RealAsset {
    public static let id = "cobble-wall-chimney-base"
    public static let summary = "Arts and Crafts cobblestone chimney base, 1.2 x 1.0 m: river cobbles in struck mortar, sandstone weathering cap, cast iron cleanout door."
    public static let tags = ["prop", "architecture", "facade", "stone", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 2.4)

    /// Overall size in meters (x width, y height, z projection from the wall).
    public var size = V3(1.2, 1.0, 0.5)
    /// Cobble row pitch (m).
    public var rowPitch: Float = 0.11
    /// Cobble tones (sRGB hex): grey, blue-grey, buff, brown, rust, near-black.
    public var tones: [UInt32] = [0x8A8680, 0x6E7276, 0xA49A86, 0x7C6A58, 0x8E6650, 0x4E4C4A, 0x9C968A]
    /// Cobble material.
    public var cobble: MaterialKey = "rock.river"
    /// Lime mortar.
    public var mortar: MaterialKey = "concrete.rough:A39C8C"
    /// Weathering cap stone.
    public var cap: MaterialKey = "stone.sandstone:B4A486"
    /// Cleanout door iron.
    public var iron: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let out: Float = 0.03, W = size.x - 2 * out, hw = W / 2, D = size.z - out, capH: Float = 0.11, bodyH = size.y - capH
        let inset: Float = 0.03 // mortar face behind the cobble crowns
        // Mortar core: front face at z = D - inset, returns at x = +-(hw - inset).
        SWK.mortar(&m, w: W - 2 * inset, y0: 0, y1: bodyH, face: D - inset, key: mortar, rough: 0.005, seed: 31, segments: 24)
        // Lays rounded cobbles over a face: u across, v up; `at(u, v, proud)` maps to 3D, `yaw` turns the stone.
        var count = 0
        func face(width: Float, sub: Int, yaw: Float, at: (Float, Float, Float) -> V3) {
            var v: Float = 0.012
            var row = 0
            while v < bodyH - 0.05 {
                var r = rng.fork(9000 + row * 97 + Int(yaw))
                let h = rowPitch * r.float(0.8...1.1)
                var u: Float = -width / 2 + r.float(0.0...0.03)
                while u < width / 2 - 0.04 {
                    count += 1
                    var s = rng.fork(count)
                    let w = min(s.float(0.085...0.15), width / 2 - u)
                    if w < 0.05 { break }
                    let sh = min(h * s.float(0.8...0.98), bodyH - v - 0.01)
                    let proud = s.float(0.02...0.032)
                    let c = at(u + w / 2, v + h / 2 + s.float(-0.008...0.008), proud - proud * 1.3)
                    SWK.stone(&m, c, V3(w * 0.96, sh, proud * 2.6), exponent: s.float(2.2...2.8), sub: sub, relief: s.float(0.05...0.09),
                              key: SWK.tint(s.chance(0.15) ? "rock.river-wet" : cobble, s.pick(tones)),
                              roll: s.float(-20...20), yaw: yaw, pitch: 0, seed: UInt32(count), face: 0.6, freq: 1.5)
                    u += w + s.float(0.006...0.014)
                }
                v += h; row += 1
            }
        }
        let zf = D - inset
        face(width: W - 2 * inset - 0.02, sub: 3, yaw: 0) { u, v, p in V3(u, v, zf + p) }
        let sideW = D - inset - 0.02
        face(width: sideW, sub: 2, yaw: 90) { u, v, p in V3(hw - inset + p, v, (D - inset) / 2 - u) }
        face(width: sideW, sub: 2, yaw: -90) { u, v, p in V3(-(hw - inset) - p, v, (D - inset) / 2 + u) }
        // Corner cobbles wrapping each arris at 45 degrees.
        for e: Float in [-1, 1] {
            var y: Float = 0.05
            var k = 0
            while y < bodyH - 0.05 {
                var s = rng.fork(20_000 + k + (e > 0 ? 500 : 0))
                let h = s.float(0.08...0.11)
                SWK.stone(&m, V3(e * (hw - inset + 0.004), y, D - inset + 0.004), V3(0.1, h * 0.9, 0.08), exponent: 2.4, sub: 2, relief: 0.08,
                          key: SWK.tint(cobble, s.pick(tones)), roll: s.float(-15...15), yaw: e * 45, seed: UInt32(30_000 + k))
                y += h + 0.012; k += 1
            }
        }
        // Sandstone weathering: sloped top falling to the front, throated drip under the nosing, both returns.
        let prof: [V2] = [V2(0, 0), V2(D + out - 0.006, 0), V2(D + out, 0.006), V2(D + out, 0.045), V2(D + out - 0.006, 0.05), V2(0, capH - 0.002)]
        FA.run(&m, prof, length: W + 2 * out, at: V3(0, bodyH, 0), cap, bevel: 0.004)
        FA.box(&m, V3(W + 2 * out - 0.03, 0.008, 0.012), V3(0, bodyH - 0.001, D + out - 0.022), "concrete.rough:5E584E", r: 0.002) // drip throat shadow line
        // Bed joint under the cap.
        FA.box(&m, V3(W - 0.01, 0.012, D - 0.01), V3(0, bodyH - 0.006, (D - 0.01) / 2), mortar, r: 0.002)
        // Cast iron ash cleanout door: frame, door leaf with raised border, hinge pins, latch with turn-button.
        let dx: Float = 0.12, dy: Float = 0.24, zd = D - inset + 0.012
        FA.box(&m, V3(0.36, 0.3, 0.05), V3(dx, dy, zd - 0.025), "concrete.rough:2E2A26", r: 0.01) // sooted reveal
        FA.box(&m, V3(0.3, 0.24, 0.014), V3(dx, dy, zd + 0.007), iron, r: 0.004)
        FA.box(&m, V3(0.24, 0.18, 0.012), V3(dx, dy, zd + 0.02), "metal.cast-iron:3A2C24", r: 0.003)
        FA.box(&m, V3(0.2, 0.14, 0.006), V3(dx, dy, zd + 0.028), iron, r: 0.002)
        for hy: Float in [dy - 0.06, dy + 0.06] {
            FA.cylX(&m, r: 0.008, h: 0.03, at: V3(dx - 0.135, hy, zd + 0.022), iron, bevel: 0.002, segments: 10)
        }
        FA.cylZ(&m, r: 0.012, h: 0.012, at: V3(dx + 0.09, dy, zd + 0.026), "metal.cast-iron:6A4A3A", bevel: 0.002, segments: 12)
        FA.box(&m, V3(0.05, 0.012, 0.008), V3(dx + 0.09, dy, zd + 0.042), "metal.cast-iron:6A4A3A", r: 0.003)
        for (fx, fy) in [(dx - 0.13, dy - 0.1), (dx + 0.13, dy - 0.1), (dx - 0.13, dy + 0.1), (dx + 0.13, dy + 0.1)] {
            FC.bead(&m, r: 0.006, at: V3(fx, fy, zd + 0.014), iron)
        }
        return SWK.finish(&m, id: Self.id, cap: SWK.tint(cobble, tones[0]))
    }
}
