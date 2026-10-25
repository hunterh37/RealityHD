import simd
import Foundation

/// Fossil shell rock, 18 cm: pitted limestone block with embedded shell casts and rough fracture faces.
public struct FossilShellRock: RealAsset {
    public static let id = "fossil-shell-rock"
    public static let summary = "Fossil shell rock, 18 cm: pitted limestone block with embedded shell casts and rough fracture faces."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 2_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.55)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.18, 0.1, 0.13); $0.lumps = 0.14; $0.erosion = 0.12; $0.detail = 0.02; $0.facets = 5; $0.chips = 8
            $0.facetDepth = 0.75...0.9; $0.bevel = 0.008; $0.squareness = 2.6; $0.strata = 0.006; $0.bedHeight = 0.02; $0.sink = 0.12
        }
        return DetailKit17.rock(id: Self.id, shape: shape, seed: seed, material: "rock.ozark-limestone", detail: [14, 6], ao: 0.06)
    }
}
