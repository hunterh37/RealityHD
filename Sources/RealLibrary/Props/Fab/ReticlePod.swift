import simd
import Foundation

/// Reticle pod: SEMI E152 EUV dual pod, matte dark grey shell, quartz reticle under window.
public struct ReticlePod: RealAsset {
    public static let id = "reticle-pod"
    public static let summary = "EUV reticle inner/outer pod with quartz reticle visible through a window."
    public static let tags = ["prop", "semiconductor", "handheld"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.2, 0.05, 0.2)
    /// Shell material key.
    public var shellMaterial = "plastic.matte:3C3F43"
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.roundedRect(s.x, s.y, radius: r * 1.5, segments: 2), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sh = shellMaterial, dk = "plastic.matte:25272A"
        // Outer pod base plate and cover shell (cover is 0.2 x 0.2 footprint, hollow via walls).
        m.add(bx(V3(0.2, 0.012, 0.2), 0.003, dk), Xform(translation: V3(0, 0.006, 0)))
        let wt: Float = 0.012
        // Cover: top plate with window opening (four frame bars) and four walls.
        let y0: Float = 0.012, y1: Float = 0.05
        for s: Float in [-1, 1] {
            m.add(bx(V3(wt, y1 - y0, 0.2), 0.003, sh), Xform(translation: V3(s * (0.1 - wt / 2), (y0 + y1) / 2, 0)))
            m.add(bx(V3(0.2 - 2 * wt, y1 - y0, wt), 0.003, sh), Xform(translation: V3(0, (y0 + y1) / 2, s * (0.1 - wt / 2))))
        }
        // Top plate as frame around 0.15 x 0.15 window.
        for s: Float in [-1, 1] {
            m.add(bx(V3(0.2, 0.006, 0.025), 0.002, sh), Xform(translation: V3(0, y1 - 0.003, s * 0.0875)))
            m.add(bx(V3(0.025, 0.006, 0.15), 0.002, sh), Xform(translation: V3(s * 0.0875, y1 - 0.003, 0)))
        }
        // Window pane.
        m.add(cuboid(V3(0.152, 0.002, 0.152), material: "glass.window-tint"), Xform(translation: V3(0, y1 - 0.004, 0)))
        // Inner pod baseplate and quartz reticle (6 inch = 152 mm).
        m.add(bx(V3(0.17, 0.005, 0.17), 0.002, "metal.aluminum-brushed"), Xform(translation: V3(0, 0.0145, 0)))
        m.add(cuboid(V3(0.152, 0.0063, 0.152), material: "glass.quartz"), Xform(translation: V3(0, 0.020, 0)))
        // Dark patterned absorber area on the reticle.
        m.add(cuboid(V3(0.104, 0.0006, 0.132), material: "plastic.matte:15171A"), Xform(translation: V3(0, 0.0236, 0)))
        // Reticle corner clamps.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(bx(V3(0.016, 0.01, 0.016), 0.002, "metal.aluminum-brushed"), Xform(translation: V3(sx * 0.074, 0.024, sz * 0.074)))
        } }
        // Latches on front wall.
        for s: Float in [-1, 1] {
            m.add(bx(V3(0.03, 0.016, 0.006), 0.002, "metal.aluminum-brushed"), Xform(translation: V3(s * 0.055, 0.03, 0.097)))
            m.add(Prim.cylinder(radius: 0.004, height: 0.004, bevel: 0.001, segments: 8, material: dk),
                  Xform(translation: V3(s * 0.055, 0.03, 0.1), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Label, scuff.
        m.add(cuboid(V3(0.05, 0.02, 0.0008), material: "plastic.matte:EEEEEA"), Xform(translation: V3(-0.04, 0.03, 0.1004)))
        m.add(cuboid(V3(0.03, 0.002, 0.0008), material: "plastic.matte:8A8C8E"), Xform(translation: V3(0.05, 0.016, 0.1004)))
        _ = rng.next()
        groundAO(&m)
        return LODModel(m)
    }
}
