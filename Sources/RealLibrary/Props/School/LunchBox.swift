import simd
import Foundation

/// Lunch Box: everyday school, plastic. Parts: molded body, lid, seam, front latches, carry handle, printed stripe.
public struct LunchBox: RealAsset {
    public static let id = "lunch-box"
    public static let summary = "Hard plastic lunch box with two front latches and a folding carry handle."
    public static let tags = ["prop", "interior", "school", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.22, 0.16, 0.1)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, baseH: Float = 0.082, lidH: Float = 0.056
        let red = "plastic.gloss:C4262E"
        // Base tub, lid with a domed top, and a dark seam gap between.
        m.add(Prim.roundedBox(V3(W, baseH, D), radius: 0.010, bevelSegments: 3, material: red), Xform(translation: V3(0, baseH / 2, 0)))
        m.add(Prim.roundedBox(V3(W + 0.002, 0.003, D + 0.002), radius: 0.001, bevelSegments: 1, material: "plastic.matte:1E1E1E"), Xform(translation: V3(0, baseH + 0.0005, 0)))
        let lidY = baseH + 0.003 + lidH / 2, top = baseH + 0.003 + lidH
        m.add(Prim.roundedBox(V3(W, lidH, D), radius: 0.014, bevelSegments: 3, material: red), Xform(translation: V3(0, lidY, 0)))
        // Printed white band around the lid and a round yellow emblem on top.
        m.add(Prim.roundedBox(V3(W + 0.0012, 0.010, D + 0.0012), radius: 0.003, bevelSegments: 1, material: "plastic.gloss:F4F1E8"), Xform(translation: V3(0, lidY - 0.006, 0)))
        m.add(Prim.cylinder(radius: 0.024, height: 0.0008, bevel: 0.0002, segments: 28, material: "plastic.matte:F2C21B"), Xform(translation: V3(0, top - 0.0003, 0)))
        m.add(Prim.torus(major: 0.019, minor: 0.0016, segments: 28, sides: 6, material: red), Xform(translation: V3(0, top + 0.0006, 0)))
        // Two front latches: body on the base, hook tab on the lid, with pivot pins.
        for s: Float in [-1, 1] {
            let x = s * 0.062
            m.add(Prim.roundedBox(V3(0.032, 0.030, 0.006), radius: 0.002, bevelSegments: 2, material: "plastic.matte:E6E6E2"), Xform(translation: V3(x, baseH + 0.001, D / 2 - 0.002)))
            m.add(Prim.roundedBox(V3(0.024, 0.014, 0.0045), radius: 0.0015, bevelSegments: 1, material: "plastic.matte:D4D4CF"), Xform(translation: V3(x, baseH + 0.020, D / 2 - 0.0015)))
            m.add(Prim.cylinder(radius: 0.0025, height: 0.034, bevel: 0.0005, segments: 10, material: "metal.steel"),
                  Xform(translation: V3(x - 0.017, baseH - 0.011, D / 2 + 0.0008), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }
        // Carry handle: arched grip standing on two hinge blocks.
        var arc: [V3] = []
        for k in 0...12 { let a = Float.pi * Float(k) / 12; arc.append(V3(-0.05 * cos(a), top + 0.004 + 0.015 * sin(a), 0)) }
        m.add(Prim.tube(arc, radii: Array(repeating: 0.0045, count: arc.count), sides: 10, seamTile: 0.04, material: "plastic.matte:555B61"), Xform())
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.016, 0.007, 0.014), radius: 0.002, bevelSegments: 2, material: "plastic.matte:555B61"), Xform(translation: V3(s * 0.05, top + 0.002, 0)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
