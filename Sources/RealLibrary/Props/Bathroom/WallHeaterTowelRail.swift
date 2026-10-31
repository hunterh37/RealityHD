import simd
import Foundation

/// Heated towel rail: everyday bathroom, chrome. Parts: two rails, eight rungs, wall brackets, valve.
public struct WallHeaterTowelRail: RealAsset {
    public static let id = "wall-heater-towel-rail"
    public static let summary = "Chrome ladder towel rail with eight rungs on wall brackets and a bottom valve."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 0.8, 0.1)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var smudged: MaterialKey = "metal.stainless-smudged"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let rx: Float = 0.235
        let zr: Float = 0.03
        // Two vertical rails.
        for sx: Float in [-1, 1] {
            Toiletry.rod(&m, axis: 1, at: V3(sx * rx, 0.01, zr), length: 0.78, r: 0.0125, chrome, seg: 16)
            // Wall brackets: flange and arm at top and bottom.
            for y: Float in [0.07, 0.73] {
                m.add(Prim.roundedBox(V3(0.034, 0.05, 0.007), radius: 0.003, bevelSegments: 2, material: chrome), Xform(translation: V3(sx * rx, y, -0.05 + 0.0035)))
                Toiletry.rod(&m, axis: 2, at: V3(sx * rx, y, -0.05 + 0.007), length: zr + 0.05 - 0.007, r: 0.0075, chrome, seg: 12)
            }
        }
        // Eight rungs, the lowest two clouded with limescale.
        for i in 0..<8 {
            let y = 0.085 + Float(i) * 0.0945
            Toiletry.rod(&m, axis: 0, at: V3(-rx, y, zr), length: 2 * rx, r: 0.0095, i < 2 ? smudged : chrome, seg: 14)
        }
        // End caps on the rails.
        for sx: Float in [-1, 1] {
            Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0125, 0.0), V2(0.0125, 0.002), V2(0.0085, 0.006), V2(0.001, 0.0065)], chrome, seg: 16, at: V3(sx * rx, 0.79, zr))
        }
        // Valve body and knob on the bottom left.
        m.add(Prim.superellipsoid(V3(0.034, 0.03, 0.034), exponent: 2, subdivisions: 10, material: chrome), Xform(translation: V3(-rx, 0.012 + 0.0, zr)))
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.008, 0.0), V2(0.0095, 0.004), V2(0.0095, 0.014), V2(0.006, 0.018), V2(0.001, 0.0185)], "plastic.gloss:F2F2EE", seg: 16, at: V3(-rx + 0.012, 0.012, zr + 0.014), rot: simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1)))
        groundAO(&m)
        return LODModel(m)
    }
}
