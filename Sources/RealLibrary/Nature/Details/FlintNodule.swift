import simd
import Foundation

/// Flint nodule, 12 cm: knobbly lumpy cortex with conchoidal chip scars, dark grey with a pale rind.
public struct FlintNodule: RealAsset {
    public static let id = "flint-nodule"
    public static let summary = "Flint nodule, 12 cm: knobbly lumpy cortex with conchoidal chip scars, dark grey with a pale rind."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 2_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.4)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.12, 0.07, 0.085); $0.lumps = 0.3; $0.warp = 0.7; $0.erosion = 0.05; $0.detail = 0.012
            $0.facets = 3; $0.chips = 9; $0.facetDepth = 0.8...0.92; $0.bevel = 0.008; $0.sink = 0.12; $0.flatBase = 0.4
        }
        return DetailKit17.rock(id: Self.id, shape: shape, seed: seed, material: "rock.basalt:5A5750", detail: [14, 6], ao: 0.04)
    }
}
