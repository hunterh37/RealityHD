import simd
import Foundation

/// Electric razor: everyday bathroom, plastic. Parts: rounded body, head housing, three rotary cutters, power button, display.
public struct ElectricRazor: RealAsset {
    public static let id = "electric-razor"
    public static let summary = "Rotary electric shaver lying flat: gloss body, head with three rotary cutters, power button and display."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.06, 0.07, 0.15)
    public init() {}

    public var shellMaterial: MaterialKey = "plastic.gloss:2A2F36"
    public var cutter: MaterialKey = "metal.stainless"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            // Body, neck block and head housing.
            m.add(Prim.superellipsoid(V3(0.05, 0.036, 0.108), exponent: 2.6, subdivisions: hi ? 14 : 8, material: shellMaterial), Xform(translation: V3(0, 0.018, -0.021)))
            m.add(Prim.roundedBox(V3(0.054, 0.034, 0.012), radius: 0.006, bevelSegments: 2, material: "plastic.matte:3A3F46"), Xform(translation: V3(0, 0.018, 0.036)))
            m.add(Prim.roundedBox(V3(0.06, 0.048, 0.04), radius: 0.01, bevelSegments: 3, material: shellMaterial), Xform(translation: V3(0, 0.040, 0.055)))
            // Three rotary cutters in black bezels on the head top.
            let top: Float = 0.064
            for (x, z) in [(-0.0155 as Float, 0.0615 as Float), (0.0155, 0.0615), (0, 0.0415)] {
                let at = V3(x, top, z)
                Toiletry.lathe(&m, [V2(0.0138, 0.0), V2(0.0138, 0.0036), V2(0.0124, 0.0042), V2(0.0124, 0.0)], "plastic.black", seg: hi ? 24 : 12, at: at)
                Toiletry.lathe(&m, [V2(0.0122, 0.0), V2(0.0122, 0.0048), V2(0.0108, 0.0058), V2(0.0076, 0.0058), V2(0.0076, 0.0036), V2(0.0036, 0.0036), V2(0.0036, 0.0056), V2(0.001, 0.0056)], cutter, seg: hi ? 24 : 12, at: at)
                if hi { Toiletry.band(&m, r: 0.0092, 0.0036, 0.0058, "plastic.black", seg: 24, at: V3(x, top + 0.0, z)) }
            }
            // Power button with LED, display window.
            Toiletry.lathe(&m, [V2(0.0, 0.0), V2(0.0072, 0.0), V2(0.0072, 0.0016), V2(0.006, 0.0022), V2(0.001, 0.0022)], "metal.chrome", seg: 20, at: V3(0, 0.0345, -0.032))
            m.add(Prim.cylinder(radius: 0.0016, height: 0.0008, bevel: 0.0003, segments: 10, material: "plastic.gloss:9FE0A8"), Xform(translation: V3(0, 0.0345, -0.0185)))
            m.add(Prim.roundedBox(V3(0.009, 0.0008, 0.016), radius: 0.0004, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, 0.0345, -0.004)))
            // Whisker dust on one cutter and a scuff on the body side.
            m.add(Prim.roundedBox(V3(0.006, 0.0004, 0.003), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:2A2A2A"), Xform(translation: V3(0.0155, top + 0.0059, 0.0615)))
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
