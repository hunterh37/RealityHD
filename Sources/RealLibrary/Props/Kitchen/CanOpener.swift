import simd
import Foundation

/// Hand squeeze can opener lying on its side: two crossed stamped-steel arms riveted at a pivot post,
/// black grip sleeves, a cutting wheel and a drive wheel at the jaws, and a butterfly turning key. Length along Z.
public struct CanOpener: RealAsset {
    public static let id = "can-opener"
    public static let summary = "Can opener: crossed steel arms on a pivot rivet, grip sleeves, cutting wheel, drive wheel, butterfly key."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.55, studio: true)

    /// Arm and key steel.
    public var steelMaterial: MaterialKey = "metal.steel"
    /// Wheel and rivet metal.
    public var wheelMaterial: MaterialKey = "metal.stainless"
    /// Grip sleeve plastic.
    public var gripMaterial: MaterialKey = "plastic.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yA: Float = 0.0055, yB: Float = 0.0105
        let pts: [(Float, Float)] = [(-0.095, 0.026), (-0.05, 0.0155), (0, 0.0045), (0.03, -0.0025), (0.065, -0.008), (0.085, -0.0105)]
        let armA = catmull(DD1BKit.xz(pts, y: yA), per: 6)
        let armB = catmull(DD1BKit.xz(pts.map { ($0.0, -$0.1) }, y: yB), per: 6)
        let armProfile = Shape2D.roundedRect(0.0036, 0.014, radius: 0.0012)
        let gripProfile = Shape2D.roundedRect(0.0092, 0.0165, radius: 0.0035)
        for (arm, mat) in [(armA, 0), (armB, 1)] {
            m.add(Prim.sweep(armProfile, along: arm, up: .up, caps: true, material: steelMaterial))
            let g = arm.filter { $0.x < -0.040 }
            m.add(Prim.sweep(gripProfile, along: g, up: .up, caps: true, material: gripMaterial))
            _ = mat
        }
        m.add(Prim.cylinder(radius: 0.0035, height: 0.0112, bevel: 0.0006, segments: 16, material: wheelMaterial), Xform(translation: V3(0.019, 0.0015, 0)))
        rivet(&m, at: V3(0.019, 0.0127, 0), normal: .up, radius: 0.0042, material: wheelMaterial)
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        m.add(Prim.cylinder(radius: 0.0108, height: 0.0016, bevel: 0.0005, segments: 40, material: wheelMaterial), Xform(translation: V3(0.088, 0.0108, -0.0125), rotation: toZ))
        m.add(Prim.cylinder(radius: 0.0085, height: 0.006, bevel: 0.0008, segments: 28, material: wheelMaterial), Xform(translation: V3(0.086, 0.0105, 0.0075), rotation: toZ))
        let kz: Float = 0.0082
        m.add(Prim.cylinder(radius: 0.0055, height: 0.0035, bevel: 0.0007, segments: 16, material: steelMaterial), Xform(translation: V3(0.066, 0.0123, kz)))
        m.add(Prim.tube(DD1BKit.xz([(0.066, kz)], y: 0.0150) + [V3(0.066, 0.0262, kz)], radii: [0.0021, 0.0021], sides: 10, seamTile: 0.02, material: steelMaterial, capEnd: true))
        let wing = Shape2D.rounded(DD1BKit.v2([(-0.004, -0.003), (-0.009, -0.014), (-0.0055, -0.0255), (0.0055, -0.0255), (0.009, -0.014), (0.004, -0.003),
                                               (0.004, 0.003), (0.009, 0.014), (0.0055, 0.0255), (-0.0055, 0.0255), (-0.009, 0.014), (-0.004, 0.003)]), radius: 0.0025, segments: 3)
        m.add(DD1BKit.flat(wing, thick: 0.0036, y: 0.027, bevel: 0.0012, material: steelMaterial), Xform(translation: V3(0.066, 0, kz)))
        return DD1BKit.finish(m, rng: &rng)
    }
}
