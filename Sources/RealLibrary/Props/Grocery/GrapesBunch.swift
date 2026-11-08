import simd
import Foundation

/// Bunch of red seedless grapes lying on its side: about fifty glossy oval berries packed on a tapered
/// cone around a branching woody rachis, with a short cut stem at the shoulder.
public struct GrapesBunch: RealAsset {
    public static let id = "grapes-bunch"
    public static let summary = "Bunch of red seedless grapes, 20 cm: about fifty glossy oval berries on a branching woody stem."
    public static let tags = ["prop", "grocery", "food", "fruit", "handheld"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.3, studio: true)

    public var berries = 52
    public var berrySize = V3(0.018, 0.02, 0.018)
    public var skin: MaterialKey = "food.tomato:5E1F35"
    public var stem: MaterialKey = "food.herb-stem:7A6A3A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let len: Float = 0.17
        // Rachis along +X, tilted so the bunch rests on its side.
        m.add(Prim.tube([V3(-0.03, 0, 0), V3(0.02, 0, 0), V3(len * 0.9, 0, 0)], radii: [0.003, 0.0028, 0.0012], sides: 5, seamTile: 0.02, material: stem))
        for i in 0..<berries {
            let t = Float(i) / Float(berries)
            let x = 0.02 + t * (len - 0.03)
            let coneR = 0.045 * (1 - t * 0.75) + 0.006
            let a = rng.float(0...(2 * .pi))
            let rr = coneR * rng.float(0.55...1.0)
            let p = V3(x, sin(a) * rr, cos(a) * rr)
            let s = berrySize * rng.float(0.88...1.08)
            m.add(Prim.superellipsoid(s, exponent: 2, subdivisions: hi ? 2 : 1, material: skin),
                  Xform(translation: p, rotation: simd_quatf(angle: a, axis: V3(1, 0, 0)) * simd_quatf(degrees: rng.float(40...80), axis: V3(0, 0, 1))))
            if hi && i % 3 == 0 {
                m.add(Prim.tube([V3(x, 0, 0), p * 0.7 + V3(x, 0, 0) * 0.3], radii: [0.0012, 0.001], sides: 3, seamTile: 0.02, material: stem, capEnd: false))
            }
        }
        m = m.transformed(Xform(rotation: simd_quatf(degrees: 10, axis: V3(0, 0, 1))))
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
