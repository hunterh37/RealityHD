import simd
import Foundation

/// Small helpers shared by the toiletry props.
enum Toiletry {
    /// Adds a lathe about +Y, optionally squashed in Z (oval sections) and offset.
    static func lathe(_ m: inout Model, _ pts: [V2], _ mat: MaterialKey, seg: Int = 32, sz: Float = 1, at: V3 = .zero, seamTile: Float = 0.1) {
        m.add(Prim.lathe(pts, segments: seg, seamTile: seamTile, material: mat), Xform(translation: at, scale: V3(1, 1, sz)))
    }
    /// Thin band of radius r between y0 and y1, 0.4 mm proud.
    static func band(_ m: inout Model, r: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey, seg: Int = 32, sz: Float = 1) {
        lathe(&m, [V2(r + 0.0004, y0), V2(r + 0.0004, y1), V2(r - 0.001, y1), V2(r - 0.001, y0)], mat, seg: seg, sz: sz)
    }
}
