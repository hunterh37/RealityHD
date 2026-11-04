import simd
import Foundation

/// Bathroom scale: everyday bathroom, glass top. Parts: glass top, base shell, rubber feet, display window.
public struct BathroomScale: RealAsset {
    public static let id = "bathroom-scale"
    public static let summary = "Square digital bathroom scale: glass platform, white base shell, four rubber feet, display window."
    public static let tags = ["prop", "interior", "bathroom", "glass", "plastic"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 0.03, 0.3)
    public init() {}

    public var shell: MaterialKey = "plastic.gloss:F2F2EE"
    public var glass: MaterialKey = "plastic.gloss:23282D"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = size.x, d = size.z
        // Rubber feet at the corners.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.0015, segments: 16, material: "plastic.black"), Xform(translation: V3(sx * (w / 2 - 0.03), 0, sz * (d / 2 - 0.03))))
            }
        }
        // Base shell with rounded corners, then a slightly smaller step.
        m.add(Prim.roundedBox(V3(w, 0.014, d), radius: 0.012, bevelSegments: 4, material: shell), Xform(translation: V3(0, 0.013, 0)))
        m.add(Prim.roundedBox(V3(w - 0.012, 0.004, d - 0.012), radius: 0.01, bevelSegments: 3, material: "plastic.matte:D9D9D4"), Xform(translation: V3(0, 0.021, 0)))
        // Glass platform with a printed border and an anti-slip dot grid.
        m.add(Prim.roundedBox(V3(w - 0.016, 0.006, d - 0.016), radius: 0.008, bevelSegments: 3, material: glass), Xform(translation: V3(0, 0.027, 0)))
        m.add(Prim.roundedBox(V3(w - 0.03, 0.0004, 0.004), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:E9E9E4"), Xform(translation: V3(0, 0.0303, d / 2 - 0.016)))
        m.add(Prim.roundedBox(V3(w - 0.03, 0.0004, 0.004), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:E9E9E4"), Xform(translation: V3(0, 0.0303, -d / 2 + 0.016)))
        for i in 0..<5 {
            for j in 0..<4 {
                m.add(Prim.cylinder(radius: 0.0026, height: 0.0004, bevel: 0.0001, segments: 6, material: "plastic.matte:E9E9E4"),
                      Xform(translation: V3((Float(i) - 2) * 0.04, 0.0299, (Float(j) - 1.5) * 0.04 - 0.02)))
            }
        }
        // Display window at the front edge with lit digits, and a footprint of scuffs.
        m.add(Prim.roundedBox(V3(0.07, 0.0006, 0.024), radius: 0.0004, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, 0.0303, d / 2 - 0.04)))
        for k in 0..<3 {
            m.add(Prim.roundedBox(V3(0.009, 0.0004, 0.014), radius: 0.0002, bevelSegments: 1, material: "plastic.gloss:9FE0A8"), Xform(translation: V3((Float(k) - 1) * 0.016, 0.0308, d / 2 - 0.04)))
        }
        m.add(Prim.roundedBox(V3(0.06, 0.0003, 0.03), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:B8BCB8"), Xform(translation: V3(-0.05, 0.0302, -0.02), rotation: simd_quatf(angle: 0.3, axis: V3(0, 1, 0))))
        groundAO(&m)
        return LODModel(m)
    }
}
