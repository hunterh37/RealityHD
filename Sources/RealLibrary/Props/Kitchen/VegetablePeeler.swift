import simd
import Foundation

/// Swivel Y-peeler lying on its side: turned stainless handle, ferrule, stem forking into two prongs that
/// pivot a slotted carbon-steel blade on pins, and a potato-eye scoop on one prong. Length along Z.
public struct VegetablePeeler: RealAsset {
    public static let id = "vegetable-peeler"
    public static let summary = "Y swivel peeler: turned stainless handle, ferrule, forked yoke with pivot pins, slotted blade, eye scoop."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.4, studio: true)

    /// Handle finish.
    public var handleMaterial: MaterialKey = "metal.satin-aluminum"
    /// Yoke finish.
    public var yokeMaterial: MaterialKey = "metal.stainless"
    /// Blade finish.
    public var bladeMaterial: MaterialKey = "metal.knife-blade"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y: Float = 0.0095
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        let hp: [(Float, Float)] = [(0, 0), (0.0075, 0), (0.0092, 0.004), (0.0095, 0.03), (0.0088, 0.065), (0.0075, 0.092), (0.0058, 0.1038), (0.0042, 0.1052), (0, 0.1052)]
        m.add(turned(hp, segments: 32, material: handleMaterial, seamTile: 0.06, grainVertical: true), Xform(translation: V3(-0.085, y, 0), rotation: toX))
        for (x, r): (Float, Float) in [(0.0, 0.0080), (-0.02, 0.0089), (-0.04, 0.0093)] {
            m.add(Prim.torus(major: r, minor: 0.0004, segments: 32, sides: 5, material: handleMaterial), Xform(translation: V3(x, y, 0), rotation: toX))
        }
        let fp: [(Float, Float)] = [(0, 0), (0.0068, 0), (0.0072, 0.002), (0.0072, 0.011), (0.0054, 0.0128), (0, 0.0130)]
        m.add(turned(fp, segments: 24, material: yokeMaterial, seamTile: 0.04, grainVertical: true), Xform(translation: V3(0.0195, y, 0), rotation: toX))
        m.add(Prim.tube(DD1BKit.xz([(0.030, 0), (0.044, 0)], y: y), radii: [0.0036, 0.0036], sides: 12, seamTile: 0.03, material: yokeMaterial, capEnd: true))
        for s: Float in [-1, 1] {
            let prong = catmull(DD1BKit.xz([(0.042, 0), (0.052, s * 0.004), (0.066, s * 0.0115), (0.084, s * 0.0168), (0.0865, s * 0.0168)], y: y), per: 6)
            m.add(Prim.tube(prong, radii: prong.map { _ in 0.0018 }, sides: 8, seamTile: 0.02, material: yokeMaterial, capEnd: true))
            let blade = [V2(0.0765, s * 0.003), V2(0.0885, s * 0.003), V2(0.0885, s * 0.0168), V2(0.0765, s * 0.0140)]
            m.add(DD1BKit.flat(Shape2D.rounded(blade, radius: 0.0004, segments: 2), thick: 0.0008, y: y, bevel: 0.0003, material: bladeMaterial))
            rivet(&m, at: V3(0.0865, y, s * 0.0180), normal: V3(0, 0, s), radius: 0.0021, material: yokeMaterial)
        }
        let eye = catmull(DD1BKit.xz([(0.058, -0.0090), (0.0625, -0.0150), (0.0685, -0.0182), (0.0750, -0.0188)], y: y), per: 5)
        m.add(Prim.tube(eye, radii: eye.indices.map { 0.0016 - 0.0009 * Float($0) / Float(eye.count) }, sides: 8, seamTile: 0.02, material: yokeMaterial, capEnd: true))
        return DD1BKit.finish(m, rng: &rng)
    }
}
