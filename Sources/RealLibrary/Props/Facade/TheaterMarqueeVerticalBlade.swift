import simd
import Foundation

/// Art Deco theatre blade sign: a stepped ziggurat silhouette in enamelled steel, vertical lamp-lit
/// lettering on a cream panel inside a red neon outline, chrome fluting, rows of bulbs down both edges and
/// a spire finial. Held off the wall on three pairs of angle brackets, wired through a conduit.
public struct TheaterMarqueeVerticalBlade: RealAsset {
    public static let id = "theater-marquee-vertical-blade"
    public static let summary = "Art Deco theatre blade sign 4.0 m: stepped crown, neon outline, vertical lamp letters, bulb borders, steel body."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.1)

    /// Vertical lettering (A-Z, 0-9), read top to bottom.
    public var word = "PALACE"
    public var body: MaterialKey = "metal.painted:1A1D26"
    public var panel: MaterialKey = "metal.painted:E6DCC0"
    public var neon: MaterialKey = "emissive.signal-red"
    public var chrome: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bz: Float = 0.12, bd: Float = 0.36, fz = bz + bd
        // Ziggurat silhouette (right half, mirrored), body 0.62 wide, crown wings to 1.0.
        let half: [V2] = [V2(0.13, 0.0), V2(0.31, 0.36), V2(0.31, 3.42), V2(0.5, 3.5), V2(0.5, 3.6), V2(0.4, 3.66), V2(0.4, 3.76), V2(0.27, 3.82), V2(0.27, 3.9), V2(0.1, 3.9)]
        var outline = half + [V2(0, 3.92)] + half.reversed().map { V2(-$0.x, $0.y) }
        outline = Shape2D.deduped(outline)
        m.add(Prim.extrude(outline.reversedIfCW(), depth: bd, bevel: 0.01, bevelSegments: 2, material: body), Xform(translation: V3(0, 0, bz + bd / 2)))
        // Cream letter panel inset 6 mm on the front, chrome flutes either side.
        FA.box(&m, V3(0.5, 3.0, 0.008), V3(0, 1.9, fz + 0.002), panel, r: 0.002)
        for sx: Float in [-1, 1] {
            for k in 0..<3 { FA.box(&m, V3(0.012, 3.05 - Float(k) * 0.0, 0.008), V3(sx * (0.265 + Float(k) * 0.016 - 0.016), 1.9, fz + 0.004), chrome, r: 0.003) }
        }
        // Crown: chevron bands and a sunburst fan in chrome and cream.
        FA.box(&m, V3(0.9, 0.04, 0.012), V3(0, 3.545, fz + 0.004), chrome, r: 0.004)
        for k in 0..<7 {
            let a = (Float(k) - 3) * 22
            FA.box(&m, V3(0.014, 0.17, 0.01), V3(sin(a * .pi / 180) * 0.1, 3.7 + cos(a * .pi / 180) * 0.0 + 0.0, fz + 0.004) + V3(0, 0, 0), chrome, r: 0.003, rot: FA.q(-a, FA.Z))
        }
        FG.dome(&m, at: V3(0, 3.62, fz + 0.006), r: 0.035, mat: "metal.brass-aged")
        // Chrome belt courses on the side walls every 0.4 m, with rivets (flat cuboids).
        for k in 0..<8 {
            let y = 0.62 + Float(k) * 0.4
            for sx: Float in [-1, 1] {
                FG.flat(&m, V3(0.012, 0.022, bd + 0.01), V3(sx * 0.316, y, bz + bd / 2), chrome)
                for dz: Float in [-0.1, 0.0, 0.1] { FG.flat(&m, V3(0.008, 0.008, 0.008), V3(sx * 0.318, y - 0.04, bz + bd / 2 + dz), "metal.brass-aged") }
            }
        }
        // Crown chevrons in red neon and a chrome lozenge on the tail.
        FA.path(&m, [V3(-0.44, 3.58, fz + 0.012), V3(0, 3.7, fz + 0.012), V3(0.44, 3.58, fz + 0.012)], r: 0.008, neon, sides: 6)
        FA.path(&m, [V3(-0.3, 3.5, fz + 0.012), V3(0, 3.58, fz + 0.012), V3(0.3, 3.5, fz + 0.012)], r: 0.007, neon, sides: 6)
        m.add(Prim.extrude([V2(0, 0.11), V2(0.07, 0), V2(0, -0.11), V2(-0.07, 0)], depth: 0.012, bevel: 0.003, bevelSegments: 1, material: chrome), Xform(translation: V3(0, 0.27, fz + 0.004)))
        // Spire finial.
        m.add(Prim.lathe([V2(0, 0), V2(0.03, 0.01), V2(0.022, 0.04), V2(0.008, 0.07), V2(0, 0.1)], segments: 14, seamTile: 0.2, material: chrome), Xform(translation: V3(0, 3.9, bz + bd / 2)))
        // Vertical lamp lettering: each letter on its own cream plate with lit lamp-white strokes.
        let n = word.count
        for (i, ch) in word.enumerated() {
            let y = 2.95 - Float(i) * 0.45
            FG.text(&m, String(ch), h: 0.34, stroke: 0.058, depth: 0.014, at: V3(0, y, fz + 0.006), "metal.painted:9E1F22")
            FG.text(&m, String(ch), h: 0.34, stroke: 0.04, depth: 0.004, at: V3(0, y, fz + 0.02), i == 3 ? "glass.frosted" : "emissive.signal-white")
        }
        // Red neon outline round the panel: two uprights and top and bottom runs on standoffs.
        let nz = fz + 0.02
        FA.path(&m, [V3(-0.235, 0.52, nz), V3(-0.235, 3.42, nz), V3(0.235, 3.42, nz), V3(0.235, 0.52, nz), V3(-0.235, 0.52, nz)], r: 0.011, neon, sides: 8)
        for y: Float in [0.8, 1.5, 2.2, 2.9] { for sx: Float in [-1, 1] { FA.cylZ(&m, r: 0.004, h: 0.02, at: V3(sx * 0.235, y, fz), "ceramic.vitreous", bevel: 0.001, segments: 8) } }
        // Bulb rows down both edges and along the crown steps (one dead bulb).
        for sx: Float in [-1, 1] {
            FG.lamps(&m, from: V3(sx * 0.292, 0.42, fz), to: V3(sx * 0.292, 3.38, fz), count: 30, r: 0.014, dead: sx > 0 ? [11] : [])
        }
        FG.lamps(&m, from: V3(-0.45, 3.56, fz), to: V3(0.45, 3.56, fz), count: 9, r: 0.013)
        // Wall brackets: plates with angle arms, bolted, and a conduit run with a junction box at the base.
        for y: Float in [0.9, 2.0, 3.1] {
            for sx: Float in [-1, 1] {
                FA.box(&m, V3(0.1, 0.1, 0.012), V3(sx * 0.18, y, 0.006), "metal.galvanized", r: 0.003)
                FA.box(&m, V3(0.05, 0.05, bz + 0.01), V3(sx * 0.18, y, (bz + 0.01) / 2), "metal.galvanized", r: 0.003)
                hexBolt(&m, at: V3(sx * 0.18, y + 0.03, 0.012), normal: FA.Z, size: 0.012, material: "metal.rust")
            }
        }
        FA.rod(&m, V3(0.22, 0.05, 0.03), V3(0.22, 0.5, 0.03), r: 0.01, "metal.galvanized-aged", sides: 10)
        FA.box(&m, V3(0.09, 0.1, 0.05), V3(0.22, 0.04, 0.03), "metal.galvanized", r: 0.004)
        // Rust and grime streaks from the lower edge and enamel loss at the lower tip.
        for _ in 0..<6 {
            let len = rng.float(0.1...0.5)
            FG.flat(&m, V3(rng.float(0.01...0.03), len, 0.001), V3(rng.float(-0.28...0.28), 0.4 + len / 2, fz + 0.0075), "metal.rust-grime")
        }
        groundAO(&m, height: 0.3, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
