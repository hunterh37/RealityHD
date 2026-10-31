import simd
import Foundation

/// Toilet paper roll: everyday bathroom, paper. Parts: paper roll body, cardboard core, loose end flap, embossed edge rings.
public struct ToiletPaperRoll: RealAsset {
    public static let id = "toilet-paper-roll"
    public static let summary = "Upright toilet paper roll: soft rounded wound paper, cardboard core, loose end flap."
    public static let tags = ["prop", "interior", "bathroom", "paper"]
    public static let budget = 3500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.11, 0.1, 0.11)
    public init() {}

    public var paper: MaterialKey = "paper.sheet:F6F4EE"
    public var core: MaterialKey = "paper.screwbox-kraft:B8935F"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let r = size.x / 2, h = size.y
            let seg = hi ? 56 : 24
            // Wound paper with rounded top and bottom edges, hole for the core.
            m.add(Prim.lathe([V2(0.0205, 0.0006), V2(r - 0.006, 0.0), V2(r - 0.002, 0.0012), V2(r - 0.0004, 0.004), V2(r, 0.009),
                              V2(r, h - 0.009), V2(r - 0.0004, h - 0.004), V2(r - 0.002, h - 0.0012), V2(r - 0.006, h), V2(0.0205, h - 0.0006)],
                             segments: seg, seamTile: 0.1, material: paper))
            // Cardboard core, visible through the hole, slightly recessed.
            m.add(Prim.lathe([V2(0.0178, 0.0008), V2(0.0208, 0.0008), V2(0.0208, h - 0.0008), V2(0.0178, h - 0.0008)],
                             segments: hi ? 32 : 14, seamTile: 0.05, material: core))
            // Embossed rings on the top and bottom faces.
            if hi {
                for (a, b) in [(0.03, 0.0315), (0.043, 0.0445)] as [(Float, Float)] {
                    m.add(Prim.lathe([V2(a, h - 0.0004), V2(a + 0.0003, h + 0.0001), V2(b - 0.0003, h + 0.0001), V2(b, h - 0.0004)], segments: seg, seamTile: 0.1, material: paper))
                    m.add(Prim.lathe([V2(a, 0.0004), V2(b, 0.0004), V2(b - 0.0003, -0.0001), V2(a + 0.0003, -0.0001)], segments: seg, seamTile: 0.1, material: paper))
                }
            }
            // End of the last sheet: a vertical seam with a lifted corner.
            let sa: Float = 35 * .pi / 180
            let seamPos = V3(sin(sa) * (r + 0.0003), h / 2, cos(sa) * (r + 0.0003))
            m.add(Prim.roundedBox(V3(0.0012, h - 0.016, 0.0006), radius: 0.0003, bevelSegments: 1, material: "paper.sheet:E4E1D8"),
                  Xform(translation: seamPos, rotation: simd_quatf(degrees: 35, axis: V3(0, 1, 0))))
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
