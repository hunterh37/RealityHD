import simd
import Foundation

/// Sweet corn ear, 26 cm: a tapered pale cob packed with 208 golden kernels in offset rows, five curled
/// husk leaves peeling back from the lower half, a cut stalk and a tuft of silk at the tip. Kernels are
/// superellipsoid caps on the cob surface, so the ear reads as a lump with knobs from every angle.
/// Standing on +Y, base at y = 0, centered on X/Z.
public struct CornCob: RealAsset {
    public static let id = "corn-cob"
    public static let summary = "Sweet corn ear, 26 cm: 168 golden kernels in offset rows, five curled husk leaves, cut stalk and silk tuft."
    public static let tags = ["prop", "food", "kitchen", "handheld"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 0.62, studio: true)

    /// Cob length and maximum radius (m).
    public var length: Float = 0.215
    public var radius: Float = 0.031
    /// Kernel count around and along the ear.
    public var columns: Int = 14
    public var rows: Int = 12
    /// Material keys.
    public var kernel: MaterialKey = "food.lemon-flesh:F2C14E"
    public var kernelDark: MaterialKey = "food.lemon-flesh:E0A83A"
    public var cob: MaterialKey = "food.banana-peel-section:E6D7A6"
    public var husk: MaterialKey = "food.stem-green:8C9A58"
    public var huskInner: MaterialKey = "food.lemon:7E8C46"
    public var silk: MaterialKey = "food.lemon-pith:E8D9B4"
    public init() {}

    /// Radius of the cob at normalized height `v` (0 base, 1 tip).
    private func profile(_ v: Float) -> Float {
        let tapered = pow(sin(.pi * min(1, max(0, 0.10 + 0.82 * v))), 0.42)
        return radius * max(0.10, tapered)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)

        // Cob core: a lathe with a blunt base and a tapered tip.
        let corePts: [V2] = (0...14).map { i in
            let v = Float(i) / 14
            return V2(profile(v) * 0.86, v * length)
        }
        m.add(Prim.lathe(Profile.smooth(corePts, per: 3), segments: 80, seamTile: 0.08, material: cob))

        // Kernels: offset rows of rounded wedges sitting on the cob surface.
        let cols = max(8, columns), rowCount = max(6, rows)
        let phase = rng.float(0...0.4)
        for r in 0..<rowCount {
            let v = (Float(r) + 0.5) / Float(rowCount)
            let rr = profile(v) * 1.005
            let y = 0.010 + v * (length - 0.014)
            let rowPhase = phase + (r % 2 == 0 ? 0 : .pi / Float(cols))
            let rowScale = 0.86 + 0.14 * sin(Float(r) * 0.9)
            for c in 0..<cols {
                let a = Float(c) / Float(cols) * 2 * .pi + rowPhase
                let mat = (rng.chance(0.16) ? kernelDark : kernel)
                var k = Prim.superellipsoid(V3(0.0125, 0.0145, 0.0105) * rowScale, exponent: 2.3,
                                            subdivisions: 1, material: mat)
                k.uvs = k.uvs.map { $0 * 4 }
                k.computeTangents()
                let radial = V3(cos(a), 0, -sin(a))
                let q = simd_quatf(from: V3(0, 0, 1), to: radial) * simd_quatf(angle: rng.float(-0.08...0.08), axis: V3(0, 1, 0))
                m.add(k, Xform(translation: radial * (rr + 0.003) + V3(0, y, 0), rotation: q)
                    .jittered(&rng, deg: 2.5, offset: 0.0007))
            }
        }

        // Husk leaves: five blades curling out from the base, outer two shorter.
        let leafCount = 5
        for i in 0..<leafCount {
            let a = Float(i) / Float(leafCount) * 2 * .pi + 0.35
            let reach = 0.058 + Float(i % 3) * 0.012
            let top = 0.085 + Float(i % 2) * 0.035
            let path: [V3] = (0...7).map { j in
                let t = Float(j) / 7
                let bend = sin(t * .pi * 0.9)
                let radial = 0.022 + reach * t
                return V3(cos(a) * radial, 0.012 + top * t + 0.018 * bend, -sin(a) * radial)
            }
            let scales: [Float] = [0.6, 1.0, 1.0, 0.9, 0.7, 0.45, 0.22, 0.03]
            let profile = Shape2D.superellipse(0.030, 0.0032, exponent: 2.1, segments: 10)
            let mat = i % 2 == 0 ? husk : huskInner
            m.add(Prim.sweep(profile, along: path, up: .up, scales: scales, caps: true,
                             grainAlongPath: true, material: mat))
        }

        // Cut stalk at the base.
        m.add(Prim.cylinder(radius: 0.008, height: 0.016, bevel: 0.0015, segments: 24,
                            material: huskInner), Xform(translation: V3(0, -0.016, 0)))

        // Silk tuft: fine pale threads curling above the tip.
        for i in 0..<9 {
            let a = Float(i) / 9 * 2 * .pi + rng.float(-0.2...0.2)
            let r0 = rng.float(0.004...0.009)
            let path: [V3] = (0...4).map { j in
                let t = Float(j) / 4
                let r = r0 * (1 - 0.4 * t)
                return V3(cos(a + t * 0.5) * r, length + 0.004 + t * (0.030 + rng.float(0...0.012)),
                          -sin(a + t * 0.5) * r)
            }
            m.add(Prim.tube(path, radii: path.map { _ in 0.0009 }, sides: 5, seamTile: 0.01, material: silk))
        }

        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.02, floor: 0.45)
        return LODModel(m)
    }
}
