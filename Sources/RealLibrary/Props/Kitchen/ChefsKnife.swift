import simd
import Foundation

/// Chef's knife lying on its side: 21 cm forged blade with belly and a ground edge, stainless tang
/// sandwiched between two walnut scales, brass rivets and a forged bolster. Length along Z.
public struct ChefsKnife: RealAsset {
    public static let id = "chefs-knife"
    public static let summary = "Chef's knife, forged steel: 21 cm blade with belly, bolster, walnut scales on a stainless tang, three brass rivets."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.55, studio: true)

    /// Blade steel.
    public var bladeMaterial: MaterialKey = "metal.knife-blade"
    /// Handle scale wood.
    public var scaleMaterial: MaterialKey = "wood.walnut"
    /// Tang and bolster metal.
    public var tangMaterial: MaterialKey = "metal.stainless"
    /// Rivet metal.
    public var rivetMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yc: Float = 0.0100
        let blade = DD1BKit.v2([(-0.040, 0.0225), (0.090, 0.0225), (0.125, 0.0205), (0.150, 0.0152), (0.169, 0.0090), (0.180, 0.0020),
                                (0.172, -0.0050), (0.158, -0.0125), (0.134, -0.0190), (0.085, -0.0225), (-0.030, -0.0225), (-0.040, -0.0215)])
        m.add(DD1BKit.flat(Shape2D.rounded(blade.map { V2($0.x, $0.y * 1.12) }, radius: 0.0008, segments: 3), thick: 0.0026, y: yc, bevel: 0.0011, material: bladeMaterial))
        let handle = Shape2D.rounded(DD1BKit.symmetric([(-0.043, 0.0115), (-0.09, 0.0125), (-0.14, 0.0118), (-0.172, 0.0100)]), radius: 0.0055, segments: 5)
        m.add(DD1BKit.flat(Shape2D.offset(handle, -0.0006), thick: 0.0036, y: yc, bevel: 0.0004, material: tangMaterial))
        for s: Float in [-1, 1] {
            m.add(DD1BKit.flat(handle, thick: 0.0068, y: yc + s * 0.0050, bevel: 0.0028, material: scaleMaterial))
        }
        m.add(Prim.roundedBox(V3(0.012, 0.0178, 0.0262), radius: 0.003, bevelSegments: 3, material: tangMaterial), Xform(translation: V3(-0.041, yc, 0)))
        for x: Float in [-0.068, -0.105, -0.145] {
            rivet(&m, at: V3(x, yc + 0.0084, 0), normal: .up, radius: 0.0023, material: rivetMaterial)
            rivet(&m, at: V3(x, yc - 0.0084, 0), normal: -.up, radius: 0.0023, material: rivetMaterial)
        }
        return DD1BKit.finish(m, rng: &rng)
    }
}
