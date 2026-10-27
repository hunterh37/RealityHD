import simd
import Foundation

/// Stainless steel teaspoon, 15 cm: an oval thin-walled bowl, a tapered neck that joins the bowl back, and a flat
/// handle with a rounded paddle end curling slightly off the table. A raised handle ridge, a smudged satin finish,
/// polished scratches and a dried sugar crust in the bowl tell its use.
public struct Teaspoon: RealAsset {
    public static let id = "teaspoon"
    public static let summary = "Stainless steel teaspoon, 15 cm: oval bowl, tapered neck, paddle handle, smudged finish and dried sugar in the bowl."
    public static let tags = ["prop", "interior", "tableware", "metal", "handheld"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, studio: true)

    /// Satin body.
    public var steel: MaterialKey = "metal.stainless-smudged"
    /// Polished scratches and ridge.
    public var polish: MaterialKey = "metal.mirror-polish"
    public init() {}

    static let len: Float = 0.15

    static func lift(_ s: Float) -> Float {
        0.0009 + 0.0050 * DD1GWare.smooth(0.040, 0.108, s) + 0.0018 * (1 - DD1GWare.smooth(0, 0.022, s))
    }

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 101)
        var m = Model(name: Self.id)
        let c = Self.len / 2
        func hw(_ s: Float) -> Float {
            if s < 0.020 { return 0.0082 * sqrt(max(0, 1 - pow((0.020 - s) / 0.020, 2))) }
            if s < 0.050 { return 0.0082 - 0.0012 * DD1GWare.smooth(0.020, 0.050, s) }
            if s < 0.088 { return 0.0070 - 0.0040 * DD1GWare.smooth(0.050, 0.088, s) }
            return 0.0030 + 0.0030 * DD1GWare.smooth(0.088, 0.1085, s)
        }
        let hOut = DD1GWare.densify(DD1GWare.blank(hw, from: 0, to: 0.1085, step: 0.003), max: 0.003).map { V2($0.x, $0.y - c) }
        var h = DD1GWare.plate(hOut, thick: 0.0017, bevel: 0.0006, material: steel)
        h.deform { p in V3(p.x, p.y + Self.lift(p.z + c), p.z) }
        m.add(h)
        // Raised ridge down the handle.
        let ridge = DD1GWare.blank({ s in 0.0007 * sin(.pi * (s - 0.014) / 0.070) }, from: 0.014, to: 0.084, step: 0.004).map { V2($0.x, $0.y - c) }
        var rs = DD1GWare.plate(DD1GWare.densify(ridge, max: 0.004), thick: 0.0006, bevel: 0.00025, material: polish)
        rs.deform { p in V3(p.x, p.y + Self.lift(p.z + c) + 0.0010, p.z) }
        m.add(rs)
        // Bowl: thin-walled oval, convex back resting on the table.
        let R: Float = 0.0150, depth: Float = 0.0092
        let outer = Profile.smooth([V2(0, 0), V2(0.0060, 0.0004), V2(0.0098, 0.0022), V2(0.0136, 0.0052), V2(R, depth)], per: detail ? 3 : 1)
        var bowl = DD1GWare.lathe(Profile.shell(outer, wall: 0.0009, floor: 0.0009, lipSegments: 2), segs: segs, steel, tile: 0.2)
        bowl.recomputeNormals()
        let bz: Float = 0.1285 - c
        m.add(bowl, Xform(translation: V3(0, 0.0004, bz), scale: V3(1, 1, 1.6)))
        // Dried sugar crust in the bowl and a few grains on the rim.
        m.add(DD1GWare.blob(V3(0.012, 0.0014, 0.020), subdivisions: 3, material: "food.sugar:EFE6D2"),
              Xform(translation: V3(0.0012, 0.0036, bz + 0.0040), rotation: simd_quatf(degrees: 15, axis: V3(0, 1, 0))))
        DD1GWare.grains(&m, &rng, center: V3(0.0024, 0.0042, bz + 0.0120), radiusMin: 0, radiusMax: 0.0040, count: detail ? 8 : 0, size: 0.0014, material: "food.sugar")
        // Scratches on the handle.
        for _ in 0..<(detail ? 6 : 0) {
            let s = rng.float(0.026...0.090)
            m.add(Prim.roundedBox(V3(0.0003, 0.00012, rng.float(0.006...0.018)), radius: 0.00005, bevelSegments: 1, material: polish),
                  Xform(translation: V3(rng.float(-0.003...0.003), Self.lift(s) + 0.00105, s - c)))
        }
        DD1GWare.plant(&m)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 40, detail: true), level(segs: 18, detail: false)], switchDistances: [1.5])
    }
}
