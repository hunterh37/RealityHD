import simd
import Foundation

/// Contemporary terracotta rainscreen: 50 mm square extruded terracotta baguettes with rounded arrises
/// and hollow cores, hung horizontally at 100 mm centres on two aluminium T-rails by stainless spring
/// clips with EPDM pads. Firings alternate in tone; one baguette carries an efflorescence bloom.
public struct TerracottaRainscreenBaguette: RealAsset {
    public static let id = "terracotta-rainscreen-baguette"
    public static let summary = "Terracotta rainscreen baguettes, 1.5 x 3.0 m: extruded square hollow terracotta fins on aluminium rails with clips and end caps."
    public static let tags = ["prop", "architecture", "facade", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 3.4)

    /// Baguette length in meters.
    public var length: Float = 1.5
    /// Overall height in meters.
    public var height: Float = 3.0
    /// Baguette section (square) in meters.
    public var section: Float = 0.05
    /// Vertical pitch of baguettes in meters.
    public var pitch: Float = 0.1
    /// Firing A.
    public var clayA: MaterialKey = "ceramic.terracotta:A35E44"
    /// Firing B.
    public var clayB: MaterialKey = "ceramic.terracotta:93533B"
    /// Rail metal.
    public var rail: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, H = height, s = section, zr: Float = 0.045
        let railX: [Float] = [-0.55, 0.0, 0.55]
        // Aluminium T-rails: web to the wall, flange carrying the clips.
        for x in railX {
            FA.box(&m, V3(0.004, H, zr - 0.004), V3(x, H / 2, (zr - 0.004) / 2), rail, r: 0.001)
            FA.box(&m, V3(0.06, H, 0.004), V3(x, H / 2, zr - 0.002), rail, r: 0.001)
            var y: Float = 0.15
            while y < H { // wall bracket fixings through the web
                FA.box(&m, V3(0.05, 0.08, 0.004), V3(x + 0.025, y, 0.002), rail, r: 0.001)
                hexBolt(&m, at: V3(x + 0.01, y, 0.0045), normal: FA.X, size: 0.008, material: "metal.stainless")
                y += 0.9
            }
        }
        let n = Int((H / pitch).rounded(.down))
        let prof = Shape2D.roundedRect(s, s, radius: 0.004, segments: 2)
        for i in 0..<n {
            let y = pitch * (Float(i) + 0.5)
            var mat: MaterialKey = rng.chance(0.15) ? "ceramic.terracotta:C48A6C" : (i % 2 == 0 ? clayA : clayB)
            if i < 3 { mat = "ceramic.terracotta:8A5038" } // splash-back grime near grade
            if i == 17 { mat = "ceramic.terracotta:D2A68E" } // efflorescence bloom
            let jx = rng.float(-0.004...0.004)
            m.add(Prim.extrude(prof, depth: L - 0.004, bevel: 0.003, bevelSegments: 1, material: mat),
                  Xform(translation: V3(jx, y, zr + 0.003 + s / 2), rotation: FA.q(90, FA.Y)))
            // Hollow cores at both ends: two cells split by a web.
            for ex in [-1, 1] as [Float] {
                for cy in [-0.011, 0.011] as [Float] {
                    FCL.cube(&m, V3(0.002, 0.016, 0.034), V3(jx + ex * (L / 2 - 0.0012), y + cy, zr + 0.003 + s / 2), "ceramic.terracotta:3A1E12")
                }
            }
            // Stainless spring clips with EPDM pad at each rail.
            for x in railX {
                FCL.cube(&m, V3(0.03, 0.004, 0.003), V3(x, y - s / 2 - 0.0025, zr + 0.0015), "rubber.plate")
                FCL.cube(&m, V3(0.022, 0.0025, s * 0.55), V3(x, y - s / 2 - 0.0012, zr + s * 0.3), "metal.stainless")
                FCL.cube(&m, V3(0.022, 0.0025, s * 0.4), V3(x, y + s / 2 + 0.0012, zr + s * 0.22), "metal.stainless")
            }
        }
        groundAO(&m, height: 0.12, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
