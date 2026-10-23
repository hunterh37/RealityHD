import simd
import Foundation

/// Hand-stacked flat river stones, a 6 to 8 stone cairn about 25 cm tall: slate and river stones from 16 cm
/// wide at the base to 4 cm at the top, each 2 to 5 cm thick, shifted and yawed so no two edges line up.
public struct StackedFlatStones: RealAsset {
    public static let id = "stacked-flat-stones"
    public static let summary = "Hand-stacked cairn of 6-8 flat river stones, ~25 cm tall, 16 cm base narrowing to 4 cm, each shifted and yawed; 2 LODs."
    public static let tags = ["nature", "rock", "stone"]
    public static let budget = 3_700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 0.95)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let n = rng.int(6...8)
        let flat = RockShape().with {
            $0.lumps = 0.1; $0.warp = 0.4; $0.erosion = 0.03; $0.detail = 0.01; $0.facets = 3; $0.chips = 4
            $0.facetDepth = 0.8...0.95; $0.verticalFacets = true; $0.bevel = 0.008
            $0.squareness = 2.6; $0.sink = 0; $0.flatBase = 0.9; $0.flatTop = 0.8
        }
        var lods = [Model(name: Self.id), Model(name: Self.id)]
        var top: Float = -0.004, off = V2.zero
        for i in 0..<n {
            let f = Float(i) / Float(n - 1)
            let w = 0.17 * (1 - 0.76 * pow(f, 0.9)) * rng.float(0.88...1.08)
            let h = rng.float(0.03...0.058) * (1 - 0.3 * f)
            let shape = flat.with { $0.size = V3(w, h, w * rng.float(0.62...0.9)) }
            let mat: MaterialKey = rng.chance(0.55) ? "rock.slate" : (rng.chance(0.5) ? "rock.river" : "rock.river")
            let seeds = seed &+ UInt64(i + 1)
            let parts = shape.surfaces(seed: seeds, material: mat, detail: [6, 4])
            // Center of mass drifts a little each level so the stack leans like a real cairn.
            off += V2(rng.float(-0.012...0.012), rng.float(-0.012...0.012))
            let yaw = simd_quatf(degrees: rng.float(-70...70), axis: .up)
            let tilt = simd_quatf(degrees: rng.float(-5...5), axis: V3(1, 0, 0)) * simd_quatf(degrees: rng.float(-5...5), axis: V3(0, 0, 1))
            for (l, p) in parts.enumerated() {
                let q = yaw * tilt
                let probe = p.transformed(Xform(translation: .zero, rotation: q))
                let b = probe.bounds
                let t = Xform(translation: V3(off.x - (b.min.x + b.max.x) / 2, top - b.min.y - 0.002, off.y - (b.min.z + b.max.z) / 2), rotation: .identity)
                var s = probe.transformed(t)
                if i == 0 { for k in s.occlusion.indices { s.occlusion[k] *= 0.9 } }
                s.computeTangents()
                lods[l].add(s)
            }
            let b = parts[0].transformed(Xform(translation: .zero, rotation: yaw * tilt)).bounds
            top += (b.max.y - b.min.y) - 0.002
        }
        var out = lods.map { DetailKit12.settle($0, sink: 0.004) }
        for k in out.indices { groundAO(&out[k]) }
        return LODModel(levels: out, switchDistances: [6])
    }
}
