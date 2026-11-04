import simd
import Foundation

/// Eraser: everyday school, rubber. Parts: rubber block, card sleeve, worn corner, bevel edges.
public struct Eraser: RealAsset {
    public static let id = "eraser"
    public static let summary = "Block eraser with a printed card sleeve and a worn end."
    public static let tags = ["prop", "interior", "school", "rubber"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.05, 0.012, 0.02)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        // White vinyl block, 3 mm corner bevel on the worn end.
        m.add(Prim.roundedBox(V3(W, H - 0.001, D - 0.0004), radius: 0.0025, bevelSegments: 3, material: "plastic.matte:F1EEE6"),
              Xform(translation: V3(0, H / 2, 0)))
        // Printed card sleeve covering the middle 60 percent of the length, 0.4 mm thick.
        let sleeve = Prim.roundedBox(V3(W * 0.62, H, D), radius: 0.0012, bevelSegments: 2, material: "plastic.matte:2F5FA8")
        m.add(sleeve, Xform(translation: V3(-W * 0.08, H / 2, 0)))
        // Printed band on the sleeve top.
        m.add(Prim.roundedBox(V3(W * 0.4, 0.0003, D * 0.5), radius: 0.0001, bevelSegments: 1, material: "paper.sheet"),
              Xform(translation: V3(-W * 0.08, H - 0.0001, 0)))
        // Used end: soft rounded corner smudge as a flat gray patch on the exposed block top.
        let smudge = Prim.roundedBox(V3(W * 0.14, 0.0003, D * 0.6), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:C9C4B8")
        m.add(smudge, Xform(translation: V3(W * 0.36, H - 0.0007, 0)).jittered(&rng))
        // Two thin printed stripes on the sleeve.
        for s in [-1, 1] as [Float] {
            m.add(Prim.roundedBox(V3(W * 0.4, 0.0003, 0.0012), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:F1EEE6"),
                  Xform(translation: V3(-W * 0.08, H - 0.0001, s * D * 0.36)))
        }
        // Printed text rows on the label: short ink bars of varied length.
        for k in 0..<5 {
            let len = W * (0.12 + 0.05 * Float((k * 7) % 4))
            m.add(Prim.roundedBox(V3(len, 0.0002, 0.0007), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:2A3A5A"),
                  Xform(translation: V3(-W * 0.08 - W * 0.15 + len / 2, H + 0.0006, -D * 0.1 + Float(k) * 0.0018)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
