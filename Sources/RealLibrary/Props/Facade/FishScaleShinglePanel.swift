import simd
import Foundation

/// Fish-scale shingle panel: architectural facade customizer, Queen Anne Victorian. Parts: round-butt (fish-scale) cedar shingles, 5 in wide, 5 in exposure, half-width starter shingles at alternate course ends, tapered shingle thickness with kick-out at the butt, doubled starter course at the bottom, beaded casing trim on the sides, drip cap / frieze board at the top with cut nails, plywood sheathing backer with exposed edge.
public struct FishScaleShinglePanel: RealAsset {
    public static let id = "fish-scale-shingle-panel"
    public static let summary = "Fish-scale shingle panel, 1.2 x 1.2 m: staggered courses of round-butt cedar shingles in two paint colors over a sheathing backer, framed by beaded trim."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.4)

    /// Panel width in meters.
    public var width: Float = 1.2
    /// Panel height in meters.
    public var height: Float = 1.2
    /// Shingle width (5 in).
    public var shingleWidth: Float = 0.127
    /// Course exposure (5 in).
    public var exposure: Float = 0.127
    /// Shingle paint tints, sRGB hex (picked per shingle).
    public var shingleTints: [String] = ["5E7350", "6E8360", "54684A", "667B58"]
    /// Trim paint tint, sRGB hex.
    public var trimTint: String = "E6DCC3"
    /// Sheathing backer material.
    public var sheathing: MaterialKey = "wood.plywood"
    /// Nail material.
    public var nail: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let m = CLAD.shinglePanel(name: Self.id, W: width, H: height, butt: .round, width: shingleWidth, exposure: exposure,
                                tints: shingleTints, trim: trimTint, worn: trimTint, sheath: sheathing,
                                plyEdge: "wood.plywood-edge", nail: nail, seed: seed)
        return LODModel(m)
    }
}
