import simd
import Foundation

/// Wide celadon stoneware serving bowl, 28 cm: thrown flaring wall with throwing rings, a rolled rim,
/// a bare-clay foot and lower body under a wavy glaze dip line, rim chips.
public struct ServingBowl: RealAsset {
    public static let id = "serving-bowl"
    public static let summary = "Celadon stoneware serving bowl, 28 cm: wavy glaze line over bare clay, throwing rings, and rim chips."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, studio: true)

    /// Celadon glaze.
    public var glaze: MaterialKey = "ceramic.celadon"
    /// Bare clay body.
    public var clay: MaterialKey = "ceramic.bisque:BC9A72"
    /// Rim diameter (m).
    public var diameter: Float = 0.28
    public init() {}

    func level(segs: Int, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let R = diameter / 2
        let outer: [V2] = Profile.smooth([
            V2(0, 0.0050), V2(0.048, 0.0050), V2(0.0535, 0.0010), V2(0.0575, 0), V2(0.0630, 0.0020), V2(0.080, 0.0120),
            V2(0.104, 0.0300), V2(0.122, 0.0560), V2(0.1345, 0.0850), V2(R - 0.0006, 0.1040), V2(R, 0.1090),
        ], per: detail ? 3 : 2)
        func rings(_ p: V3) -> V3 {
            // Throwing rings: faint radial ripple by height, fading near the foot.
            let a = 1 + 0.0035 * sin(p.y * 330) * DD1GWare.smooth(0.01, 0.04, p.y)
            return V3(p.x * a, p.y, p.z * a)
        }
        var body = DD1GWare.lathe(Profile.shell(outer, wall: 0.0062, floor: 0.0085), segs: segs, glaze)
        if detail { body.deform(rings) } else { body.recomputeNormals() }
        m.add(body)
        // Bare clay: underside, foot and lower wall up to a wavy glaze line.
        let top: Float = 0.056
        var band: [V2] = [V2(0, 0.0046)]
        band += stride(from: Float(0.0050), through: top, by: 0.0025).map { V2(DD1GWare.radius(outer, $0) + 0.00035, $0) }
        band += [V2(DD1GWare.radius(outer, top) + 0.0001, top), V2(DD1GWare.radius(outer, top) - 0.0004, top)]
        band[1] = V2(0.048, 0.0044)
        var clayS = DD1GWare.lathe(band, segs: segs, clay)
        clayS.deform { p in
            guard p.y >= top - 1e-5 else { return rings(p) }
            let th = atan2(p.z, p.x)
            let y = top + 0.0075 * sin(th * 5 + 0.7) + 0.0035 * sin(th * 11 + 2.1) + 0.0012 * sin(th * 23)
            let r = DD1GWare.radius(outer, y) + (simd_length(V2(p.x, p.z)) - DD1GWare.radius(outer, top))
            return V3(cos(th) * r, y, sin(th) * r)
        }
        m.add(clayS)
        // Chips on the rim.
        DD1GWare.chip(&m, at: V3(cos(2.2) * (R - 0.0008), 0.1088, sin(2.2) * (R - 0.0008)), size: 0.0105, yaw: -2.2 * 57.3 + 90)
        DD1GWare.chip(&m, at: V3(cos(0.4) * (R - 0.0008), 0.1088, sin(0.4) * (R - 0.0008)), size: 0.0045, yaw: -0.4 * 57.3 + 90)
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 64, detail: true), level(segs: 32, detail: false)], switchDistances: [4])
    }
}
