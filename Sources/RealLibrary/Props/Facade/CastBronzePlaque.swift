import simd
import Foundation

/// Civic dedication plaque cast in bronze: a recessed dark field inside a raised border with an inner
/// bead, a dedication seal, four lines of raised lettering and four domed cap screws on washers. Hand
/// rubbed bright on the raised faces, verdigris running from the screws and the top rim.
public struct CastBronzePlaque: RealAsset {
    public static let id = "cast-bronze-plaque"
    public static let summary = "Civic cast bronze plaque 0.6 x 0.4 m: raised border with bead, cast lettering, dedication seal, domed cap screws."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 11500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.2)

    /// Dedication lines, top to bottom (A-Z, 0-9).
    public var lines = ["CITY OF HARTWELL", "MUNICIPAL BUILDING", "ERECTED MCMXXVII", "J T HARRIS MAYOR"]
    public var field: MaterialKey = "metal.bronze-weathered"
    public var raised: MaterialKey = "metal.bronze-cast"
    public var rubbed: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.6, H: Float = 0.4
        // Cast slab, then the raised border and inner bead.
        FA.box(&m, V3(W, H, 0.016), V3(0, H / 2, 0.008), field, r: 0.005)
        FA.box(&m, V3(W, 0.032, 0.01), V3(0, H - 0.016, 0.019), raised, r: 0.0035)
        FA.box(&m, V3(W, 0.032, 0.01), V3(0, 0.016, 0.019), raised, r: 0.0035)
        FA.box(&m, V3(0.032, H - 0.064, 0.01), V3(-W / 2 + 0.016, H / 2, 0.019), raised, r: 0.0035)
        FA.box(&m, V3(0.032, H - 0.064, 0.01), V3(W / 2 - 0.016, H / 2, 0.019), raised, r: 0.0035)
        for (w, h, x, y) in [(W - 0.08, 0.006, 0.0, H - 0.042), (W - 0.08, 0.006, 0.0, 0.042), (0.006, H - 0.084, -W / 2 + 0.042, H / 2), (0.006, H - 0.084, W / 2 - 0.042, H / 2)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, 0.006), V3(x, y, 0.019), rubbed, r: 0.002)
        }
        // Seal: ring, inner ring, field disc and an eight point star.
        let sc = V3(0, 0.3, 0.016)
        m.add(Prim.torus(major: 0.052, minor: 0.0045, segments: 36, sides: 8, material: raised), Xform(translation: sc + V3(0, 0, 0.003), rotation: FA.q(90, FA.X)))
        m.add(Prim.torus(major: 0.039, minor: 0.0025, segments: 32, sides: 6, material: rubbed), Xform(translation: sc + V3(0, 0, 0.0025), rotation: FA.q(90, FA.X)))
        var star: [V2] = []
        for k in 0..<16 { let a = Float(k) * .pi / 8; star.append(V2(cos(a), sin(a)) * (k % 2 == 0 ? 0.034 : 0.017)) }
        m.add(Prim.extrude(star, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: raised), Xform(translation: sc + V3(0, 0, 0.002)))
        FA.cylZ(&m, r: 0.009, h: 0.007, at: sc, rubbed, bevel: 0.002, segments: 14)
        // Lettering with a rubbed bright top over each cast letter.
        let sizes: [(Float, Float, Float)] = [(0.2, 0.034, 0.0048), (0.15, 0.0245, 0.0034), (0.108, 0.0215, 0.003), (0.066, 0.0195, 0.0028)]
        for (i, s) in lines.enumerated() where i < sizes.count {
            let (y, h, st) = sizes[i]
            FG.text(&m, s, h: h, stroke: st, depth: 0.0042, at: V3(0, y, 0.016), raised)
            FG.text(&m, s, h: h, stroke: st * 0.6, depth: 0.0008, at: V3(0, y, 0.0202), rng.chance(0.5) ? rubbed : raised)
        }
        // Rules between the lines.
        for y: Float in [0.1735, 0.1285, 0.083] { FA.box(&m, V3(0.34, 0.004, 0.004), V3(0, y, 0.018), raised, r: 0.0012) }
        // Cap screws on washers at the corners.
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            let p = V3(sx * (W / 2 - 0.016), H / 2 + sy * (H / 2 - 0.016), 0.024)
            FA.cylZ(&m, r: 0.0085, h: 0.0022, at: p, "metal.brass", bevel: 0.0006, segments: 14)
            FG.dome(&m, at: V3(p.x, p.y, p.z + 0.0018), r: 0.0066, mat: rng.chance(0.5) ? "metal.stainless" : "metal.brass-aged")
            // Verdigris run below each screw.
            if sy > 0 {
                let len = rng.float(0.03...0.09)
                FG.flat(&m, V3(0.0045, len, 0.0004), V3(p.x + 0.002, p.y - 0.01 - len / 2, 0.0165), "paint.stucco:46685A")
            }
        }}
        // Verdigris bloom along the top inner edge and water tracks across the field.
        for _ in 0..<6 {
            FG.flat(&m, V3(rng.float(0.02...0.08), rng.float(0.01...0.03), 0.0004), V3(rng.float(-0.25...0.25), H - 0.06, 0.0166), "paint.stucco:46685A", rot: FA.q(rng.float(-10...10), FA.Z))
            let len = rng.float(0.05...0.16)
            FG.flat(&m, V3(0.004, len, 0.0004), V3(rng.float(-0.26...0.26), H - 0.07 - len / 2, 0.0165), "paint.stucco:46685A")
        }
        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
