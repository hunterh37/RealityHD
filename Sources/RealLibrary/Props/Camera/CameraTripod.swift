import simd
import Foundation

/// Video tripod: black anodized telescoping legs, geared column, fluid pan head with handle and quick-release plate, extended to 1.45 m.
public struct CameraTripod: RealAsset {
    public static let id = "camera-tripod"
    public static let summary = "Video tripod 1.45 m: three telescoping legs with locks, geared column, fluid pan head with handle, plate."
    public static let tags = ["prop", "camera", "metal", "plastic", "tool"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 2.8)

    /// Height of the head mount plate in meters.
    public var height: Float = 1.45
    /// Radius of the foot circle in meters.
    public var spread: Float = 0.5
    /// Leg tubes.
    public var leg: MaterialKey = "metal.anodized-black"
    /// Head and handle.
    public var plastic: MaterialKey = "plastic.black"
    /// Locks and dials.
    public var metal: MaterialKey = "metal.satin-aluminum"
    /// Feet.
    public var rubber: MaterialKey = "rubber"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let top = V3(0, height - 0.17, 0)
        // Hub.
        m.add(turned([(0, 0), (0.07, 0), (0.075, 0.01), (0.07, 0.07), (0.04, 0.09), (0, 0.09)], segments: 20, material: plastic, seamTile: 0.1), Xform(translation: top + V3(0, -0.07, 0)))
        for k in 0..<3 {
            let a = Float(k) * 2 * .pi / 3
            let dir = V3(cos(a), 0, sin(a))
            let hip = top + dir * 0.07 + V3(0, -0.04, 0)
            let foot = V3(dir.x * spread, 0.025, dir.z * spread)
            let mid1 = hip + (foot - hip) * 0.38, mid2 = hip + (foot - hip) * 0.7
            m.add(Prim.tube([hip, mid1], radii: [0.016, 0.016], sides: 12, seamTile: 0.1, material: leg, capEnd: true))
            m.add(Prim.tube([mid1 - (foot - hip) * 0.02, mid2], radii: [0.0135, 0.0135], sides: 12, seamTile: 0.1, material: leg, capEnd: true))
            m.add(Prim.tube([mid2 - (foot - hip) * 0.02, foot], radii: [0.011, 0.011], sides: 12, seamTile: 0.1, material: leg, capEnd: true))
            for p in [mid1, mid2] {
                m.add(Prim.cylinder(radius: 0.0195, height: 0.035, bevel: 0.003, segments: 12, bevelSegments: 1, material: metal), Xform(translation: p + V3(0, -0.017, 0)))
                m.add(Prim.roundedBox(V3(0.012, 0.03, 0.028), radius: 0.003, bevelSegments: 1, material: plastic), Xform(translation: p + dir * 0.022 + V3(0, -0.008, 0)))
            }
            m.add(Prim.cylinder(radius: 0.017, height: 0.035, bevel: 0.006, segments: 12, bevelSegments: 2, material: rubber), Xform(translation: foot + V3(0, -0.025, 0)))
            // Hinge hub and spreader strut.
            m.add(Prim.roundedBox(V3(0.05, 0.04, 0.05), radius: 0.008, bevelSegments: 2, material: plastic), Xform(translation: hip, rotation: simd_quatf(degrees: -a * 180 / .pi, axis: .up)))
        }
        // Column.
        m.add(Prim.cylinder(radius: 0.021, height: 0.16, bevel: 0.002, segments: 16, bevelSegments: 1, material: metal), Xform(translation: top + V3(0, 0.02, 0)))
        m.add(Prim.cylinder(radius: 0.03, height: 0.012, bevel: 0.003, segments: 16, bevelSegments: 1, material: metal), Xform(translation: top + V3(0, 0.17, 0)))
        // Fluid head.
        let h0 = top + V3(0, 0.182, 0)
        m.add(Prim.roundedBox(V3(0.1, 0.03, 0.08), radius: 0.008, bevelSegments: 2, material: plastic), Xform(translation: h0 + V3(0, 0.015, 0)))
        m.add(Prim.roundedBox(V3(0.075, 0.07, 0.07), radius: 0.015, bevelSegments: 3, material: plastic), Xform(translation: h0 + V3(0, 0.065, 0)))
        m.add(Prim.roundedBox(V3(0.11, 0.008, 0.06), radius: 0.002, bevelSegments: 1, material: metal), Xform(translation: h0 + V3(0, 0.104, 0)))
        // Pan handle sweeping back and down.
        m.add(Prim.tube([h0 + V3(0, 0.07, 0.035), h0 + V3(0, 0.05, 0.18), h0 + V3(0, 0.0, 0.34)], radii: [0.008, 0.008, 0.008], sides: 8, seamTile: 0.1, material: plastic, capEnd: true))
        m.add(Prim.cylinder(radius: 0.014, height: 0.11, bevel: 0.004, segments: 12, bevelSegments: 2, material: rubber), Xform(translation: h0 + V3(0, -0.0, 0.34) + V3(0, 0, 0.0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Tilt lock knob.
        m.add(Prim.cylinder(radius: 0.017, height: 0.02, bevel: 0.004, segments: 12, bevelSegments: 1, material: metal), Xform(translation: h0 + V3(0.045, 0.065, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        groundAO(&m)
        return LODModel(m)
    }
}
