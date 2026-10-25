import simd
import Foundation

/// Iron-stained river pebble, 6 cm: smooth rounded stone with rusty orange banding over grey.
public struct IronStainedPebble: RealAsset {
    public static let id = "iron-stained-pebble"
    public static let summary = "Iron-stained river pebble, 6 cm: smooth rounded stone with rusty orange banding over grey."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 2_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.06, 0.035, 0.045); $0.lumps = 0.08; $0.warp = 0.3; $0.erosion = 0; $0.detail = 0.003
            $0.facets = 0; $0.chips = 0; $0.squareness = 2.2; $0.sink = 0.15; $0.flatBase = 0.45
        }
        return DetailKit17.rock(id: Self.id, shape: shape, seed: seed, material: "rock.river:9A6540", detail: [14, 6], ao: 0.02)
    }
}
