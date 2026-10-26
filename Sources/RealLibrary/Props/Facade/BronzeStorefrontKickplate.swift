import simd
import Foundation

/// Art Deco bronze storefront kickplate: cast-bronze plate with stepped borders, a fluted centre panel,
/// brass chevron inlay, corner rosettes, countersunk screws and a projecting capping lip. Wall plane z = 0.
public struct BronzeStorefrontKickplate: RealAsset {
    public static let id = "bronze-storefront-kickplate"
    public static let summary = "Bronze storefront kickplate, 2.0 x 0.4 m: stepped Deco border, fluted center panel, chevron inlay, corner rosettes, screws."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 2.8)

    public var width: Float = 2.0
    public var height: Float = 0.4
    public var bronze: MaterialKey = "metal.bronze-cast"
    public var bronzeWorn: MaterialKey = "metal.bronze-weathered"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, hw = W / 2
        // Back plate and the stepped frame (three nested rectangles, each a little higher).
        FA.box(&m, V3(W, H - 0.05, 0.014), V3(0, 0.025 + (H - 0.05) / 2, 0.007), bronzeWorn, r: 0.002)
        func frame(inset: Float, bar: Float, rise: Float, z0: Float, _ mat: MaterialKey) {
            let w = W - 2 * inset, h = H - 0.05 - 2 * inset, y0 = 0.025 + inset
            FA.box(&m, V3(w, bar, rise), V3(0, y0 + bar / 2, z0 + rise / 2), mat, r: 0.0025)
            FA.box(&m, V3(w, bar, rise), V3(0, y0 + h - bar / 2, z0 + rise / 2), mat, r: 0.0025)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(bar, h - 2 * bar + 0.004, rise), V3(s * (w / 2 - bar / 2), y0 + h / 2, z0 + rise / 2), mat, r: 0.0025)
            }
        }
        frame(inset: 0.012, bar: 0.026, rise: 0.016, z0: 0.012, bronze)
        frame(inset: 0.05, bar: 0.016, rise: 0.012, z0: 0.026, bronzeWorn)
        frame(inset: 0.066, bar: 0.004, rise: 0.003, z0: 0.038, brass)
        frame(inset: 0.078, bar: 0.008, rise: 0.008, z0: 0.036, bronze)
        // Fluted centre panel: half-round reeds between two end blocks.
        let cw: Float = 0.9, ch: Float = H - 0.05 - 2 * 0.09
        FA.box(&m, V3(cw + 0.04, ch + 0.02, 0.012), V3(0, 0.025 + H / 2 - 0.025, 0.02), bronzeWorn, r: 0.002)
        let nf = 13
        for i in 0..<nf {
            let x = -cw / 2 + (Float(i) + 0.5) * cw / Float(nf)
            m.add(Prim.cylinder(radius: cw / Float(nf) * 0.43, height: ch, bevel: 0.002, segments: 8, bevelSegments: 1, material: bronze),
                  Xform(translation: V3(x, 0.025 + H / 2 - 0.025 - ch / 2, 0.034)))
        }
        // Chevron inlay each side of the panel: three nested V bars in brass.
        for s: Float in [-1, 1] {
            for k in 0..<3 {
                let y = 0.025 + H / 2 - 0.025 + Float(k - 1) * 0.06
                let cx = s * 0.68
                let len: Float = 0.13 - Float(k) * 0.012
                FA.box(&m, V3(len, 0.012, 0.007), V3(cx - len * 0.45 * s, y + 0.012, 0.042), brass, r: 0.0015, rot: FA.q(-s * 28, FA.Z))
                FA.box(&m, V3(len, 0.012, 0.007), V3(cx + len * 0.45 * s, y + 0.012, 0.042), brass, r: 0.0015, rot: FA.q(s * 28, FA.Z))
            }
        }
        // Verdigris pooled between the reeds at the foot and in the frame corners.
        for i in 0..<(nf - 1) where i % 2 == 0 {
            let x = -cw / 2 + Float(i + 1) * cw / Float(nf)
            FA.box(&m, V3(0.006, rng.float(0.04...0.1), 0.004), V3(x, 0.025 + H / 2 - 0.025 - ch / 2 + 0.05, 0.036), "metal.copper-patina", r: 0.001)
        }
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.05, 0.012, 0.003), V3(sx * (hw - 0.09), 0.04, 0.0385), "metal.copper-patina", r: 0.0008)
        }
        // Deco sunburst plaque above the reeds: half-disc with nine tapered rays.
        let sy = 0.025 + H / 2 - 0.025 + ch / 2 + 0.002
        FA.cylZ(&m, r: 0.034, h: 0.008, at: V3(0, sy - 0.012, 0.046), brass, bevel: 0.0015, segments: 16)
        for k in 0..<9 {
            let a: Float = 20 + Float(k) * 17.5
            let r: Float = 0.055
            FA.box(&m, V3(0.006, 0.05, 0.006), V3(cosf(a * .pi / 180) * r * 0.82, sy - 0.012 + sinf(a * .pi / 180) * r * 0.82, 0.045), brass, r: 0.0012, rot: FA.q(a - 90, FA.Z))
        }
        // Rivet rows along the middle frame.
        rivetRow(&m, along: [V3(-hw + 0.075, 0.025 + 0.062, 0.038), V3(hw - 0.075, 0.025 + 0.062, 0.038)], spacing: 0.2, normal: { _ in FA.Z }, radius: 0.0038, material: brass)
        rivetRow(&m, along: [V3(-hw + 0.075, H - 0.087, 0.038), V3(hw - 0.075, H - 0.087, 0.038)], spacing: 0.2, normal: { _ in FA.Z }, radius: 0.0038, material: brass)
        // Corner rosettes on the outer frame.
        for sx: Float in [-1, 1] {
            for y in [0.025 + 0.045, H - 0.045] as [Float] {
                FP.rosette(&m, at: V3(sx * (hw - 0.05), y, 0.028), r: 0.022, petals: 5, bronzeWorn, boss: brass)
            }
        }
        // Screws along the outer frame, rotated randomly so slots do not line up.
        var x: Float = -hw + 0.12
        while x < hw - 0.1 {
            for y in [0.025 + 0.025, H - 0.025] as [Float] { FP.screw(&m, at: V3(x, y, 0.028), brass) }
            x += 0.25
        }
        // Capping lip along the top with a chamfered nosing, and a toe rail at the bottom.
        FA.run(&m, [V2(0, 0), V2(0.08, 0), V2(0.08, 0.008), V2(0.072, 0.018), V2(0.0, 0.022)], length: W, at: V3(0, H - 0.022, 0), bronzeWorn, bevel: 0.0015)
        FA.run(&m, [V2(0, 0), V2(0.05, 0), V2(0.05, 0.012), V2(0.04, 0.025), V2(0, 0.025)], length: W, at: V3(0, 0, 0), bronzeWorn, bevel: 0.0015)
        // Story detail: scuffed, bright brass-polished strip where shoes strike the toe, and a dent shadow.
        FA.box(&m, V3(0.55, 0.05, 0.002), V3(0.2 + rng.float(-0.01...0.01), 0.075, 0.05), brass, r: 0.0005)
        FA.box(&m, V3(0.34, 0.02, 0.002), V3(-0.5, 0.2, 0.05), bronzeWorn, r: 0.0005)
        groundAO(&m, height: 0.08, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
