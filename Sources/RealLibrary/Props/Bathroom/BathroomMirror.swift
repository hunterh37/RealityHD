import simd
import Foundation

/// Bathroom mirror: everyday bathroom, framed. Parts: walnut frame, mirror glass, back panel, hanging cleat.
public struct BathroomMirror: RealAsset {
    public static let id = "bathroom-mirror"
    public static let summary = "Wall mirror in a walnut frame with beveled glass."
    public static let tags = ["prop", "interior", "bathroom", "wood", "glass"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 0.8, 0.03)
    public init() {}

    public var frame: MaterialKey = "wood.walnut"
    public var mirror: MaterialKey = "metal.mirror-polish"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let fw: Float = 0.045
        // Back panel and mirror glass with a beveled edge.
        m.add(Prim.roundedBox(V3(w - 0.01, h - 0.01, 0.006), radius: 0.001, bevelSegments: 1, material: "wood.plywood"), Xform(translation: V3(0, h / 2, -d / 2 + 0.003)))
        m.add(Prim.roundedBox(V3(w - 2 * fw + 0.014, h - 2 * fw + 0.014, 0.005), radius: 0.0025, bevelSegments: 3, material: mirror), Xform(translation: V3(0, h / 2, 0.002)))
        // Frame bars, mitred at the corners by slight overlap.
        m.add(Prim.roundedBox(V3(w, fw, d), radius: 0.004, bevelSegments: 3, material: frame), Xform(translation: V3(0, h - fw / 2, 0)))
        m.add(Prim.roundedBox(V3(w, fw, d), radius: 0.004, bevelSegments: 3, material: frame), Xform(translation: V3(0, fw / 2, 0)))
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(fw, h - 2 * fw + 0.004, d), radius: 0.004, bevelSegments: 3, material: frame), Xform(translation: V3(sx * (w / 2 - fw / 2), h / 2, 0)))
        }
        // Inner lip and outer fillet strips on the frame face.
        m.add(Prim.roundedBox(V3(w - 2 * fw + 0.008, 0.005, 0.008), radius: 0.0015, bevelSegments: 2, material: frame), Xform(translation: V3(0, h - fw + 0.0015, d / 2 - 0.004)))
        m.add(Prim.roundedBox(V3(w - 2 * fw + 0.008, 0.005, 0.008), radius: 0.0015, bevelSegments: 2, material: frame), Xform(translation: V3(0, fw - 0.0015, d / 2 - 0.004)))
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.005, h - 2 * fw + 0.008, 0.008), radius: 0.0015, bevelSegments: 2, material: frame), Xform(translation: V3(sx * (w / 2 - fw + 0.0015), h / 2, d / 2 - 0.004)))
        }
        // Hanging cleat on the back.
        m.add(Prim.roundedBox(V3(0.3, 0.03, 0.008), radius: 0.001, bevelSegments: 1, material: "wood.oak"), Xform(translation: V3(0, h - 0.12, -d / 2 + 0.006)))
        // Foxing at the lower mirror corners.
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.03, 0.03, 0.0003), radius: 0.001, bevelSegments: 1, material: "metal.stainless-smudged"), Xform(translation: V3(sx * (w / 2 - fw - 0.012), fw + 0.012, 0.0047)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
