import simd
import Foundation

/// Porcelain outdoor tile paving: architectural facade customizer, Contemporary. 20 mm rectified
/// porcelain slabs 1000 x 500 mm in half bond on a mortar bed with 3 mm grey grout joints; matte
/// anti-slip finish, slight shade batch variation, one slab from a lighter batch.
public struct PorcelainOutdoorTilePaving: RealAsset {
    public static let id = "porcelain-outdoor-tile-paving"
    public static let summary = "Porcelain outdoor tile paving, 2 x 2 m: contemporary 1000 x 500 mm rectified porcelain slabs, half bond, 3 mm grout."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.05, 2.0)
    /// Slab length (x) and width (z) pitch (m); divide the tile so it repeats.
    public var slab = V2(1.0, 0.5)
    /// Grout joint (m), slab thickness (m).
    public var joint: Float = 0.003
    public var thickness: Float = 0.02
    /// Porcelain tones (sRGB hex), warm grey batch.
    public var tones: [UInt32] = [0x6C6964, 0x67645F, 0x716D67]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2
        PTK.bed(&m, w: size.x, d: size.z, top: size.y - 0.0015, PTK.tint("concrete.smooth", 0x6E6C68))
        let rows = Int(size.z / slab.y + 0.5), cols = Int(size.x / slab.x + 0.5)
        for j in 0..<rows {
            let z = -size.z / 2 + slab.y * (Float(j) + 0.5)
            let off: Float = j % 2 == 0 ? 0 : slab.x / 2
            for i in 0..<cols {
                var r = rng.fork(j * 7 + i)
                for (x, w) in PTK.wrap(-hx + slab.x * (Float(i) + 0.5) + off, slab.x, half: hx) {
                    PTK.slab(&m, x: x, z: z, w: w - joint, d: slab.y - joint, t: thickness, top: size.y - r.float(0...0.0006),
                             bevel: 0.0012, corner: 0.0015, key: PTK.tint("ceramic.porcelain-gray", (i, j) == (1, 2) ? 0x7A766F : r.pick(tones)))
                }
            }
        }
        // Run-off stain along one grout line.
        return PTK.finish(&m, id: Self.id, size: size, cap: PTK.tint("ceramic.porcelain-gray", tones[0]))
    }
}
