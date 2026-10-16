import simd
import Foundation

/// Shared construction helpers for the hunt-camp props.
enum HuntCampKit {
    /// Round rod between two points.
    static func rod(_ m: inout Model, _ a: V3, _ b: V3, r: Float, sides: Int = 8, mat: MaterialKey, seamTile: Float = 0.1) {
        m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: seamTile, material: mat))
    }

    /// Flat or square bar between two points. `w` is the width across `up`'s perpendicular, `t` the thickness along `up`.
    static func bar(_ m: inout Model, _ a: V3, _ b: V3, w: Float, t: Float, up: V3 = .up, mat: MaterialKey, bevel: Float = 0.003) {
        let (_, x) = board(from: a, to: b, width: w, thick: t, up: up, bevel: bevel, material: mat)
        m.add(Prim.roundedBox(V3(simd_length(b - a), t, w), radius: min(bevel, t * 0.4), bevelSegments: 1, material: mat), x)
    }

    static func hex(_ c: UInt32) -> String { String(format: "%06X", c) }

    /// Leaf-shaped outline, length `l`, pointing +Y.
    static func leaf(_ l: Float, _ w: Float) -> [V2] {
        let n = 4
        var pts: [V2] = []
        for i in 0...n {
            let t = Float(i) / Float(n)
            pts.append(V2(w * 0.5 * sin(.pi * t) * (1 - 0.35 * t), l * t))
        }
        for i in stride(from: n - 1, to: 0, by: -1) {
            let t = Float(i) / Float(n)
            pts.append(V2(-w * 0.5 * sin(.pi * t) * (1 - 0.35 * t), l * t))
        }
        return pts
    }
}
