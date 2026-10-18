import simd
import Foundation

/// Yellow-room lighting panel: amber diffuser in a white metal frame with back housing.
public struct FabYellowLightPanel: RealAsset {
    public static let id = "fab-yellow-light-panel"
    public static let summary = "Yellow-room lighting panel: amber diffuser in a white metal frame with back housing."
    public static let tags = ["prop", "semiconductor"]
    public static let budget = 400
    public static let author = "realityhd"

    /// Overall size in meters.
    public var size = V3(1.2, 0.05, 0.6)
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wh = "metal.powdercoat:F4F4F2", al = "metal.aluminum-brushed"
        // Frame bars, back tray, amber diffuser, prismatic ribs, end caps.
        for s: Float in [-1, 1] {
            m.add(bx(V3(1.2, 0.03, 0.025), 0.004, wh), Xform(translation: V3(0, 0.015, s * 0.2875)))
            m.add(bx(V3(0.025, 0.03, 0.55), 0.004, wh), Xform(translation: V3(s * 0.5875, 0.015, 0)))
        }
        m.add(bx(V3(1.16, 0.02, 0.56), 0.003, wh), Xform(translation: V3(0, 0.035, 0)))
        m.add(bx(V3(1.15, 0.008, 0.55), 0.002, "emissive.amber"), Xform(translation: V3(0, 0.008, 0)))
        for i in 0..<11 {
            m.add(bx(V3(0.006, 0.004, 0.55), 0.001, "emissive.amber"), Xform(translation: V3(-0.5 + Float(i) * 0.1, 0.002, 0)))
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.008 / 2, height: 0.008 * 0.5, bevel: 0, segments: 6, material: al), Xform(translation: V3(sx * 0.5875, 0.03, sz * 0.2875)))
        } }
        m.add(bx(V3(0.08, 0.012, 0.04), 0.002, al), Xform(translation: V3(0.3 + rng.float(-0.01...0.01), 0.044, 0)))
        // Laid face-up so the diffuser reads from above.
        m = m.transformed(Xform(rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        let b = m.bounds; m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(m)
    }
}
