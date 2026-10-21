import simd
import Foundation

/// Fan filter unit: white sheet-metal plenum box, HEPA pleat pack behind a slotted grille, fan collar.
public struct FfuCeilingTile: RealAsset {
    public static let id = "ffu-ceiling-tile"
    public static let summary = "Fan filter unit: white sheet-metal plenum box, HEPA pleat pack behind a slotted grille, fan collar."
    public static let tags = ["prop", "semiconductor"]
    public static let budget = 1200
    public static let author = "realityhd"

    /// Overall size in meters.
    public var size = V3(1.2, 0.3, 0.6)
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wh = "metal.powdercoat:F4F4F2", al = "metal.aluminum-brushed"
        // Housing box above the flange, bottom frame at y 0.
        m.add(bx(V3(1.16, 0.24, 0.56), 0.004, wh), Xform(translation: V3(0, 0.17, 0)))
        m.add(bx(V3(1.2, 0.03, 0.6), 0.004, wh), Xform(translation: V3(0, 0.015, 0)))
        // HEPA pleat pack: zigzag section extruded along Z, inside the frame opening.
        var pts: [V2] = []
        let n = 14, w: Float = 1.12, pitch = w / Float(n)
        for i in 0...n { pts.append(V2(-w / 2 + Float(i) * pitch, i % 2 == 0 ? 0.0 : 0.03)) }
        for i in stride(from: n, through: 0, by: -1) { pts.append(V2(-w / 2 + Float(i) * pitch, i % 2 == 0 ? 0.012 : 0.042)) }
        m.add(Prim.extrude(pts, depth: 0.52, bevel: 0, bevelSegments: 1, material: "filter.hepa"),
              Xform(translation: V3(0, 0.03, 0)))
        m.add(bx(V3(1.14, 0.012, 0.54), 0.002, "filter.hepa"), Xform(translation: V3(0, 0.026, 0)))
        // Slotted grille: aluminum bars along Z across the face, plus a perimeter rim.
        for i in 0..<8 {
            let x = -0.55 + Float(i) * 0.157
            m.add(bx(V3(0.012, 0.01, 0.56), 0.002, al), Xform(translation: V3(x, 0.005, 0)))
        }
        for s: Float in [-1, 1] {
            m.add(bx(V3(1.2, 0.012, 0.02), 0.003, al), Xform(translation: V3(0, 0.006, s * 0.29)))
            m.add(bx(V3(0.02, 0.012, 0.6), 0.003, al), Xform(translation: V3(s * 0.59, 0.006, 0)))
        }
        // Fan collar and duct spigot on top, lid ribs.
        m.add(Prim.cylinder(radius: 0.14, height: 0.03, bevel: 0.004, segments: 20, material: wh), Xform(translation: V3(0, 0.27, 0)))
        m.add(Prim.cylinder(radius: 0.1, height: 0.012, bevel: 0.002, segments: 20, material: "metal.stainless"), Xform(translation: V3(0, 0.287, 0)))
        for sx: Float in [-1, 1] {
            m.add(bx(V3(0.03, 0.02, 0.56), 0.003, wh), Xform(translation: V3(sx * 0.4, 0.29, 0)))
        }
        // Side rating plate and flange screws.
        m.add(bx(V3(0.1, 0.05, 0.003), 0.0005, "metal.stainless"), Xform(translation: V3(0.3, 0.17, 0.281)))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.01 / 2, height: 0.01 * 0.5, bevel: 0, segments: 6, material: al), Xform(translation: V3(sx * 0.57, 0.03, sz * 0.27)))
        } }
        _ = rng.float()
        let b = m.bounds; m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(m)
    }
}
