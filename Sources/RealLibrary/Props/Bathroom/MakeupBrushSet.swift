import simd
import Foundation

/// Makeup brush set: everyday bathroom, cup and brushes. Parts: ceramic cup, five brushes, gold ferrules, fur heads.
public struct MakeupBrushSet: RealAsset {
    public static let id = "makeup-brush-set"
    public static let summary = "Cup holding five makeup brushes with black handles, gold ferrules and soft fur heads."
    public static let tags = ["prop", "interior", "bathroom", "ceramic", "plastic"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.08, 0.18, 0.08)
    public init() {}

    public var cup: MaterialKey = "ceramic.vitreous:EBD9D3"
    public var handle: MaterialKey = "plastic.gloss:1C1C20"
    public var ferrule: MaterialKey = "metal.brass"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let seg = hi ? 40 : 16
            // Cup with foot, wall, rolled lip and inner floor.
            Toiletry.lathe(&m, [V2(0.001, 0.0), V2(0.03, 0.0), V2(0.033, 0.0012), V2(0.0345, 0.006), V2(0.0365, 0.05), V2(0.0385, 0.088), V2(0.0392, 0.0905), V2(0.0385, 0.092), V2(0.0365, 0.0912),
                                V2(0.0355, 0.088), V2(0.034, 0.05), V2(0.03, 0.012), V2(0.001, 0.011)], cup, seg: seg, seamTile: 0.2)
            Toiletry.band(&m, r: 0.0382, 0.07, 0.078, "ceramic.vitreous:D9B7B0", seg: seg)
            // Five brushes: angle around the cup, tilt, handle length, head kind (0 round, 1 flat, 2 angled).
            let specs: [(Float, Float, Float, Int)] = [(0.2, 0.09, 0.106, 0), (1.4, 0.15, 0.096, 1), (2.6, 0.12, 0.108, 2), (3.7, 0.16, 0.092, 0), (5.0, 0.1, 0.102, 1)]
            for (i, s) in specs.enumerated() {
                let (phi, tilt, hl, kind) = s
                let dx = cos(phi), dz = sin(phi)
                let q = simd_quatf(angle: tilt * dz, axis: V3(1, 0, 0)) * simd_quatf(angle: -tilt * dx, axis: V3(0, 0, 1))
                let at = V3(dx * 0.01, 0.012, dz * 0.01)
                let tseg = hi ? 16 : 8
                // Tapered handle.
                Toiletry.lathe(&m, [V2(0.0028, 0.0), V2(0.0042, 0.03), V2(0.0048, 0.075), V2(0.0042, hl - 0.01), V2(0.0038, hl)], handle, seg: tseg, at: at, rot: q)
                // Ferrule.
                Toiletry.lathe(&m, [V2(0.0038, hl - 0.002), V2(0.0056, hl + 0.002), V2(0.0058, hl + 0.026), V2(0.0048, hl + 0.03), V2(0.001, hl + 0.03)], ferrule, seg: tseg, at: at, rot: q)
                // Fur head.
                let base = hl + 0.026
                let fur: MaterialKey = i % 2 == 0 ? "plastic.matte:EADFCB" : "plastic.matte:3A2F2B"
                switch kind {
                case 0: Toiletry.lathe(&m, [V2(0.0055, base), V2(0.0092, base + 0.008), V2(0.0098, base + 0.018), V2(0.0072, base + 0.03), V2(0.003, base + 0.036), V2(0.0005, base + 0.0375)], fur, seg: tseg, at: at, rot: q)
                case 1: Toiletry.lathe(&m, [V2(0.0055, base), V2(0.0092, base + 0.006), V2(0.0105, base + 0.016), V2(0.0095, base + 0.026), V2(0.0045, base + 0.029), V2(0.0005, base + 0.03)], fur, seg: tseg, sz: 0.4, at: at, rot: q)
                default: Toiletry.lathe(&m, [V2(0.0055, base), V2(0.0085, base + 0.006), V2(0.0085, base + 0.016), V2(0.006, base + 0.026), V2(0.0005, base + 0.0285)], fur, seg: tseg, sz: 0.5, at: at, rot: q)
                }
            }
            // Powder smudges on the cup, where brushes get tapped.
            for (a, y) in [(0.9, 0.075), (2.8, 0.062), (4.4, 0.08)] as [(Float, Float)] {
                m.add(Prim.roundedBox(V3(0.009, 0.007, 0.0006), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:E58FA0"),
                      Xform(translation: V3(cos(a) * 0.0388, y, sin(a) * 0.0388), rotation: simd_quatf(angle: -a + Float.pi / 2, axis: V3(0, 1, 0))))
            }
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
