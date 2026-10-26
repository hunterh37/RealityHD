import simd
import Foundation

/// Shared helpers for details group 25 (flowers).
enum DetailKit25 {
    /// Two LODs from one seed so both share a layout.
    static func lods(_ rng: SeededRNG, dist: Float, _ f: (Int, inout SeededRNG) -> Model) -> LODModel {
        var a = rng, b = rng
        var m0 = f(0, &a), m1 = f(1, &b)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        groundAO(&m0, height: 0.05, floor: 0.6); groundAO(&m1, height: 0.05, floor: 0.6)
        return LODModel(levels: [m0, m1], switchDistances: [dist])
    }

    static func card(_ root: V3, yaw: Float, len: Float, wid: Float, lean: Float, curl: Float, belly: Float = 0.6,
                     fold: Float = 0.05, weight: Float = 0.6, segs: Int = 2, tip: Float = 0.1, material: MaterialKey) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = len; b.width = wid; b.lean = lean; b.curl = curl
        b.belly = belly; b.tipWidth = tip; b.fold = fold; b.segments = segs
        b.u = V2(0, wid); b.v = V2(0, len)
        b.weight = V2(weight * 0.3, weight); b.ao = V2(0.6, 1)
        return PlantKit.blade(b, material: material)
    }

    static func wire(_ pts: [V3], r0: Float, r1: Float, sides: Int = 3, material: MaterialKey, weight: Float = 0) -> Surface {
        let n = pts.count
        let radii = (0..<n).map { r0 + (r1 - r0) * Float($0) / Float(max(1, n - 1)) }
        return Prim.tube(pts, radii: radii, sides: sides, seamTile: 1.0, material: material,
                         weights: pts.map { $0.y * weight }, capEnd: false)
    }

    static func arc(_ base: V3, h: Float, reach: Float, yaw: Float, n: Int = 6, droop: Float = 0) -> [V3] {
        let d = V3(cos(yaw), 0, sin(yaw))
        return (0...n).map { i in
            let t = Float(i) / Float(n)
            return base + d * reach * t * t + V3(0, h * (t - droop * t * t), 0)
        }
    }

    static func blob(_ c: V3, _ r: V3, sub: Int = 1, material: MaterialKey) -> Surface {
        Prim.cubeSphere(subdivisions: sub, material: material) { d in c + V3(d.x * r.x, d.y * r.y, d.z * r.z) }
    }

    static func tint(_ rng: inout SeededRNG, _ list: [String]) -> String { list[rng.int(0...(list.count - 1))] }

    /// Point along a path at t in 0...1.
    static func at(_ p: [V3], _ t: Float) -> V3 {
        let f = max(0, min(1, t)) * Float(p.count - 1)
        let i = min(p.count - 2, Int(f))
        return p[i] + (p[i + 1] - p[i]) * (f - Float(i))
    }
}
