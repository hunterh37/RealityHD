import simd
import Foundation

/// Composition Notebook: everyday school, cardboard cover. Parts: marbled cardboard cover, cloth tape binding, stitched page block, name label panel.
public struct CompositionNotebook: RealAsset {
    public static let id = "composition-notebook"
    public static let summary = "Marbled composition notebook with a taped spine and a blank name label."
    public static let tags = ["prop", "interior", "school", "cardboard", "paper"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.19, 0.01, 0.24)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, T = size.y, D = size.z
        let cov: Float = 0.0009
        // Page block (about 100 sheets) with a 2 mm cover overhang.
        m.add(Prim.roundedBox(V3(W - 0.004, T - 2 * cov, D - 0.004), radius: 0.0005, bevelSegments: 1, material: "paper.pages"),
              Xform(translation: V3(0.0, T / 2, 0)))
        // Front and back marbled card covers.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W, cov, D), radius: 0.0004, bevelSegments: 1, material: "plastic.matte:4A4A52"),
                  Xform(translation: V3(0, T / 2 + s * (T / 2 - cov / 2), 0)))
        }
        // Black cloth tape wrapping the spine, folded 25 mm onto both covers.
        m.add(Prim.roundedBox(V3(0.0032, T, D + 0.0004), radius: 0.0012, bevelSegments: 2, material: "fabric.webbing"),
              Xform(translation: V3(-W / 2 + 0.0004, T / 2, 0)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.025, 0.0004, D + 0.0004), radius: 0.0002, bevelSegments: 1, material: "fabric.webbing"),
                  Xform(translation: V3(-W / 2 + 0.0125, T / 2 + s * (T / 2 + 0.0001), 0)))
        }
        // White name label with a ruled border on the front cover.
        m.add(Prim.roundedBox(V3(0.1, 0.0003, 0.062), radius: 0.0001, bevelSegments: 1, material: "paper.sheet"),
              Xform(translation: V3(0.012, T + 0.00005, 0)).jittered(&rng))
        m.add(Prim.roundedBox(V3(0.082, 0.0004, 0.0005), radius: 0.0001, bevelSegments: 1, material: "plastic.matte"),
              Xform(translation: V3(0.012, T + 0.0001, 0.008)))
        // Marbled cover: white flecks and swirls as flat elliptical discs on the front cover.
        for _ in 0..<70 {
            let cx = rng.float(-W / 2 + 0.03...W / 2 - 0.008), cz = rng.float(-D / 2 + 0.006...D / 2 - 0.006)
            if abs(cx - 0.012) < 0.055 && abs(cz) < 0.034 { continue }
            let r = rng.float(0.0012...0.0055)
            let disc = Prim.cylinder(radius: r, height: 0.00012, bevel: 0, segments: 10, material: "plastic.matte:D8D6D0")
            let x = Xform(translation: V3(cx, T - 0.00001, cz), rotation: simd_quatf(degrees: rng.float(0...180), axis: .up), scale: V3(rng.float(1...2.6), 1, 1))
            m.add(disc, x)
        }
        // Ruled lines on the name label.
        for k in -1...1 {
            m.add(Prim.roundedBox(V3(0.07, 0.0004, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:6A7FA8"),
                  Xform(translation: V3(0.012, T + 0.0001, Float(k) * 0.014 - 0.006)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
