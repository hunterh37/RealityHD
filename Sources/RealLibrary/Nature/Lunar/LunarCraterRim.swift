import simd
import Foundation

/// Single lunar crater 14 m across on a 30 m patch: bowl 2.2 m deep, rim crest about 0.6 m above the plain,
/// ejecta apron, angular blocks along the rim and inner wall. Flat at the border. 3 LODs.
public struct LunarCraterRim: RealAsset {
    public static let id = "lunar-crater-rim"
    public static let summary = "Lunar crater, 14 m across, 2.2 m deep: raised rim, ejecta apron, angular blocks on the rim, 3 LODs."
    public static let tags = ["nature", "terrain", "ground", "rock", "lunar"]
    public static let budget = 50_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 0.85, ground: false, fog: 0)

    /// Patch side length in meters.
    public var size: Float = 30
    /// Crater radius, depth (floor to plain) and rim height above the plain, in meters.
    public var radius: Float = 7
    public var depth: Float = 2.2
    public var rimHeight: Float = 0.6
    public var blocks = 46
    public var material: MaterialKey = "regolith.lunar"
    public var rockMaterial: MaterialKey = "rock.basalt"
    public var detail: [Int] = [130, 66, 34]
    public var lodDistances: [Float] = [40, 100]
    public init() {}

    public func height(x: Float, z: Float, seed: UInt64) -> Float {
        let ns = UInt32(truncatingIfNeeded: seed)
        // Rim wobble: radius varies with angle so the outline is not a circle.
        let a = atan2(z, x)
        let wob = 1 + 0.07 * sin(3 * a + Float(ns % 7)) + 0.04 * sin(5 * a + Float(ns % 5))
        let c = LunarTerrain.Crater(x: 0, z: 0, r: radius * wob, depth: depth, rim: rimHeight / 0.75)
        var h = c.height(x, z)
        h += Noise.fbm(V3(x * 0.5, 0, z * 0.5), octaves: 3, seed: ns) * 0.07
        h += Noise.fbm(V3(x * 0.08, 0, z * 0.08), octaves: 2, seed: ns &+ 4) * 0.35
        let half = size / 2
        return h * (1 - smoothstep(half - 4.5, half - 0.5, max(abs(x), abs(z))))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let h = { (x: Float, z: Float) in height(x: x, z: z, seed: seed) }
        let angular = RockShape().with {
            $0.lumps = 0.05; $0.erosion = 0.01; $0.detail = 0.01; $0.squareness = 3
            $0.facets = 9; $0.chips = 3; $0.facetDepth = 0.4...0.7; $0.sink = 0.35
        }
        var parts: [RockPart] = []
        var sizes: [Float] = []
        var tries = 0
        while parts.count < blocks && tries < blocks * 20 {
            tries += 1
            let a = rng.float(0...(2 * .pi)), d = radius * rng.float(0.55...1.9)
            let p = V2(cos(a) * d, sin(a) * d)
            guard abs(p.x) < size / 2 - 2.5, abs(p.y) < size / 2 - 2.5 else { continue }
            let s = rng.float(0.1...0.5) * (rng.chance(0.1) ? 3 : 1)
            let y = h(p.x, p.y)
            let gx = h(p.x + 0.05, p.y) - h(p.x - 0.05, p.y), gz = h(p.x, p.y + 0.05) - h(p.x, p.y - 0.05)
            let up = simd_normalize(V3(-gx / 0.1, 1, -gz / 0.1))
            let rot = simd_quatf(from: V3(0, 1, 0), to: up) * simd_quatf(angle: rng.float(0...(2 * .pi)), axis: V3(0, 1, 0))
            sizes.append(s)
            parts.append(RockPart(shape: angular.with { $0.size = V3(s * rng.float(1.0...1.6), s * rng.float(0.5...0.85), s); $0.bevel = s * 0.04 },
                                  seed: seed &+ UInt64(parts.count + 1),
                                  xform: Xform(translation: V3(p.x, y - s * 0.12, p.y), rotation: rot), material: rockMaterial))
        }
        let ground = { (n: Int) -> Surface in
            var g = Prim.terrain(size: V2(size, size), segments: n, material: material) { h($0.x, $0.y) }
            g.computeTangents()
            g.occlusion = g.positions.map { 0.55 + 0.45 * smoothstep(-depth * 0.9, 0.05, $0.y) }
            return g
        }
        var levels = rockCluster(name: Self.id, parts: parts, lods: detail.count, facets: true) { i, lod in
            let s = sizes[i]
            switch lod {
            case 0: return s > 0.25 ? 4 : 3
            case 1: return s > 0.15 ? 2 : nil
            default: return s > 0.4 ? 2 : nil
            }
        }
        for (k, n) in detail.enumerated() where k < levels.count { levels[k].add(ground(n)) }
        return LODModel(levels: levels, switchDistances: Array(lodDistances.prefix(detail.count - 1)))
    }
}
