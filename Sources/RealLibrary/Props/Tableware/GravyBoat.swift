import simd
import Foundation

/// White porcelain gravy boat: a boat-shaped lofted body with a pinched pouring spout at +X, a loop handle at
/// -X, a round pedestal foot on an unglazed ring, a cobalt rim line, a dried gravy drip down the spout and a chipped handle.
public struct GravyBoat: RealAsset {
    public static let id = "gravy-boat"
    public static let summary = "White porcelain gravy boat: pinched spout, loop handle, pedestal foot, cobalt rim line, dried gravy drip and a handle chip."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, studio: true)

    /// Glaze.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Dried gravy.
    public var gravy: MaterialKey = "food.stock:7A5230"
    public init() {}

    static let yb: Float = 0.016, yt: Float = 0.082

    /// Boat outline at height fraction hf: oval body with the +X end drawn out into a pinched spout.
    static func outline(_ hf: Float, n: Int) -> [V2] {
        let a: Float = 0.060, b: Float = 0.040, sp: Float = 0.040
        let s = 0.46 + 0.54 * pow(sin(hf * .pi * 0.5), 0.7)
        let tuck = 1 - 0.035 * pow(hf, 4)
        return (0..<n).map { i in
            let t = Float(i) / Float(n) * 2 * .pi
            let c = max(0, cos(t))
            var x = a * s * tuck * cos(t), z = b * s * tuck * sin(t)
            x += sp * pow(hf, 1.5) * pow(c, 6)
            z *= 1 - 0.42 * pow(hf, 1.2) * pow(c, 4)
            return V2(x, z)
        }
    }

    func level(segs: Int, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let yb = Self.yb, yt = Self.yt
        let o: (Float) -> [V2] = { Self.outline($0, n: segs) }
        func hf(_ y: Float) -> Float { max(0, min(1, (y - yb) / (yt - yb))) }
        let outerY: [Float] = [0.016, 0.022, 0.032, 0.044, 0.057, 0.069, 0.077, 0.0805]
        var st: [(Float, Float, Float)] = outerY.map { (0, $0, hf($0)) }
        st += [(0.0006, 0.0826, 1), (0.0018, 0.0835, 1), (0.0033, 0.0830, 1), (0.0040, 0.0815, 1)]
        for y in [Float(0.070), 0.058, 0.046, 0.034, 0.026, 0.021] { st.append((0.0040 + 0.0045 * (1 - hf(y)), y, hf(y))) }
        st.append((0.020, 0.0195, 0.05))
        var hull = DD1GWare.loft(o, st, capStart: true, capEnd: true, material: glaze)
        hull.recomputeNormals(weldSeams: true)
        hull.computeTangents()
        m.add(hull)
        // Pedestal foot with an unglazed contact ring.
        let ped: [V2] = [V2(0, 0.0040), V2(0.0250, 0.0040), V2(0.0265, 0.0008), V2(0.0280, 0), V2(0.0305, 0.0012), V2(0.0285, 0.0030),
                         V2(0.0200, 0.0070), V2(0.0165, 0.0100), V2(0.0185, 0.0130), V2(0.0235, 0.0150), V2(0.0270, 0.0165), V2(0.0270, 0.0185), V2(0, 0.0185)]
        m.add(DD1GWare.lathe(Profile.smooth(ped, per: detail ? 2 : 1), segs: detail ? 48 : 24, glaze))
        m.add(DD1GWare.footBand(r: 0.0280, w: 0.0016, segs: detail ? 48 : 24))
        // Cobalt line around the rim, just below the lip.
        let line: [(Float, Float, Float)] = [(0.0003, 0.0786, 1), (0.0003, 0.0764, 1), (0.0000, 0.0764, 1), (0.0000, 0.0786, 1)]
        _ = line
        let band: [(Float, Float, Float)] = [(-0.0004, 0.0768, hf(0.0768)), (-0.0004, 0.0792, hf(0.0792))]
        m.add(DD1GWare.loft(o, band, material: "ceramic.cobalt"))
        // Dried gravy tide line inside the bowl, a little below the rim.
        let tide: [(Float, Float, Float)] = [0.0735, 0.0705, 0.0665, 0.0630].map { y in (0.0044 + 0.0045 * (1 - hf(y)) - 0.0003, y, hf(y)) }
        m.add(DD1GWare.loft(o, tide, material: "food.stock:6B4A2B"))
        // Loop handle at -X: flat oval section, roots sunk in the wall.
        let hp = [V3(-0.0585, 0.0690, 0), V3(-0.078, 0.0790, 0), V3(-0.094, 0.0740, 0), V3(-0.100, 0.0590, 0),
                  V3(-0.094, 0.0440, 0), V3(-0.075, 0.0340, 0), V3(-0.044, 0.0310, 0)]
        let sec = Shape2D.superellipse(0.0090, 0.0064, exponent: 2.4, segments: detail ? 12 : 8)
        let path = catmull(hp, per: detail ? 5 : 2)
        let sc = path.indices.map { i -> Float in 1 + 0.18 * pow(abs(Float(i) / Float(path.count - 1) - 0.5) * 2, 2) }
        m.add(Prim.sweep(sec, along: path, up: V3(0, 0, 1), scales: sc, material: glaze))
        DD1GWare.chip(&m, at: V3(-0.0805, 0.0821, 0), size: 0.0055, yaw: 18)
        DD1GWare.chip(&m, at: V3(-0.0995, 0.0640, 0.0034), size: 0.0032, yaw: 90)
        // Dried gravy drip from the spout lip down the outer wall.
        let ys: [Float] = [0.0812, 0.0780, 0.0742, 0.0702, 0.0655, 0.0610]
        let dp = ys.map { y -> V3 in
            let pts = Self.outline(hf(min(y, 0.0805)), n: segs)
            return V3(pts[0].x + 0.0001, y, 0.0004)
        }
        let streak = Shape2D.superellipse(0.0009, 0.0034, exponent: 2.6, segments: 10)
        m.add(Prim.sweep(streak, along: dp, up: V3(1, 0, 0), scales: [1, 0.95, 0.8, 0.6, 0.5, 0.75], material: gravy))
        m = m.transformed(Xform(scale: V3(1, 1.18, 1.14)))
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.012, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 56, detail: true), level(segs: 24, detail: false)], switchDistances: [3])
    }
}
