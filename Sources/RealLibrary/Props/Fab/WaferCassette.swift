import simd
import Foundation

/// Wafer cassette: Entegris-class 300 mm open wafer cassette, milky white PFA, light handling wear.. Parts: translucent milky PFA side walls, 25 slot ribs per side, H-bar back and top handle, bottom rails, wafers loaded in slots.
public struct WaferCassette: RealAsset {
    public static let id = "wafer-cassette"
    public static let summary = "Open 25-slot PFA wafer cassette with H-bar and slot ribs."
    public static let tags = ["prop", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.33, 0.3, 0.3)
    public var wafers = 25
    public init() {}
    /// Wall material key.
    public var wallMaterial = "plastic.pfa"

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w: Float = 0.33, h: Float = 0.27, d: Float = 0.3, t: Float = 0.006
        let wall = wallMaterial
        // Bottom plate with cut-out frame and two end rails.
        m.add(bx(V3(w - 0.02, 0.008, 0.012), 0.002, wall), Xform(translation: V3(0, 0.004, -d / 2 + 0.03)))
        m.add(bx(V3(w - 0.02, 0.008, 0.012), 0.002, wall), Xform(translation: V3(0, 0.004, 0.02)))
        // Side walls (solid plates, x = +-), top strap and back H-bar.
        for s: Float in [-1, 1] {
            m.add(bx(V3(t, h - 0.02, d - 0.06), 0.002, wall), Xform(translation: V3(s * (w / 2 - t / 2 - 0.004), h / 2, -0.03 + 0.0)))
            // End plates: front and back vertical posts.
            m.add(bx(V3(0.02, h, 0.014), 0.003, wall), Xform(translation: V3(s * (w / 2 - 0.012), h / 2, d / 2 - 0.007)))
            m.add(bx(V3(0.02, h, 0.014), 0.003, wall), Xform(translation: V3(s * (w / 2 - 0.012), h / 2, -d / 2 + 0.007)))
            // Slot ribs on the inside of each wall, 25 slots at 10 mm pitch.
            for i in 0..<25 {
                let y = 0.03 + Float(i) * 0.0098
                m.add(cuboid(V3(0.014, 0.0025, d - 0.1), material: wall), Xform(translation: V3(s * (w / 2 - t - 0.011), y, -0.03)))
            }
            // Outer reinforcing ribs.
            for z: Float in [-0.1, -0.03, 0.04] {
                m.add(bx(V3(0.004, h - 0.05, 0.008), 0.0015, wall), Xform(translation: V3(s * (w / 2 - 0.002), h / 2, z)))
            }
        }
        // H-bar: two verticals plus crossbar on the back.
        for s: Float in [-1, 1] {
            m.add(bx(V3(0.014, h - 0.01, 0.012), 0.003, wall), Xform(translation: V3(s * 0.1, h / 2, -d / 2 + 0.006)))
        }
        m.add(bx(V3(0.2, 0.016, 0.012), 0.003, wall), Xform(translation: V3(0, 0.15, -d / 2 + 0.006)))
        // Top handle bar (robotic/manual), with two posts.
        for s: Float in [-1, 1] {
            m.add(bx(V3(0.012, 0.03, 0.012), 0.003, wall), Xform(translation: V3(s * 0.12, h + 0.015, -0.03)))
        }
        m.add(Prim.cylinder(radius: 0.008, height: 0.26, bevel: 0.002, segments: 10, material: "plastic.matte:D8D8D2"),
              Xform(translation: V3(0.13, h + 0.022, -0.03), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Top rails joining the walls.
        m.add(bx(V3(w - 0.03, 0.01, 0.012), 0.002, wall), Xform(translation: V3(0, h - 0.005, -d / 2 + 0.02)))
        m.add(bx(V3(w - 0.03, 0.01, 0.012), 0.002, wall), Xform(translation: V3(0, h - 0.005, d / 2 - 0.02)))
        // Wafers in slots (every slot up to count).
        for i in 0..<min(wafers, 25) {
            let y = 0.03 + Float(i) * 0.0098 + 0.0027
            m.add(Prim.lathe([V2(0, 0.00078), V2(0.15, 0.00078), V2(0.15, 0), V2(0, 0)], segments: 10, material: "silicon.thinfilm"),
                  Xform(translation: V3(0, y, -0.03 + Float.random(in: -0.002...0.002, using: &rng))))
        }
        // Story detail: slot number labels and a scuffed corner tab.
        m.add(bx(V3(0.05, 0.02, 0.0008), 0.0004, "plastic.matte:EEEEEA"), Xform(translation: V3(0.08, 0.16, d / 2 + 0.0004)))
        m.add(bx(V3(0.02, 0.003, 0.0008), 0.0004, "plastic.matte:8A8A84"), Xform(translation: V3(-0.12, 0.05, d / 2 + 0.0004)))
        groundAO(&m)
        return LODModel(m)
    }
}
