import simd
import Foundation

/// Helpers for the facade green and sustainability props (wall plane z = 0, piece projecting toward +Z).
extension FC {
    /// Seats the model on y = 0, centers X/Z and scales each axis to exactly `size` (real pieces vary a few
    /// percent; the brief size is the catalog contract).
    static func fit(_ m: Model, _ size: V3) -> Model { ShrubKit.fit(m, size: size) }

    /// One leaf-atlas card (a spray of leaves) with its base at `at`, up-axis rotated `spin` degrees about the
    /// card normal and tilted `tilt` degrees about X (positive tips the top away from the wall).
    static func leafCard(_ m: inout Model, _ mat: MaterialKey, at p: V3, width: Float, height: Float,
                         spin: Float = 0, tilt: Float = 0, yaw: Float = 0) {
        let s = Prim.card(width: width, height: height, cell: (origin: V2(0, 0), size: V2(1, 1)), material: mat)
        m.add(s, Xform(translation: p, rotation: FA.q(yaw, FA.Y) * FA.q(tilt, FA.X) * FA.q(spin, FA.Z)))
    }

    /// Two-board front (butt joint on x = 0) with a round entrance hole centered at x = 0, y = holeY.
    /// Board spans y 0...h, front face at z + thick / 2.
    static func boardWithHole(_ m: inout Model, width w: Float, height h: Float, thick: Float, holeR r: Float, holeY: Float,
                              z: Float, y0: Float = 0, _ mat: MaterialKey, bevel: Float = 0.0015) {
        for side: Float in [1, -1] {
            var o: [V2] = [V2(0, 0), V2(w / 2, 0), V2(w / 2, h), V2(0, h), V2(0, holeY + r)]
            for i in 1..<12 {
                let a = Float.pi / 2 - Float(i) / 12 * .pi
                o.append(V2(r * cos(a), holeY + r * sin(a)))
            }
            o.append(V2(0, holeY - r))
            if side < 0 { o = o.map { V2(-$0.x, $0.y) }.reversed() }
            m.add(Prim.extrude(o, depth: thick, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(side * 0.0006, y0, z)))
        }
    }

    /// Cheap flat slab (12 triangles) for stains, streaks and tide marks lying on a surface facing +Z.
    static func slab(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey) {
        m.add(Prim.extrude(Shape2D.rect(size.x, size.y), depth: size.z, bevel: 0.0001, bevelSegments: 1, material: mat), Xform(translation: c))
    }
}
