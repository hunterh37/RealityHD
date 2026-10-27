import simd
import Foundation

/// Champagne flute: everyday tableware, stemmed crystal. Parts: tall tapered bowl, thin rim, drawn stem with knop, disc foot, etched nucleation dot at the bowl base.
public struct ChampagneFlute: RealAsset {
    public static let id = "champagne-flute"
    public static let summary = "Stemmed crystal flute: narrow bowl, knopped stem, disc foot, etched bubble point inside the base."
    public static let tags = ["prop", "interior", "glass", "container", "handheld"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.06, 0.23, 0.06)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Etched point material.
    public var etch: MaterialKey = "glass.frosted"
    public init() {}

    static let outer: [V2] = [
        V2(0, 0.0040), V2(0.014, 0.0030), V2(0.0268, 0.0010), V2(0.0296, 0.0004), V2(0.0301, 0.0016), V2(0.0292, 0.0030),
        V2(0.022, 0.0036), V2(0.0140, 0.0050), V2(0.0080, 0.0085), V2(0.0045, 0.0150), V2(0.0033, 0.028), V2(0.0032, 0.040),
        V2(0.0050, 0.045), V2(0.0066, 0.0495), V2(0.0050, 0.054), V2(0.0033, 0.060), V2(0.0033, 0.074), V2(0.0045, 0.084),
        V2(0.0085, 0.094), V2(0.0140, 0.106), V2(0.0190, 0.124), V2(0.0222, 0.150), V2(0.0226, 0.176), V2(0.0222, 0.202),
        V2(0.0214, 0.2288), V2(0.0212, 0.2300)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0011, floorY: Float = 0.0905
        m.add(Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY, smooth: detail ? 6 : 2), segments: seg, seamTile: 0.1, material: glass))
        // Nucleation point: tiny frosted etch where bubbles stream from.
        m.add(Prim.superellipsoid(V3(0.0032, 0.0014, 0.0032), exponent: 2, subdivisions: 3, material: etch), Xform(translation: V3(0, floorY + 0.0003, 0)))
        if detail {
            for k in 0..<5 {
                let a = Float(k) * 1.256
                m.add(Prim.superellipsoid(V3(0.0009, 0.0006, 0.0009), exponent: 2, subdivisions: 2, material: etch),
                      Xform(translation: V3(cos(a) * 0.0028, floorY + 0.0002, sin(a) * 0.0028)))
            }
        }
        // Dried champagne ring on the inner wall at the old pour line, pale amber.
        func ri(_ y: Float) -> Float { DD1FTableware.radius(Self.outer, at: y) - wall - 0.0002 }
        m.add(DD1FTableware.band([V2(ri(0.1730) - 0.0005, 0.1730), V2(ri(0.1705) - 0.0009, 0.1705), V2(ri(0.1680) - 0.0005, 0.1680)], segments: seg, material: "plastic.matte:B39A52"))
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(32, true), make(24, false)], switchDistances: [3])
    }
}
