import simd
import Foundation

/// Beer mug: everyday tableware, heavy glass. Parts: thick base, tapered thick wall with rolled rim, applied sweep handle with thumb curve, beer with foam head, scuffed foot ring.
public struct BeerMug: RealAsset {
    public static let id = "beer-mug"
    public static let summary = "Heavy glass beer mug: thick base, tapered wall, applied handle, beer and foam, scuffed foot ring."
    public static let tags = ["prop", "interior", "glass", "container", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, studio: true)

    /// Overall size in meters (x width, y height, z depth including the handle).
    public var size = V3(0.09, 0.15, 0.13)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Scuff material on the foot ring.
    public var scuff: MaterialKey = "glass.frosted"
    /// Beer colour.
    public var beer: MaterialKey = "plastic.amber"
    /// Foam colour.
    public var foam: MaterialKey = "plastic.matte:F3EBD2"
    /// Beer level as a fraction of the inner height (0 = empty).
    public var fill: Float = 0.97
    public init() {}

    static let outer: [V2] = [V2(0, 0.0055), V2(0.020, 0.0048), V2(0.033, 0.0022), V2(0.0385, 0.0), V2(0.0408, 0.0030), V2(0.0420, 0.010),
                              V2(0.0426, 0.030), V2(0.0436, 0.080), V2(0.0446, 0.120), V2(0.0452, 0.1496)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let off = V3(0, 0, -0.02)
        let H: Float = 0.1496, wall: Float = 0.0045, floorY: Float = 0.022
        m.add(Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY, smooth: 2), segments: seg, seamTile: 0.15, material: glass), Xform(translation: off))
        // Scuffed foot ring: frosted wear band slightly proud of the glass.
        m.add(Prim.lathe([V2(0.0387, 0.0001), V2(0.0411, 0.0030), V2(0.0424, 0.0072)], segments: seg, seamTile: 0.15, material: scuff), Xform(translation: off))
        func ri(_ y: Float) -> Float { DD1FTableware.radius(Self.outer, at: y) - wall - 0.0004 }
        if fill > 0.01 {
            let top = floorY + (H - 0.016 - floorY) * fill
            let foamH: Float = 0.022
            let by = top - foamH
            m.add(Prim.lathe([V2(0, floorY + 0.0003), V2(ri(floorY) - 0.003, floorY + 0.0003), V2(ri(floorY + 0.004), floorY + 0.004), V2(ri(by), by), V2(0, by)],
                             segments: seg, seamTile: 0.15, material: beer), Xform(translation: off))
            m.add(Prim.lathe([V2(ri(by) + 0.0002, by - 0.0004), V2(ri(top) + 0.0003, top - 0.003), V2(ri(top), top), V2(ri(top) - 0.003, top + 0.0035), V2(ri(top) - 0.012, top + 0.0055), V2(0, top + 0.0058)],
                             segments: seg, seamTile: 0.15, material: foam), Xform(translation: off))
        }
        // Applied handle: flat strap, thumb curve at the top.
        let ctrl = [V2(0.0425, 0.1215), V2(0.0580, 0.1290), V2(0.0770, 0.1190), V2(0.0830, 0.0950), V2(0.0800, 0.0500), V2(0.0690, 0.0280), V2(0.0425, 0.0230)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(0, 0, 1), section: V2(0.0105, 0.0072), detail: detail, flare: 0.5, material: glass), Xform(translation: off))
        groundAO(&m, height: 0.03, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(56, true), make(28, false)], switchDistances: [3])
    }
}
