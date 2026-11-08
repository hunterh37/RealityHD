import simd
import Foundation

/// Cube facial tissue box, 11.3 x 13 x 11.3 cm: printed paperboard with a leaf panel, oval film-lined opening on top
/// with a tissue puffing out, brand PLUMA SOFT TISSUES. Invented brand.
public struct TissueBox: RealAsset {
    public static let id = "tissue-box"
    public static let summary = "Cube facial tissue box, 13 cm: printed paperboard, oval film opening with a tissue puffing out, invented brand PLUMA."
    public static let tags = ["prop", "grocery", "paper", "cardboard", "bathroom", "home", "handheld"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 16, distance: 1.3, studio: true)

    public var color: UInt32 = 0x8EC5D6
    public var brand = "PLUMA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let s = V3(0.113, 0.13, 0.113)
        GroceryKit.carton(&m, size: s, body: color, panel: 0xF6FAF8, accent: 0x2E73A8, ink: 0x2E5D7A, brand: brand, line: "SOFT TISSUES 80", hi: hi)
        let seg = hi ? 20 : 10
        m.add(Prim.lathe([V2(0, 0), V2(0.03, 0), V2(0.03, 0.0005), V2(0, 0.0005)], segments: seg, seamTile: 0.05, material: "plastic.clear"),
              Xform(translation: V3(0, s.y + 0.0004, 0), scale: V3(1, 1, 0.45)))
        m.add(Prim.lathe([V2(0, 0), V2(0.0315, 0), V2(0.0315, 0.0004), V2(0, 0.0004)], segments: seg, seamTile: 0.05, material: "paper.sheet:1E3A4C"),
              Xform(translation: V3(0, s.y + 0.0001, 0), scale: V3(1, 1, 0.47)))
        m.add(Prim.superellipsoid(V3(0.06, 0.05, 0.022), exponent: 2.4, subdivisions: hi ? 4 : 2, material: "paper.sheet:FBFBF8"),
              Xform(translation: V3(0.004, s.y + 0.02, 0), rotation: simd_quatf(degrees: 12, axis: V3(0, 0, 1))))
        return m
    }
}
