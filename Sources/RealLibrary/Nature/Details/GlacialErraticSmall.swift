import simd
import Foundation

/// Small glacial erratic, 45 cm: rounded granite boulder with polished facets and scattered chips.
public struct GlacialErraticSmall: RealAsset {
    public static let id = "glacial-erratic-small"
    public static let summary = "Small glacial erratic, 45 cm: rounded granite boulder with polished facets and scattered chips."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 2_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 1.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.45, 0.28, 0.36); $0.lumps = 0.14; $0.warp = 0.5; $0.erosion = 0.05; $0.detail = 0.012
            $0.facets = 5; $0.chips = 8; $0.bevel = 0.03; $0.squareness = 2.3; $0.sink = 0.1
        }
        return DetailKit17.rock(id: Self.id, shape: shape, seed: seed, material: "rock.granite-weathered", detail: [14, 6], ao: 0.15)
    }
}
