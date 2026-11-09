import simd
import Foundation

/// Gold upper-arm cuff, open at the inner side: 38 mm hammered dome-section band tapering toward barrel finials, a beaded centre
/// cord, plain edge rails, patina-dark engraved lines, a bezel-set emerald cabochon on the front-outer side and a dent from a knock.
public struct GoldArmCuff: RealAsset {
    public static let id = "gold-arm-cuff"
    public static let summary = "Worn gold arm cuff: hammered band, beaded cord, engraved patina lines, bezel-set emerald, barrel finials."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "glass"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 0.5, ground: false, studio: true)

    /// Cuff metal.
    public var gold: MaterialKey = "metal.gold"
    /// Patina in the engraving.
    public var patina: MaterialKey = "metal.brass-aged"
    /// Cabochon.
    public var stone: MaterialKey = "glass.emerald"
    /// Cuff height on the arm (m).
    public var centreY: Float = 0.028
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias A = ArmKit
        let y = centreY, w: Float = 0.038, hw = w / 2
        let off: Float = 0.0042
        let g: Float = 0.28
        let thA = -Float.pi / 2 + g, thB = 3 * Float.pi / 2 - g
        let nPath = 120
        func thAt(_ s: Float) -> Float { thA + (thB - thA) * s }
        func spow(_ v: Float, _ e: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), e) }
        /// Outer dome height at width position x.
        func dome(_ x: Float) -> Float { 0.0042 * (0.55 + 0.45 * (1 - pow(x / hw, 2))) }
        var prof: [V2] = []
        for k in 0..<24 {
            let ph = 2 * Float.pi * Float(k) / 24
            let x = hw * spow(cos(ph), 0.35), s = sin(ph)
            prof.append(V2(x, s >= 0 ? dome(x) * pow(s, 0.55) : -0.0016 * pow(-s, 0.55)))
        }
        let path = (0..<nPath).map { A.P(thAt(Float($0) / Float(nPath - 1)), y, off) }
        let fr = A.K.frames(path, normal: { A.nrm($0) })
        var band = A.skin(fr, profile: prof, scale: { 1 - 0.18 * pow(abs($0 - 0.5) * 2, 3) }, material: gold)
        let dentAt = A.P(2.3, y, off + 0.004)
        band.displace { p, _ in
            0.00035 * Noise.fbm(p * 150, octaves: 2) - 0.0009 * exp(-simd_length_squared(p - dentAt) / 0.000036)
        }
        m.add(band)

        // Beaded centre cord and plain edge rails.
        let nb = 190
        let beadPts = (0..<nb).map { A.P(thAt(0.03 + 0.94 * Float($0) / Float(nb - 1)), y, off + 0.0042 + 0.0004) }
        let beadR = (0..<nb).map { k -> Float in 0.0008 + 0.00055 * pow(abs(sin(Float(k) / 6 * Float.pi)), 0.6) }
        m.add(Prim.tube(beadPts, radii: beadR, sides: 5, seamTile: 0.01, material: gold, capEnd: true))
        for s: Float in [-1, 1] {
            let pts = (0..<80).map { A.P(thAt(0.04 + 0.92 * Float($0) / 79), y + s * 0.0155, off + dome(0.0155) + 0.0003) }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0011 }, sides: 5, seamTile: 0.01, material: gold, capEnd: true))
            let eng = (0..<90).map { A.P(thAt(0.05 + 0.90 * Float($0) / 89), y + s * 0.0065, off + dome(0.0065) + 0.0001) }
            m.add(Prim.tube(eng, radii: eng.map { _ in 0.00045 }, sides: 4, seamTile: 0.01, material: patina, capEnd: true))
        }


        // Barrel finials at both ends.
        for s: Float in [0, 1] {
            let p = A.P(thAt(s), y, off + 0.0008)
            m.add(Prim.cylinder(radius: 0.0072, height: 0.038, bevel: 0.0034, segments: 24, bevelSegments: 3, material: gold),
                  Xform(translation: p - V3(0, 0.019, 0)))
            m.add(Prim.torus(major: 0.0072, minor: 0.0008, segments: 24, sides: 5, material: patina), Xform(translation: p + V3(0, 0.0105, 0)))
            m.add(Prim.torus(major: 0.0072, minor: 0.0008, segments: 24, sides: 5, material: patina), Xform(translation: p - V3(0, 0.0105, 0)))
        }

        // Bezel-set cabochon, long axis along the arm.
        let th0: Float = 0.75
        let c = A.P(th0, y, off + 0.0042)
        let q = A.onSurface(c)
        let n = A.nrm(c)
        m.add(Prim.torus(major: 0.0098, minor: 0.0017, segments: 36, sides: 8, material: gold),
              Xform(translation: c + n * 0.0006, rotation: q, scale: V3(1, 1, 1.40)))
        m.add(Prim.superellipsoid(V3(0.016, 0.0085, 0.023), exponent: 2, subdivisions: 6, material: stone),
              Xform(translation: c + n * 0.0026, rotation: q))
        for k in 0..<4 {
            let a = Float(k) * Float.pi / 2 + Float.pi / 4
            let d = A.tangent(th0) * cos(a) * 0.0105 + V3(0, 1, 0) * sin(a) * 0.0150
            m.add(Prim.superellipsoid(V3(0.0036, 0.0036, 0.0036), exponent: 2, subdivisions: 3, material: gold), Xform(translation: c + d + n * 0.0014))
        }
        return LODModel(m)
    }
}
