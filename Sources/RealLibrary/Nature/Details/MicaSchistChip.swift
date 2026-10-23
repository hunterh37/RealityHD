import simd
import Foundation

/// Mica schist chip, 9 cm: flat foliated flake with stepped broken edges and a silvery sheen.
public struct MicaSchistChip: RealAsset {
    public static let id = "mica-schist-chip"
    public static let summary = "Mica schist chip, 9 cm: flat foliated flake with stepped broken edges and a silvery sheen."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 2_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.35)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.09, 0.02, 0.065); $0.lumps = 0.1; $0.erosion = 0.02; $0.detail = 0.006; $0.facets = 6; $0.chips = 8
            $0.facetDepth = 0.8...0.95; $0.bevel = 0.004; $0.verticalFacets = true; $0.squareness = 2.8; $0.flatTop = 0.7
            $0.strata = 0.002; $0.bedHeight = 0.006; $0.sink = 0.1; $0.flatBase = 0.7
        }
        return DetailKit17.rock(id: Self.id, shape: shape, seed: seed, material: "rock.slate:8C8C93", detail: [14, 6], ao: 0.015)
    }
}
