import simd
import Foundation

/// Retail mannequin bust, 0.60 m tall: glossy white plastic head and shoulders on a brushed steel pole with a
/// round base. Sculpted head (brow, nose, cheekbones, chin), separate neck and shoulder caps with seam lines.
/// Faces +Z.
public struct MannequinBust: RealAsset {
    public static let id = "mannequin-bust"
    public static let summary = "Mannequin bust: 60 cm glossy white plastic head and shoulders, sculpted face, seam lines, brushed steel stand with round base."
    public static let tags = ["prop", "retail", "furniture"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8)

    /// Plastic material key for the bust.
    public var plastic = "plastic.gloss"
    /// Stand metal key.
    public var steel = "metal.stainless"
    /// Seam gap material key.
    public var seam = "plastic.black"
    /// Base disc radius in meters.
    public var baseRadius: Float = 0.13
    /// Head centre height in meters.
    public var headY: Float = 0.49
    public init() {}

    @inline(__always) static func g(_ d: V3, _ c: V3, _ w: Float) -> Float {
        let q = d - simd_normalize(c)
        return exp(-simd_dot(q, q) / (w * w))
    }
    @inline(__always) static func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1); return t * t * (3 - 2 * t)
    }

    static func head(_ mat: String, n: Int) -> Surface {
        Prim.cubeSphere(subdivisions: n, material: mat) { d in
            var f: Float = 1
            let ax = abs(d.x)
            f += 0.30 * g(V3(ax, d.y, d.z), V3(0, -0.14, 1), 0.2)                 // nose
            f += 0.10 * g(V3(0, d.y, d.z), V3(0, -0.34, 1), 0.12) * (1 - ax)      // nose tip / alar base
            f += 0.055 * exp(-pow((d.y - 0.26) / 0.13, 2)) * pow(max(d.z, 0), 3)   // brow ridge
            f -= 0.05 * g(V3(ax, d.y, d.z), V3(0.42, 0.2, 0.88), 0.2)             // eye sockets
            f += 0.03 * g(V3(ax, d.y, d.z), V3(0.62, -0.12, 0.76), 0.25)          // cheekbones
            f += 0.06 * g(V3(0, d.y, d.z), V3(0, -0.68, 0.72), 0.26)              // chin
            f -= 0.045 * g(V3(0, d.y, d.z), V3(0, -0.45, 0.9), 0.14)              // under-lip dip
            let jaw = smooth(-0.1, -0.85, d.y)
            let width = 1 - 0.2 * jaw
            let depth = 1 - 0.1 * jaw * smooth(0.2, -0.6, d.z)
            return V3(0.08 * d.x * f * width, 0.108 * d.y * f * (d.y < 0 ? 0.97 : 1), 0.1 * d.z * f * depth)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        func add(_ s: Surface, _ p: V3, rx: Float = 0, rz: Float = 0, scale: V3 = V3(1, 1, 1)) {
            let q = simd_quatf(angle: rx, axis: V3(1, 0, 0)) * simd_quatf(angle: rz, axis: V3(0, 0, 1))
            m.add(s, Xform(translation: p, rotation: q, scale: scale))
        }
        // Stand: round base, pole, collar.
        add(Prim.cylinder(radius: baseRadius, height: 0.012, bevel: 0.004, segments: 56, material: steel), V3(0, 0, 0))
        add(Prim.lathe([V2(0.016, 0.012), V2(0.016, 0.02), V2(0.012, 0.03), V2(0.0115, 0.2), V2(0.0115, 0.24)],
                       segments: 40, seamTile: 0.3, material: steel), V3(0, 0, 0))
        add(Prim.lathe([V2(0.0, 0.205), V2(0.03, 0.205), V2(0.034, 0.209), V2(0.034, 0.222), V2(0.03, 0.226), V2(0.0, 0.226)],
                       segments: 40, seamTile: 0.3, material: steel), V3(0, 0, 0))
        // Torso (sloped trapezius, tapered chest) and shoulder caps.
        var torso = Prim.superellipsoid(V3(0.38, 0.2, 0.2), exponent: 2.6, subdivisions: 12, material: plastic)
        torso.deform { p in
            let xn = abs(p.x) / 0.19, yn = p.y / 0.1
            var q = p
            if yn > 0 { q.y -= 0.05 * Self.smooth(0.15, 1.0, xn) * yn }
            if yn < 0 { q.x *= 1 - 0.16 * min(-yn, 1); q.z *= 1 - 0.12 * min(-yn, 1) }
            return q
        }
        add(torso, V3(0, 0.305, 0))
        for sx: Float in [-1, 1] {
            add(Prim.superellipsoid(V3(0.085, 0.13, 0.15), exponent: 2.2, subdivisions: 8, material: plastic), V3(sx * 0.175, 0.27, 0), rz: -sx * 0.25)
            add(Prim.torus(major: 0.066, minor: 0.0018, segments: 32, sides: 6, material: seam),
                V3(sx * 0.136, 0.272, 0), rz: .pi / 2 - sx * 0.25)
        }
        // Neck and neck seam.
        add(Prim.lathe([V2(0.0, 0.37), V2(0.046, 0.37), V2(0.04, 0.4), V2(0.037, 0.44), V2(0.0, 0.44)], segments: 40,
                       seamTile: 0.3, material: plastic), V3(0, 0, 0.004))
        add(Prim.torus(major: 0.043, minor: 0.0017, segments: 32, sides: 6, material: seam), V3(0, 0.376, 0.004))
        add(Prim.torus(major: 0.043, minor: 0.0017, segments: 32, sides: 6, material: seam), V3(0, 0.395, 0.004), scale: V3(0.9, 1, 0.9))
        // Head, tilted slightly up, set forward over the neck.
        add(Self.head(plastic, n: 24), V3(0, headY, 0.012), rx: -0.05)
        return LODModel(m)
    }
}
