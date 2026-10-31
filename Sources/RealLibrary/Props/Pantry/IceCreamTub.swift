import simd
import Foundation

/// IceCreamTub: everyday pantry, pantry. Real-size 0.14 x 0.13 x 0.14 m.
public struct IceCreamTub: RealAsset {
    public static let id = "ice-cream-tub"
    public static let summary = "IceCreamTub, 0.14 x 0.13 x 0.14 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "pantry"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "plastic.matte:EFE3C8"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "plastic.matte:C8507A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let body = FoodMesh.revolve(edge: 0.012, seamTile: 0.08, material: skin, curve: FoodMesh.profile([V2(0, 0), V2(0.052, 0), V2(0.055, 0.0025), V2(0.0655, 0.06), V2(0.0685, 0.116), V2(0.0698, 0.12), V2(0.0698, 0.1215), V2(0, 0.1215)], per: 1))
        m.add(body, Xform(scale: V3(0.93, 0.963, 0.93)))
        let band = FoodMesh.revolve(edge: 0.012, seamTile: 0.08, material: accent, curve: FoodMesh.profile([V2(0, 0.03), V2(0.0603, 0.03), V2(0.0635, 0.065), V2(0.0667, 0.1), V2(0, 0.1)], per: 1))
        m.add(band, Xform(scale: V3(0.93, 0.963, 0.93)))
        let lid = FoodMesh.revolve(edge: 0.012, seamTile: 0.08, material: accent, curve: FoodMesh.profile([V2(0, 0.119), V2(0.0705, 0.119), V2(0.0712, 0.1205), V2(0.0705, 0.1255), V2(0.062, 0.128), V2(0.035, 0.1295), V2(0, 0.13)], per: 3))
        m.add(lid, Xform(scale: V3(0.93, 0.963, 0.93)))
        m.add(Prim.torus(major: 0.0705, minor: 0.0012, segments: 40, sides: 6, material: accent), Xform(translation: V3(0, 0.115, 0), scale: V3(0.93, 1, 0.93)))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
