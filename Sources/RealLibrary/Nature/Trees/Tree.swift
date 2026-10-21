import simd
import Foundation

/// Generic tree asset over a species. LOD0 hero (~20-35k tris), LOD1 (~6-10k), LOD2 (~1.5-3k), LOD3 far cards (~150-300).
public struct Tree: RealAsset {
    public static let id = "tree"
    public static let summary = "Recursive-branching tree with bark, alpha-card foliage, crown normals, wind weights, 3 LODs."
    public static let tags = ["nature", "tree"]
    public static let budget = 45_000

    public var species: TreeSpecies = .oak
    public var lodDistances: [Float] = [14, 40, 85]
    public init() {}
    public init(_ species: TreeSpecies) { self.species = species }

    /// Callers that set three-level distances get a far switch at 2.1x the last one.
    static func fourLevel(_ d: [Float]) -> [Float] { d.count >= 3 ? Array(d.prefix(3)) : d + [(d.last ?? 40) * 2.1] }

    public func build(seed: UInt64) -> LODModel {
        let g = TreeGenerator(species: species, seed: seed)
        let l0 = g.model(.lod0)
        return LODModel(levels: [l0, Tree.cappedLOD1(g, lod0: l0.triangleCount), g.model(.lod2), g.model(.lod3)],
                        switchDistances: Tree.fourLevel(lodDistances))
    }

    /// LOD1 stays at or under 45 % of LOD0. Over that, leaf cards are thinned and enlarged to hold crown density.
    static let lod1Cap: Float = 0.45
    static func cappedLOD1(_ g: TreeGenerator, lod0: Int) -> Model {
        var s = TreeGenerator.LODSettings.lod1
        var m = g.model(s)
        for _ in 0..<8 where Float(m.triangleCount) > lod1Cap * Float(lod0) && lod0 > 0 {
            let k = max(0.5, lod1Cap * 0.97 * Float(lod0) / Float(m.triangleCount))
            s.leafFraction *= k; s.leafScale /= k.squareRoot()
            m = g.model(s)
        }
        return m
    }
}
