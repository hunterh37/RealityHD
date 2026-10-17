import simd
import Foundation

/// Tactical-grade inertial measurement unit, 0.1 m body on a 0.12 m flanged base. A machined grey
/// anodized aluminium housing with a raised, screwed brushed lid; four bolted mounting ears; white X/Y
/// axis arrows engraved-and-filled on the lid with a Z dot; a circular connector with a dust cap on one
/// side and a calibration label on the other.
public struct Imu: RealAsset {
    public static let id = "imu"
    public static let summary = "Inertial measurement unit, 0.1 m footprint: machined aluminium housing with flanged mounts, screwed lid, axis marking and a circular connector."
    public static let tags = ["prop", "aerospace", "electronics"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 30, distance: 1.1, studio: true)

    /// Body size (m).
    public var body = V3(0.09, 0.05, 0.09)
    public var housing: MaterialKey = "metal.anodized:5C6670"
    public var lid: MaterialKey = "metal.aluminum-brushed"
    public var marking: MaterialKey = "paint.field-white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let B = body, flangeH: Float = 0.006, lidH: Float = 0.005
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            // Base flange: square plate with corner ears.
            m.add(Prim.roundedBox(V3(B.x + 0.004, flangeH, B.z + 0.004), radius: 0.003, bevelSegments: bs, material: housing),
                  Xform(translation: V3(0, flangeH / 2, 0)))
            for (sx, sz) in [(Float(-1), Float(-1)), (-1, 1), (1, -1), (1, 1)] {
                let p = V3(sx * (B.x / 2 + 0.006), flangeH / 2, sz * (B.z / 2 + 0.006))
                m.add(Prim.roundedBox(V3(0.022, flangeH, 0.022), radius: 0.006, bevelSegments: bs, material: housing),
                      Xform(translation: p, rotation: simd_quatf(angle: .pi / 4, axis: .up)))
                if l == 0 { hexBolt(&m, at: V3(p.x, flangeH, p.z), normal: .up, size: 0.0045, material: "metal.steel") }
            }
            // Body and lid.
            let bodyH = B.y - flangeH - lidH
            m.add(Prim.roundedBox(V3(B.x, bodyH, B.z), radius: 0.004, bevelSegments: bs, material: housing),
                  Xform(translation: V3(0, flangeH + bodyH / 2, 0)))
            m.add(Prim.roundedBox(V3(B.x - 0.004, lidH, B.z - 0.004), radius: 0.002, bevelSegments: bs, material: lid),
                  Xform(translation: V3(0, B.y - lidH / 2, 0)))
            if l == 0 {
                // Lid screws.
                for (sx, sz) in [(Float(-1), Float(-1)), (-1, 1), (1, -1), (1, 1), (0, -1), (0, 1)] {
                    rivet(&m, at: V3(sx * (B.x / 2 - 0.008), B.y, sz * (B.z / 2 - 0.008)), normal: .up, radius: 0.0028, segments: 8, material: "metal.steel")
                }
                // Axis arrows: X along +X, Y along -Z (body frame), Z dot.
                let arrow: [V2] = [V2(0, -0.0015), V2(0.022, -0.0015), V2(0.022, -0.004), V2(0.03, 0), V2(0.022, 0.004), V2(0.022, 0.0015), V2(0, 0.0015)]
                let flat = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
                m.add(Prim.extrude(arrow, depth: 0.0006, bevel: 0, bevelSegments: 0, material: marking),
                      Xform(translation: V3(-0.012, B.y + 0.0003, 0.012), rotation: flat))
                m.add(Prim.extrude(arrow, depth: 0.0006, bevel: 0, bevelSegments: 0, material: marking),
                      Xform(translation: V3(-0.012, B.y + 0.0003, 0.012), rotation: simd_quatf(angle: .pi / 2, axis: .up) * flat))
                m.add(Prim.cylinder(radius: 0.0035, height: 0.0006, bevel: 0, segments: 16, material: marking),
                      Xform(translation: V3(-0.012, B.y, 0.012)))
                // Circular connector with a chained dust cap on +X.
                let cy = flangeH + bodyH * 0.5
                let rx = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
                m.add(Prim.roundedBox(V3(0.003, 0.026, 0.026), radius: 0.002, bevelSegments: 1, material: housing),
                      Xform(translation: V3(B.x / 2 + 0.0015, cy, 0)))
                m.add(Prim.cylinder(radius: 0.009, height: 0.014, bevel: 0.0015, segments: 20, material: "metal.anodized:8A9097"),
                      Xform(translation: V3(B.x / 2 + 0.002, cy, 0), rotation: rx))
                m.add(Prim.cylinder(radius: 0.0095, height: 0.004, bevel: 0.001, segments: 20, material: "plastic.matte:B83A1E"),
                      Xform(translation: V3(B.x / 2 + 0.015, cy, 0), rotation: rx))
                for (sy, sz) in [(Float(-1), Float(-1)), (1, 1)] {
                    rivet(&m, at: V3(B.x / 2 + 0.003, cy + sy * 0.01, sz * 0.01), normal: V3(1, 0, 0), radius: 0.0018, segments: 6, material: "metal.steel")
                }
                // Calibration label on -X, slightly crooked.
                m.add(Prim.roundedBox(V3(0.0008, 0.022, 0.05), radius: 0.0003, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: V3(-B.x / 2 - 0.0004, cy, 0), rotation: simd_quatf(angle: rng.float(-0.05...0.05), axis: V3(1, 0, 0))))
            }
            groundAO(&m, height: 0.02, floor: 0.6)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
