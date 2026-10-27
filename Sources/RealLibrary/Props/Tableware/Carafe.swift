import simd
import Foundation

/// Carafe: everyday tableware, glass. Parts: wide round base with punt, sloped shoulder to a tall neck, flared lip, mushroom stopper, sediment ring at the base.
public struct Carafe: RealAsset {
    public static let id = "carafe"
    public static let summary = "Glass decanter carafe: wide base, sloped shoulder, flared neck, glass stopper, sediment ring."
    public static let tags = ["prop", "interior", "glass", "container"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.11, 0.24, 0.11)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Sediment colour.
    public var sediment: MaterialKey = "plastic.matte:3A1418"
    public init() {}

    static let outer: [V2] = [V2(0, 0.0085), V2(0.020, 0.0078), V2(0.040, 0.0040), V2(0.0520, 0.0005), V2(0.0556, 0.0040), V2(0.0560, 0.010),
                              V2(0.0552, 0.040), V2(0.0505, 0.080), V2(0.0390, 0.114), V2(0.0245, 0.140), V2(0.0168, 0.162), V2(0.0146, 0.185),
                              V2(0.0145, 0.205), V2(0.0158, 0.2150), V2(0.0182, 0.2205), V2(0.0192, 0.2218)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0026, floorY: Float = 0.0105
        m.add(Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY, smooth: 2), segments: seg, seamTile: 0.2, material: glass))
        // Mushroom stopper: ground plug in the neck, domed head sitting just above the lip.
        let stopper: [V2] = [V2(0, 0.2050), V2(0.0108, 0.2050), V2(0.0112, 0.2066), V2(0.0112, 0.2226), V2(0.0170, 0.2234), V2(0.0198, 0.2250),
                             V2(0.0206, 0.2290), V2(0.0196, 0.2352), V2(0.0150, 0.2390), V2(0.0080, 0.2402), V2(0, 0.2405)]
        m.add(Prim.lathe(stopper, segments: seg, seamTile: 0.12, material: glass))
        // Sediment: a dark crescent ring settled where the floor meets the wall.
        let r = DD1FTableware.radius(Self.outer, at: floorY + 0.002) - wall - 0.0003
        m.add(Prim.lathe([V2(r, floorY + 0.0050), V2(r - 0.002, floorY + 0.0030), V2(r - 0.006, floorY + 0.0014), V2(r - 0.011, floorY + 0.0002)],
                         segments: seg, seamTile: 0.12, material: sediment))
        groundAO(&m, height: 0.03, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(64, true), make(32, false)], switchDistances: [3.5])
    }
}
