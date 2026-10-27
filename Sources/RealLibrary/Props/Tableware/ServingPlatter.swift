import simd
import Foundation

/// Oval white porcelain serving platter, 40 x 28 cm: a flat sloping rim with a rolled edge, a shallow
/// well, an oval unglazed foot ring, a cobalt rim line, a chipped edge and grey cutlery scuffs in the well.
public struct ServingPlatter: RealAsset {
    public static let id = "serving-platter"
    public static let summary = "Oval white porcelain serving platter, 40 cm: rolled rim, shallow well, foot ring, rim chip and cutlery scuffs."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, studio: true)

    /// Glaze.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Length and width (m).
    public var length: Float = 0.40
    public var width: Float = 0.28
    public init() {}

    func outline(_ segs: Int) -> (Float) -> [V2] {
        let l = length, w = width
        return { _ in Shape2D.superellipse(l, w, exponent: 2.5, segments: segs) }
    }

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 21)
        var m = Model(name: Self.id)
        let o = outline(segs)
        // (inset, y): underside recess, foot ring, flared underside, rolled edge, sloping rim, cove, well.
        let st: [(Float, Float, Float)] = [
            (0.115, 0.0058, 0), (0.075, 0.0058, 0), (0.067, 0.0045, 0), (0.0645, 0.0006, 0), (0.0600, 0, 0), (0.0555, 0.0006, 0),
            (0.0530, 0.0030, 0), (0.045, 0.0075, 0), (0.030, 0.0140, 0), (0.015, 0.0205, 0), (0.006, 0.0245, 0), (0.0010, 0.0268, 0),
            (0.0, 0.0285, 0), (0.0010, 0.0302, 0), (0.0060, 0.0309, 0), (0.030, 0.0200, 0), (0.045, 0.0140, 0), (0.053, 0.0105, 0),
            (0.062, 0.0098, 0), (0.080, 0.0096, 0), (0.115, 0.0095, 0),
        ]
        m.add(DD1GWare.loft(o, st, capStart: true, capEnd: true, material: glaze))
        // Oval unglazed foot ring.
        let foot: [(Float, Float, Float)] = [(0.0645, -0.00005, 0), (0.0555, -0.00005, 0), (0.0555, 0.0003, 0), (0.0645, 0.0003, 0), (0.0645, -0.00005, 0)]
        m.add(DD1GWare.loft(o, foot, material: DD1GWare.bisque))
        // Cobalt line just inside the rim top.
        let line: [(Float, Float, Float)] = [(0.0105, 0.0292, 0), (0.0128, 0.0292, 0), (0.0128, 0.0286, 0), (0.0105, 0.0286, 0)]
        m.add(DD1GWare.loft(o, line, material: "ceramic.cobalt"))
        // Chip on the rim, far end.
        DD1GWare.chip(&m, at: V3(0.172, 0.0299, -0.087), size: 0.0075, yaw: 35)
        DD1GWare.chip(&m, at: V3(-0.011, 0.0299, 0.1365), size: 0.0034, yaw: 4)
        // Cutlery scuffs: short grey slivers in the well.
        for i in 0..<(detail ? 22 : 6) {
            let a = rng.float(0...(2 * .pi)), r = rng.float(0.2...1) .squareRoot()
            let x = cos(a) * r * 0.125, z = sin(a) * r * 0.055
            let len = rng.float(0.008...0.03)
            m.add(Prim.roundedBox(V3(len, 0.0003, 0.0011), radius: 0.00012, bevelSegments: 1, material: "ceramic.vitreous:A8A59B"),
                  Xform(translation: V3(x, 0.0096 + 0.00012, z), rotation: simd_quatf(degrees: rng.float(-30...30) + (i % 3 == 0 ? 80 : 0), axis: V3(0, 1, 0))))
        }
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.012, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 96, detail: true), level(segs: 40, detail: false)], switchDistances: [4])
    }
}
