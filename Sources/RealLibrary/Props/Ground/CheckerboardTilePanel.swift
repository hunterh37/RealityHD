import simd
import Foundation

/// Checkerboard ceramic tile floor, 1.2 x 1.2 m: 15 cm black and ivory glazed tiles on grey grout,
/// one chipped tile showing mortar, one crazed tile, and a worn walking path across the ivory tiles.
public struct CheckerboardTilePanel: RealAsset {
    public static let id = "checkerboard-tile-panel"
    public static let summary = "Checkerboard tile floor, 1.2 x 1.2 m: black and ivory 15 cm glazed ceramic tiles on grout, one chipped."
    public static let tags = ["prop", "tile", "ground", "urban", "outdoor", "ceramic"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 55, distance: 1.7, studio: true)

    /// Tile edge (m).
    public var tile: Float = 0.15
    /// Tiles per side.
    public var count = 8
    /// Tile colors (sRGB hex): light, dark.
    public var light: UInt32 = 0xE9E2D0
    public var dark: UInt32 = 0x1F1E1F
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let size = Float(count) * tile + 0.02, th: Float = 0.012, gap: Float = 0.004
        GK.slab(&m, w: size, d: size, h: th * 0.6, "concrete.smooth:8E8B86", r: 0.003)
        let chip = (rng.int(1...count - 2), rng.int(1...count - 2))
        for j in 0..<count { for i in 0..<count {
            let isLight = (i + j) % 2 == 0
            let c = V3((Float(i) - Float(count - 1) / 2) * tile, 0, (Float(j) - Float(count - 1) / 2) * tile)
            if i == chip.0 && j == chip.1 {
                GK.layer(&m, x: c.x, z: c.z, w: tile - gap, d: tile - gap, top: th * 0.6 - 0.002, "concrete.rough:77736C")
                GK.box(&m, V3(c.x - 0.03, th * 0.5, c.z + 0.035), V3(0.06, th, 0.07), "ceramic.stoneware:" + String(format: "%06X", isLight ? light : dark), r: 0.002, yaw: 12)
                continue
            }
            let hex = isLight ? light : dark
            let h = th * rng.float(0.97...1.0)
            GK.box(&m, c + V3(0, h / 2, 0), V3(tile - gap, h, tile - gap), "ceramic.stoneware:" + String(format: "%06X", hex), r: 0.0025)
        }}
        // Worn path through the ivory tiles.
        for k in 0..<4 {
            GK.layer(&m, x: -0.3 + Float(k) * 0.22, z: -0.2 + Float(k) * 0.12, w: 0.1, d: 0.12, top: th, "plastic.matte:A89F8C")
        }
        return GK.finish(&m, ao: 0.04)
    }
}
