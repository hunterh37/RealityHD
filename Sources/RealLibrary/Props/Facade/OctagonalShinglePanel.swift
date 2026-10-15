import simd
import Foundation

/// Octagonal shingle panel: architectural facade customizer, Queen Anne Victorian. Parts: octagon-butt shingles with 45 degree clipped corners, staggered half-lap courses, tapered shingle thickness with kick-out at the butt, doubled starter course, beaded side casings, top drip cap with cut nails, plywood sheathing backer.
public struct OctagonalShinglePanel: RealAsset {
    public static let id = "octagonal-shingle-panel"
    public static let summary = "Octagonal shingle panel, 1.2 x 1.2 m: staggered clipped-corner cedar shingles in varied paint over sheathing, framed by beaded trim."
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
    public var shingleTints: [String] = ["8E4130", "A3513C", "7E3A2B", "974634"]
    /// Trim paint tint, sRGB hex.
    public var trimTint: String = "E3D8BC"
    /// Sheathing backer material.
    public var sheathing: MaterialKey = "wood.plywood"
    /// Nail material.
    public var nail: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let m = CLAD.shinglePanel(name: Self.id, W: width, H: height, butt: .octagon, width: shingleWidth, exposure: exposure,
                                tints: shingleTints, trim: trimTint, worn: trimTint, sheath: sheathing,
                                plyEdge: "wood.plywood-edge", nail: nail, seed: seed)
        return LODModel(m)
    }
}
