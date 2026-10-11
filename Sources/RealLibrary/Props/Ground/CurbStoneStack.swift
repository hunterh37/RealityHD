import simd
import Foundation

/// Stack of granite curb stones, 1.0 x 0.9 x 0.65 m: nine 15 x 30 x 100 cm stones in three layers
/// separated by pine spacers, saw-cut faces and dressed tops, on two timber bearers.
public struct CurbStoneStack: RealAsset {
    public static let id = "curb-stone-stack"
    public static let summary = "Stack of granite curb stones, 1 x 0.9 x 0.65 m: nine stones in three layers on spacers and bearers."
    public static let tags = ["prop", "ground", "street", "road", "construction", "outdoor", "stone"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 2.4, studio: true)

    /// Stone length, width, height (m).
    public var stone = V3(1.0, 0.15, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bearer: Float = 0.08
        for x: Float in [-0.35, 0.35] { GK.box(&m, V3(x, bearer / 2, 0), V3(0.1, bearer, 0.9), "wood.pine-aged", r: 0.003) }
        var y = bearer
        // Layers lie on their wide faces: 0.3 x 0.15 section, so a layer is 3 stones on edge, 0.15 high.
        for l in 0..<3 {
            for k in 0..<3 {
                let z = (Float(k) - 1) * (stone.y * 2 + 0.01) * 0.0 + (Float(k) - 1) * 0.31
                let tone = rng.pick([0x8E8E90, 0x7F7F82, 0x95918B, 0x6F6E70])
                let len = stone.x * rng.float(0.97...1.0)
                m.add(Prim.roundedBox(V3(len, stone.y, stone.z), radius: 0.01, bevelSegments: 1, material: "stone.granite-curb:" + String(format: "%06X", tone)),
                      Xform(translation: V3(rng.float(-0.02...0.02), y + stone.y / 2, z), rotation: simd_quatf(degrees: rng.float(-1.5...1.5), axis: .up)))
            }
            y += stone.y
            if l < 2 { for x: Float in [-0.35, 0.35] { GK.box(&m, V3(x, y + 0.02, 0), V3(0.06, 0.04, 0.9), "wood.pine-aged", r: 0.003) }; y += 0.04 }
        }
        // Mud splash on the lowest layer.
        GK.layer(&m, x: 0, z: 0.46, w: 0.8, d: 0.01, top: bearer + 0.05, "ground.mud")
        return GK.finish(&m, ao: 0.1)
    }
}
