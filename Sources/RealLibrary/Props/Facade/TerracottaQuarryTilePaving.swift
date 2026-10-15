import simd
import Foundation

/// Terracotta quarry tile paving: architectural facade customizer, Mediterranean. 325 mm square
/// unglazed quarry tiles, 20 mm thick, in a square grid with 8 mm recessed lime mortar joints; tones
/// from orange to burnt umber, white efflorescence on one tile, one chipped corner.
public struct TerracottaQuarryTilePaving: RealAsset {
    public static let id = "terracotta-quarry-tile-paving"
    public static let summary = "Terracotta quarry tile paving, 2 x 2 m: Mediterranean 325 mm quarry tiles in a square grid with recessed mortar joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.06, 2.0)
    /// Tiles per side.
    public var count = 6
    /// Joint (m) and tile thickness (m).
    public var joint: Float = 0.008
    public var thickness: Float = 0.02
    /// Terracotta tones (sRGB hex).
    public var tones: [UInt32] = [0xA85A38, 0xA05434, 0x94492C, 0x9C5032, 0x8A4428]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let p = size.x / Float(count)
        PTK.bed(&m, w: size.x, d: size.z, top: size.y - 0.004, PTK.tint("concrete.rough", 0x8E8474))
        let chip = (rng.int(0...(count - 1)), rng.int(0...(count - 1)))
        let bloom = (rng.int(0...(count - 1)), rng.int(0...(count - 1)))
        for j in 0..<count { for i in 0..<count {
            var r = rng.fork(j * 17 + i)
            let x = -size.x / 2 + p * (Float(i) + 0.5), z = -size.z / 2 + p * (Float(j) + 0.5)
            let s = p - joint - r.float(0...0.003)
            let tone: UInt32 = (i, j) == bloom ? 0xB08070 : r.pick(tones)
            let top = size.y - r.float(0...0.0025)
            PTK.slab(&m, x: x, z: z, w: s, d: s, t: thickness, top: top, bevel: 0.003, corner: 0.004,
                     key: PTK.tint("ceramic.terracotta", tone), tilt: V2(r.float(-0.25...0.25), r.float(-0.25...0.25)))
            if (i, j) == chip {
                // Chipped corner: bed shows through a small triangular loss.
                let c = V2(x + s / 2 - 0.018, z + s / 2 - 0.018)
                GK.poly(&m, [c + V2(-0.02, 0.02), c + V2(0.02, 0.02), c + V2(0.02, -0.02)], top: top + 0.0004, PTK.tint("concrete.rough", 0x9A8E7C), thick: 0.002)
            }
        }}
        return PTK.finish(&m, id: Self.id, size: size, cap: PTK.tint("ceramic.terracotta", tones[0]))
    }
}
