import simd
import Foundation

/// Small helpers shared by the toiletry props.
enum Toiletry {
    /// Adds a lathe about +Y, optionally squashed in Z (oval sections) and offset.
    static func lathe(_ m: inout Model, _ pts: [V2], _ mat: MaterialKey, seg: Int = 32, sz: Float = 1, at: V3 = .zero, rot: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)), seamTile: Float = 0.1) {
        m.add(Prim.lathe(pts, segments: seg, seamTile: seamTile, material: mat), Xform(translation: at, rotation: rot, scale: V3(1, 1, sz)))
    }
    /// Thin band of radius r between y0 and y1, 0.4 mm proud.
    static func band(_ m: inout Model, r: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey, seg: Int = 32, sz: Float = 1, at: V3 = .zero, rot: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0))) {
        lathe(&m, [V2(r + 0.0004, y0), V2(r + 0.0004, y1), V2(r - 0.001, y1), V2(r - 0.001, y0)], mat, seg: seg, sz: sz, at: at, rot: rot)
    }
    /// Cylinder rod starting at `at` and running `length` along +X (axis 0), +Y (1) or +Z (2).
    static func rod(_ m: inout Model, axis: Int, at: V3, length: Float, r: Float, _ mat: MaterialKey, seg: Int = 6) {
        let rot: simd_quatf = axis == 0 ? simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1)) : axis == 2 ? simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0)) : simd_quatf(angle: 0, axis: V3(0, 1, 0))
        m.add(Prim.cylinder(radius: r, height: length, bevel: 0.0003, segments: seg, material: mat), Xform(translation: at, rotation: rot))
    }
}
