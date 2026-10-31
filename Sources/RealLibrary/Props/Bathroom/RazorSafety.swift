import simd
import Foundation

/// Safety razor: everyday bathroom, chrome. Parts: knurled chrome handle, neck, head cap and base plate, blade.
public struct RazorSafety: RealAsset {
    public static let id = "razor-safety"
    public static let summary = "Double-edge safety razor lying flat: knurled chrome handle, neck, head with blade."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.125, 0.014, 0.045)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var groove: MaterialKey = "metal.stainless"
    public var blade: MaterialKey = "metal.steel"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let y0: Float = 0.0056
        let rotZ = simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1))
        // Handle along X: weighted tail, knurled grip, shoulder. Lathe runs -X from the start point.
        let hStart: Float = 0.0275
        Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.0042, 0.0), V2(0.005, 0.002), V2(0.0052, 0.006), V2(0.0046, 0.012), V2(0.0046, 0.082), V2(0.0052, 0.086), V2(0.0048, 0.089), V2(0.001, 0.09)], chrome, seg: 24, at: V3(hStart, y0, 0), rot: rotZ)
        for k in 0..<22 {
            let y = 0.014 + Float(k) * 0.0031
            Toiletry.band(&m, r: 0.0046, y, y + 0.0013, groove, seg: 18, at: V3(hStart, y0, 0), rot: rotZ)
        }
        // Neck up to the head.
        Toiletry.lathe(&m, [V2(0.0046, 0.0), V2(0.0036, 0.004), V2(0.0033, 0.02), V2(0.0033, 0.0225), V2(0.001, 0.0225)], chrome, seg: 16, at: V3(0.05, y0, 0), rot: rotZ)
        // Head: curved cap, base plate and exposed blade edge.
        let hx: Float = 0.0565
        m.add(Prim.roundedBox(V3(0.0125, 0.0042, size.z), radius: 0.0018, bevelSegments: 3, material: chrome), Xform(translation: V3(hx, y0 + 0.0042, 0)))
        m.add(Prim.roundedBox(V3(0.0125, 0.0036, size.z), radius: 0.0016, bevelSegments: 3, material: chrome), Xform(translation: V3(hx, y0 - 0.0036, 0)))
        m.add(Prim.roundedBox(V3(0.0138, 0.0005, size.z - 0.004), radius: 0.0002, bevelSegments: 1, material: blade), Xform(translation: V3(hx, y0 + 0.0003, 0)))
        // Rust bloom on the blade edge and a chrome scratch on the base plate.
        m.add(Prim.roundedBox(V3(0.0145, 0.0006, 0.008), radius: 0.0002, bevelSegments: 1, material: "metal.rust"), Xform(translation: V3(hx, y0 + 0.0004, 0.012)))
        m.add(Prim.roundedBox(V3(0.0125, 0.0004, 0.0012), radius: 0.0002, bevelSegments: 1, material: "metal.stainless-smudged"), Xform(translation: V3(hx, y0 - 0.0016, -0.01)))
        // Resting height: base the model at y = 0.
        groundAO(&m)
        return LODModel(m)
    }
}
