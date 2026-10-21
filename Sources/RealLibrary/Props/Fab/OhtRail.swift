import simd
import Foundation

/// OHT ceiling track: extruded aluminum inverted-U rail with power bar, splice plate and hanger rods.
public struct OhtRail: RealAsset {
    public static let id = "oht-rail"
    public static let summary = "OHT ceiling track: extruded aluminum inverted-U rail with power bar, splice plate and hanger rods."
    public static let tags = ["prop", "semiconductor"]
    public static let budget = 800
    public static let author = "realityhd"

    /// Overall size in meters.
    public var size = V3(3.0, 0.2, 0.2)
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let al = "metal.aluminum-brushed", st = "metal.stainless", L = size.x
        // Top plate, two walls, inward bottom lips (gap 0.08 for the vehicle hoist).
        m.add(bx(V3(L, 0.03, 0.20), 0.004, al), Xform(translation: V3(0, 0.185, 0)))
        for s: Float in [-1, 1] {
            m.add(bx(V3(L, 0.15, 0.014), 0.003, al), Xform(translation: V3(0, 0.105, s * 0.093)))
            m.add(bx(V3(L, 0.014, 0.06), 0.003, al), Xform(translation: V3(0, 0.037, s * 0.07)))
            // Copper power-feed bar on the inner wall face.
            m.add(bx(V3(L - 0.02, 0.02, 0.006), 0.002, "metal.copper"), Xform(translation: V3(0, 0.10, s * 0.083)))
            // Running surface strip on lip.
            m.add(bx(V3(L - 0.01, 0.006, 0.03), 0.002, "plastic.matte:2A2C2F"), Xform(translation: V3(0, 0.047, s * 0.062)))
        }
        // Splice plate midway and rail end caps with bolts.
        for sx: Float in [-0.5, 0.5] where sx != 0 {
            m.add(bx(V3(0.02, 0.16, 0.012), 0.002, st), Xform(translation: V3(sx * (L - 0.012), 0.105, 0.093)))
        }
        m.add(bx(V3(0.24, 0.04, 0.2), 0.004, st), Xform(translation: V3(0, 0.205 - 0.015, 0)))
        // Hanger brackets: cross bar with two nuts on threaded rods.
        for hx: Float in [-1.0, 1.0] {
            m.add(bx(V3(0.05, 0.012, 0.2), 0.002, st), Xform(translation: V3(hx, 0.206, 0)))
            for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.005, height: 0.012, bevel: 0.0005, segments: 6, material: st),
                      Xform(translation: V3(hx, 0.2, sz * 0.085)))
            }
        }
        _ = rng.float()
        let b = m.bounds; m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(m)
    }
}
