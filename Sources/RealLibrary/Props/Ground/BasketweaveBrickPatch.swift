import simd
import Foundation

/// Clay brick basketweave paving, 1.0 x 1.0 m: 20 x 10 cm pavers laid in pairs, alternating direction
/// every 20 cm, on a sand bed, with tone variation, one stained brick and swept joint sand.
public struct BasketweaveBrickPatch: RealAsset {
    public static let id = "basketweave-brick-patch"
    public static let summary = "Clay brick paving, 1 x 1 m: 20 x 10 cm pavers in a basketweave pattern on sand with swept joints."
    public static let tags = ["prop", "street", "urban", "outdoor", "ground", "brick"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.3, studio: true)

    /// Patch size (m).
    public var size: Float = 1.0
    /// Paver thickness (m).
    public var thickness: Float = 0.065
    /// Tones (sRGB hex).
    public var tones: [UInt32] = [0xA2523B, 0x8E4733, 0xB0614A, 0x7C3F30]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let joint: Float = 0.006, cell: Float = 0.2, pw: Float = 0.1 - joint
        GK.slab(&m, w: size, d: size, h: thickness * 0.5, "ground.sand", r: 0.004)
        let n = Int(size / cell)
        for j in 0..<n { for i in 0..<n {
            let cx = -size / 2 + (Float(i) + 0.5) * cell, cz = -size / 2 + (Float(j) + 0.5) * cell
            let horizontal = (i + j) % 2 == 0
            for k in 0..<2 {
                let o = (Float(k) - 0.5) * (cell / 2)
                let (dx, dz) = horizontal ? (cell - joint, pw) : (pw, cell - joint)
                let (px, pz) = horizontal ? (cx, cz + o) : (cx + o, cz)
                let h = thickness * rng.float(0.96...1.03)
                let stained = rng.chance(0.04)
                let mat = stained ? "paver.clay-stained" : "paver.clay:" + String(format: "%06X", rng.pick(tones))
                m.add(Prim.roundedBox(V3(dx, h, dz), radius: 0.004, bevelSegments: 1, material: mat),
                      Xform(translation: V3(px, h / 2, pz), rotation: simd_quatf(degrees: rng.float(-0.8...0.8), axis: .up)))
            }
        }}
        return GK.finish(&m, ao: 0.06)
    }
}
