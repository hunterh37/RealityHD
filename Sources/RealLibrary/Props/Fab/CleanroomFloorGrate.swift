import simd
import Foundation

/// Raised-floor grate panel: epoxy-coated steel frame with bearing bars and cross rods.
public struct CleanroomFloorGrate: RealAsset {
    public static let id = "cleanroom-floor-grate"
    public static let summary = "Raised-floor grate panel: epoxy-coated steel frame with bearing bars and cross rods."
    public static let tags = ["prop", "semiconductor"]
    public static let budget = 800
    public static let author = "realityhd"

    /// Overall size in meters.
    public var size = V3(0.6, 0.05, 0.6)
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ep = "metal.powdercoat:8C9196", st = "metal.stainless"
        // Perimeter frame.
        for s: Float in [-1, 1] {
            m.add(bx(V3(0.6, 0.05, 0.02), 0.003, ep), Xform(translation: V3(0, 0.025, s * 0.29)))
            m.add(bx(V3(0.02, 0.05, 0.56), 0.003, ep), Xform(translation: V3(s * 0.29, 0.025, 0)))
        }
        // Bearing bars along X, cross rods along Z.
        for i in 0..<13 {
            let z = -0.264 + Float(i) * 0.044
            m.add(bx(V3(0.56, 0.044, 0.006), 0.001, ep), Xform(translation: V3(0, 0.025, z)))
        }
        for i in 0..<5 {
            let x = -0.22 + Float(i) * 0.11
            m.add(bx(V3(0.006, 0.01, 0.56), 0.001, ep), Xform(translation: V3(x, 0.035, 0)))
        }
        // Lifting-hole plate and corner screws (one worn scuff via a lighter patch).
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.012 / 2, height: 0.012 * 0.5, bevel: 0, segments: 6, material: st), Xform(translation: V3(sx * 0.29, 0.047, sz * 0.29)))
        } }
        m.add(bx(V3(0.05, 0.004, 0.02), 0.001, "metal.powdercoat:C8B070"), Xform(translation: V3(0.12 + rng.float(-0.02...0.02), 0.048, 0.29)))
        let b = m.bounds; m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(m)
    }
}
