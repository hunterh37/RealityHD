import simd
import Foundation

/// Pothole in worn asphalt, 1.0 x 1.0 m: a 45 cm ragged bowl 4 cm deep, exposed gravel base, water
/// pooled at the low point and broken edge fragments around the rim.
public struct Pothole: RealAsset {
    public static let id = "pothole"
    public static let summary = "Pothole in worn asphalt, 1 x 1 m: ragged 45 cm bowl with gravel base, pooled water and broken rim."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, distance: 1.5, studio: true)

    /// Bowl radius (m).
    public var radius: Float = 0.23
    /// Depth below the road surface (m).
    public var depth: Float = 0.045
    /// Road thickness at the border (m).
    public var thickness: Float = 0.06
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let lobes = (0..<5).map { _ in rng.float(0.8...1.25) }, phase = rng.float(0...6.28)
        func rim(_ a: Float) -> Float {
            radius * (1 + 0.18 * sin(a * 3 + phase) * lobes[0] + 0.1 * sin(a * 5 + phase * 2) * lobes[1] - 0.1)
        }
        GK.field(&m, w: 1.0, d: 1.0, edge: thickness, segments: 56, "asphalt.worn") { p in
            let r = simd_length(p), a = atan2(p.y, p.x), R = rim(a)
            if r >= R { return 0 }
            let t = r / R
            return -(thickness - 0.012) * (1 - t * t * t)
        }
        // Gravel base and water at the bottom of the bowl.
        let floorY = thickness - (thickness - 0.012) + 0.002
        m.add(Prim.superellipsoid(V3(radius * 1.4, 0.006, radius * 1.4), exponent: 2, subdivisions: 6, material: "ground.gravel"),
              Xform(translation: V3(0, floorY, 0)))
        m.add(Prim.superellipsoid(V3(radius * 0.9, 0.003, radius * 0.7), exponent: 2, subdivisions: 6, material: "ground.puddle"),
              Xform(translation: V3(radius * 0.1, floorY + 0.004, 0), rotation: simd_quatf(angle: phase, axis: .up)))
        // Broken edge fragments and loose chips.
        for _ in 0..<14 {
            let a = rng.float(0...6.28), r = rim(a) + rng.float(0.01...0.12)
            m.add(Prim.superellipsoid(V3(rng.float(0.02...0.05), 0.012, rng.float(0.02...0.04)), exponent: 3, subdivisions: 3, material: "asphalt.worn"),
                  Xform(translation: V3(cos(a) * r, thickness + 0.004, sin(a) * r), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        return GK.finish(&m, ao: 0.08)
    }
}
