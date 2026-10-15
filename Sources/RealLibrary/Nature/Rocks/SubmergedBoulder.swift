import simd
import Foundation

/// Submerged streambed boulder, 1.1 x 0.6 x 0.9 m: rounded sandstone worn smooth by the current, glossy
/// periphyton film over the whole stone and a 1 to 2.5 cm algae and aquatic moss (Fontinalis) cushion on
/// the upstream and upper faces, sunk a third into the bed. 3 LODs.
public struct SubmergedBoulder: RealAsset {
    public static let id = "submerged-boulder"
    public static let summary = "Submerged river boulder, 1.1 m: current-rounded stone under a slick algae film and a moss cushion on the upper and upstream faces, 3 LODs."
    public static let tags = ["nature", "rock", "water", "river"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.9)

    public var size: V3 = V3(1.1, 0.6, 0.9)
    public var material: MaterialKey = "rock.algae-wet"
    /// Moss and algae cushion thickness in meters.
    public var mossThickness: Float = 0.022
    /// Bias of the cushion toward the upstream (-X) face, 0...1.
    public var upstream: Float = 0.35
    public var detail: [Int] = [28, 12, 6]
    public var lodDistances: [Float] = [10, 28]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = size; $0.lumps = 0.12; $0.erosion = 0.02; $0.warp = 0.45; $0.facets = 2; $0.chips = 0
            $0.facetDepth = 0.85...0.95; $0.bevel = 0.14; $0.sink = 0.3; $0.squareness = 2.4
        }
        let ns = UInt32(truncatingIfNeeded: seed) &+ 91
        let levels = shape.surfaces(seed: seed, material: material, detail: detail).map { s -> Model in
            var s = s
            for i in s.positions.indices {
                let n = s.normals[i], p = s.positions[i]
                let facing = n.y + upstream * max(0, -n.x)
                let cover = smoothstep(0.0, 0.5, facing + 0.3 * Noise.fbm(p * 3, octaves: 3, seed: ns))
                let bump = 0.5 + 0.5 * Noise.fbm(p * 18, octaves: 2, seed: ns &+ 1)
                s.positions[i] += n * mossThickness * cover * bump
            }
            s.recomputeNormals(); s.computeTangents()
            rockContactAO(&s, height: size.y)
            return Model(name: Self.id, surfaces: [s])
        }
        return LODModel(levels: levels, switchDistances: lodDistances)
    }
}
