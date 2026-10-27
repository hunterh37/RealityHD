import simd
import Foundation

/// Salad plate, 21 cm: glazed vitreous ceramic with a shallow well, coved rise, flat rim, rolled edge and bisque foot ring. Story: fine grey cutlery scuff ring in the well.
public struct SaladPlate: RealAsset {
    public static let id = "salad-plate"
    public static let summary = "Salad plate, 21 cm: glazed white ceramic, shallow well, rolled rim, unglazed foot ring."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.15, studio: true)

    /// Outer diameter (m).
    public var diameter: Float = 0.21
    /// Rim height above the base (m).
    public var height: Float = 0.02
    /// Radius of the flat well (m).
    public var wellRadius: Float = 0.055
    /// Top of the well floor above the base (m).
    public var wellY: Float = 0.0085
    /// Flat rim width (m).
    public var rimWidth: Float = 0.03
    /// Glazed body and unglazed foot ring.
    public var glaze: MaterialKey = "ceramic.vitreous"
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        m.add(DD1ETableware.lathe(DD1ETableware.plate(diameter: diameter, height: height, wellRadius: wellRadius, wellY: wellY, rimWidth: rimWidth, thickness: 0.004), glaze))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(wellRadius), foot))
        // Sage line near the rim and pale cutlery scuff rings in the well.
        let R = diameter / 2
        m.add(DD1ETableware.lathe(DD1ETableware.rimBand(diameter: diameter, height: height, rimWidth: rimWidth, R - 0.0185, R - 0.0160), "ceramic.vitreous:8FAA9C"))
        let scuff: MaterialKey = "ceramic.vitreous:C9C5BB"
        m.add(DD1ETableware.lathe(DD1ETableware.annulus(0.043, 0.0475, y: wellY, thick: 0.0002), scuff))
        m.add(DD1ETableware.lathe(DD1ETableware.annulus(0.0215, 0.0250, y: wellY, thick: 0.0002), scuff))
        m.add(DD1ETableware.lathe(DD1ETableware.annulus(0.0330, 0.0345, y: wellY, thick: 0.0002), scuff))
        _ = rng.float()
        DD1ETableware.finish(&m)
        return LODModel(m)
    }
}
