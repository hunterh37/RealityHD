import simd
import Foundation

/// Department-store mannequin head, 26 cm on its neck: a smooth fibreglass cranium with a square jaw,
/// cheekbones, a straight nose, closed painted lips, shallow painted eyes with lash lines, sculpted ears
/// and a moulded shoulder stub. Ivory gloss with a visible side seam and a dark mounting socket.
/// Face on +Z, centered on X/Z, base at y = 0.
public struct MannequinHead: RealAsset {
    public static let id = "mannequin-head"
    public static let summary = "Fibreglass mannequin head, 26 cm: smooth ivory cranium, square jaw, straight nose, painted lips and eyes, ears, neck and side seam."
    public static let tags = ["prop", "decor", "mannequin", "retail", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 6, distance: 0.52, studio: true)

    /// Overall height (m).
    public var height: Float = 0.260
    /// Material keys.
    public var skin: MaterialKey = "plastic.gloss:E9E3D5"
    public var skinShadow: MaterialKey = "plastic.gloss:D8D1C1"
    public var paint: MaterialKey = "plastic.gloss:2A2522"
    public var lip: MaterialKey = "plastic.gloss:B98C84"
    public var seam: MaterialKey = "plastic.matte:8A8375"
    public var socket: MaterialKey = "plastic.matte:171615"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let s = 80

        // Neck: a short tapered column with a rounded shoulder stub and a socket in the base.
        let neckPts: [V2] = [V2(0, 0.000), V2(0.036, 0.000), V2(0.034, 0.012), V2(0.031, 0.040),
                             V2(0.033, 0.060), V2(0.040, 0.072), V2(0, 0.076)]
        m.add(Prim.lathe(Profile.smooth(neckPts, per: 3), segments: s, seamTile: 0.12, material: skin))
        m.add(Prim.cylinder(radius: 0.014, height: 0.003, bevel: 0.0008, segments: 32, material: socket),
              Xform(translation: V3(0, 0.0005, 0)))

        // Cranium: egg-shaped lathe, deeper front to back.
        let headPts: [V2] = [V2(0, 0.058), V2(0.040, 0.060), V2(0.057, 0.076), V2(0.068, 0.104),
                             V2(0.073, 0.140), V2(0.072, 0.176), V2(0.064, 0.208), V2(0.046, 0.232),
                             V2(0.024, 0.248), V2(0, 0.252)]
        m.add(Prim.lathe(Profile.smooth(headPts, per: 3), segments: s, seamTile: 0.16, material: skin),
              Xform(scale: V3(1.0, 1.0, 1.14)))

        // Jaw block and chin: square but soft, the mannequin read.
        m.add(Prim.superellipsoid(V3(0.108, 0.050, 0.094), exponent: 3.4, subdivisions: 4, material: skin),
              Xform(translation: V3(0, 0.106, 0.020)))
        m.add(Prim.superellipsoid(V3(0.050, 0.030, 0.038), exponent: 2.6, subdivisions: 4, material: skin),
              Xform(translation: V3(0, 0.091, 0.061)))

        // Cheekbones and cheek pads.
        for sx: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.034, 0.020, 0.034), exponent: 2.4, subdivisions: 3, material: skin),
                  Xform(translation: V3(sx * 0.047, 0.146, 0.050),
                        rotation: simd_quatf(angle: sx * -0.42, axis: V3(0, 1, 0))))
            m.add(Prim.superellipsoid(V3(0.032, 0.034, 0.030), exponent: 2.5, subdivisions: 3, material: skin),
                  Xform(translation: V3(sx * 0.040, 0.118, 0.055)))
            // Ear: a shallow outer shell and a small lobe.
            m.add(Prim.superellipsoid(V3(0.016, 0.040, 0.022), exponent: 2.3, subdivisions: 3, material: skin),
                  Xform(translation: V3(sx * 0.075, 0.160, -0.002),
                        rotation: simd_quatf(angle: sx * 0.18, axis: V3(0, 0, 1))))
            m.add(Prim.torus(major: 0.010, minor: 0.0022, segments: 32, sides: 10, material: skinShadow),
                  Xform(translation: V3(sx * 0.079, 0.160, -0.002),
                        rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0)), scale: V3(0.55, 1.5, 1)))
        }

        // Brow ridge, then painted brows.
        m.add(Prim.superellipsoid(V3(0.086, 0.014, 0.018), exponent: 4.0, subdivisions: 3, material: skin),
              Xform(translation: V3(0, 0.184, 0.066)))
        for sx: Float in [-1, 1] {
            let brow = Prim.superellipsoid(V3(0.030, 0.0045, 0.004), exponent: 2.4, subdivisions: 3, material: paint)
            m.add(brow, Xform(translation: V3(sx * 0.030, 0.187, 0.077),
                              rotation: simd_quatf(angle: sx * 0.10, axis: V3(0, 0, 1))))
        }

        // Eye sockets: a shallow almond depression and a painted lash line, eyes closed.
        for sx: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.031, 0.017, 0.008), exponent: 2.2, subdivisions: 3, material: skinShadow),
                  Xform(translation: V3(sx * 0.030, 0.165, 0.071),
                        rotation: simd_quatf(angle: sx * 0.12, axis: V3(0, 0, 1))))
            let lashPath: [V3] = (0...6).map { j in
                let t = Float(j) / 6
                return V3(sx * (0.016 + 0.030 * t), 0.166 + 0.006 * sin(t * .pi * 0.9) - 0.004 * t, 0.079)
            }
            m.add(Prim.tube(lashPath, radii: lashPath.map { _ in 0.00115 }, sides: 6, seamTile: 0.01, material: paint))
        }

        // Nose: bridge, tip and wings.
        m.add(Prim.superellipsoid(V3(0.017, 0.062, 0.022), exponent: 2.8, subdivisions: 4, material: skin),
              Xform(translation: V3(0, 0.158, 0.078), rotation: simd_quatf(angle: -0.10, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(0.022, 0.018, 0.020), exponent: 2.4, subdivisions: 4, material: skin),
              Xform(translation: V3(0, 0.135, 0.092)))
        for sx: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.012, 0.012, 0.014), exponent: 2.3, subdivisions: 3, material: skin),
                  Xform(translation: V3(sx * 0.012, 0.136, 0.086)))
        }

        // Lips: two closed, softly painted pads and a shadow line between them.
        m.add(Prim.superellipsoid(V3(0.044, 0.010, 0.014), exponent: 2.6, subdivisions: 3, material: lip),
              Xform(translation: V3(0, 0.115, 0.080)))
        m.add(Prim.superellipsoid(V3(0.038, 0.008, 0.012), exponent: 2.6, subdivisions: 3, material: lip),
              Xform(translation: V3(0, 0.106, 0.079)))
        m.add(Prim.superellipsoid(V3(0.040, 0.0014, 0.0014), exponent: 2, subdivisions: 2, material: paint),
              Xform(translation: V3(0, 0.111, 0.087)))

        // Moulded side seams: a fine recessed line from the crown to the jaw on both sides.
        for sx: Float in [-1, 1] {
            let path: [V3] = (0...9).map { j in
                let t = Float(j) / 9
                let y = 0.235 - t * 0.135
                let r = 0.066 + 0.010 * sin(t * .pi)
                return V3(sx * r, y, -0.002 + 0.010 * t)
            }
            m.add(Prim.tube(path, radii: path.map { _ in 0.00075 }, sides: 5, seamTile: 0.01, material: seam))
        }

        // A small moulded neck join line.
        m.add(Prim.torus(major: 0.036, minor: 0.0012, segments: 48, sides: 8, material: seam),
              Xform(translation: V3(0, 0.065, 0), scale: V3(1.0, 1.0, 1.12)))

        let b = m.bounds
        let k = height / max(b.max.y - b.min.y, 1e-5)
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2 * k, -b.min.y * k, -(b.min.z + b.max.z) / 2 * k),
                               scale: V3(k, k, k)))
        groundAO(&m, height: 0.02, floor: 0.3)
        return LODModel(m)
    }
}
