import simd
import Foundation

/// Hairbrush: everyday bathroom, wood. Parts: wooden handle, brass ferrule, paddle back, rubber cushion pad, bristle pins.
public struct Hairbrush: RealAsset {
    public static let id = "hairbrush"
    public static let summary = "Oval paddle hairbrush lying flat: walnut handle and back, brass ferrule, rubber cushion with ball-tip pins."
    public static let tags = ["prop", "interior", "bathroom", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.07, 0.03, 0.23)
    public init() {}

    public var wood: MaterialKey = "wood.walnut"
    public var ferrule: MaterialKey = "metal.brass"
    public var pad: MaterialKey = "plastic.matte:2B2B2F"
    public var pin: MaterialKey = "plastic.matte:E9E4D8"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            var rng = SeededRNG(seed: seed)
            let hi = lod == 0
            // Walnut handle, neck, brass ferrule and paddle back.
            m.add(Prim.superellipsoid(V3(0.026, 0.022, 0.13), exponent: 2.6, subdivisions: hi ? 12 : 6, material: wood), Xform(translation: V3(0, 0.011, -0.05)))
            m.add(Prim.superellipsoid(V3(0.018, 0.013, 0.036), exponent: 2.4, subdivisions: hi ? 8 : 5, material: wood), Xform(translation: V3(0, 0.0075, 0.016)))
            Toiletry.lathe(&m, [V2(0.0085, 0.0), V2(0.0122, 0.0006), V2(0.0124, 0.011), V2(0.0085, 0.0118), V2(0.001, 0.0118)], ferrule, seg: hi ? 24 : 10, sz: 0.62, at: V3(0, 0.0105, 0.004), rot: simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0)))
            m.add(Prim.superellipsoid(V3(0.07, 0.013, 0.1), exponent: 2.4, subdivisions: hi ? 12 : 6, material: wood), Xform(translation: V3(0, 0.0065, 0.065)))
            // Rubber cushion pad.
            m.add(Prim.superellipsoid(V3(0.062, 0.0075, 0.092), exponent: 2.4, subdivisions: hi ? 12 : 6, material: pad), Xform(translation: V3(0, 0.0138, 0.065)))
            // Ball-tip pins in a hex grid across the oval, a few bent or flattened.
            let prof = [V2(0.0009, 0.0), V2(0.0009, 0.0105), V2(0.0015, 0.0108), V2(0.0015, 0.0122), V2(0.0007, 0.0128)]
            let rx: Float = 0.026, rz: Float = 0.039, dd: Float = 0.0068
            var idx = 0
            for j in -7...7 {
                for i in -5...5 {
                    let x = (Float(i) + (j % 2 == 0 ? 0 : 0.5)) * dd
                    let z = Float(j) * dd * 0.866
                    if (x / rx) * (x / rx) + (z / rz) * (z / rz) > 1 { continue }
                    var f = rng.fork(idx); idx += 1
                    let bend: Float = (idx % 17 == 3) ? 0.35 : 0.08
                    let q = simd_quatf(angle: f.float(-bend...bend), axis: V3(1, 0, 0)) * simd_quatf(angle: f.float(-bend...bend), axis: V3(0, 0, 1))
                    m.add(Prim.lathe(prof, segments: hi ? 5 : 4, seamTile: 0.01, material: pin), Xform(translation: V3(x, 0.0174, 0.065 + z), rotation: q))
                }
            }
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
