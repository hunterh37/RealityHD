import simd
import Foundation

/// Pallet of concrete pavers, 1.1 x 0.9 x 1.0 m: ten layers of grey 6 cm pavers strapped with two steel
/// bands on a pine pallet, corner boards, a shipping label and a loose paver leaning at the side.
public struct PaverPallet: RealAsset {
    public static let id = "paver-pallet"
    public static let summary = "Pallet of concrete pavers, 1.1 x 0.9 x 1 m: ten strapped layers on a pine pallet with a loose paver."
    public static let tags = ["prop", "ground", "street", "construction", "outdoor", "concrete"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 2.2, studio: true)

    /// Layers.
    public var layers = 10
    /// Paver thickness (m).
    public var thickness: Float = 0.08
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w: Float = 1.1, d: Float = 0.9, pallet: Float = 0.14
        // Pallet: 3 stringers, 5 top boards, 3 bottom boards.
        for i in 0..<3 {
            GK.box(&m, V3(Float(i - 1) * (w / 2 - 0.05), pallet / 2, 0), V3(0.1, pallet - 0.044, d), "wood.pine-aged", r: 0.003)
        }
        for i in 0..<5 {
            GK.box(&m, V3(0, pallet - 0.011, (Float(i) - 2) * (d - 0.1) / 4), V3(w, 0.022, 0.1), "wood.pine-aged", r: 0.003)
        }
        for i in 0..<3 {
            GK.box(&m, V3(0, 0.011, (Float(i) - 1) * (d - 0.1) / 2), V3(w, 0.022, 0.1), "wood.pine-aged", r: 0.003)
        }
        // Paver layers: 2 x 2 blocks of 1.0 x 0.8 footprint with a 5 mm seam, alternating tone.
        let pw: Float = 1.0, pd: Float = 0.8
        for l in 0..<layers {
            let y = pallet + Float(l) * thickness
            let tone = rng.pick([0x9C9A96, 0x8E8C88, 0xA3A19C])
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                GK.box(&m, V3(sx * (pw / 4 + 0.0025), y + thickness / 2, sz * (pd / 4 + 0.0025)), V3(pw / 2 - 0.005, thickness - 0.003, pd / 2 - 0.005),
                       "concrete.rough:" + String(format: "%06X", tone), r: 0.004, yaw: rng.float(-0.5...0.5))
            }}
        }
        let topY = pallet + Float(layers) * thickness
        // Two steel bands over the stack and a shipping label.
        for z: Float in [-0.22, 0.22] {
            GK.box(&m, V3(0, topY + 0.001, z), V3(pw + 0.012, 0.003, 0.016), "metal.steel", r: 0.001)
            for s: Float in [-1, 1] { GK.box(&m, V3(s * (pw / 2 + 0.003), pallet + Float(layers) * thickness / 2, z), V3(0.003, Float(layers) * thickness, 0.016), "metal.steel", r: 0.001) }
        }
        GK.box(&m, V3(0, pallet + Float(layers) * thickness * 0.55, pd / 2 + 0.002), V3(0.2, 0.14, 0.003), "paint.field-white", r: 0.001)
        // Loose paver leaning on the pallet end.
        GK.box(&m, V3(w / 2 + 0.1, 0.2, 0.05), V3(0.2, 0.4, 0.06), "concrete.rough:9C9A96", r: 0.004, yaw: 90)
        return GK.finish(&m, ao: 0.1)
    }
}
