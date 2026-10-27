import simd
import Foundation

/// Shared helpers for DD1E kitchen gadgets.
enum DD1EKitchen {
    /// Closed lathe shell: outer points bottom to top, then the inner points top to bottom, thickness already applied.
    static func shell(_ outer: [V2], wall: Float) -> [V2] {
        var inner: [V2] = []
        for i in outer.indices {
            let a = outer[max(0, i - 1)], b = outer[min(outer.count - 1, i + 1)]
            let d = simd_normalize(b - a)
            let n = V2(d.y, -d.x)          // outward for an upward-travelling wall
            inner.append(outer[i] - n * wall)
        }
        return outer + inner.reversed()
    }

    /// Rotation about +Y by degrees.
    static func rotY(_ deg: Float) -> simd_quatf { simd_quatf(degrees: deg, axis: V3(0, 1, 0)) }

    /// Cylinder along +Z starting at p (for knobs and buttons on a front face).
    static func frontCylinder(_ m: inout Model, at p: V3, radius: Float, length: Float, bevel: Float = 0.0012, material: MaterialKey) {
        m.add(Prim.cylinder(radius: radius, height: length, bevel: bevel, segments: 24, material: material),
              Xform(translation: p, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }
}
