import simd
import Foundation

/// Creamer jug: everyday tableware, porcelain. Parts: pot-bellied body, unglazed foot ring, pinched pouring lip, pulled loop handle, small glaze chip on the foot.
public struct CreamerJug: RealAsset {
    public static let id = "creamer-jug"
    public static let summary = "Porcelain creamer jug: pot belly, pinched lip, loop handle, unglazed foot ring, small foot chip."
    public static let tags = ["prop", "interior", "ceramic", "kitchen", "container"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, studio: true)

    /// Overall size in meters (x width including lip and handle, y height, z depth).
    public var size = V3(0.10, 0.09, 0.07)
    /// Glaze material.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Unglazed foot ring.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    /// Chip material.
    public var chipMaterial: MaterialKey = "ceramic.porcelain-fracture"
    public init() {}

    static let outer: [V2] = [V2(0, 0.0032), V2(0.0205, 0.0030), V2(0.0230, 0.0008), V2(0.0242, 0.0), V2(0.0268, 0.0018), V2(0.0318, 0.0085),
                              V2(0.0346, 0.021), V2(0.0350, 0.035), V2(0.0334, 0.051), V2(0.0294, 0.066), V2(0.0272, 0.078), V2(0.0284, 0.0894)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0028, floorY: Float = 0.0055
        var body = Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY), segments: seg, seamTile: 0.15, material: glaze)
        // Pinched pouring lip toward +X.
        body.deform { p in
            guard p.y > 0.066 else { return p }
            let r = (p.x * p.x + p.z * p.z).squareRoot()
            guard r > 0.005 else { return p }
            let a = atan2(p.z, p.x)
            let s = exp(-(a * a) / 0.2) * smoothstep(0.066, 0.0894, p.y)
            return V3(p.x * (1 + 0.50 * s) + 0.006 * s, p.y - 0.007 * s, p.z * (1 - 0.32 * s))
        }
        m.add(body)
        m.add(Prim.lathe([V2(0.0231, 0.0010), V2(0.0242, -0.00006), V2(0.0270, 0.0019)], segments: seg, seamTile: 0.15, material: foot))
        let ctrl = [V2(0.0258, 0.0775), V2(0.0425, 0.0810), V2(0.0488, 0.0660), V2(0.0478, 0.0480), V2(0.0400, 0.0360), V2(0.0335, 0.0340)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(-1, 0, 0), section: V2(0.0070, 0.0050), detail: detail, material: glaze))
        // Story: glaze chip on the foot ring showing bare body.
        m.add(Prim.superellipsoid(V3(0.0065, 0.0030, 0.0045), exponent: 2.5, subdivisions: 3, material: chipMaterial),
              Xform(translation: V3(cos(2.2) * 0.0262, 0.0014, sin(2.2) * 0.0262), rotation: simd_quatf(angle: -2.2 - .pi / 2, axis: V3(0, 1, 0))))
        // Second chip on the rim, on the side facing the viewer.
        DD1FTableware.chip(&m, radius: 0.0276, y: 0.0891, angle: 1.25, size: 0.0060, material: chipMaterial, off: .zero)
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(56, true), make(28, false)], switchDistances: [3])
    }
}
