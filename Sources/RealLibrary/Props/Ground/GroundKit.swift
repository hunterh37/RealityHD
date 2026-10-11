import simd
import Foundation

/// Helpers shared by the ground, road and tile props. Slabs sit on y = 0; paint and joints are thin
/// layers lifted 1.5 mm above the surface they mark.
enum GK {
    static let paintWhite = "paint.lane-white", paintYellow = "paint.lane-yellow"

    /// Rounded box centered at `c`, yawed `yaw` degrees; the radius is clamped to the thinnest side.
    static func box(_ m: inout Model, _ c: V3, _ size: V3, _ mat: MaterialKey, r: Float = 0.003, yaw: Float = 0) {
        let rr = min(r, min(size.x, min(size.y, size.z)) * 0.4)
        m.add(Prim.roundedBox(size, radius: rr, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: simd_quatf(degrees: yaw, axis: .up)))
    }

    /// Flat slab of road or paving: top at `h`, base at 0.
    static func slab(_ m: inout Model, w: Float, d: Float, h: Float, _ mat: MaterialKey, r: Float = 0.006) {
        box(&m, V3(0, h / 2, 0), V3(w, h, d), mat, r: r)
    }

    /// Paint, joint or stain layer 2 mm thick standing on `top`.
    static func layer(_ m: inout Model, x: Float, z: Float, w: Float, d: Float, top: Float, _ mat: MaterialKey, yaw: Float = 0) {
        box(&m, V3(x, top + 0.0005 + 0.001, z), V3(w, 0.003, d), mat, r: 0.0006, yaw: yaw)
    }

    /// Flat polygon layer (outline in XZ) standing on `top`.
    static func poly(_ m: inout Model, _ outline: [V2], top: Float, _ mat: MaterialKey, thick: Float = 0.003) {
        var o = outline
        if Shape2D.area(o) < 0 { o.reverse() }
        cityLayer(&m, outline: o, y: top, lift: 0.0005, thick: thick, bevel: 0.0006, material: mat)
    }

    /// Heightfield slab: constant `edge` height at the border (walled by a skirt) plus `bump` inside.
    static func field(_ m: inout Model, w: Float, d: Float, edge: Float, segments: Int, _ mat: MaterialKey, bump: @escaping (V2) -> Float) {
        let fall: Float = 0.06
        m.add(Prim.terrain(size: V2(w, d), segments: segments, material: mat) { p in
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, e / fall))
            return edge + bump(p) * k * k * (3 - 2 * k)
        })
        for s: Float in [-1, 1] {
            box(&m, V3(s * (w / 2 - 0.005), edge / 2, 0), V3(0.01, edge, d), mat, r: 0.001)
            box(&m, V3(0, edge / 2, s * (d / 2 - 0.005)), V3(w, edge, 0.01), mat, r: 0.001)
        }
    }

    static func finish(_ m: inout Model, ao: Float = 0.05) -> LODModel { K.finish(&m, ao: ao) }
}
