import simd
import Foundation

/// Open pine cone, 8 cm long and 5 cm across, lying on its side: about 90 woody scales in a 5/8 spiral,
/// each with a thick rounded apophysis flaring out, shaded dark at the core. 2 LODs.
public struct PineCone: RealAsset {
    public static let id = "pine-cone"
    public static let summary = "Open pine cone, 8 cm, with a scale spiral of flared woody scales, lying on the ground; 2 LODs."
    public static let tags = ["nature", "ground", "plant", "wood"]
    public static let budget = 2_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.55, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let mat: MaterialKey = "wood.oak:8A5A30"
        var hi = Surface(material: mat), lo = Surface(material: mat)
        let n = 92, golden: Float = 2.399963
        let L: Float = 0.08
        for i in 0..<n {
            let t = Float(i) / Float(n - 1)
            let y = t * L
            let ang = Float(i) * golden + rng.float(-0.05...0.05)
            let envelope = pow(sin(.pi * min(max(t * 0.92 + 0.04, 0), 1)), 0.7)
            let R = 0.005 + 0.017 * envelope * rng.float(0.92...1.08)
            let out = V3(cos(ang), 0, sin(ang))
            let w = 0.011 * (1 - 0.3 * t)
            let p0 = V3(0, y, 0) + out * 0.004
            let p1 = V3(0, y + 0.0035, 0) + out * (R * 0.7)
            let p2 = V3(0, y + 0.0055 + 0.002 * (1 - t), 0) + out * R
            hi.append(Prim.tube([p0, p1, p2], radii: [w * 0.4, w * 0.5, w * 0.45], sides: 5, seamTile: 0.02, material: mat, capEnd: true))
            lo.append(Prim.tube([p0, p2], radii: [w * 0.4, w * 0.45], sides: 4, seamTile: 0.02, material: mat, capEnd: true))
        }
        let core = Prim.lathe([V2(0, -0.002), V2(0.006, 0.0), V2(0.007, L * 0.5), V2(0.003, L + 0.004), V2(0, L + 0.006)], segments: 8, material: mat)
        hi.append(core); lo.append(core)
        let tilt = simd_quatf(angle: rng.float(-0.15...0.15), axis: V3(0, 1, 0))
        let lay = simd_quatf(angle: .pi / 2 + rng.float(-0.1...0.1), axis: V3(0, 0, 1))
        let x = Xform(translation: V3(L / 2 * 0, 0.021, 0), rotation: tilt * lay)
        func finish(_ s: Surface) -> Model {
            var m = Model(name: Self.id)
            var t = s.transformed(Xform(translation: V3(0, -L / 2, 0)))
            t = t.transformed(x)
            t.computeTangents(); m.add(t); groundAO(&m); return m
        }
        return LODModel(levels: [finish(hi), finish(lo)], switchDistances: [4])
    }
}
