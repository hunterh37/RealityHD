import simd
import Foundation

/// Textbook: everyday school, hardcover. Parts: cloth-wrapped board cover, rounded spine, page block, head and tail band, cover label panel.
public struct Textbook: RealAsset {
    public static let id = "textbook"
    public static let summary = "Hardcover school textbook with cloth-wrapped boards, rounded spine and a page block."
    public static let tags = ["prop", "interior", "school", "hardcover", "paper"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.21, 0.04, 0.28)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, T = size.y, D = size.z
        let cover = "fabric.wool", board: Float = 0.003, over: Float = 0.003
        let pageH = T - 2 * board - 0.0006
        // Page block, inset from the board edges (square: head, tail and fore edge reveals of 3 mm).
        m.add(Prim.roundedBox(V3(W - 0.006 - over - 0.002, pageH, D - 2 * over), radius: 0.0008, bevelSegments: 1, material: "paper.sheet:EDE6D2"),
              Xform(translation: V3(0.0015 + over / 2 - 0.0005, T / 2, 0)))
        // Front and back boards.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W - 0.004, board, D), radius: 0.0012, bevelSegments: 2, material: cover),
                  Xform(translation: V3(0.002, T / 2 + s * (T / 2 - board / 2), 0)))
        }
        // Rounded spine: half-round cloth strip along Z.
        let spine = Prim.cylinder(radius: T / 2, height: D - 0.001, bevel: 0.0008, segments: 20, material: cover)
        m.add(spine, Xform(translation: V3(-W / 2 + T / 2 + 0.0005, T / 2, -D / 2 + 0.0005), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Head and tail bands: striped cloth at the page block ends against the spine.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.004, pageH * 0.9, 0.0016), radius: 0.0006, bevelSegments: 1, material: "plastic.matte"),
                  Xform(translation: V3(-W / 2 + 0.012, T / 2, s * (D / 2 - over - 0.0008))))
        }
        // Page edges with printed line texture on fore edge, head and tail.
        m.add(Prim.roundedBox(V3(0.0004, pageH, D - 2 * over - 0.002), radius: 0.0001, bevelSegments: 1, material: "paper.pages:E9E1CC"),
              Xform(translation: V3(0.0025 + (W - 0.006 - over - 0.002) / 2 + 0.0001, T / 2, 0)))
        for sg: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W - 0.006 - over - 0.002, pageH, 0.0004), radius: 0.0001, bevelSegments: 1, material: "paper.pages:E9E1CC"),
                  Xform(translation: V3(0.0025, T / 2, sg * (D / 2 - over + 0.0001))))
        }
        // Gold-stamped title bars and a thin border on the front cover; red silk ribbon marker out of the head.
        for (k, w) in [0.11, 0.08, 0.05].enumerated() {
            m.add(Prim.roundedBox(V3(Float(w), 0.0004, 0.0065), radius: 0.0001, bevelSegments: 1, material: "metal.brass-aged"),
                  Xform(translation: V3(0.005, T + 0.0001, D * 0.30 - Float(k) * 0.012)))
        }
        for (x, z, w, d) in [(0.0, D / 2 - 0.016, W - 0.04, 0.0008), (0.0, -D / 2 + 0.016, W - 0.04, 0.0008), (-W / 2 + 0.02, 0.0, 0.0008, D - 0.032), (W / 2 - 0.02, 0.0, 0.0008, D - 0.032)] as [(Float, Float, Float, Float)] {
            m.add(Prim.roundedBox(V3(w, 0.0004, d), radius: 0.0001, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(x + 0.002, T + 0.0001, z)))
        }
        m.add(Prim.roundedBox(V3(0.007, 0.0008, 0.020), radius: 0.0003, bevelSegments: 1, material: "fabric.webbing:A81C2A"),
              Xform(translation: V3(0.03, T / 2, D / 2 + 0.006), rotation: simd_quatf(degrees: 6, axis: .up)))
        // Worn corners: lighter cloth showing where the boards are bumped.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.012, 0.0004, 0.012), radius: 0.001, bevelSegments: 1, material: "fabric.wool:B88277"),
                  Xform(translation: V3(0.002 + sx * (W / 2 - 0.008), T + 0.00005, sz * (D / 2 - 0.008))))
        } }
        groundAO(&m)
        return LODModel(m)
    }
}
