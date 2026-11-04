import simd
import Foundation

/// Toothbrush: everyday bathroom, nylon bristle. Parts: handle, rubber grip insert, neck, head, bristle tufts.
public struct Toothbrush: RealAsset {
    public static let id = "toothbrush"
    public static let summary = "Toothbrush lying flat: tapered handle with rubber grip, slim neck, head with bristle tufts."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.02, 0.02, 0.19)
    public init() {}

    public var handle: MaterialKey = "plastic.gloss:2FA3C9"
    public var grip: MaterialKey = "plastic.matte:2B3036"
    public var bristle: MaterialKey = "plastic.matte:E9EEF2"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        var rng = SeededRNG(seed: seed)
        let z0 = -size.z / 2
        // Handle: tapered body, grip insert on top, slim neck, head plate.
        m.add(Prim.superellipsoid(V3(0.020, 0.010, 0.115), exponent: 3.2, subdivisions: 14, material: handle), Xform(translation: V3(0, 0.005, z0 + 0.0575)))
        m.add(Prim.superellipsoid(V3(0.0105, 0.0095, 0.05), exponent: 3, subdivisions: 10, material: handle), Xform(translation: V3(0, 0.00475, z0 + 0.135 - 0.01)))
        m.add(Prim.superellipsoid(V3(0.0112, 0.0042, 0.066), exponent: 4, subdivisions: 12, material: grip), Xform(translation: V3(0, 0.0092, z0 + 0.052)))
        // Thumb-rest ridges across the grip.
        for k in 0..<6 {
            m.add(Prim.roundedBox(V3(0.0112, 0.0012, 0.0014), radius: 0.0005, bevelSegments: 1, material: "plastic.matte:3C434A"), Xform(translation: V3(0, 0.0114, z0 + 0.03 + Float(k) * 0.0045)))
        }
        m.add(Prim.roundedBox(V3(0.0062, 0.0062, 0.052), radius: 0.0025, bevelSegments: 2, material: handle), Xform(translation: V3(0, 0.0031, z0 + 0.1375)))
        m.add(Prim.roundedBox(V3(0.0135, 0.0062, 0.034), radius: 0.0025, bevelSegments: 2, material: handle), Xform(translation: V3(0, 0.0031, z0 + 0.173)))
        // Bristle tufts: 4 columns by 10 rows, staggered, with blue indicator tufts.
        let tuft = [V2(0.0013, 0.0), V2(0.0013, 0.0118), V2(0.0009, 0.0125), V2(0.0001, 0.0128)]
        for r in 0..<10 {
            for c in 0..<4 {
                let x = (Float(c) - 1.5) * 0.0027 + (r % 2 == 0 ? 0 : 0.0006)
                let z = z0 + 0.158 + Float(r) * 0.0027
                let mat: MaterialKey = (r == 0 || r == 9) && c % 2 == 0 ? "plastic.matte:2F6FB5" : bristle
                var t = rng.fork(r * 4 + c)
                // Used brush: tufts splay outward from the centre, a few more than the rest.
                let splay: Float = (r == 3 && c == 0) || (r == 6 && c == 3) ? 0.34 : 0.1
                let ax = t.float(-splay...splay), az = (Float(c) - 1.5) * 0.06 + t.float(-splay...splay)
                m.add(Prim.lathe(tuft, segments: 6, seamTile: 0.01, material: mat),
                      Xform(translation: V3(x, 0.0062, z), rotation: simd_quatf(angle: ax, axis: V3(1, 0, 0)) * simd_quatf(angle: az, axis: V3(0, 0, 1)), scale: V3(1, 1 + 0.06 * Float((r + c) % 3), 1)))
            }
        }
        // Dried toothpaste on the bristles.
        m.add(Prim.superellipsoid(V3(0.006, 0.003, 0.012), exponent: 2, subdivisions: 8, material: "plastic.gloss:DDF0F5"), Xform(translation: V3(0.0, 0.0165, z0 + 0.171)))
        groundAO(&m)
        return LODModel(m)
    }
}
