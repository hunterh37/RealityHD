import simd
import Foundation

/// Blanking panel: New, matte black molded ABS, subtle texture, 1U tool-less snap-in. Parts: 19 in flange plate with rail ears, stiffening ribs on back, snap latches, molded texture.
public struct BlankingPanel: RealAsset {
    public static let id = "blanking-panel"
    public static let summary = "1U tool-less snap-in rack blanking panel in matte black plastic with rail ears, rear stiffening ribs and snap latches."
    public static let tags = ["prop"]
    public static let budget = 400
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.48, 0.044, 0.01)
    public init() {}

    /// Panel material.
    public var plastic: MaterialKey = "plastic.matte:1A1A1A"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let mat = plastic
        let w = size.x, h = size.y, d = size.z
        let zFront = d / 2 - 0.0016, t: Float = 0.002
        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey? = nil) {
            let mat = mat ?? self.plastic
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Front plate with a slightly thicker rolled top and bottom edge.
        box(V3(w, h - 0.0006, t), V3(0, h / 2, zFront - t / 2), r: 0.0008)
        box(V3(w - 0.03, 0.0025, 0.0014), V3(0, h - 0.0016, zFront - t - 0.0005))
        box(V3(w - 0.03, 0.0025, 0.0014), V3(0, 0.0016, zFront - t - 0.0005))
        // Rail ears: raised pads at each end with an oval mounting slot boss.
        for s: Float in [-1, 1] {
            box(V3(0.018, h - 0.006, 0.0008), V3(s * (w / 2 - 0.0125), h / 2, zFront + 0.0004))
            box(V3(0.012, 0.011, 0.0008), V3(s * (w / 2 - 0.0125), h / 2, zFront + 0.0012), mat: "plastic.matte:050505")
        }
        // Molded vertical grille ribs on the front, subtle.
        for i in 0..<7 {
            let x = -0.15 + Float(i) * 0.05
            box(V3(0.0016, h - 0.014, 0.0007), V3(x, h / 2, zFront + 0.00035), mat: "plastic.matte:262729")
        }
        // Rear stiffening ribs (long horizontal pair and cross ribs).
        for y in [h * 0.3, h * 0.7] {
            box(V3(w - 0.07, 0.0016, 0.005), V3(0, y, zFront - t - 0.0025))
        }
        for i in 0..<2 {
            let x = -0.06 + Float(i) * 0.12
            box(V3(0.0016, h - 0.012, 0.004), V3(x, h / 2, zFront - t - 0.002))
        }
        // Snap latches: flexing arms with hook tips at both ends, rear side.
        for s: Float in [-1, 1] {
            let x = s * (w / 2 - 0.045)
            box(V3(0.008, 0.016, 0.0016), V3(x, h / 2, -d / 2 + 0.0033))
            box(V3(0.008, 0.016, 0.0016), V3(x, h / 2, zFront - t - 0.0012))
            box(V3(0.008, 0.004, 0.0024), V3(x, h / 2 + 0.006, -d / 2 + 0.0012), mat: "plastic.matte:3A3B3D")
        }
        // Handling scuff: pale rub mark near one ear.
        box(V3(0.03 + 0.01 * Float(rng.next() % 100) / 100, 0.0015, 0.0003), V3(-0.12, h * 0.62, zFront + 0.00045), mat: "plastic.matte:4A4B4D")
        groundAO(&m)
        return LODModel(m)
    }
}
