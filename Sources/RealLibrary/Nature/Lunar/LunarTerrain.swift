import simd
import Foundation

/// Cratered lunar regolith patch, 40 m square: gentle undulation, two large and several small craters with
/// raised rims and ejecta aprons, scattered angular rocks. Flat at the border so patches tile edge to edge. 3 LODs.
public struct LunarTerrain: RealAsset {
    public static let id = "lunar-terrain"
    public static let summary = "Cratered lunar regolith patch, 40 m: bowl craters with raised rims and ejecta, scattered angular rocks, flat border, 3 LODs."
    public static let tags = ["nature", "terrain", "ground", "rock", "lunar"]
    public static let budget = 56_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 0.9, ground: false, fog: 0)

    /// Side length in meters.
    public var size: Float = 40
    /// Flat border width in meters.
    public var border: Float = 3
    /// Craters: large (radius 4 to 6 m), small (1 to 2.5 m), tiny (0.3 to 0.8 m).
    public var largeCraters = 2
    public var smallCraters = 9
    public var tinyCraters = 24
    /// Loose rocks (5 to 50 cm, a few up to 1 m).
    public var rocks = 70
    public var material: MaterialKey = "regolith.lunar"
    public var rockMaterial: MaterialKey = "rock.basalt"
    /// Grid segments per LOD.
    public var detail: [Int] = [150, 75, 38]
    public var lodDistances: [Float] = [45, 120]
    public init() {}

    /// A crater of radius `r` meters: bowl of depth `depth`, rim crest `rim` high, ejecta apron fading outward.
    public struct Crater: Sendable {
        public var x: Float, z: Float, r: Float, depth: Float, rim: Float
        public init(x: Float, z: Float, r: Float, depth: Float, rim: Float) { self.x = x; self.z = z; self.r = r; self.depth = depth; self.rim = rim }
        /// Height contribution at (px, pz).
        public func height(_ px: Float, _ pz: Float) -> Float {
            let d = simd_length(V2(px - x, pz - z)) / r
            if d > 6 { return 0 }
            if d < 1 {
                let bowl = -depth * (1 - d * d) * (1 - d * d * 0.35)
                let c = (d - 1) / 0.16
                return bowl + rim * (0.75 * exp(-c * c) + 0.25 * exp((d - 1) * 6))
            }
            let c = (d - 1) / 0.14
            return rim * (0.75 * exp(-c * c) + 0.25 * exp(-(d - 1) * 2.2)) * (1 - smoothstep(3.5, 6, d))
        }
    }

    /// Crater layout for a seed, centers kept inside the flat border.
    public func craters(seed: UInt64) -> [Crater] {
        var rng = SeededRNG(seed: seed &+ 101)
        var out: [Crater] = []
        func add(_ n: Int, _ radius: ClosedRange<Float>, _ ratio: ClosedRange<Float>) {
            var tries = 0, placed = 0
            while placed < n && tries < n * 40 {
                tries += 1
                let r = rng.float(radius)
                let lim = size / 2 - border - r * 0.9
                guard lim > 0 else { continue }
                let p = V2(rng.float(-lim...lim), rng.float(-lim...lim))
                if out.contains(where: { simd_distance(V2($0.x, $0.z), p) < ($0.r + r) * 0.9 }) { continue }
                let depth = r * rng.float(ratio)
                out.append(Crater(x: p.x, z: p.y, r: r, depth: depth, rim: depth * rng.float(0.22...0.32)))
                placed += 1
            }
        }
        add(largeCraters, 4...6, 0.2...0.34)
        add(smallCraters, 1...2.5, 0.2...0.36)
        add(tinyCraters, 0.3...0.8, 0.2...0.38)
        return out
    }

    /// Ground height at (x, z), matching LOD 0 at the grid vertices.
    public func height(x: Float, z: Float, seed: UInt64, craters cs: [Crater]) -> Float {
        let ns = UInt32(truncatingIfNeeded: seed)
        var h = Noise.fbm(V3(x * 0.07, 0, z * 0.07), octaves: 3, seed: ns) * 0.55
        h += Noise.fbm(V3(x * 0.6, 0, z * 0.6), octaves: 3, seed: ns &+ 9) * 0.06
        for c in cs { h += c.height(x, z) }
        let half = size / 2
        let fade = 1 - smoothstep(half - border * 1.6, half - border * 0.2, max(abs(x), abs(z)))
        return h * fade
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let cs = craters(seed: seed)
        let h = { (x: Float, z: Float) in height(x: x, z: z, seed: seed, craters: cs) }
        let half = size / 2 - border
        let angular = RockShape().with {
            $0.lumps = 0.05; $0.erosion = 0.01; $0.detail = 0.01; $0.squareness = 3
            $0.facets = 9; $0.chips = 3; $0.facetDepth = 0.4...0.7; $0.sink = 0.35
        }
        var parts: [RockPart] = []
        var sizes: [Float] = []
        var tries = 0
        while parts.count < rocks && tries < rocks * 20 {
            tries += 1
            // Rocks cluster on crater rims and ejecta: pick a crater or open ground.
            var p = V2(rng.float(-half...half), rng.float(-half...half))
            if rng.chance(0.55), let c = cs.randomElement(using: &rng) {
                let a = rng.float(0...(2 * .pi)), d = c.r * rng.float(0.8...2.4)
                p = V2(c.x + cos(a) * d, c.z + sin(a) * d)
                if abs(p.x) > half || abs(p.y) > half { continue }
            }
            let s = rng.float(0.05...0.3) * (rng.chance(0.05) ? 3.2 : 1)
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
            g.occlusion = g.positions.map { 0.72 + 0.28 * smoothstep(-0.7, 0.02, $0.y) }
            return g
        }
        var levels = rockCluster(name: Self.id, parts: parts, lods: detail.count, facets: true) { i, lod in
            let s = sizes[i]
            switch lod {
            case 0: return s > 0.2 ? 4 : 3
            case 1: return s > 0.12 ? 2 : nil
            default: return s > 0.4 ? 2 : nil
            }
        }
        for (k, n) in detail.enumerated() where k < levels.count { levels[k].add(ground(n)) }
        return LODModel(levels: levels, switchDistances: Array(lodDistances.prefix(detail.count - 1)))
    }
}
