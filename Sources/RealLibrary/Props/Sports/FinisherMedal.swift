import simd
import Foundation

/// Marathon finisher medal, 64 mm cast gold-finish disc 8 mm thick with a raised beaded rim, recessed field and
/// a raised eight-point star boss, a brass bail ring, and a blue grosgrain ribbon with a gold center stripe
/// that folds over the bail into two strands. Total height 0.10 m. Lies upright, face +Z, base at y = 0.
/// Anchors: `medal.center`, `ribbon.top` (neck loop attach).
public struct FinisherMedal: RealAsset {
    public static let id = "finisher-medal"
    public static let summary = "Marathon finisher medal: 64 mm cast gold disc with beaded rim and star boss, bail ring and blue grosgrain ribbon with gold stripe."
    public static let tags = ["prop", "sports", "metal", "handheld"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 0.3, studio: true)

    /// Cast medal metal.
    public var metal: MaterialKey = "metal.gold"
    /// Bail ring.
    public var bail: MaterialKey = "metal.brass"
    /// Ribbon cloth.
    public var ribbon: MaterialKey = "fabric.grosgrain:1B3E91"
    /// Center stripe.
    public var stripe: MaterialKey = "fabric.grosgrain:F2C230"
    public init() {}

    public var anchors: [String: Xform] {
        ["medal.center": Xform(translation: V3(0, 0.032, 0.004)), "ribbon.top": Xform(translation: V3(0, 0.1, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let R: Float = 0.032, cy: Float = 0.032
        // Disc: lathe about Y (profile r, y), then stood up so the axis is +Z.
        let prof: [V2] = [V2(0, 0), V2(R - 0.002, 0), V2(R, 0.0015), V2(R, 0.0065), V2(R - 0.0025, 0.008), V2(R - 0.0045, 0.0072),
                          V2(R - 0.0055, 0.0035), V2(R - 0.007, 0.0028), V2(0.016, 0.0028), V2(0.0115, 0.0036), V2(0.0045, 0.0045), V2(0, 0.0047)]
        let stand = Xform(translation: V3(0, cy, -0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        m.add(Prim.lathe(prof, segments: 96, seamTile: 0.02, material: metal), stand)
        // Bead ring inside the rim.
        m.add(Prim.torus(major: R - 0.0085, minor: 0.0007, segments: 96, sides: 12, material: metal), Xform(translation: V3(0, cy, 0.0003), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Star boss.
        var star: [V2] = []
        for i in 0..<16 { let a = Float(i) / 16 * 2 * .pi, r: Float = i % 2 == 0 ? 0.0165 : 0.0078; star.append(V2(r * sin(a), r * cos(a))) }
        m.add(Prim.extrude(star, depth: 0.0012, bevel: 0.0003, bevelSegments: 2, material: metal), Xform(translation: V3(0, cy, 0.0013)))
        // Bail ring above the disc.
        m.add(Prim.torus(major: 0.0055, minor: 0.0013, segments: 48, sides: 24, material: bail), Xform(translation: V3(0, 2 * cy + 0.004, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.roundedBox(V3(0.008, 0.004, 0.003), radius: 0.001, bevelSegments: 2, material: bail), Xform(translation: V3(0, 0.0645, 0)))
        // Ribbon: two strands folded over the bail, crossing slightly.
        for s in [Float(-1), 1] {
            let q = simd_quatf(degrees: -s * 18, axis: V3(0, 0, 1))
            let c = V3(s * 0.011, 0.083, 0)
            m.add(Prim.roundedBox(V3(0.026, 0.036, 0.0016), radius: 0.0007, bevelSegments: 2, material: ribbon), Xform(translation: c, rotation: q))
            m.add(Prim.roundedBox(V3(0.006, 0.0362, 0.0019), radius: 0.0007, bevelSegments: 2, material: stripe), Xform(translation: c, rotation: q))
        }
        m.add(Prim.roundedBox(V3(0.03, 0.006, 0.002), radius: 0.001, bevelSegments: 2, material: ribbon), Xform(translation: V3(0, 0.0675, 0.0004)))
        return LODModel(m)
    }
}
