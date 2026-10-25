import simd
import Foundation

/// Shared helpers for details group 12.
enum DetailKit12 {
    /// Centers the model on X/Z and sets its lowest point to `sink` below y = 0.
    static func settle(_ m: Model, sink: Float = 0.003) -> Model {
        let b = m.bounds
        return m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y - sink, -(b.min.z + b.max.z) / 2)))
    }

    /// One strap leaf from `root`: uses a column of the grass strip atlas like PlantKit.tuft.
    static func leaf(root: V3, yaw: Float, length: Float, width: Float, lean: Float, curl: Float, twist: Float,
                     segments: Int, material: MaterialKey, rng: inout SeededRNG, phase: Float, rootWeight: Float = 0.1) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = length; b.width = width
        b.lean = lean; b.curl = curl; b.twist = twist; b.segments = segments
        let cols = PlantKit.Tuft().columns
        let col = Float(rng.int(0...(cols - 1)))
        b.u = V2((col + 0.12) / Float(cols), (col + 0.88) / Float(cols))
        b.v = V2(0.01, 0.99)
        b.phase = phase
        b.weight = V2(rootWeight, 1)
        b.ao = V2(rng.float(0.5...0.7), rng.float(0.85...1))
        return PlantKit.blade(b, material: material)
    }
}
