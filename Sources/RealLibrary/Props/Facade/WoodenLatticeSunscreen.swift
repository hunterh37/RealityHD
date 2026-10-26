import simd
import Foundation

/// Wooden lattice sunscreen: a hardwood frame holding vertical battens over horizontal slats with pegged
/// half-lap crossings, stood off the wall on stainless standoffs with domed caps. Wall plane at z = 0.
public struct WoodenLatticeSunscreen: RealAsset {
    public static let id = "wooden-lattice-sunscreen"
    public static let summary = "Tropical modern hardwood lattice sunscreen 1.5 x 2.4 m: framed square slat lattice, half-lap crossings, stainless standoffs."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal", "decor"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 6, distance: 3.9)

    public var width: Float = 1.5
    public var height: Float = 2.4
    /// Batten and slat pitch (m).
    public var battenPitch: Float = 0.092
    public var slatPitch: Float = 0.150
    public var frame: MaterialKey = "wood.lumber-oak:7A5434"
    public var slat: MaterialKey = "wood.lumber-oak:94693F"
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let fz: Float = 0.017, fd: Float = 0.032   // frame front plane start and depth
        let stile: Float = 0.068, rail: Float = 0.085
        // Frame: stiles run full height, rails tenon between them, with a stopped rebate bead inside.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(stile, H, fd), V3(e * (W / 2 - stile / 2), H / 2, fz + fd / 2), frame, r: 0.004)
            FA.box(&m, V3(0.005, H - 2 * rail, 0.006), V3(e * (W / 2 - stile - 0.0025), H / 2, fz + fd - 0.003), frame, r: 0.001)
        }
        let iw = W - 2 * stile
        for (y, tag) in [(rail / 2, 0), (H - rail / 2, 1)] {
            FA.box(&m, V3(iw + 0.004, rail, fd * 0.96), V3(0, y, fz + fd / 2), tag == 1 ? "wood.cedar-weathered" : frame, r: 0.004)
        }
        FA.box(&m, V3(iw, 0.005, 0.006), V3(0, rail + 0.0025, fz + fd - 0.003), frame, r: 0.001)
        FA.box(&m, V3(iw, 0.005, 0.006), V3(0, H - rail - 0.0025, fz + fd - 0.003), frame, r: 0.001)
        // Horizontal slats (rear layer), then vertical battens (front layer).
        let hy0 = rail + 0.04, hy1 = H - rail - 0.04
        let nh = Int((hy1 - hy0) / slatPitch) + 1
        let hp = (hy1 - hy0) / Float(nh - 1)
        let nv = Int(iw / battenPitch)
        let vp = iw / Float(nv)
        var slatTones: [MaterialKey] = []
        for i in 0..<nh {
            let y = hy0 + Float(i) * hp
            let tone: MaterialKey = rng.chance(0.25) ? "wood.cedar-weathered" : slat
            slatTones.append(tone)
            FA.box(&m, V3(iw - 0.004, 0.040, 0.015), V3(0, y, fz + 0.012), tone, r: 0.0022)
        }
        for j in 0..<nv {
            let x = -iw / 2 + vp * (Float(j) + 0.5)
            let tone: MaterialKey = rng.chance(0.22) ? "wood.cedar-weathered" : slat
            FA.box(&m, V3(0.032, hy1 - hy0 + 0.17, 0.016), V3(x, H / 2, fz + 0.027), tone, r: 0.0022)
        }
        // Pegged crossings: round hardwood pegs through the half-laps on every second crossing.
        for i in 0..<nh {
            for j in 0..<nv where (i + j) % 3 == 0 {
                let x = -iw / 2 + vp * (Float(j) + 0.5)
                FA.cylZ(&m, r: 0.0042, h: 0.004, at: V3(x, hy0 + Float(i) * hp, fz + 0.034), "wood.endgrain-weathered", bevel: 0.0006, segments: 6)
            }
        }
        // Stainless standoffs: tube spacers on the stiles with domed cap screws on the front.
        for y in [0.35, H / 2, H - 0.35] as [Float] {
            for e: Float in [-1, 1] {
                let x = e * (W / 2 - stile / 2)
                FA.cylZ(&m, r: 0.011, h: fz + 0.001, at: V3(x, y, 0), steel, bevel: 0.0015, segments: 14)
                FA.cylZ(&m, r: 0.0085, h: 0.0035, at: V3(x, y, fz + fd - 0.001), steel, bevel: 0.0015, segments: 12)
                FC.bead(&m, r: 0.0078, at: V3(x, y, fz + fd + 0.002), steel, sub: 3)
            }
        }
        // Silvered tops and water staining at the foot of the stiles.
        FA.box(&m, V3(iw, 0.0008, fd * 0.9), V3(0, H + 0.0004, fz + fd / 2), "wood.weathered", r: 0.0002)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(stile * 0.9, 0.26, 0.0008), V3(e * (W / 2 - stile / 2), 0.15, fz + fd + 0.0004), "wood.weathered", r: 0.0003)
            FA.box(&m, V3(stile * 0.9, 0.0008, fd * 0.8), V3(e * (W / 2 - stile / 2), H + 0.0004, fz + fd / 2), "wood.weathered", r: 0.0002)
        }
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
