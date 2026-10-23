import simd
import Foundation

/// Shared builders for details group 08.
enum DetailKit08 {
    /// Fan of thin tapered blades (floss, thistle florets) rising from `c`.
    static func fan(at c: V3, axis: V3, count: Int, length: ClosedRange<Float>, width: Float, spread: ClosedRange<Float>,
                    curl: ClosedRange<Float>, phase: Float, rng: inout SeededRNG, material: MaterialKey) -> [Surface] {
        let ax = simd_normalize(axis)
        let baseYaw = atan2(ax.z, ax.x)
        let baseLean = acos(max(-1, min(1, ax.y)))
        var out: [Surface] = []
        for _ in 0..<count {
            var b = PlantKit.Blade()
            b.root = c; b.yaw = baseYaw + rng.float(-1.2...1.2)
            b.length = rng.float(length); b.width = width * rng.float(0.7...1.3)
            b.lean = baseLean + rng.float(spread); b.curl = rng.float(curl); b.segments = 2; b.tipWidth = 0.2
            b.weight = V2(0.5, 1); b.phase = phase; b.ao = V2(0.8, 1); b.upNormal = 0.5
            out.append(PlantKit.blade(b, material: material))
        }
        return out
    }
}
