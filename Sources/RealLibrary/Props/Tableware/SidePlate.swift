import simd
import Foundation

/// Side plate, 17 cm: glazed ceramic with shallow well, coved rise, flat rim, rolled edge and bisque foot ring. Story: small chip on the rim exposing the bisque body.
public struct SidePlate: RealAsset {
    public static let id = "side-plate"
    public static let summary = "Side plate, 17 cm: glazed ceramic, shallow well, rolled rim, foot ring, one small edge chip."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.15, studio: true)

    /// Outer diameter (m).
    public var diameter: Float = 0.17
    /// Rim height above the base (m).
    public var height: Float = 0.02
    /// Radius of the flat well (m).
    public var wellRadius: Float = 0.04
    /// Top of the well floor above the base (m).
    public var wellY: Float = 0.0085
    /// Flat rim width (m).
    public var rimWidth: Float = 0.028
    /// Glazed body and unglazed foot ring.
    public var glaze: MaterialKey = "ceramic.vitreous:E6EEF0"
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        m.add(DD1ETableware.lathe(DD1ETableware.plate(diameter: diameter, height: height, wellRadius: wellRadius, wellY: wellY, rimWidth: rimWidth, thickness: 0.004), glaze))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(wellRadius), foot))
        // Rim chip: bisque body showing through the glaze at the edge.
        let a: Float = 0.9
        let R = diameter / 2
        let chip = Prim.superellipsoid(V3(0.0085, 0.0014, 0.005), exponent: 3, subdivisions: 8, material: foot)
        m.add(chip, Xform(translation: V3((R - 0.0035) * cos(a), height - 0.0010, -(R - 0.0035) * sin(a)),
                          rotation: simd_quatf(degrees: a * 180 / .pi, axis: V3(0, 1, 0))))
        // Tea ring left by a cup on the well.
        m.add(DD1ETableware.lathe(DD1ETableware.annulus(0.0190, 0.0260, y: wellY, thick: 0.0002), "ceramic.vitreous:D6C5A5"))
        let R2 = diameter / 2
        m.add(DD1ETableware.lathe(DD1ETableware.rimBand(diameter: diameter, height: height, rimWidth: rimWidth, R2 - 0.0150, R2 - 0.0125), "ceramic.cobalt"))
        _ = rng.float()
        DD1ETableware.finish(&m)
        return LODModel(m)
    }
}
