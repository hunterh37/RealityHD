import simd
import Foundation

/// Shared helpers for the DD1C kitchen batch.
enum DD1CKitchen {
    /// Closed thin-walled vessel profile for `Prim.lathe`: outer points bottom to rim, then the inner wall back down to the floor.
    static func vessel(_ outer: [V2], wall: Float, floor: Float) -> [V2] {
        let h = outer.map { $0.y }.max() ?? 1
        var pts = outer
        for p in outer.reversed() {
            pts.append(V2(max(p.x - wall, 0), floor + p.y * (h - floor) / h))
        }
        return pts
    }

    /// Centre the footprint on X/Z and put the lowest point at y = 0.
    static func ground(_ m: Model) -> Model {
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    /// Flat strip handle along +X from x0 to x1 at height y, with a hanging hole ring and a stamped mark.
    static func strip(_ m: inout Model, from x0: Float, to x1: Float, y: Float, width: Float, thick: Float, yaw: Float, material: MaterialKey, hole: Bool = true) {
        var s = Model(name: "strip")
        let len = x1 - x0
        s.add(Prim.roundedBox(V3(len, thick, width), radius: thick * 0.45, bevelSegments: 2, material: material), Xform(translation: V3(x0 + len / 2, y, 0)))
        if hole {
            s.add(Prim.torus(major: width * 0.2, minor: thick * 0.4, segments: 20, sides: 6, material: material), Xform(translation: V3(x1 - width * 0.55, y, 0)))
        }
        m.add(s, Xform(rotation: simd_quatf(degrees: yaw, axis: .up)))
    }
}
