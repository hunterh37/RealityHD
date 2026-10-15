import simd
import Foundation

/// Course debris rock, radius 2 to 8 m: a free-floating fractured block built from the `boulder` rock
/// shape with no sink and no flat base, so every side reads in flight. Seeds vary proportions, facets
/// and rock (granite or basalt). Courses spin and drift it at runtime.
public struct DebrisRock: RealAsset {
    public static let id = "debris-rock"
    public static let summary = "Course debris rock, radius 2-8 m, seeded: free-floating fractured granite or basalt block from the boulder shape, facets all round."
    public static let tags = ["prop", "aerospace", "outdoor", "rock", "stone"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.1)

    /// Mean radius in meters (2 to 8).
    public var radius: Float = 2
    /// Rock materials picked per seed.
    public var materials: [MaterialKey] = ["rock.granite-bare", "rock.granite-bare", "rock.basalt"]
    /// Cube-sphere subdivisions per LOD.
    public var detail: [Int] = [32, 16, 7]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed &+ 0xDEB)
        let r = min(max(radius, 2), 8)
        let shape = RockShape().with {
            $0.size = V3(2.6 * r, 1.75 * r * rng.float(0.85...1.05), 2.3 * r)
            $0.facets = rng.int(9...13); $0.chips = rng.int(12...18)
            $0.facetDepth = 0.55...0.82
            $0.lumps = 0.18; $0.erosion = 0.08; $0.detail = 0.022
            $0.bevel = 0.012 * r
            $0.sink = 0; $0.flatBase = 2
        }
        let mat = rng.pick(materials)
        let levels = shape.surfaces(seed: seed, material: mat, detail: detail).map { s -> Model in
            var s = s
            let b = s.bounds
            s.positions = s.positions.map { $0 - V3((b.min.x + b.max.x) / 2, b.min.y, (b.min.z + b.max.z) / 2) }
            s.bakeCavityAO()
            return Model(name: Self.id, surfaces: [s])
        }
        return LODModel(levels: levels, switchDistances: [r * 10, r * 30])
    }
}
