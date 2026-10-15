import simd
import Foundation

/// Digital wall thermostat, 90 x 90 x 30 mm. Authored with its lowest point at y = 0 and its back face at
/// z = -0.015 (the planner lifts it to 1.45 m). Back plate, rounded white case with a bevelled front, dark glass,
/// backlit LCD with seven-segment "72", three touch buttons, side vent slots and a status LED.
public struct Thermostat: RealAsset {
    public static let id = "thermostat"
    public static let summary = "Digital wall thermostat: white square case, dark glass display with lit readout, touch buttons, side vent slots."
    public static let tags = ["prop", "floorplan", "interior", "hvac", "electronics", "plastic", "wall"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.09, 0.09, 0.03)
    /// Case color.
    public var caseMaterial: MaterialKey = "plastic.gloss:F2F2EF"
    /// Setpoint digits shown on the display.
    public var digits: [Int] = [7, 2]
    public init() {}

    /// Seven-segment masks in the order a b c d e f g.
    static let segments: [[Bool]] = [
        [true, true, true, true, true, true, false], [false, true, true, false, false, false, false],
        [true, true, false, true, true, false, true], [true, true, true, true, false, false, true],
        [false, true, true, false, false, true, true], [true, false, true, true, false, true, true],
        [true, false, true, true, true, true, true], [true, true, true, false, false, false, false],
        [true, true, true, true, true, true, true], [true, true, true, true, false, true, true]]

    public func build(seed: UInt64) -> LODModel {
        let W = size.x, H = size.y, back = -size.z / 2, front = size.z / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let cy = H / 2
            // Back plate and case body.
            m.add(Prim.extrude(Shape2D.roundedRect(W, H, radius: 0.008, segments: lod == 0 ? 3 : 2), depth: 0.006, bevel: 0.0012, bevelSegments: 1, material: caseMaterial),
                  Xform(translation: V3(0, cy, back + 0.003)))
            m.add(Prim.extrude(Shape2D.roundedRect(W - 0.004, H - 0.004, radius: 0.0095, segments: lod == 0 ? 4 : 2), depth: 0.0215, bevel: 0.004, bevelSegments: lod == 0 ? 3 : 1, material: caseMaterial),
                  Xform(translation: V3(0, cy, back + 0.006 + 0.01075)))
            let fz = front - 0.0025                     // front plane of the case body
            // Dark glass panel.
            m.add(Prim.extrude(Shape2D.roundedRect(0.072, 0.066, radius: 0.006, segments: lod == 0 ? 3 : 2), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: "screen.off"),
                  Xform(translation: V3(0, cy + 0.004, fz + 0.0005)))
            // Lit LCD with seven-segment readout.
            let lcdW: Float = 0.052, lcdH: Float = 0.032, lcdY = cy + 0.012
            m.add(cuboid(V3(lcdW, lcdH, 0.0004), material: "screen.lcd"), Xform(translation: V3(0, lcdY, fz + 0.0012)))
            let dw: Float = 0.012, dh: Float = 0.02, th: Float = 0.0022
            let vl = dh / 2 - th
            for (di, dg) in digits.enumerated() {
                let ox = Float(di) * 0.019 - 0.0135
                let cells: [(Float, Float, Float, Float)] = [
                    (0, dh / 2 - th / 2, dw, th), (dw / 2 - th / 2, dh / 4, th, vl), (dw / 2 - th / 2, -dh / 4, th, vl),
                    (0, -dh / 2 + th / 2, dw, th), (-dw / 2 + th / 2, -dh / 4, th, vl), (-dw / 2 + th / 2, dh / 4, th, vl), (0, 0, dw, th)]
                for (k, on) in Self.segments[dg % 10].enumerated() where on {
                    let c = cells[k]
                    m.add(cuboid(V3(c.2, c.3, 0.0004), material: "plastic.black"), Xform(translation: V3(ox + c.0, lcdY - 0.001 + c.1, fz + 0.0016)))
                }
            }
            // Degree mark and unit bar.
            m.add(Prim.torus(major: 0.0022, minor: 0.0007, segments: 8, sides: 4, material: "plastic.black"), Xform(translation: V3(0.0185, lcdY + 0.0075, fz + 0.0016), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(cuboid(V3(0.0045, 0.0022, 0.0004), material: "plastic.black"), Xform(translation: V3(0.0225, lcdY - 0.0085, fz + 0.0016)))
            // Touch buttons along the bottom of the glass.
            for k in -1...1 {
                m.add(Prim.roundedBox(V3(0.016, 0.0075, 0.0016), radius: 0.0012, bevelSegments: 1, material: "plastic.matte"), Xform(translation: V3(Float(k) * 0.023, cy - 0.0225, fz + 0.0014)))
            }
            // Status LED and vent slots on the top and bottom edges.
            if lod == 0 {
                m.add(Prim.cylinder(radius: 0.0013, height: 0.0008, bevel: 0.0002, segments: 8, bevelSegments: 1, material: "emissive.led-green"), Xform(translation: V3(-0.0315, cy + 0.0345, fz + 0.0012), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                for k in 0..<9 {
                    let x = (Float(k) - 4) * 0.0065
                    m.add(cuboid(V3(0.0022, 0.0006, 0.013), material: "plastic.black"), Xform(translation: V3(x, H - 0.0019, back + 0.0125)))
                    m.add(cuboid(V3(0.0022, 0.0006, 0.013), material: "plastic.black"), Xform(translation: V3(x, 0.0019, back + 0.0125)))
                }
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [3])
    }
}
