import simd
import Foundation

/// Open-top punnet tray used by pantry produce props.
enum PantryTray {
    /// Adds a tray (floor plus four walls, inset 1 mm) of width w, depth d, height h.
    static func add(_ m: inout Model, w: Float, d: Float, h: Float, material: MaterialKey) {
        let t: Float = 0.0025
        m.add(Prim.roundedBox(V3(w, 0.004, d), radius: 0.0012, bevelSegments: 1, material: material), Xform(translation: V3(0, 0.002, 0)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(w, h, t), radius: 0.001, bevelSegments: 1, material: material), Xform(translation: V3(0, h / 2, s * (d / 2 - t / 2))))
            m.add(Prim.roundedBox(V3(t, h, d - 2 * t + 0.002), radius: 0.001, bevelSegments: 1, material: material), Xform(translation: V3(s * (w / 2 - t / 2), h / 2, 0)))
        }
    }
}
