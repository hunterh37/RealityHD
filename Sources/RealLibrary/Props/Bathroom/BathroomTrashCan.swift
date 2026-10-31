import simd
import Foundation

/// Bathroom trash can: everyday bathroom, plastic. Parts: tapered bin body, rolled rim, plastic liner folded over rim, base foot ring.
public struct BathroomTrashCan: RealAsset {
    public static let id = "bathroom-trash-can"
    public static let summary = "Tapered round bathroom bin with rolled rim, folded liner bag and foot ring."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.2, 0.28, 0.2)
    public init() {}

    public var bin: MaterialKey = "plastic.matte:E6E3DC"
    public var liner: MaterialKey = "plastic.gloss:30343A"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 56 : 24
            // Bin: foot ring, flaring wall, rolled rim, inner wall down to the floor.
            Toiletry.lathe(&m, [V2(0.001, 0), V2(0.074, 0), V2(0.0785, 0.001), V2(0.0795, 0.007), V2(0.0835, 0.0095), V2(0.0965, 0.255), V2(0.0985, 0.262),
                                V2(0.0985, 0.268), V2(0.096, 0.2705), V2(0.0925, 0.269), V2(0.0915, 0.262), V2(0.0805, 0.024), V2(0.075, 0.0125), V2(0.001, 0.0125)], bin, seg: seg, seamTile: 0.2)
            if lod == 0 {
                // Moulded ribs and a hand-grip lip band.
                for y: Float in [0.09, 0.175] {
                    Toiletry.band(&m, r: 0.0835 + (y - 0.0095) / 0.2455 * 0.013, y, y + 0.006, bin, seg: seg)
                }
            }
            // Liner bag folded over the rim and hanging down the outside.
            Toiletry.lathe(&m, [V2(0.0905, 0.2), V2(0.0915, 0.265), V2(0.0955, 0.2765), V2(0.0995, 0.2785), V2(0.1, 0.27), V2(0.0995, 0.24), V2(0.0985, 0.236), V2(0.0975, 0.24), V2(0.0975, 0.268), V2(0.095, 0.272), V2(0.0925, 0.268), V2(0.0895, 0.2)], liner, seg: seg, seamTile: 0.2)
            // Scuffed grime band along the foot and a dirty tide line inside the rim.
            Toiletry.band(&m, r: 0.0795 + 0.0004, 0.0095, 0.03, "plastic.matte:CBC6BA", seg: seg)
            Toiletry.lathe(&m, [V2(0.0745, 0.0125), V2(0.0805, 0.0245), V2(0.0795, 0.0255), V2(0.074, 0.0135)], "plastic.matte:BDB7A8", seg: seg)

            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [4])
    }
}
