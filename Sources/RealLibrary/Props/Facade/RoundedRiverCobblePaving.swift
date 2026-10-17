import simd
import Foundation

/// Rounded river cobble paving: architectural facade customizer, Vernacular. Water-worn river cobbles
/// 90-135 mm long set on end, close-packed in a lime mortar bed with recessed joints; mixed grey,
/// buff and dark stones, a few proud of the bed.
public struct RoundedRiverCobblePaving: RealAsset {
    public static let id = "rounded-river-cobble-paving"
    public static let summary = "Rounded river cobble paving, 2 x 2 m: vernacular rounded river cobbles set close in a lime mortar bed."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Cobble grid pitch (m); divides the tile so it repeats.
    public var pitch: Float = 2.0 / 17
    /// Stone tones (sRGB hex).
    public var tones: [UInt32] = [0x8E8A82, 0x6E6A66, 0xA49A88, 0x5A5856, 0x9A9690, 0x7E7262]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = Int(size.x / pitch + 0.5)
        let bedTop = size.y - 0.028
        PTK.bed(&m, w: size.x, d: size.z, top: bedTop, PTK.tint("concrete.rough", 0x8C8476))
        for j in 0..<n { for i in 0..<n {
            var r = rng.fork(j * 131 + i)
            let jx = r.float(-0.02...0.02), jz = r.float(-0.02...0.02)
            let c = V2(-size.x / 2 + pitch * (Float(i) + 0.5) + jx, -size.z / 2 + pitch * (Float(j) + 0.5) + jz)
            let l = pitch * r.float(0.95...1.15), w = l * r.float(0.62...0.85)
            let h = r.float(0.07...0.09)
            let lim = size.x / 2 - l / 2 - 0.002
            let cc = V2(max(-lim, min(lim, c.x)), max(-lim, min(lim, c.y)))
            let top = size.y - r.float(0...0.012)
            PTK.block(&m, V3(cc.x, top - h / 2, cc.y), V3(l, h, w), exponent: 2.3, subdivisions: 2, relief: 0.06,
                      key: PTK.tint(r.float() < 0.25 ? "rock.river-wet" : "rock.river", r.pick(tones)), yaw: r.float(0...180), tilt: r.float(-6...6),
                      seed: UInt32(truncatingIfNeeded: r.int(0...100_000)))
        }}
        return PTK.finish(&m, id: Self.id, size: size, cap: PTK.tint("rock.river", tones[0]))
    }
}
