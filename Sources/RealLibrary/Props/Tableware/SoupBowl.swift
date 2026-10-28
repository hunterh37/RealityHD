import simd
import Foundation

/// Soup bowl, 18 cm: glazed vitreous ceramic, deep curved wall to a rolled lip, bisque foot ring, cobalt rim line. Story: spoon scratch ring on the floor.
public struct SoupBowl: RealAsset {
    public static let id = "soup-bowl"
    public static let summary = "Soup bowl, 18 cm: glazed ceramic, deep curved wall, rolled rim, foot ring."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.15, studio: true)

    /// Rim diameter (m).
    public var diameter: Float = 0.18
    /// Height (m).
    public var height: Float = 0.06
    /// Foot ring radius (m).
    public var footRadius: Float = 0.035
    /// Glaze, bisque foot and cobalt rim line.
    public var glaze: MaterialKey = "ceramic.vitreous"
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    public var stripe: MaterialKey = "ceramic.cobalt"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let b = DD1ETableware.Bowl(D: diameter, H: height, footR: footRadius)
        var m = Model(name: Self.id)
        m.add(DD1ETableware.lathe(b.profile(), glaze))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(footRadius), foot))
        m.add(DD1ETableware.lathe(b.innerBand(b.theta(innerY: height - 0.017), b.theta(innerY: height - 0.012), thick: 0.0004), stripe))
        // Cobalt line across the top of the rolled lip.
        let lr = diameter / 2 - b.wall / 2
        m.add(DD1ETableware.lathe([V2(lr - 0.0009, height - 0.0006), V2(lr + 0.0009, height - 0.0006), V2(lr + 0.0009, height + 0.0002), V2(lr - 0.0009, height + 0.0002), V2(lr - 0.0009, height - 0.0006)], stripe))
        // Spoon scratches: grey rings on the floor of the bowl.
        let scuff: MaterialKey = "ceramic.vitreous:B2AEA5"
        m.add(DD1ETableware.lathe(b.innerBand(0.16, 0.172, thick: 0.00025), scuff))
        m.add(DD1ETableware.lathe(b.innerBand(0.33, 0.338, thick: 0.00025), scuff))
        _ = rng.float()
        DD1ETableware.finish(&m, aoHeight: 0.02)
        return LODModel(m)
    }
}
