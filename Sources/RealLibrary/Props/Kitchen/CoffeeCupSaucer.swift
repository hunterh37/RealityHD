import simd
import Foundation

/// White porcelain coffee cup on its saucer: thrown 75 mm cup, 65 mm tall, with a rolled rim, foot
/// ring and pulled loop handle, seated in the recessed well of a 140 mm saucer with a raised rim and
/// an unglazed foot ring. Black coffee fills the cup to `fillDrop` below the rim.
public struct CoffeeCupSaucer: RealAsset {
    public static let id = "coffee-cup-saucer"
    public static let summary = "White glazed porcelain coffee cup on a saucer: 75 mm cup with loop handle, 140 mm saucer with a well, black coffee inside."
    public static let tags = ["prop", "kitchen", "ceramic", "container", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, studio: true)

    /// Porcelain glaze.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Unglazed foot rings.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    /// Coffee surface (same look as coffee-mug).
    public var coffee: MaterialKey = "plastic.gloss:24130A"
    /// Cup outer diameter at the rim (m).
    public var cupDiameter: Float = 0.075
    /// Cup height (m).
    public var cupHeight: Float = 0.065
    /// Saucer diameter (m).
    public var saucerDiameter: Float = 0.14
    /// Coffee level below the cup rim (m); nil = empty.
    public var fillDrop: Float? = 0.013
    public init() {}

    /// Height of the saucer well floor; the cup stands here.
    var wellY: Float { 0.0052 }

    func level(segs: Int, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let S = saucerDiameter / 2
        // Saucer: underside, foot ring, flaring body, rolled rim, top surface, recessed well.
        let sp: [V2] = [
            V2(0, 0.0032), V2(S * 0.46, 0.0032), V2(S * 0.5, 0.0012), V2(S * 0.53, 0.0001), V2(S * 0.6, 0.0001),
            V2(S * 0.63, 0.0016), V2(S * 0.8, 0.0068), V2(S * 0.93, 0.0118), V2(S * 0.99, 0.0148), V2(S, 0.0158),
            V2(S * 0.985, 0.0168), V2(S * 0.955, 0.0162), V2(S * 0.86, 0.0124), V2(S * 0.66, 0.0082),
            V2(S * 0.56, 0.0074), V2(S * 0.53, 0.0064), V2(S * 0.5, wellY + 0.0004), V2(S * 0.46, wellY), V2(0, wellY),
        ]
        m.add(Prim.lathe(sp, segments: segs, seamTile: 0.3, material: glaze))
        // Unglazed foot ring band of the saucer (slightly proud, same profile section).
        m.add(Prim.lathe([V2(S * 0.6 + 0.0003, 0.0004), V2(S * 0.565, -0.00005), V2(S * 0.525, 0.0004)].reversed(), segments: segs, seamTile: 0.3, material: foot))

        // Cup: recessed base, foot ring, wall flaring to the rim, rolled lip, inner wall, inner floor.
        let R = cupDiameter / 2, H = cupHeight, y0 = wellY
        let cp: [V2] = [
            V2(0, 0.0034), V2(R * 0.5, 0.0034), V2(R * 0.55, 0.0016), V2(R * 0.58, 0.0002), V2(R * 0.66, 0),
            V2(R * 0.7, 0.0014), V2(R * 0.74, 0.006), V2(R * 0.84, 0.017), V2(R * 0.93, 0.033), V2(R * 0.985, H * 0.75),
            V2(R, H - 0.003), V2(R * 0.995, H - 0.001), V2(R * 0.975, H), V2(R * 0.952, H - 0.0008), V2(R * 0.94, H - 0.004),
            V2(R * 0.925, H * 0.75), V2(R * 0.86, 0.033), V2(R * 0.76, 0.017), V2(R * 0.62, 0.0085), V2(R * 0.4, 0.0068), V2(0, 0.0066),
        ]
        m.add(Prim.lathe(cp, segments: segs, seamTile: 0.3, material: glaze), Xform(translation: V3(0, y0, 0)))
        m.add(Prim.lathe([V2(R * 0.7 + 0.0002, 0.0012), V2(R * 0.62, -0.00005), V2(R * 0.56, 0.0012)].reversed(), segments: segs, seamTile: 0.3, material: foot), Xform(translation: V3(0, y0, 0)))
        // Loop handle on +X: ear shape, oval section, roots buried in the wall.
        func wallR(_ y: Float) -> Float { R * (0.74 + 0.26 * min(1, pow(y / (H * 0.75), 0.6))) }
        let yt = H * 0.82, yb = H * 0.3
        let path = catmull([V3(wallR(yt) - 0.004, yt, 0), V3(wallR(yt) + 0.011, yt + 0.002, 0), V3(wallR(yt) + 0.022, yt - 0.009, 0),
                            V3(wallR(yb) + 0.02, yb + 0.012, 0), V3(wallR(yb) + 0.009, yb, 0), V3(wallR(yb) - 0.004, yb + 0.001, 0)], per: detail ? 4 : 2)
        let sec = Shape2D.superellipse(0.0105, 0.0062, exponent: 2.4, segments: detail ? 12 : 8)
        let scales = path.indices.map { i -> Float in
            let t = Float(i) / Float(path.count - 1)
            return 1 + 0.25 * pow(abs(t - 0.5) * 2, 2)
        }
        m.add(Prim.sweep(sec, along: path, up: V3(0, 0, 1), scales: scales, material: glaze), Xform(translation: V3(0, y0, 0)))
        if let drop = fillDrop {
            let y = H - drop, r = wallR(min(y, H * 0.75)) - (R - R * 0.925) - 0.0002
            m.add(Prim.lathe([V2(r, y + 0.0009), V2(r - 0.0022, y), V2(0, y)], segments: segs, seamTile: 0.3, material: coffee), Xform(translation: V3(0, y0, 0)))
        }
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 40, detail: true), level(segs: 18, detail: false)], switchDistances: [3])
    }
}
