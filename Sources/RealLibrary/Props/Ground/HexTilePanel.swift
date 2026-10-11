import simd
import Foundation

/// Hexagonal cement tile floor, 1.0 x 1.0 m: honeycomb of 8 cm-radius glazed hex tiles in terracotta,
/// cream and teal on grout, with one tile cracked and a chip at the edge.
public struct HexTilePanel: RealAsset {
    public static let id = "hex-tile-panel"
    public static let summary = "Hexagonal tile floor, 1 x 1 m: honeycomb of terracotta, cream and teal glazed hex tiles on grout."
    public static let tags = ["prop", "tile", "ground", "urban", "outdoor", "ceramic"]
    public static let budget = 4500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 55, distance: 1.4, studio: true)

    /// Tile circumradius (m).
    public var radius: Float = 0.08
    /// Tile colors (sRGB hex).
    public var colors: [UInt32] = [0xB5573A, 0xE8DCC2, 0x2E7A78]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let size: Float = 1.0, th: Float = 0.012, r = radius - 0.003
        GK.slab(&m, w: size, d: size, h: th * 0.6, "concrete.smooth:8E8B86", r: 0.003)
        let dx = radius * 1.7320508, dz = radius * 1.5
        let outline = Shape2D.polygon(sides: 6, radius: r, rotation: .pi / 6)
        let cracked = rng.int(5...20)
        var n = 0
        for j in -8...8 { for i in -8...8 {
            let x = Float(i) * dx + (j % 2 == 0 ? 0 : dx / 2), z = Float(j) * dz
            guard abs(x) < size / 2 - radius * 0.6, abs(z) < size / 2 - radius * 0.6 else { continue }
            let hex = colors[abs(i + 2 * j) % 3]
            n += 1
            if n == cracked {
                GK.poly(&m, outline.map { $0 + V2(x, z) }, top: th * 0.6, "concrete.rough:77736C")
                continue
            }
            let h = th * rng.float(0.97...1.0)
            let s = Prim.extrude(outline, depth: h, bevel: 0.0025, bevelSegments: 1, material: "ceramic.stoneware:" + String(format: "%06X", hex))
            m.add(s, Xform(translation: V3(x, h, z), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }}
        return GK.finish(&m, ao: 0.04)
    }
}
