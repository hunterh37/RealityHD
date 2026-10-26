import simd
import Foundation

/// Contemporary slatted privacy screen, 2.0 x 2.2 m: 22 vertical cedar slats with 20 mm gaps screwed to
/// three horizontal rails, held between two black anodized steel posts on base plates with a steel capping
/// channel. Cedar weathers unevenly slat to slat. Standing on the ground, slats toward +Z.
public struct SlattedTimberPrivacyScreen: RealAsset {
    public static let id = "slatted-timber-privacy-screen"
    public static let summary = "Contemporary slatted privacy screen, 2.0 x 2.2 m: cedar slats on rails between black steel posts, capping channel."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 2.4)

    /// Fresh cedar.
    public var cedar: MaterialKey = "wood.cedar"
    /// Weathered cedar.
    public var weathered: MaterialKey = "wood.cedar-weathered"
    /// Black anodized steel.
    public var steel: MaterialKey = "metal.anodized-black"
    /// Stainless screws.
    public var screw: MaterialKey = "metal.stainless"
    /// Slat count.
    public var slats = 22
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 2.0, H: Float = 2.2, D: Float = 0.1
        let postW: Float = 0.06
        let railY: [Float] = [0.38, 1.1, 1.82]
        // Posts: black anodized square tube with bevelled edges, base plates and four anchor bolts each.
        for s: Float in [-1, 1] {
            let px = s * (W / 2 - postW / 2)
            FA.box(&m, V3(postW, H - 0.05, D - 0.01), V3(px, 0.0 + (H - 0.05) / 2 + 0.01, 0), steel, r: 0.004)
            FA.box(&m, V3(0.08, 0.012, 0.1), V3(px, 0.0185, 0), steel, r: 0.002)
            // Concrete footing collar: poured pad sloped away from the post, with a hairline crack and surface stain.
            FA.box(&m, V3(0.1, 0.012, 0.098), V3(px - s * 0.012, 0.006, 0), "concrete.rough", r: 0.004)
            FA.box(&m, V3(0.088, 0.0125, 0.1), V3(px, 0.0065, 0), "concrete.rough", r: 0.003)
            FA.box(&m, V3(0.002, 0.0006, 0.05), V3(px - s * 0.01, 0.0124, 0.0), "concrete.sealed-dark", r: 0.0003, rot: FA.q(20, FA.Y))
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                hexBolt(&m, at: V3(px + sx * 0.026, 0.0245, sz * 0.034), normal: V3(0, 1, 0), size: 0.01, material: screw)
            } }
        }
        // Capping channel: U section over the slats, closed with end plates.
        FA.box(&m, V3(W, 0.03, D), V3(0, H - 0.015, 0), steel, r: 0.003)
        FA.box(&m, V3(W - 0.01, 0.012, D - 0.016), V3(0, H - 0.036, 0), steel, r: 0.002)
        // Rails: 40 x 40 timber battens behind the slats between the posts.
        for y in railY {
            FA.box(&m, V3(W - postW * 2 - 0.004, 0.04, 0.04), V3(0, y, -0.015), cedar, r: 0.003)
        }
        // Slats: vertical boards with grain along their length, bevelled edges, slight length variation.
        let n = slats
        let clear = W - postW * 2
        let gap: Float = 0.02
        let sw = (clear - Float(n + 1) * gap) / Float(n)
        let tones: [MaterialKey] = [cedar, cedar, cedar, "wood.pine-aged", weathered, "wood.cedar:8C5E3E"]
        for i in 0..<n {
            let x = -clear / 2 + gap + sw / 2 + Float(i) * (sw + gap)
            let top: Float = H - 0.045, bot: Float = 0.045 + rng.float(0...0.004)
            let mat: MaterialKey = (i == 5 || i == 14) ? "wood.lumber-cedar" : tones[rng.int(0...5)]
            let lean = rng.float(-0.35...0.35)
            let zoff = rng.float(-0.0012...0.0012)
            let sl = Prim.roundedBox(V3(sw, top - bot, 0.034), radius: 0.0035, bevelSegments: 1, material: mat)
            m.add(sl, Xform(translation: V3(x, (top + bot) / 2, 0.012 + zoff), rotation: FA.q(lean, FA.Z)))
            // Splash zone: end grain and base of each slat darkens where rain bounces off the ground.
            let splash = rng.float(0.1...0.26)
            FC.brickBox(&m, V3(sw - 0.002, splash, 0.0016), V3(x, bot + splash / 2, 0.0292 + zoff), "wood.cedar:4F3626", r: 0.0004)
            // Sun bleach on the upper slat where the finish has gone silver.
            if rng.chance(0.5) {
                let bl = rng.float(0.2...0.5)
                FC.brickBox(&m, V3(sw - 0.002, bl, 0.0014), V3(x, top - bl / 2, 0.0291 + zoff), "wood.cedar:9A8468", r: 0.0004)
            }
            // Countersunk stainless screws into each rail, with rust bleed on a few.
            for y in railY {
                FA.cylZ(&m, r: 0.0042, h: 0.0016, at: V3(x, y, 0.029 + zoff), screw, bevel: 0.0006, segments: 6)
                if rng.chance(0.2) { FC.brickBox(&m, V3(0.003, 0.05, 0.0012), V3(x, y - 0.03, 0.0292 + zoff), "wood.cedar:5C3D28", r: 0.0003) }
            }
        }
        // Story: one cracked slat with a knot and a bleach stain.
        let kx = -clear / 2 + gap + sw / 2 + 7 * (sw + gap)
        m.add(Prim.superellipsoid(V3(0.03, 0.045, 0.004), exponent: 2, subdivisions: 4, material: "wood.charred"), Xform(translation: V3(kx, 1.42, 0.0295)))
        FA.box(&m, V3(0.002, 0.22, 0.0025), V3(kx + 0.012, 1.58, 0.0295), "wood.charred", r: 0.0006)
        // Floor channel: steel kick strip protecting slat ends from splash.
        FA.box(&m, V3(clear, 0.04, 0.05), V3(0, 0.02, 0.005), steel, r: 0.003)
        groundAO(&m, height: 0.3, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
