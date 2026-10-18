import simd
import Foundation

/// FOUP: SEMI E47.1 300 mm front-opening pod, smoke polycarbonate, light handling wear.
public struct Foup: RealAsset {
    public static let id = "foup"
    public static let summary = "25-slot front-opening pod for 300 mm wafers with top flange, side handles and door."
    public static let tags = ["prop", "semiconductor", "handheld", "articulated"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width incl. handles, y height incl. flange, z depth incl. door).
    public var size = V3(0.4, 0.34, 0.34)
    /// Wafers loaded (0...25).
    public var wafers = 25
    /// Shell material key.
    public var shellMaterial = "plastic.polycarbonate-tint"
    /// Door and frame material key.
    public var doorMaterial = "plastic.matte:3A3C40"
    public init() {}

    /// Beveled box from an extruded rectangle (about 40 tris).
    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w: Float = 0.316, shellY0: Float = 0.014, shellY1: Float = 0.300
        let z0: Float = -0.16, z1: Float = 0.16, zc = (z0 + z1) / 2
        // Kinematic coupling plate with three V-groove pads.
        m.add(bx(V3(0.30, 0.014, 0.30), 0.003, doorMaterial),
              Xform(translation: V3(0, 0.007, zc)))
        for (i, p) in [V3(-0.07, 0, 0.05), V3(0.07, 0, 0.05), V3(0, 0, -0.09)].enumerated() {
            m.add(Prim.cylinder(radius: 0.012, height: 0.003, bevel: 0.001, segments: 10, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(p.x, -0.0005, zc + p.z)).jittered(&rng))
            _ = i
        }
        // Shell: open-front box walls (back, top, bottom, sides) in translucent polycarbonate.
        let h = shellY1 - shellY0, t: Float = 0.004
        m.add(bx(V3(w, t, z1 - z0), 0.0015, shellMaterial), Xform(translation: V3(0, shellY1 - t / 2, zc)))
        m.add(bx(V3(w, t, z1 - z0), 0.0015, shellMaterial), Xform(translation: V3(0, shellY0 + t / 2, zc)))
        m.add(bx(V3(w, h, t), 0.0015, shellMaterial), Xform(translation: V3(0, shellY0 + h / 2, z0 + t / 2)))
        for s: Float in [-1, 1] {
            m.add(bx(V3(t, h, z1 - z0), 0.0015, shellMaterial), Xform(translation: V3(s * (w - t) / 2, shellY0 + h / 2, zc)))
            // Vertical stiffening ribs on the outside of each side wall.
            for k in 0..<3 {
                let zz = z0 + 0.06 + Float(k) * 0.10
                m.add(bx(V3(0.004, h - 0.03, 0.005), 0.0015, shellMaterial),
                      Xform(translation: V3(s * (w / 2 + 0.002), shellY0 + h / 2, zz)))
            }
            // Side carry handle.
            var hd = barHandle(length: 0.12, standoff: 0.036, radius: 0.007, material: doorMaterial)
            hd.recomputeNormals()
            m.add(hd, Xform(translation: V3(s * (w / 2 + 0.002), 0.17, zc), rotation: simd_quatf(degrees: s > 0 ? 90 : -90, axis: V3(0, 1, 0))))
        }
        // Wafer support teeth, two per side.
        for s: Float in [-1, 1] {
            for zz: Float in [0.0] {
                m.add(bx(V3(0.014, 0.25, 0.012), 0.002, "plastic.matte:E8E4D8"),
                      Xform(translation: V3(s * (w / 2 - t - 0.007), 0.16, zc + zz)))
            }
        }
        // Wafers.
        for i in 0..<min(wafers, 25) {
            m.add(Prim.lathe([V2(0, 0.00078), V2(0.15, 0.00078), V2(0.15, 0), V2(0, 0)], segments: 10, material: "silicon.thinfilm"),
                  Xform(translation: V3(0, 0.04 + Float(i) * 0.010, zc)))
        }
        // Door with gasket frame, latch keyholes and RFID label.
        m.add(bx(V3(w + 0.006, h + 0.006, 0.006), 0.002, "plastic.matte:2A2C2F"),
              Xform(translation: V3(0, shellY0 + h / 2, z1 + 0.003)))
        m.add(bx(V3(w - 0.016, h - 0.016, 0.014), 0.004, doorMaterial),
              Xform(translation: V3(0, shellY0 + h / 2, z1 + 0.012)))
        for s: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.011, height: 0.003, bevel: 0.0008, segments: 10, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(s * 0.11, shellY0 + h / 2 - 0.02, z1 + 0.019), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(bx(V3(0.002, 0.012, 0.004), 0.0005, "plastic.matte:101010"),
                  Xform(translation: V3(s * 0.11, shellY0 + h / 2 - 0.02, z1 + 0.0215)))
        }
        m.add(bx(V3(0.05, 0.03, 0.0008), 0.0004, "plastic.matte:EEEEEA"),
              Xform(translation: V3(0.09, shellY0 + h / 2 + 0.08, z1 + 0.0194)).jittered(&rng))
        // Robotic top flange: stem and plate.
        m.add(Prim.cylinder(radius: 0.014, height: 0.03, bevel: 0.002, segments: 16, material: doorMaterial), Xform(translation: V3(0, shellY1, zc)))
        m.add(bx(V3(0.19, 0.006, 0.09), 0.003, doorMaterial),
              Xform(translation: V3(0, 0.337, zc)))
        groundAO(&m)
        return LODModel(m)
    }
}
