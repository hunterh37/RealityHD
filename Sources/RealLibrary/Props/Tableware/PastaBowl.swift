import simd
import Foundation

/// Pasta bowl, 24 cm: glazed vitreous ceramic, wide shallow well, broad flat rim, rolled edge, bisque foot ring. Story: tomato sauce splash on the rim.
public struct PastaBowl: RealAsset {
    public static let id = "pasta-bowl"
    public static let summary = "Pasta bowl, 24 cm: glazed ceramic, wide shallow well, broad rim, foot ring."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.15, studio: true)

    /// Outer diameter (m).
    public var diameter: Float = 0.24
    /// Rim height (m).
    public var height: Float = 0.05
    /// Well floor radius (m).
    public var wellRadius: Float = 0.055
    /// Top of the well floor (m).
    public var wellY: Float = 0.013
    /// Flat rim width (m).
    public var rimWidth: Float = 0.045
    /// Glaze and bisque foot.
    public var glaze: MaterialKey = "ceramic.vitreous:F1EFE8"
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        m.add(DD1ETableware.lathe(DD1ETableware.plate(diameter: diameter, height: height, wellRadius: wellRadius, wellY: wellY, rimWidth: rimWidth, thickness: 0.005, edgeRadius: 0.0028), glaze))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(wellRadius), foot))
        // Sauce splash on the flat rim, plus a sauce film in the well.
        let R = diameter / 2
        let a: Float = 2.2
        let rr = R - 0.02
        let top = height - 0.0012
        m.add(Prim.superellipsoid(V3(0.020, 0.0010, 0.011), exponent: 2.5, subdivisions: 8, material: "food.tomato-sauce"),
              Xform(translation: V3(rr * cos(a), top, -rr * sin(a)), rotation: simd_quatf(degrees: a * 180 / .pi, axis: V3(0, 1, 0))))
        m.add(Prim.superellipsoid(V3(0.006, 0.0008, 0.004), exponent: 2.5, subdivisions: 6, material: "food.tomato-sauce"),
              Xform(translation: V3((rr - 0.014) * cos(a + 0.12), top - 0.0001, -(rr - 0.014) * sin(a + 0.12)), rotation: simd_quatf(degrees: 30, axis: V3(0, 1, 0))))
        m.add(DD1ETableware.lathe(DD1ETableware.rimBand(diameter: diameter, height: height, rimWidth: rimWidth, R - 0.0180, R - 0.0150), "ceramic.cobalt"))
        _ = rng.float()
        DD1ETableware.finish(&m, aoHeight: 0.02)
        return LODModel(m)
    }
}
