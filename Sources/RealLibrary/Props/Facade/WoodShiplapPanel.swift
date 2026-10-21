import simd
import Foundation

/// Wood shiplap panel, Modern Farmhouse: sixteen painted pine boards (140 mm exposure) with rabbeted
/// lap joints and a 6 mm nickel gap, face-nailed through two furring strips. Wall plane at z = 0.
public struct WoodShiplapPanel: RealAsset {
    public static let id = "wood-shiplap-panel"
    public static let summary = "Wood shiplap panel: painted pine boards with rabbeted shiplap joints and 6 mm nickel gaps, face-nailed to furring strips."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 3.2)

    /// Panel width (m).
    public var width: Float = 1.2
    /// Panel height (m).
    public var height: Float = 2.4
    /// Exposed board face (m).
    public var exposure: Float = 0.144
    /// Nickel gap between boards (m).
    public var gap: Float = 0.008
    /// Board thickness (m).
    public var thickness: Float = 0.019
    /// Paint finish.
    public var paint: MaterialKey = "wood.weathered:E2DCCF"
    /// Weathered paint on the splash-zone boards.
    public var paintWorn: MaterialKey = "wood.weathered:B9B09E"
    /// Furring and rabbet tongue (bare wood).
    public var bare: MaterialKey = "wood.pine-aged"
    /// Nail heads.
    public var nail: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let furr: Float = 0.01, t = thickness, pitch = exposure + gap
        let n = Int((height / pitch).rounded())
        let p = height / Float(n), face = p - gap
        // furring strips on the wall
        for x in [-width / 2 + 0.06, Float(0), width / 2 - 0.06] {
            FA.box(&m, V3(0.04, height, furr - 0.001), V3(x, height / 2, furr / 2), bare, r: 0.002)
        }
        for i in 0..<n {
            var r = rng.fork(i)
            let y0 = Float(i) * p
            let mat: MaterialKey = i < 2 ? paintWorn : paint
            let lenJ = r.float(-0.002...0.0)
            // board face
            FA.box(&m, V3(width + lenJ, face, t * 0.55), V3(lenJ / 2, y0 + gap + face / 2, furr + t - t * 0.275), mat, r: 0.0035)
            // rabbet lip seen through the nickel gap (lower board tongue)
            FA.box(&m, V3(width - 0.002, face * 0.98 + gap, t * 0.3), V3(0, y0 + (face + gap) / 2, furr + t * 0.15), "wood.pine-aged:6B5A44", r: 0.0015)
            // face nails, two per furring, heads filled and painted over
            for x in [-width / 2 + 0.06, Float(0), width / 2 - 0.06] {
                let ny = y0 + gap + face * 0.5 + r.float(-0.01...0.01)
                let head: MaterialKey = r.chance(0.3) ? nail : mat
                FA.cylZ(&m, r: 0.0032, h: 0.0012, at: V3(x + r.float(-0.006...0.006), ny, furr + t - 0.0002), head, bevel: 0.0005, segments: 8)
            }
        }
        // story detail: one board end replaced with a short scarfed piece left unprimed
        let k = n / 2 + 2, ky = Float(k) * p + gap + face / 2
        FA.box(&m, V3(0.32, face - 0.002, t * 0.56), V3(width / 2 - 0.16, ky, furr + t - t * 0.27), "wood.weathered:CDBF9E", r: 0.003)
        // galvanized Z-flashing drip edge under the bottom board
        FA.run(&m, [V2(0, 0.03), V2(0.0015, 0.03), V2(0.0015, 0.002), V2(furr + t - 0.001, 0.002), V2(furr + t, -0.008), V2(furr + t - 0.0015, -0.008), V2(furr + t - 0.003, 0), V2(0, 0)],
               length: width, at: V3(0, -0.002, 0), "metal.galvanized-aged", bevel: 0.0004)
        groundAO(&m, height: 0.15, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
