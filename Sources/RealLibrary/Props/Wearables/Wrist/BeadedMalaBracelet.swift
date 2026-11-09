import simd
import Foundation

/// Sandalwood and rosewood mala bracelet worn on the left wrist: 21 polished 8 mm beads in three tones strung on elastic cord with
/// the thread showing at every bead hole, brass rondelle spacers, a larger guru bead with a knotted cap and a hand-wrapped silk
/// tassel. One bead is a lighter replacement and the guru bead is rubbed dull by years of fingers.
public struct BeadedMalaBracelet: RealAsset {
    public static let id = "beaded-mala-bracelet"
    public static let summary = "Worn wooden mala bracelet: polished beads on elastic, brass spacers, guru bead with a wrapped silk tassel."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "wood", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 24, distance: 1.0, ground: false, studio: true)

    /// Main bead wood.
    public var wood: MaterialKey = "wood.mahogany"
    /// Darker rosewood beads.
    public var dark: MaterialKey = "wood.mahogany:3F1E14"
    /// Lighter sandalwood beads.
    public var light: MaterialKey = "wood.walnut-oiled"
    /// Spacers.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Tassel silk.
    public var silk: MaterialKey = "thread.red"
    /// Elastic cord.
    public var cord: MaterialKey = "thread.white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let off: Float = 0.0052
        let count = 120
        let loop = (0...count).map { k -> V3 in
            let ph = 2 * Float.pi * Float(k) / Float(count)
            return WristKit.P(ph, 0, off)
        }
        let cum = WristKit.lengths(loop)
        let total = cum.last!
        func bead(_ r: Float, flat: Float = 0.94, _ mat: MaterialKey) -> Surface {
            var pr: [V2] = []
            let a0 = asin(0.0008 / r)
            for k in 0...9 {
                let a = a0 + (Float.pi - 2 * a0) * Float(k) / 9
                pr.append(V2(r * sin(a), r * flat * cos(a)))
            }
            return Prim.lathe(pr.reversed(), segments: 18, seamTile: 0.012, material: mat)
        }
        enum Item { case bead(Int), rondelle, guru }
        var items: [Item] = [.guru, .rondelle]
        var widths: [Float] = [0.0130, 0.0022]
        let nb = Int((total - 0.0130 - 0.0022 * 5) / 0.0090)
        for k in 0..<nb {
            items.append(.bead(k))
            widths.append(0.0090)
            if k == 5 || k == 10 || k == 15 { items.append(.rondelle); widths.append(0.0022) }
        }
        items.append(.rondelle); widths.append(0.0022)
        let k = total / widths.reduce(0, +)
        var s: Float = 0
        var centres: [V3] = []
        let tones = [wood, dark, light, wood, dark]
        let cap0 = WristKit.P(1.05, 0, off)
        _ = cap0
        let guruPhase: Float = 0.0
        var guruPos = V3.zero, guruN = V3(0, 0, 1)
        for (i, it) in items.enumerated() {
            let w = widths[i] * k
            let (p, t, n) = WristKit.at(loop, cum, s + w / 2)
            let q = simd_quatf(from: V3(0, 1, 0), to: t)
            centres.append(p)
            switch it {
            case .guru:
                var g = bead(0.0066, flat: 0.98, dark)
                g.displace { pp, _ in 0.00012 * Noise.fbm(pp * 500, octaves: 2) }
                m.add(g, Xform(translation: p, rotation: q))
                guruPos = p; guruN = n
            case .rondelle:
                m.add(Prim.lathe([V2(0.0008, -0.0010), V2(0.0033, -0.0010), V2(0.0038, -0.0003), V2(0.0038, 0.0003), V2(0.0033, 0.0010), V2(0.0008, 0.0010)],
                                 segments: 20, seamTile: 0.01, material: brass), Xform(translation: p, rotation: q))
            case .bead(let j):
                let mat: MaterialKey = j == 9 ? "wood.lumber-maple" : tones[(j * 7 + 3) % tones.count]
                let r = 0.0045 + rng.float(-0.0001...0.0001)
                var bd = bead(r, mat)
                if j % 4 == 1 {
                    let c = V3(rng.float(-0.6...0.6), rng.float(-0.6...0.6), 0.9) * r
                    bd.displace { pp, _ in -0.00035 * exp(-simd_length_squared(pp - c) / 0.0000012) + 0.00008 * Noise.fbm(pp * 700, octaves: 2) }
                }
                m.add(bd, Xform(translation: p, rotation: simd_quatf(angle: rng.float(0...6), axis: t) * q))
                if j == 4 || j == 13 {
                    m.add(WristKit.box(V3(0.00012, 0.0036, 0.00008), material: "plastic.grime"),
                          Xform(translation: p + n * (r * 0.97), rotation: WristKit.K.basis(t, n) * simd_quatf(angle: 0.5, axis: V3(0, 0, 1))))
                }
            }
            s += w
        }
        _ = guruPhase
        // Elastic cord threaded through the beads, visible at the holes.
        centres.append(centres[0])
        let cordPath = catmull(centres, per: 3)
        m.add(Prim.tube(cordPath, radii: cordPath.map { _ in 0.00045 }, sides: 5, seamTile: 0.01, material: cord, capEnd: false))

        // Cord knot beside the guru bead.
        m.add(Prim.lathe([V2(0, -0.0010), V2(0.0010, -0.0007), V2(0.0012, 0), V2(0.0010, 0.0007), V2(0, 0.0010)], segments: 12, seamTile: 0.01, material: cord),
              Xform(translation: guruPos + guruN * (-0.0001) + V3(0, -0.0001, 0) + WristKit.T(0) * 0.0000))
        // Knotted cap and wrapped tassel hanging below the guru bead.
        let hang = guruPos + V3(0, -0.0062, 0) + guruN * 0.0006
        m.add(Prim.lathe([V2(0, 0.0030), V2(0.0014, 0.0028), V2(0.0026, 0.0008), V2(0.0030, -0.0006), V2(0.0024, -0.0022), V2(0.0010, -0.0030), V2(0, -0.0031)].reversed(),
                         segments: 20, seamTile: 0.01, material: brass), Xform(translation: hang))
        let top = hang + V3(0, -0.0034, 0)
        for t in 0..<40 {
            let a = rng.float(0...(2 * Float.pi)), rr = rng.float(0.0002...0.0014)
            let p0 = top + V3(cos(a) * rr, 0, sin(a) * rr)
            let len = rng.float(0.026...0.034)
            let sway = V3(rng.float(-0.0025...0.0025), 0, rng.float(-0.0025...0.0025)) + guruN * 0.0012
            let path = catmull([p0, p0 + V3(0, -len * 0.45, 0) + sway * 0.3, p0 + V3(0, -len * 0.8, 0) + sway * 0.7, p0 + V3(0, -len, 0) + sway], per: 3)
            m.add(Prim.tube(path, radii: path.indices.map { 0.00022 - 0.00006 * Float($0) / Float(path.count) }, sides: 3, seamTile: 0.01, material: silk, capEnd: false))
            _ = t
        }
        for (j, y) in [Float(-0.0046), -0.0052, -0.0058, -0.0064].enumerated() {
            m.add(Prim.torus(major: 0.0016 + 0.00006 * Float(j % 2), minor: 0.00032, segments: 14, sides: 4, material: silk), Xform(translation: top + V3(0, y + 0.0034, 0)))
        }
        m.add(Prim.lathe([V2(0, 0.0000), V2(0.0014, -0.0002), V2(0.0019, -0.0014), V2(0.0016, -0.0026), V2(0, -0.0028)].reversed(), segments: 16, seamTile: 0.008, material: silk),
              Xform(translation: top + V3(0, -0.0050, 0)))
        return LODModel(m)
    }
}
