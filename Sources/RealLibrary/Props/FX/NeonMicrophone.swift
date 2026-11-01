import simd
import Foundation

/// Neon microphone: Matte black body, chrome mesh head, cyan neon ring. Parts: Black matte handle, Chrome mesh grille ball, Grille collar, Thin emissive ring, Pop-grid band.
public struct NeonMicrophone: RealAsset {
    public static let id = "neon-microphone"
    public static let summary = "Handheld stage microphone, 19 cm: matte black handle, chrome mesh grille, thin emissive ring. Grip origin at handle center, grille along +Y."
    public static let tags = ["prop", "handheld", "fx", "metal", "light"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Neon ring material (an emissive.* key).
    public var ring: MaterialKey = "emissive.thruster-cyan"
    /// Overall length in meters; bottom of the handle at -0.08, grip center near the origin.
    public var length: Float = 0.19
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let black: MaterialKey = "plastic.matte:121214", chrome: MaterialKey = "metal.chrome", mesh: MaterialKey = "metal.basket-mesh"
        let b: Float = -0.08, hTop: Float = 0.04
        // Handle: slightly tapered, rounded butt end, a step ring near the base.
        m.add(turned([(0, b), (0.0115, b), (0.0135, b + 0.003), (0.0142, b + 0.008), (0.0142, b + 0.012), (0.0136, b + 0.0135), (0.0136, b + 0.018),
                      (0.0148, b + 0.06), (0.0166, hTop - 0.01), (0.0182, hTop), (0, hTop)], segments: 48, material: black, seamTile: 0.1))
        // Chrome collar with the thin emissive ring seated in a groove above it.
        m.add(turned([(0.0182, hTop), (0.0215, hTop), (0.0222, hTop + 0.002), (0.0222, hTop + 0.008), (0.021, hTop + 0.012), (0.0185, hTop + 0.0125), (0, hTop + 0.0125)], segments: 48, material: chrome))
        m.add(Prim.torus(major: 0.0183, minor: 0.0019, segments: 56, sides: 8, material: ring), Xform(translation: V3(0, hTop - 0.0215, 0)))
        // Grille: mesh ball with chrome base band, equator seam and cap.
        let r: Float = 0.027
        let cy = length + b - r
        var pts: [(Float, Float)] = []
        for i in 0...14 {
            let ang = Float(i) / 14 * (.pi * 0.5 + 1.15) - 1.15   // from the neck up over the pole
            pts.append((r * cos(ang), cy + r * sin(ang)))
        }
        pts[0].0 = max(pts[0].0, 0.0185)
        pts[pts.count - 1].0 = 0
        m.add(turned(pts.map { ($0.0, $0.1) }, segments: 56, material: mesh, seamTile: 0.2))
        m.add(turned([(0.0222, hTop + 0.0125), (r * 0.78, hTop + 0.0125), (r * 0.8, hTop + 0.016), (r * 0.74, hTop + 0.0215), (0.0222, hTop + 0.0215)], segments: 56, material: chrome))
        m.add(Prim.torus(major: r * 0.995, minor: 0.0013, segments: 56, sides: 6, material: chrome), Xform(translation: V3(0, cy, 0)))
        return LODModel(m)
    }
}
