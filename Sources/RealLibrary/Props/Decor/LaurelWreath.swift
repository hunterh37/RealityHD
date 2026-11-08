import simd
import Foundation

/// Gold laurel wreath, 24 cm across: two ribbon-like branches in a near-closed ring, 48 tapered leaves
/// in alternating polished and aged gold, six berries at the front and a small clasp at the back. Lays in
/// the XZ plane, base at y = 0, centered on X/Z; the gap sits at -Z (back of the head).
public struct LaurelWreath: RealAsset {
    public static let id = "laurel-wreath"
    public static let summary = "Gold laurel wreath, 24 cm: two branch ribbons, 48 tapered leaves in polished and aged gold, berries and a back clasp."
    public static let tags = ["prop", "decor", "jewelry", "classical", "handheld"]
    public static let budget = 10_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 36, distance: 0.42, studio: true)

    /// Ring radius and branch wire radius (m).
    public var radius: Float = 0.118
    public var wire: Float = 0.0032
    /// Leaves per branch and leaf length (m).
    public var leaves: Int = 24
    public var leafLength: Float = 0.040
    /// Material keys.
    public var gold: MaterialKey = "metal.gold-leaf"
    public var aged: MaterialKey = "metal.brass-aged"
    public var berry: MaterialKey = "metal.brass"
    public init() {}

    private func leafSurface(_ length: Float, _ width: Float, _ material: MaterialKey) -> Surface {
        let path: [V3] = (0...6).map { j in
            let t = Float(j) / 6
            return V3(t * length, 0.010 * sin(t * .pi * 0.85) + 0.004 * t, 0.006 * t * t)
        }
        let scales: [Float] = [0.55, 1.0, 1.0, 0.86, 0.62, 0.34, 0.04]
        let profile = Shape2D.superellipse(width, 0.0014, exponent: 2.1, segments: 10)
        return Prim.sweep(profile, along: path, up: .up, scales: scales, caps: true,
                          grainAlongPath: true, material: material)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y0: Float = 0.004

        // Branch ribbons: a near-closed ring with a small gap at the back (-Z).
        let gap: Float = 0.10
        for (start, end) in [(gap, Float.pi - 0.03), (Float.pi + 0.03, 2 * .pi - gap)] {
            let steps = 40
            let path: [V3] = (0...steps).map { j in
                let a = start + (end - start) * Float(j) / Float(steps)
                return V3(cos(a) * radius, y0, -sin(a) * radius)
            }
            m.add(Prim.tube(path, radii: path.map { _ in wire }, sides: 12, seamTile: 0.05, material: aged))
        }

        // Clasp at the back.
        m.add(Prim.roundedBox(V3(0.016, 0.006, 0.010), radius: 0.002, bevelSegments: 2, material: gold),
              Xform(translation: V3(0, y0 + 0.002, radius * 0.99)))

        // Leaves: two rows, one on each side of the branch, alternating material.
        for i in 0..<leaves {
            let a = Float(i) / Float(leaves) * 2 * .pi + 0.12
            if a > .pi - 0.12 && a < .pi + 0.12 { continue }
            let base = V3(cos(a) * radius, y0, -sin(a) * radius)
            let outward = simd_quatf(angle: a, axis: V3(0, 1, 0))
            for side: Float in [-1, 1] {
                let tilt = side * 0.62 + rng.float(-0.06...0.06)
                let q = outward * simd_quatf(angle: tilt, axis: V3(0, 1, 0))
                    * simd_quatf(angle: side * 0.20, axis: V3(1, 0, 0))
                let leaf = leafSurface(leafLength * rng.vary(1, 0.10), 0.011 * rng.vary(1, 0.12),
                                       i % 3 == 0 ? aged : gold)
                m.add(leaf, Xform(translation: base + V3(0, 0.003, 0), rotation: q))
            }
        }

        // Berries: two clusters of three at the front sides.
        for side: Float in [-1, 1] {
            let a = side * 0.36
            for j in 0..<3 {
                let aa = a + Float(j - 1) * 0.07
                let p = V3(cos(aa) * (radius + 0.004), y0 + 0.004 + Float(j % 2) * 0.004, -sin(aa) * (radius + 0.004))
                m.add(Prim.superellipsoid(V3(0.0085, 0.0085, 0.0085), exponent: 2, subdivisions: 3, material: berry),
                      Xform(translation: p))
            }
        }

        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.006, floor: 0.25)
        return LODModel(m)
    }
}
