import simd
import Foundation

/// Polished supermarket floor patch: 30 cm vinyl composition tile (`floor.grocery-vct`, off-white with
/// grey chips and thin seams, high-gloss finish) on a 3 mm slab, with an optional row of charcoal accent
/// tiles across the middle. Use the material directly on large floors; the patch is for previews and
/// for placing on top of other ground.
public struct FloorTileGrocery: RealAsset {
    public static let id = "floor-tile-grocery"
    public static let summary = "Polished supermarket floor patch, 2.4 x 2.4 m: 30 cm off-white vinyl composition tiles with grey chips and a charcoal accent band."
    public static let tags = ["prop", "grocery", "retail", "ground", "tile", "vinyl", "interior"]
    public static let budget = 2000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.2, studio: true)

    /// Patch size (x, z) in meters, a multiple of 0.3 keeps whole tiles.
    public var size = V2(2.4, 2.4)
    public var material: MaterialKey = "floor.grocery-vct"
    /// Charcoal accent band across the middle.
    public var accentBand = true
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        m.add(cuboid(V3(size.x, 0.003, size.y), material: material), Xform(translation: V3(0, 0.0015, 0)))
        if accentBand {
            m.add(cuboid(V3(size.x, 0.0006, 0.3), material: "floor.grocery-vct:4A4D52"), Xform(translation: V3(0, 0.0033, 0)))
        }
        return LODModel(m)
    }
}
