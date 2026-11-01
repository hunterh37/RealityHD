import simd
import Foundation

/// Magic wand: Dark oiled wood, faceted glowing crystal. Parts: Turned dark wood shaft, Carved handle bands, Pommel bulb, Crystal tip, emissive.
public struct MagicWand: RealAsset {
    public static let id = "magic-wand"
    public static let summary = "Turned dark wood wand, 35 cm, carved handle bands and a small glowing crystal tip. Grip origin at handle center, tip along +Y."
    public static let tags = ["prop", "handheld", "fx", "wood", "light"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Shaft wood (sRGB hex of the wood tint).
    public var woodColor: UInt32 = 0x2A1A10
    /// Crystal material (an emissive.* key).
    public var crystal: MaterialKey = "emissive.thruster-cyan"
    /// Overall length in meters; the grip center sits at the origin, the tip along +Y.
    public var length: Float = 0.35
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wood: MaterialKey = MaterialKey("wood.walnut:" + String(format: "%06X", woodColor))
        let dark: MaterialKey = "wood.walnut:140B06"
        let y0: Float = -0.1, ytip = y0 + length - 0.03   // crystal occupies the last 3 cm
        // Shaft profile: pommel bulb, waisted handle, long taper to a slim tip.
        var prof: [(Float, Float)] = [(0, y0), (0.008, y0), (0.0135, y0 + 0.006), (0.0145, y0 + 0.016), (0.0125, y0 + 0.028), (0.0102, y0 + 0.036)]
        var y = y0 + 0.04
        while y < 0.06 {   // carved handle: shallow ovolo swells
            let r: Float = 0.0105 + 0.0012 * sin((y - y0) * 90)
            prof.append((r, y)); y += 0.005
        }
        prof += [(0.0112, 0.06), (0.0125, 0.07), (0.0112, 0.08), (0.0085, 0.092)]
        let span = ytip - 0.092
        for i in 1...12 {
            let t = Float(i) / 12
            prof.append((0.0085 - 0.0052 * t + 0.0003 * rng.float(-1...1) * (i < 12 ? 1 : 0), 0.092 + span * t))
        }
        prof.append((0, ytip))
        m.add(turned(prof, segments: 28, material: wood, seamTile: 0.1, grainVertical: true))
        // Carved bands: raised rings of darker wood on the handle.
        for (by, r, hgt) in [(y0 + 0.042, 0.0112, 0.004), (y0 + 0.056, 0.0108, 0.003), (y0 + 0.066, 0.0108, 0.003), (0.058, 0.0112, 0.004), (0.083, 0.0098, 0.004)] as [(Float, Float, Float)] {
            m.add(turned([(r - 0.001, by), (r + 0.0012, by + 0.0008), (r + 0.0016, by + hgt / 2), (r + 0.0012, by + hgt - 0.0008), (r - 0.001, by + hgt)], segments: 28, material: dark, grainVertical: true))
        }
        // Story detail: grip worn pale where the hand rests.
        m.add(turned([(0.0098, y0 + 0.07), (0.0104, y0 + 0.074), (0.0106, y0 + 0.088), (0.0104, y0 + 0.1), (0.0098, y0 + 0.104)], segments: 28, material: "wood.walnut:5A3A22", grainVertical: true))
        // Claw cup under the crystal.
        m.add(turned([(0.0035, ytip - 0.012), (0.0058, ytip - 0.008), (0.0068, ytip - 0.002), (0.0072, ytip + 0.002), (0.0045, ytip + 0.002)], segments: 24, material: dark, grainVertical: true))
        // Crystal: six-sided point, slightly faceted.
        let c = ytip + 0.0015
        m.add(turned([(0, c), (0.0052, c), (0.0075, c + 0.007), (0.0075, c + 0.013), (0.0045, c + 0.024), (0, c + 0.03)], segments: 6, material: crystal))
        return LODModel(m)
    }
}
