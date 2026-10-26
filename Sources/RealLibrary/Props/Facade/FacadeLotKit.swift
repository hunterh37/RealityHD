import simd
import Foundation

extension FC {
    /// Low-poly masonry/tile unit: rectangle extruded along Z with bevelled front and back arrises (about 30 tris).
    /// Use for repeated bricks, voussoirs and tiles where `FA.box` (108 tris) would blow the budget.
    static func brickBox(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
        let b = min(r, min(size.x, min(size.y, size.z)) * 0.4)
        m.add(Prim.extrude(Shape2D.rect(size.x, size.y), depth: size.z, bevel: b, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: rot))
    }
}
