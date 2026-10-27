import simd
import Foundation

/// White porcelain sugar bowl: slightly oval thrown body on an unglazed foot ring, two loop ear handles,
/// a domed lid with an inner flange and a ball knob. A chipped lid rim, a tea drip and spilled sugar.
public struct SugarBowl: RealAsset {
    public static let id = "sugar-bowl"
    public static let summary = "White glazed porcelain sugar bowl: lidded, two loop handles, foot ring, chipped lid rim, tea drip and spilled sugar."
    public static let tags = ["prop", "interior", "tableware", "ceramic", "handheld"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, studio: true)

    /// Porcelain glaze of the bowl.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Slightly yellowed glaze of the lid.
    public var lidGlaze: MaterialKey = "ceramic.vitreous:F1EBDD"
    /// Spilled sugar.
    public var sugar: MaterialKey = "food.sugar"
    /// Front-to-back stretch of the oval body.
    public var ovalness: Float = 1.03
    public init() {}

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 11)
        var m = Model(name: Self.id)
        let ov = ovalness
        let outer: [V2] = Profile.smooth([
            V2(0, 0.0032), V2(0.0245, 0.0032), V2(0.0258, 0.0005), V2(0.0272, 0), V2(0.0292, 0.0012), V2(0.0318, 0.0070),
            V2(0.0372, 0.0170), V2(0.0414, 0.0320), V2(0.0432, 0.0460), V2(0.0428, 0.0560), V2(0.0436, 0.0618),
        ], per: detail ? 2 : 1)
        var body = DD1GWare.lathe(Profile.shell(outer, wall: 0.0032, floor: 0.0062), segs: segs, glaze)
        body.recomputeNormals()
        m.add(body, Xform(scale: V3(1, 1, ov)))
        m.add(DD1GWare.footBand(r: 0.0272, w: 0.0015, segs: segs), Xform(scale: V3(1, 1, ov)))
        // Lid: one profile from the underside centre, flange, rim, dome, knob.
        let lid: [V2] = [
            V2(0, 0.0765), V2(0.020, 0.0752), V2(0.032, 0.0722), V2(0.0375, 0.0672), V2(0.0390, 0.0632), V2(0.0386, 0.0548),
            V2(0.0392, 0.0536), V2(0.0398, 0.0540), V2(0.0399, 0.0612), V2(0.0430, 0.0620), V2(0.0446, 0.0626), V2(0.0450, 0.0646),
            V2(0.0426, 0.0686), V2(0.0372, 0.0735), V2(0.0292, 0.0776), V2(0.0200, 0.0797), V2(0.0120, 0.0806), V2(0.0072, 0.0809),
            V2(0.0050, 0.0814), V2(0.0056, 0.0830), V2(0.0072, 0.0850), V2(0.0074, 0.0868), V2(0.0062, 0.0886), V2(0.0036, 0.0897), V2(0, 0.0900),
        ]
        var lidS = DD1GWare.lathe(Profile.smooth(lid, per: detail ? 2 : 1), segs: segs, lidGlaze)
        lidS.recomputeNormals()
        m.add(lidS, Xform(scale: V3(1, 1, ov)))
        // Ear handles: loops with a flat oval section, roots sunk into the wall.
        for sgn: Float in [1, -1] {
            let pts = [V3(0.0405, 0.0535, 0), V3(0.0440, 0.0540, 0), V3(0.0462, 0.0490, 0), V3(0.0460, 0.0400, 0), V3(0.0442, 0.0338, 0), V3(0.0410, 0.0318, 0)]
                .map { V3($0.x * sgn, $0.y, 0) }
            let sec = Shape2D.superellipse(0.0070, 0.0052, exponent: 2.4, segments: detail ? 12 : 8)
            m.add(Prim.sweep(sec, along: catmull(pts, per: detail ? 5 : 2), up: V3(0, 0, 1), material: glaze))
        }
        // Chip on the lid rim.
        let a: Float = 0.7
        DD1GWare.chip(&m, at: V3(cos(a) * 0.0447, 0.0627, sin(a) * 0.0447 * ov), size: 0.0042, yaw: -a * 57)
        // Tea drip down the wall.
        let ta: Float = 1.25
        let tp = stride(from: Float(0.0602), through: 0.0392, by: -0.003).map { y -> V3 in
            let r = DD1GWare.radius(outer, y) + 0.0001
            return V3(cos(ta) * r, y, sin(ta) * r * ov)
        }
        let radial = V3(cos(ta), 0, sin(ta) * ov).normalized
        let streak = Shape2D.superellipse(0.0007, 0.0023, exponent: 2.6, segments: 10)
        m.add(Prim.sweep(streak, along: tp, up: radial, scales: [1, 0.95, 0.8, 0.6, 0.45, 0.4, 0.6, 0.3], material: "food.stock:B58A4F"))
        // Cobalt line on the body and a grey rub band where the lid flange chafes the rim.
        let band = stride(from: Float(0.0455), through: 0.0475, by: 0.001).map { V2(DD1GWare.radius(outer, $0) + 0.00025, $0) }
        m.add(DD1GWare.lathe(band + [V2(band.last!.x - 0.0004, band.last!.y), V2(band.first!.x - 0.0004, band.first!.y), band[0]], segs: segs, "ceramic.cobalt"), Xform(scale: V3(1, 1, ov)))
        let rub = stride(from: Float(0.0572), through: 0.0612, by: 0.002).map { V2(DD1GWare.radius(outer, $0) + 0.0002, $0) }
        m.add(DD1GWare.lathe(rub + [V2(rub.last!.x - 0.0004, rub.last!.y), V2(rub.first!.x - 0.0004, rub.first!.y), rub[0]], segs: segs, "ceramic.vitreous:CFC8B6"), Xform(scale: V3(1, 1, ov)))
        // Spilled sugar on the table.
        DD1GWare.grains(&m, &rng, center: V3(0.010, 0, 0.0462), radiusMin: 0.0, radiusMax: 0.0085, count: detail ? 34 : 8,
                        size: 0.0022, angle: 0.2...2.4, material: sugar)
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.012, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 56, detail: true), level(segs: 28, detail: false)], switchDistances: [3])
    }
}
