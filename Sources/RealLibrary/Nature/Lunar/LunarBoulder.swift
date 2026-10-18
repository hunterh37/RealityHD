import simd
import Foundation

/// Lunar boulder about 1.8 x 1.2 x 1.5 m: fresh angular basalt block with sharp fracture faces and chips,
/// a third buried, ringed by a low regolith apron thrown up around the base. 3 LODs.
public struct LunarBoulder: RealAsset {
    public static let id = "lunar-boulder"
    public static let summary = "Lunar boulder, 1.8 m: angular fractured basalt, third buried, regolith apron at the base, 3 LODs."
    public static let tags = ["nature", "rock", "lunar"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, ground: false, fog: 0)

    public var size: V3 = V3(1.8, 1.2, 1.5)
    public var material: MaterialKey = "rock.basalt"
    public var apronMaterial: MaterialKey = "regolith.lunar"
    public var facets = 12
    public var chips = 8
    /// Cube-sphere subdivisions per LOD.
    public var detail: [Int] = [30, 14, 6]
    public var lodDistances: [Float] = [12, 35]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let shape = RockShape().with {
            $0.size = size; $0.facets = facets; $0.chips = chips
            $0.lumps = 0.07; $0.erosion = 0.012; $0.detail = 0.012; $0.squareness = 3
            $0.facetDepth = 0.42...0.7; $0.sink = 0.33
            $0.bevel = max(0.01, 0.018 * min(size.x, size.y, size.z))
        }
        let spin = rng.float(0...(2 * .pi))
        let rad = max(size.x, size.z) * 0.5
        let apronSide = rad * 2.9
        let ns = UInt32(truncatingIfNeeded: seed)
        let levels = shape.surfaces(seed: seed, material: material, detail: detail).enumerated().map { k, s -> Model in
            var s = s
            rockContactAO(&s, height: size.y)
            var apron = Prim.terrain(size: V2(apronSide, apronSide), segments: [28, 14, 8][min(k, 2)], material: apronMaterial) { p in
                let r = simd_length(p) / rad
                let lump = Noise.fbm(V3(p.x * 1.4, 0, p.y * 1.4), octaves: 2, seed: ns) * 0.03
                return (0.07 * exp(-pow((r - 1.05) / 0.35, 2)) + lump) * (1 - smoothstep(1.2, 1.45, r)) - 0.01
            }
            apron.computeTangents()
            apron.occlusion = apron.positions.map { 0.75 + 0.25 * smoothstep(0, 0.06, $0.y) }
            var m = Model(name: Self.id, surfaces: [s])
            m.add(apron, Xform(rotation: simd_quatf(angle: spin, axis: V3(0, 1, 0))))
            return m
        }
        return LODModel(levels: levels, switchDistances: Array(lodDistances.prefix(detail.count - 1)))
    }
}
