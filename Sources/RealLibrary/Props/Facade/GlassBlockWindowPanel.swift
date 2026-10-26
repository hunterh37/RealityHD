import simd
import Foundation

/// Streamline Moderne glass block window, 1.2 x 1.2 m: a 6 x 6 grid of 180 mm wave-pattern glass blocks (pillowed
/// faces, horizontal ridge rows) laid in tooled white mortar, framed by a stainless U-channel with anchor clips and a
/// caulk bead, sitting on a cast stone sill with a drip. Lower joints carry mildew and hairline cracks, one block is
/// hazed with dust and the sill front is streaked with run-off.
public struct GlassBlockWindowPanel: RealAsset {
    public static let id = "glass-block-window-panel"
    public static let summary = "Streamline Moderne glass block window: 6 x 6 grid of 180 mm wave-pattern glass blocks in tooled mortar joints, framed by a stainless channel on a cast stone sill."
    public static let tags = ["prop", "architecture", "facade", "window", "glass", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 2.8)

    /// Block edge length (m).
    public var block: Float = 0.18
    /// Mortar joint width (m).
    public var joint: Float = 0.01
    /// Blocks per side.
    public var count = 6
    public var glass: MaterialKey = "glass.tinted:5F9A8C"
    public var mortar: MaterialKey = "concrete.smooth:DAD7CD"
    public var channel: MaterialKey = "metal.stainless"
    public var sillStone: MaterialKey = "stone.cast-stone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = count, bw = block, jt = joint
        let inner = Float(n) * bw + Float(n + 1) * jt
        let d: Float = 0.08, y0: Float = 0.04
        let pitch = bw + jt

        // Sill: cast stone with a sloped top, drip nosing and throat.
        FA.run(&m, [V2(0, 0), V2(0.10, 0), V2(0.10, 0.012), V2(0.088, 0.017), V2(0.088, 0.028), V2(0.10, 0.032), V2(0.10, 0.036), V2(0.02, 0.05), V2(0, 0.05)],
               length: inner + 0.05, at: V3(0, 0, 0), sillStone, bevel: 0.0025)
        for i in 0..<6 {
            let sx = -inner / 2 + 0.1 + Float(i) * (inner - 0.2) / 5 + rng.float(-0.03...0.03)
            FJ.streak(&m, x: sx, top: 0.034, length: rng.float(0.014...0.03), width: rng.float(0.02...0.05), z: 0.1005, "stone.limestone-sooted:6A6358")
        }
        // Mortar bed and tooled joints (vertical joints sit a millimetre behind the horizontal ones).
        FJ.slab(&m, V3(inner, inner, 0.05), V3(0, y0 + inner / 2, 0.035), mortar)
        for i in 0...n {
            let c = -inner / 2 + jt / 2 + Float(i) * pitch
            FJ.slab(&m, V3(jt, inner, 0.068), V3(c, y0 + inner / 2, 0.04), mortar)
            let cy = y0 + jt / 2 + Float(i) * pitch
            FJ.slab(&m, V3(inner, jt, 0.07), V3(0, cy, 0.04), mortar)
        }
        // Blocks: pillowed shells with horizontal wave ridges and a hazed one.
        let hazed = (r: 4, c: 2)
        for r in 0..<n {
            for c in 0..<n {
                let x = -inner / 2 + jt + bw / 2 + Float(c) * pitch, y = y0 + jt + bw / 2 + Float(r) * pitch
                let mat: MaterialKey = glass
                m.add(Prim.roundedBox(V3(bw, bw, d), radius: 0.007, bevelSegments: 1, material: mat), Xform(translation: V3(x, y, d / 2)))
                for k in 0..<3 {
                    let yy = y - bw * 0.22 + Float(k) * bw * 0.22
                    FJ.slab(&m, V3(bw * 0.62, 0.0035, 0.0016), V3(x, yy, d + 0.0006), "glass.clear")
                }
                if r == hazed.r && c == hazed.c {   // dust haze: tan smudges across the face
                    for _ in 0..<5 {
                        FJ.peel(&m, at: V3(x + rng.float(-0.05...0.05), y + rng.float(-0.05...0.05), d + 0.0016), w: rng.float(0.05...0.09), h: rng.float(0.03...0.06), "concrete.smooth:A39C8A", rng: &rng)
                    }
                }
                if r < 3 {   // grime band collecting on the lower edge of each block face, heavier toward the sill
                    let a = Float(3 - r) / 3
                    FJ.slab(&m, V3(bw * rng.float(0.55...0.85), 0.006 + 0.012 * a, 0.0012), V3(x + rng.float(-0.02...0.02), y - bw / 2 + 0.01 + 0.004 * a, d + 0.0014), "concrete.smooth:6F6A5C")
                    FJ.streak(&m, x: x + rng.float(-0.06...0.06), top: y + 0.02, length: rng.float(0.05...0.11), width: rng.float(0.006...0.012), z: d + 0.0014, "concrete.smooth:807B6D")
                }
                if r < 3, rng.chance(0.75) {   // mildew in the lower mortar lines
                    FJ.slab(&m, V3(rng.float(0.06...0.15), jt * 1.2, 0.0012), V3(x + rng.float(-0.04...0.04), y - bw / 2 - jt / 2, 0.0746), "concrete.smooth:5E6652")
                }
            }
        }
        // Cracked block (story detail): star crack in one lower block and a mortar patch beside it.
        do {
            let cxk = -inner / 2 + jt + bw / 2 + 4 * pitch, cyk = y0 + jt + bw / 2 + 1 * pitch
            for k in 0..<5 {
                let ang = Float(k) * 63 + 10
                FJ.slab(&m, V3(0.06 + Float(k % 3) * 0.02, 0.0016, 0.001), V3(cxk + cos(ang * .pi / 180) * 0.03, cyk + sin(ang * .pi / 180) * 0.03, d + 0.0018), "concrete.smooth:34322D", rot: FA.q(ang, FA.Z))
            }
            FJ.peel(&m, at: V3(cxk + bw / 2 + jt / 2, cyk - 0.03, 0.0752), w: 0.05, h: 0.05, "concrete.smooth:B4B1A6", rng: &rng)
        }
        // Run-off trails down the glass from the channel clips and a mildew edge along the bottom channel.
        for e: Float in [-1, 1] {
            FJ.streak(&m, x: e * (inner / 2 - 0.02), top: y0 + inner - 0.01, length: 0.35, width: 0.012, z: d + 0.0013, "concrete.smooth:7A786B")
        }
        FJ.slab(&m, V3(inner * 0.8, 0.012, 0.0013), V3(0, y0 + 0.008, d + 0.0012), "concrete.smooth:56604A")
        // Hairline cracks in the mortar at two crossings.
        FJ.slab(&m, V3(0.075, 0.0016, 0.0012), V3(-0.18, y0 + pitch * 2 + jt / 2, 0.0758), "concrete.smooth:55524A", rot: FA.q(14, FA.Z))
        FJ.slab(&m, V3(0.06, 0.0016, 0.0012), V3(0.30, y0 + pitch * 3 + jt / 2 + 0.02, 0.0758), "concrete.smooth:55524A", rot: FA.q(-38, FA.Z))
        // Perimeter: stainless U-channel with caulk bead inside, anchor clips on the face.
        let cw = inner + 0.026, chh = inner + 0.026
        let cy = y0 + inner / 2
        let u: [V2] = [V2(-0.045, -0.013), V2(0.045, -0.013), V2(0.045, -0.011), V2(-0.043, -0.011), V2(-0.043, 0.011), V2(0.045, 0.011), V2(0.045, 0.013), V2(-0.045, 0.013)]
        _ = u
        FJ.mouldedFrame(&m, cx: 0, cy: cy, w: cw - 0.013, h: chh - 0.013, z: 0.045,
                        profile: [V2(-0.045, -0.013), V2(0.045, -0.013), V2(0.045, 0.013), V2(-0.045, 0.013)], channel, r: 0.0025)
        FJ.mouldedFrame(&m, cx: 0, cy: cy, w: inner + 0.003, h: inner + 0.003, z: d - 0.012,
                        profile: FJ.beadProfile(0.0055, segments: 4), "concrete.smooth:CFCDC4", r: 0.002)
        for e: Float in [-1, 1] {
            for t: Float in [0.2, 0.5, 0.8] {
                let px = e * (cw / 2 - 0.007)
                FA.box(&m, V3(0.014, 0.034, 0.003), V3(px, y0 + chh * t, 0.0905), "metal.steel", r: 0.0008)
                rivet(&m, at: V3(px, y0 + chh * t, 0.092), normal: FA.Z, radius: 0.003, segments: 6, material: "metal.screw-zinc")
                let py = y0 + chh - 0.007 - (t - 0.5) * 0.0
                _ = py
            }
        }
        for t: Float in [0.22, 0.5, 0.78] {
            FA.box(&m, V3(0.034, 0.014, 0.003), V3((t - 0.5) * cw, y0 + chh - 0.0065, 0.0905), "metal.steel", r: 0.0008)
            rivet(&m, at: V3((t - 0.5) * cw, y0 + chh - 0.0065, 0.092), normal: FA.Z, radius: 0.003, segments: 6, material: "metal.screw-zinc")
        }
        // Dull scuffs on the stainless and a rust bloom at a clip.
        FJ.streak(&m, x: -cw / 2 + 0.007, top: y0 + chh * 0.5 - 0.02, length: 0.07, width: 0.0035, z: 0.0905, "metal.rust")
        FJ.chips(&m, spots: [V3(0.2, y0 + chh - 0.007, 0), V3(-0.3, y0 + 0.007, 0)], face: 0.0903, "metal.rust", rng: &rng, each: 2)
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
