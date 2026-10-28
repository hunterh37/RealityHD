import simd
import Foundation

/// Whiskey tumbler: everyday tableware, cut crystal. Parts: heavy solid base, ten faceted cut flats on the lower body, round upper rim, star cut underside, chipped rim spot.
public struct WhiskeyTumbler: RealAsset {
    public static let id = "whiskey-tumbler"
    public static let summary = "Cut crystal rocks glass: heavy base, 10 faceted cut flats on the lower body, round rim, one small rim chip."
    public static let tags = ["prop", "interior", "glass", "container", "handheld"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.09, 0.08)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Chip patch material.
    public var chipMaterial: MaterialKey = "glass.frosted"
    /// Number of flat cuts around the lower body.
    public var cuts = 10
    public init() {}

    static let outer: [V2] = [V2(0, 0.0046), V2(0.012, 0.0040), V2(0.022, 0.0022), V2(0.0295, 0.0008), V2(0.0318, 0.0), V2(0.0338, 0.0016),
                              V2(0.0352, 0.0060), V2(0.0364, 0.015), V2(0.0376, 0.040), V2(0.0388, 0.065), V2(0.0398, 0.0895)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0042, floorY: Float = 0.0225
        var body = Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY, smooth: 2), segments: seg, seamTile: 0.1, material: glass)
        DD1FTableware.facets(&body, outer: Self.outer, wall: wall, n: cuts, y0: 0.008, y1: 0.052, fade: 0.012, depth: 2.4)
        if detail {
            // Star cut on the underside: shallow ridges radiating from the centre.
            body.deform { p in
                let r = (p.x * p.x + p.z * p.z).squareRoot()
                guard p.y < 0.0050, r > 0.003, r < 0.030 else { return p }
                let a = atan2(p.z, p.x)
                return V3(p.x, p.y + 0.0007 * cos(a * 10) * smoothstep(0.003, 0.012, r), p.z)
            }
        }
        m.add(body)
        // Chip on the rim.
        DD1FTableware.chip(&m, radius: 0.0393, y: 0.0893, angle: 0.9, size: 0.0085, material: chipMaterial, off: .zero)
        // Scratches from a drawer: three fine frosted lines across one cut flat.
        let ha: Float = 1.9
        for (i, spec) in [(0.0, 0.030, 0.026), (0.0042, 0.022, 0.044), (-0.0046, 0.017, 0.053)].enumerated() {
            let hy = Float(spec.2), len = Float(spec.1), hr = DD1FTableware.radius(Self.outer, at: hy) * 0.975
            let a = ha + Float(spec.0) / hr
            let tilt = simd_quatf(angle: Float(i) * 0.5 - 0.5, axis: V3(0, 0, 1))
            m.add(Prim.superellipsoid(V3(len, 0.0005, 0.0006), exponent: 2, subdivisions: 2, material: chipMaterial),
                  Xform(translation: V3(cos(a) * hr, hy, sin(a) * hr), rotation: simd_quatf(angle: -a - .pi / 2, axis: V3(0, 1, 0)) * tilt))
        }
        // Scuffed foot: frosted wear band where the glass has slid on tables.
        m.add(Prim.lathe([V2(0.0319, 0.0001), V2(0.0339, 0.0016), V2(0.0353, 0.0062), V2(0.0357, 0.0085)], segments: seg, seamTile: 0.1, material: chipMaterial))
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(96, true), make(48, false)], switchDistances: [3])
    }
}
