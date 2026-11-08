import simd
import Foundation

/// Hand of six ripe bananas lying on a counter: fingers fan out from a shared crown in two rows and curve
/// up toward dark blossom tips. Each finger is a five-ridged tapered tube in `food.banana-peel`; the crown
/// and short stalk are green-brown, the tips dark.
public struct BananaBunch: RealAsset {
    public static let id = "banana-bunch"
    public static let summary = "Hand of six ripe bananas, 22 cm: ridged curved fingers fanned from a green-brown crown, dark blossom tips."
    public static let tags = ["prop", "grocery", "food", "fruit", "handheld"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.3, studio: true)

    /// Finger length along the curve (m) and max radius.
    public var length: Float = 0.18
    public var radius: Float = 0.018
    public var peel: MaterialKey = "food.banana-peel"
    public var crown: MaterialKey = "food.stem-green:6B6A36"
    public var tip: MaterialKey = "food.banana-tip"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let crownP = V3(-0.06, 0.035, 0)
        let n = hi ? 12 : 7
        let fingers: [(Float, Float)] = [(-24, 0), (-8, 0), (8, 0), (24, 0), (-14, 1), (6, 1)]
        for (yaw, row) in fingers {
            let a = (yaw + rng.float(-3...3)) * .pi / 180
            let d = V3(cos(a), 0, sin(a))
            let R = length / 1.0, L = length * rng.float(0.94...1.04)
            var path: [V3] = [], radii: [Float] = []
            for i in 0...n {
                let t = Float(i) / Float(n), ang = t * L / R
                let lift = row * 0.026
                path.append(crownP + d * (R * sin(ang)) + V3(0, R * (1 - cos(ang)) * 0.55 - sin(ang) * 0.02 + lift * (1 - t * 0.5), 0))
                radii.append(radius * (t < 0.15 ? 0.45 + 3.6 * t : (t > 0.85 ? max(0.2, 1 - (t - 0.85) * 5.3) : 1)) * rng.float(0.97...1.03))
            }
            m.add(Prim.tube(path, radii: radii, sides: 5, seamTile: 0.04, material: peel, capEnd: true))
            m.add(Prim.superellipsoid(V3(0.008, 0.008, 0.008), exponent: 2, subdivisions: 2, material: tip), Xform(translation: path[n]))
        }
        // Crown and stalk.
        m.add(Prim.superellipsoid(V3(0.04, 0.045, 0.06), exponent: 3, subdivisions: hi ? 3 : 2, material: crown), Xform(translation: crownP + V3(0, 0.005, 0)))
        m.add(Prim.tube([crownP, crownP + V3(-0.03, 0.02, 0)], radii: [0.012, 0.009], sides: 6, seamTile: 0.03, material: crown))
        m.add(Prim.superellipsoid(V3(0.006, 0.02, 0.02), exponent: 3, subdivisions: 1, material: tip), Xform(translation: crownP + V3(-0.03, 0.02, 0)))
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.01, floor: 0.6)
        return m
    }
}
