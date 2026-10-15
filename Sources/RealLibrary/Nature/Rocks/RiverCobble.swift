import simd
import Foundation

/// Streambed cobble patch, ~1.8 m across: 10 to 16 rounded and flattened sandstone and chert cobbles,
/// 8 to 32 cm, imbricated (tilted upstream, toward -X) the way current stacks them, wet and glossy by
/// default. 2 LODs.
public struct RiverCobble: RealAsset {
    public static let id = "river-cobble"
    public static let summary = "Streambed cobble patch, ~1.8 m: 10-16 rounded flat cobbles, 8-32 cm, imbricated by the current, wet or dry, 2 LODs."
    public static let tags = ["nature", "rock", "water", "river"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 0.9)

    /// Patch radius in meters.
    public var radius: Float = 0.9
    public var count: ClosedRange<Int> = 10...16
    /// Wet stones (riverbed, waterline) use `rock.cobble-wet`, dry ones `rock.cobble-dry`.
    public var wet = true
    /// Imbrication tilt in degrees (stones lean with their upstream edge down).
    public var imbrication: Float = 14
    public var lodDistances: [Float] = [12]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let material: MaterialKey = wet ? "rock.cobble-wet" : "rock.cobble-dry"
        let smooth = RockShape().with {
            $0.lumps = 0.08; $0.erosion = 0; $0.detail = 0.004; $0.warp = 0.35; $0.facets = 0; $0.chips = 0
            $0.squareness = 2.2; $0.sink = 0.35; $0.flatBase = 0.3
        }
        let n = rng.int(count)
        var parts: [RockPart] = [], placed: [(V2, Float)] = []
        var tries = 0
        while parts.count < n && tries < n * 50 {
            tries += 1
            let p = rng.inDisc(radius: radius)
            let s = parts.count < 3 ? rng.float(0.22...0.32) : rng.float(0.08...0.22)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + s) * 0.45 }) { continue }
            placed.append((p, s))
            let tilt = simd_quatf(degrees: imbrication * rng.float(0.6...1.3), axis: V3(0, 0, 1))
            let yaw = simd_quatf(degrees: rng.float(-25...25), axis: .up)
            let mat: MaterialKey = rng.chance(0.25) ? "rock.ozark-sandstone" : material
            parts.append(RockPart(shape: smooth.with { $0.size = V3(s, s * rng.float(0.3...0.45), s * rng.float(0.6...0.85)) },
                                  seed: seed &+ UInt64(parts.count + 1),
                                  xform: Xform(translation: V3(p.x, 0, p.y), rotation: yaw * tilt), material: mat))
        }
        let sizes = placed.map { $0.1 }
        let levels = rockCluster(name: Self.id, parts: parts, lods: 2) { i, lod in
            lod == 0 ? (sizes[i] > 0.2 ? 10 : 7) : (sizes[i] > 0.12 ? 4 : nil)
        }
        return LODModel(levels: levels, switchDistances: lodDistances)
    }
}
