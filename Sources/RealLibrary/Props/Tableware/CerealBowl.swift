import simd
import Foundation

/// Cereal bowl, 16 cm: blue-glazed stoneware, deep curved wall, rolled lip, bisque foot ring. Story: dried milk ring and spoon marks inside.
public struct CerealBowl: RealAsset {
    public static let id = "cereal-bowl"
    public static let summary = "Cereal bowl, 16 cm: glazed ceramic, deep curved wall, rolled rim, foot ring."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.15, studio: true)

    /// Rim diameter (m).
    public var diameter: Float = 0.16
    /// Height (m).
    public var height: Float = 0.07
    /// Foot ring radius (m).
    public var footRadius: Float = 0.03
    /// Glaze and bisque foot.
    public var glaze: MaterialKey = "ceramic.celadon"
    public var foot: MaterialKey = "ceramic.bisque:D8CDB8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let b = DD1ETableware.Bowl(D: diameter, H: height, footR: footRadius)
        var m = Model(name: Self.id)
        m.add(DD1ETableware.lathe(b.profile(), glaze))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(footRadius), foot))
        // Dried milk ring where the level stood, two thin bands.
        let milk: MaterialKey = "ceramic.vitreous:EFE8D6"
        let t0 = b.theta(innerY: 0.036)
        m.add(DD1ETableware.lathe(b.innerBand(t0, t0 + 0.07, thick: 0.0004), milk))
        m.add(DD1ETableware.lathe(b.innerBand(t0 + 0.11, t0 + 0.135, thick: 0.0003), milk))
        // Spoon marks.
        m.add(DD1ETableware.lathe(b.innerBand(0.2, 0.21, thick: 0.00025), "ceramic.vitreous:A9B7C2"))
        _ = rng.float()
        DD1ETableware.finish(&m, aoHeight: 0.02)
        return LODModel(m)
    }
}
