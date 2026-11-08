import simd
import Foundation

/// Head of iceberg lettuce, 15 cm: a pale tight inner head wrapped in loose cupped outer leaves with wavy
/// lobes and a trimmed whitish core stub on the underside.
public struct LettuceHead: RealAsset {
    public static let id = "lettuce-head"
    public static let summary = "Iceberg lettuce head, 15 cm: pale tight heart wrapped in loose cupped wavy outer leaves, trimmed core stub."
    public static let tags = ["prop", "grocery", "food", "vegetable", "handheld"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 1.3, studio: true)

    public var diameter: Float = 0.15
    public var heart: MaterialKey = "food.broccoli-stem:C9DE9A"
    public var leaf: MaterialKey = "food.basil:79AD4C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let D = diameter
        let ph = rng.float(0...6.28)
        m.add(Prim.superellipsoid(V3(D * 0.86, D * 0.8, D * 0.86), exponent: 2.2, subdivisions: hi ? 6 : 3, material: heart) { d in
            1 + 0.04 * sin(atan2(d.z, d.x) * 5 + ph) * (1 - abs(d.y))
        }, Xform(translation: V3(0, D * 0.42, 0)))
        // Outer leaves: thin cupped shells hugging the head, lobed edges via the bulge.
        let leaves = hi ? 7 : 4
        for i in 0..<leaves {
            let a = Float(i) / Float(leaves) * 2 * .pi + rng.float(-0.3...0.3)
            let lp = rng.float(0...6.28)
            let shell = Prim.superellipsoid(V3(D * 0.62, D * 0.8, D * 0.2), exponent: 2.4, subdivisions: hi ? 5 : 3, material: leaf) { d in
                1 + 0.08 * sin(d.x * 14 + lp) * max(0, d.y)
            }
            let dir = V3(cos(a), 0, sin(a))
            m.add(shell, Xform(translation: V3(0, D * 0.38, 0) + dir * D * 0.36,
                               rotation: simd_quatf(angle: -a + .pi / 2, axis: .up) * simd_quatf(degrees: rng.float(-14...(-6)), axis: V3(1, 0, 0))))
        }
        m.add(GroceryKit.cyl(0.016, 0.012, seg: 10, "food.broccoli-stem:E4EBC8", bevel: 0.003), Xform(translation: V3(0, 0, 0)))
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.03, floor: 0.6)
        return m
    }
}
