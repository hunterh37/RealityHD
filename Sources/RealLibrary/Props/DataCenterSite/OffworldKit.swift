import simd

/// Shared helpers for the off-world site props.
enum OK {
    static let qx = simd_quatf(degrees: -90, axis: V3(0, 0, 1))
    static let qz = simd_quatf(degrees: 90, axis: V3(1, 0, 0))

    static func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) -> (Surface, Xform) {
        if min(s.x, min(s.y, s.z)) > 0.25 { return (Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c)) }
        return (Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c))
    }
    static func rod(_ a: V3, _ b: V3, r: Float, _ mat: MaterialKey, sides: Int = 4) -> Surface {
        Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.25, material: mat)
    }
    /// Cylinder along +X starting at x0.
    static func cylX(_ r: Float, _ len: Float, x0: Float, y: Float, z: Float, _ mat: MaterialKey, seg: Int = 10, bevel: Float = 0) -> (Surface, Xform) {
        (Prim.cylinder(radius: r, height: len, bevel: bevel, segments: seg, bevelSegments: 1, material: mat), Xform(translation: V3(x0, y, z), rotation: qx))
    }
    /// Cylinder along +Z starting at z0.
    static func cylZ(_ r: Float, _ len: Float, x: Float, y: Float, z0: Float, _ mat: MaterialKey, seg: Int = 10, bevel: Float = 0) -> (Surface, Xform) {
        (Prim.cylinder(radius: r, height: len, bevel: bevel, segments: seg, bevelSegments: 1, material: mat), Xform(translation: V3(x, y, z0), rotation: qz))
    }
    /// Cylinder along +Y.
    static func cylY(_ r: Float, _ len: Float, at p: V3, _ mat: MaterialKey, seg: Int = 10, bevel: Float = 0) -> (Surface, Xform) {
        (Prim.cylinder(radius: r, height: len, bevel: bevel, segments: seg, bevelSegments: 1, material: mat), Xform(translation: p))
    }
    /// Low-poly bolt head (hex prism, ~20 tris) for budget-tight props.
    static func bolt(_ m: inout Model, at p: V3, size: Float, _ mat: MaterialKey, rotation: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0))) {
        m.add(Prim.cylinder(radius: size * 0.6, height: size * 0.5, bevel: 0, segments: 6, bevelSegments: 1, material: mat), Xform(translation: p, rotation: rotation))
    }
}
