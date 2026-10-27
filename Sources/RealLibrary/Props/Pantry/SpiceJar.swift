import simd
import Foundation

/// Glass spice jar 5 cm wide with a threaded neck, tin shaker lid with rolled rim and sifter holes,
/// a wrapped paper label with an overlapped seam, paprika fill with a settled slope, and a scuffed lid edge.
public struct SpiceJar: RealAsset {
    public static let id = "spice-jar"
    public static let summary = "Glass spice jar with threaded tin shaker lid, paper label wrap and ground paprika inside, 5 cm wide."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal", "paper"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, studio: true)

    /// Jar body radius (m).
    public var bodyRadius: Float = 0.0245
    /// Glass.
    public var glass: MaterialKey = "glass.clear"
    /// Lid tin.
    public var tin: MaterialKey = "metal.galvanized-aged"
    /// Worn lid rim.
    public var tinWorn: MaterialKey = "metal.nickel-worn"
    /// Label paper.
    public var label: MaterialKey = "paper.sheet:E9DFC8"
    /// Label print.
    public var ink: MaterialKey = "paper.sheet:9C2B1B"
    /// Spice fill.
    public var spice: MaterialKey = "plastic.matte:A8431F"
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = detail ? 56 : 20, R = bodyRadius
        // Glass body: shoulder, neck, rolled finish.
        let outer: [V2] = Profile.smooth([V2(0.0, 0.0), V2(R - 0.003, 0.0), V2(R, 0.003), V2(R, 0.070), V2(R - 0.003, 0.078),
                                           V2(0.0197, 0.0825), V2(0.0197, 0.0905)], per: detail ? 5 : 2)
        var body = Prim.lathe(Profile.shell(outer, wall: 0.0022, floor: 0.0045), segments: seg, seamTile: 0.1, material: glass)
        if detail { body.displace { p, _ in 0.00025 * Noise.perlin(V3(p.x * 160, p.y * 120, p.z * 160)) } }
        m.add(body)
        // Neck finish ring and thread (glass, visible below the lid skirt).
        m.add(Prim.lathe([V2(0.0207, 0.0805), V2(0.0222, 0.0812), V2(0.0222, 0.0828), V2(0.0207, 0.0836)], segments: seg, seamTile: 0.1, material: glass))
        if detail {
            m.add(Prim.helix(radius: 0.0199, pitch: 0.0028, turns: 1.2, wire: 0.00055, material: glass), Xform(translation: V3(0, 0.0845, 0)))
        }
        // Paprika fill with a settled, slightly tilted surface.
        var fill = Prim.lathe([V2(0, 0.0045), V2(R - 0.0023, 0.0045), V2(R - 0.0023, 0.0585), V2(0.013, 0.0592), V2(0.0, 0.0572)],
                              segments: seg, seamTile: 0.05, material: spice)
        if detail { fill.displace { p, _ in 0.0006 * Noise.perlin(V3(p.x * 220, p.y * 220, p.z * 220)) * smoothstep(0.057, 0.059, p.y) } }
        m.add(fill, Xform(rotation: DD1LPantry.q(0.05, V3(0, 0, 1))))
        // Label wrap: band with printed rules, overlapped seam at the back.
        let ly0: Float = 0.016, ly1: Float = 0.060
        m.add(Prim.lathe(DD1LPantry.band(r: R + 0.0004, y0: ly0, y1: ly1, rows: 2), segments: seg, seamTile: 0.1, material: label))
        m.add(DD1LPantry.cylPatch(r: R + 0.0004, a0: -.pi / 2 - 0.9, a1: -.pi / 2 + 0.9, y0: 0.047, y1: 0.056, rows: 1, material: ink))
        m.add(DD1LPantry.cylPatch(r: R + 0.0004, a0: -.pi / 2 - 0.55, a1: -.pi / 2 + 0.55, y0: 0.030, y1: 0.041, rows: 1, material: ink))
        for k in 0..<3 {
            let y = 0.0235 + Float(k) * 0.0028
            m.add(DD1LPantry.cylPatch(r: R + 0.0004, a0: -.pi / 2 - 0.5 + Float(k) * 0.06, a1: -.pi / 2 + 0.5 - Float(k) * 0.08, y0: y, y1: y + 0.0012, rows: 1, material: ink))
        }
        m.add(DD1LPantry.cylPatch(r: R + 0.0007, a0: .pi / 2 - 0.07, a1: .pi / 2 + 0.07, y0: ly0, y1: ly1, rows: 2, material: label))
        // Tin lid: skirt, rolled lower rim, domed top with recessed sifter plate.
        let lid: [V2] = [V2(0.0212, 0.0875), V2(0.0226, 0.0880), V2(0.0230, 0.0890), V2(0.0226, 0.0900), V2(0.0222, 0.0905),
                         V2(0.0222, 0.0950), V2(0.0216, 0.0962), V2(0.0200, 0.0965), V2(0.0185, 0.0960), V2(0.0170, 0.0953),
                         V2(0.0, 0.0951)]
        m.add(Prim.lathe(lid, segments: seg, seamTile: 0.1, material: tin))
        if detail {
            for k in 0..<3 {
                let y = 0.0912 + Float(k) * 0.0014
                m.add(Prim.lathe([V2(0.0222, y), V2(0.0226, y + 0.0004), V2(0.0222, y + 0.0008)], segments: seg, seamTile: 0.1, material: tin))
            }
        }
        // Worn rim and rust-grime flecks (the story detail: a scuffed, dinged lid edge).
        m.add(DD1LPantry.cylPatch(r: 0.0231, a0: 0.2, a1: 1.1, y0: 0.0884, y1: 0.0897, rows: 1, material: tinWorn, radiusAt: nil))
        m.add(DD1LPantry.cylPatch(r: 0.0231, a0: 0.55, a1: 0.7, y0: 0.0886, y1: 0.0894, lift: 0.0006, rows: 1, material: "metal.rust-grime"))
        // Sifter holes.
        let hole: MaterialKey = "plastic.matte:1A1410"
        m.add(Prim.cylinder(radius: 0.0021, height: 0.0004, bevel: 0.0001, segments: detail ? 10 : 6, bevelSegments: 1, material: hole), Xform(translation: V3(0, 0.0950, 0)))
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + 0.2
            m.add(Prim.cylinder(radius: 0.0016, height: 0.0004, bevel: 0.0001, segments: detail ? 10 : 6, bevelSegments: 1, material: hole),
                  Xform(translation: V3(0.0095 * cos(a), 0.0950, 0.0095 * sin(a))))
        }
        m.add(Prim.torus(major: 0.0135, minor: 0.0005, segments: detail ? 40 : 16, sides: 6, material: tin), Xform(translation: V3(0, 0.0954, 0)))
        _ = rng.float()
        groundAO(&m, height: 0.01, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
