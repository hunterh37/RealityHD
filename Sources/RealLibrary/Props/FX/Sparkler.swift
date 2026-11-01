import simd
import Foundation

/// Sparkler: Thin wire, dull grey pyrotechnic coating, orange ember head. Parts: Steel wire stick, Grey coated end, Glowing ember head.
public struct Sparkler: RealAsset {
    public static let id = "sparkler"
    public static let summary = "Wire sparkler, 30 cm: steel stick, grey coated end, glowing ember head. Grip origin at the handle center, head along +Y."
    public static let tags = ["prop", "handheld", "fx", "metal", "light"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall length in meters; handle center at the origin, ember head along +Y.
    public var length: Float = 0.3
    /// Ember head material (an emissive.* key).
    public var ember: MaterialKey = "emissive.amber"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y0: Float = -0.075, y1 = y0 + length
        let coatY: Float = 0.075, headY: Float = y1 - 0.026
        // Steel wire: slight hand-bent drift, small hooked loop at the butt.
        let pts: [V3] = (0...8).map { i in
            let t = Float(i) / 8
            let y = y0 + (headY + 0.01 - y0) * t
            return V3(0.0012 * sin(t * 5 + rng.float(0...1)), y, 0.0009 * cos(t * 4))
        }
        m.add(Prim.tube(pts, radii: pts.map { _ in 0.0014 }, sides: 8, seamTile: 0.02, material: "metal.steel", capEnd: true))
        m.add(Prim.torus(major: 0.0055, minor: 0.0013, segments: 20, sides: 6, material: "metal.steel"),
              Xform(translation: V3(0.0055, y0 + 0.001, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Grey pyrotechnic coating: uneven radius, rounded dull end.
        var prof: [(Float, Float)] = [(0, coatY - 0.001), (0.0026, coatY - 0.001), (0.0032, coatY + 0.001)]
        let n = 14
        for i in 0...n {
            let t = Float(i) / Float(n)
            let rr: Float = 0.0033 + 0.00035 * rng.float(-1...1)
            prof.append((rr, coatY + 0.002 + (headY - coatY - 0.002) * t))
        }
        prof += [(0.0028, headY), (0, headY)]
        m.add(turned(prof, segments: 14, material: "plastic.matte:6A6C6E", seamTile: 0.02))
        // Story detail: burnt-back black band where the coating has already spent.
        m.add(turned([(0.0029, headY - 0.012), (0.0038, headY - 0.011), (0.0038, headY - 0.002), (0.0029, headY - 0.001)], segments: 14, material: "plastic.matte:151515", seamTile: 0.02))
        // Glowing ember head: lumpy burning cap and a few glowing specks.
        m.add(turned([(0, headY - 0.001), (0.0033, headY - 0.001), (0.0046, headY + 0.003), (0.0041, headY + 0.011), (0.0027, headY + 0.0185), (0.0012, headY + 0.0235), (0, headY + 0.0245)],
                     segments: 12, material: ember, seamTile: 0.02))
        for i in 0..<10 {
            let a = rng.float(0...(2 * .pi)), r = rng.float(0.006...0.016), y = headY + rng.float(0.0...0.03)
            m.add(turned([(0, -0.0006), (0.0008, 0), (0, 0.0006)], segments: 6, material: "emissive.warm"), Xform(translation: V3(cos(a) * r, y + 0.002 * Float(i % 3), sin(a) * r)))
        }
        return LODModel(m)
    }
}
