import simd
import Foundation

/// Wire trellis curtain: vertical stainless wire ropes tensioned between top and bottom rails, horizontal
/// cable rows anchored to two side posts on wall standoffs, swaged terminals, turnbuckles and crossing
/// clamps, with a star jasmine climbing the left third. Wall plane at z = 0.
public struct WireTrellisCurtain: RealAsset {
    public static let id = "wire-trellis-curtain"
    public static let summary = "Contemporary stainless wire trellis curtain 1.5 x 3.0 m: tensioned cable grid on standoff posts with turnbuckles and a climbing jasmine."
    public static let tags = ["prop", "architecture", "facade", "metal", "plant", "garden"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 4.0)

    public var width: Float = 1.5
    public var height: Float = 3.0
    /// Vertical wire pitch and horizontal row pitch (m).
    public var verticalPitch: Float = 0.17
    public var rowPitch: Float = 0.30
    public var leafCount: Int = 110
    public var steel: MaterialKey = "metal.stainless"
    public var bolt: MaterialKey = "metal.bolt-bright"
    public var leaf: MaterialKey = "leaf.plain:3E6B2D"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let px = W / 2 - 0.015, zV: Float = 0.058, zH: Float = 0.079
        // Side posts: square stainless section on stand-off spacers every 0.75 m.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.03, H, 0.03), V3(e * px, H / 2, 0.070), steel, r: 0.003)
            var y: Float = 0.25
            while y < H {
                FA.cylZ(&m, r: 0.0095, h: 0.056, at: V3(e * px, y, 0.0), steel, bevel: 0.0012, segments: 12)
                FA.box(&m, V3(0.044, 0.044, 0.004), V3(e * px, y, 0.002), steel, r: 0.0015)
                FA.cylZ(&m, r: 0.0075, h: 0.004, at: V3(e * px, y, 0.0855), bolt, bevel: 0.001, segments: 10)
                y += 0.75
            }
        }
        // Top and bottom rails: flat bars between the posts carrying the wire eyes.
        let rw = W - 0.06
        for (y, top) in [(H - 0.03, true), (0.03, false)] as [(Float, Bool)] {
            FA.box(&m, V3(rw, 0.03, 0.016), V3(0, y, zV - 0.005), steel, r: 0.0025)
            for x in [-rw / 2 + 0.04, 0, rw / 2 - 0.04] as [Float] {
                FA.cylZ(&m, r: 0.0085, h: zV - 0.012, at: V3(x, y, 0.0), steel, bevel: 0.001, segments: 10)
            }
            _ = top
        }
        // Vertical wire ropes: terminal swage at the top, turnbuckle in the tail at the bottom.
        let nv = Int((W - 0.12) / verticalPitch)
        let vp = (W - 0.12) / Float(nv)
        var xs: [Float] = []
        for j in 0...nv {
            let x = -W / 2 + 0.06 + vp * Float(j)
            xs.append(x)
            FA.rod(&m, V3(x, 0.085, zV), V3(x, H - 0.045, zV), r: 0.0027, steel, sides: 5)
            // Swage sleeve and eye-nut at the top, tensioning turnbuckle near the foot.
            FA.rod(&m, V3(x, H - 0.052, zV), V3(x, H - 0.040, zV), r: 0.0045, bolt, sides: 8)
            FA.cylZ(&m, r: 0.0042, h: 0.004, at: V3(x, H - 0.03, zV + 0.0075), bolt, bevel: 0.0008, segments: 8)
            FA.rod(&m, V3(x, 0.088, zV), V3(x, 0.125, zV), r: 0.0055, steel, sides: 8)
            FA.rod(&m, V3(x, 0.125, zV - 0.008), V3(x, 0.19, zV - 0.008), r: 0.0033, bolt, sides: 6)
            FA.rod(&m, V3(x, 0.125, zV + 0.008), V3(x, 0.19, zV + 0.008), r: 0.0033, bolt, sides: 6)
            FA.rod(&m, V3(x, 0.19, zV - 0.008), V3(x, 0.19, zV + 0.008), r: 0.0033, bolt, sides: 6)
        }
        // Horizontal rows anchored through the posts with end swages.
        let nr = Int((H - 0.45) / rowPitch)
        let rp = (H - 0.45) / Float(nr)
        for i in 0...nr {
            let y = 0.30 + rp * Float(i)
            FA.rod(&m, V3(-px, y, zH), V3(px, y, zH), r: 0.0025, steel, sides: 5)
            for e: Float in [-1, 1] {
                FA.rod(&m, V3(e * (px - 0.024), y, zH), V3(e * (px - 0.012), y, zH), r: 0.0042, bolt, sides: 8)
            }
            // Crossing clamps on every vertical.
            for x in xs {
                FC.bead(&m, r: 0.0058, at: V3(x, y, (zV + zH) / 2), bolt, sub: 1)
            }
        }
        // Climbing jasmine: a twining stem up the left third, with leaf pairs and a few pale flowers.
        let sx = xs[1]
        var stem: [V3] = []
        for i in 0...28 {
            let t = Float(i) / 28
            stem.append(V3(sx + sin(t * 17) * 0.05 + t * 0.12, 0.12 + t * (H * 0.7), zV + 0.008 + sin(t * 23) * 0.008))
        }
        FA.path(&m, stem, r: 0.0042, "plant.stem", sides: 5)
        for i in 0..<leafCount {
            let s = stem[min(28, Int(Float(i) / Float(leafCount) * 29))]
            let o = V3(rng.float(-0.12...0.12), rng.float(-0.07...0.07), rng.float(0.0...0.008))
            m.add(Prim.superellipsoid(V3(0.07, 0.09, 0.008) * rng.float(0.8...1.25), exponent: 2.5, subdivisions: 2, material: leaf),
                  Xform(translation: s + o, rotation: FA.q(rng.float(0...360), FA.Z) * FA.q(rng.float(-25...25), FA.X)))
        }
        for _ in 0..<5 {
            let s = stem[rng.int(8...26)]
            FC.bead(&m, r: 0.011, at: s + V3(rng.float(-0.06...0.06), rng.float(-0.03...0.03), 0.014), "flower.petal", sub: 2)
        }
        _ = rng.float()
        groundAO(&m, height: 0.15, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
