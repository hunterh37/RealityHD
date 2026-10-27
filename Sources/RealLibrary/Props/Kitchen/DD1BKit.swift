import simd
import Foundation

/// Shared helpers for the DD1B kitchen utensil props. Parts are modelled lying along +X with width on Z
/// and thickness on Y; `finish` turns the length onto Z, centers on X/Z and sets the base at y = 0.
enum DD1BKit {
    /// Prism from an outline given as (x, z) in the ground plane, `thick` tall, centered at height `y`.
    static func flat(_ outline: [V2], thick: Float, y: Float, bevel: Float = 0.0006, material: MaterialKey) -> Surface {
        Prim.extrude(outline, depth: thick, bevel: bevel, bevelSegments: 2, material: material)
            .transformed(Xform(translation: V3(0, y, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    /// (x, z) pairs at a fixed height as a 3D path.
    static func xz(_ pts: [(Float, Float)], y: Float) -> [V3] { pts.map { V3($0.0, y, $0.1) } }

    static func v2(_ pts: [(Float, Float)]) -> [V2] { pts.map { V2($0.0, $0.1) } }

    /// Symmetric outline from half widths along x: (x, halfWidth) listed from one end to the other.
    static func symmetric(_ half: [(Float, Float)]) -> [V2] {
        half.map { V2($0.0, $0.1) } + half.reversed().map { V2($0.0, -$0.1) }
    }

    static func finish(_ m: Model, rng: inout SeededRNG, groundHeight: Float = 0.02, turn: Bool = true) -> LODModel {
        let yaw = rng.float(-2...2)
        var out = m.transformed(Xform(rotation: simd_quatf(degrees: (turn ? 90 : 0) + yaw, axis: .up)))
        let b = out.bounds
        out = out.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&out, height: groundHeight, floor: 0.6)
        return LODModel(out)
    }
}
