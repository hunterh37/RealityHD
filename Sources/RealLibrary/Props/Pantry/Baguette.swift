import simd
import Foundation

/// Baguette: everyday pantry, bakery. 65 cm long and 7 cm wide: tapered crust with five overlapping
/// diagonal grigne cuts, each with a raised ear, flour dusting, and one end torn off to show open crumb.
public struct Baguette: RealAsset {
    public static let id = "baguette"
    public static let summary = "Baguette with diagonal scored ears, tapered ends and a torn end."
    public static let tags = ["prop", "interior", "pantry", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 32, distance: 0.95, studio: true)

    /// Crust.
    public var crust: MaterialKey = "food.bread-crust"
    /// Darker ears and blisters.
    public var crustDark: MaterialKey = "food.bread-crust-toasted"
    /// Crumb.
    public var crumb: MaterialKey = "food.bread-crumb"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = DD1IPantry.bakery(length: 0.6, hUp: 0.055, hDown: 0.008, w: 0.033, nTop: 2.6, start: .cut, end: .closed(0.1),
                                  slashes: 5, slashHalfLen: 0.05, slashHalfSpan: 0.02, slashRange: 0.2...0.82,
                                  torn: true, flour: 60, crust: crust, crustDark: crustDark, crumb: crumb, flourKey: "food.flour", seed: seed)
        for _ in 0..<7 {
            let x = rng.float(-0.22...0.22), z = rng.float(-0.012...0.012)
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.02), 0.0016, rng.float(0.006...0.01)), exponent: 3, subdivisions: 3, material: crustDark),
                  Xform(translation: V3(x, 0.066 - 0.0016, z)))
        }
        for _ in 0..<6 {
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.005), 0.002, rng.float(0.002...0.004)), exponent: 3, subdivisions: 2, material: crumb),
                  Xform(translation: V3(rng.float(0.301...0.318), 0.001, rng.float(-0.03...0.03)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        m.add(Prim.superellipsoid(V3(0.5, 0.003, 0.04), exponent: 4, subdivisions: 4, material: "food.bread-crust-toasted"), Xform(translation: V3(0, 0.0016, 0)))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
