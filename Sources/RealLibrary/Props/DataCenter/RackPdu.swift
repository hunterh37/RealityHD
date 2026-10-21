import simd
import Foundation

/// Vertical zero-U rack PDU, 0.06 x 1.8 x 0.06 m: black powder-coat extrusion, 24 C13 outlets and 6 C19 outlets, breaker bank, inlet cord, LED display.
public struct RackPdu: RealAsset {
    public static let id = "rack-pdu"
    public static let summary = "Vertical zero-U rack PDU: black extruded body, 24 C13 and 6 C19 outlets, breaker bank, LED current display, mounting buttons."
    public static let tags = ["prop"]
    public static let budget = 3000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Outlets face +Z.
    public var size = V3(0.06, 1.8, 0.06)
    /// Body material.
    public var bodyMaterial: MaterialKey = "metal.powdercoat:141517"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let body = bodyMaterial, dark: MaterialKey = "plastic.matte:060607"
        let w = size.x, H = size.y, hz = size.z / 2
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey) { m.add(cuboid(s, material: mat), Xform(translation: c)) }
        m.add(Prim.roundedBox(V3(w, H - 0.04, size.z), radius: 0.004, bevelSegments: 1, material: body), Xform(translation: V3(0, H / 2, 0)))
        // Outlets: 6 C19 at the bottom, 24 C13 above.
        let y0: Float = 0.3, top = H - 0.16
        for i in 0..<6 {
            let y = y0 + 0.055 * Float(i)
            box(V3(0.042, 0.036, 0.006), V3(0, y, hz + 0.003), "plastic.matte:2A2C30")
            box(V3(0.034, 0.028, 0.008), V3(0, y, hz + 0.004), dark)
        }
        let c13 = y0 + 0.055 * 6 + 0.03
        let pitch = (top - c13) / 24
        for i in 0..<24 {
            let y = c13 + pitch * (Float(i) + 0.5)
            box(V3(0.034, pitch * 0.82, 0.005), V3(0, y, hz + 0.0025), "plastic.matte:2A2C30")
            box(V3(0.026, pitch * 0.6, 0.007), V3(0, y, hz + 0.0035), dark)
        }
        // Breaker bank.
        for i in 0..<3 { box(V3(0.024, 0.04, 0.012), V3(0, 0.12 + 0.05 * Float(i), hz + 0.006), "plastic.matte:C8CACD") }
        // Display and LED.
        box(V3(0.036, 0.03, 0.004), V3(0, H - 0.1, hz + 0.002), dark)
        box(V3(0.028, 0.014, 0.003), V3(0, H - 0.1, hz + 0.0045), "glass.lamp")
        box(V3(0.008, 0.008, 0.003), V3(0, H - 0.07, hz + 0.0025), "glass.lamp")
        // End caps, inlet cord and rear mounting buttons.
        for y in [Float(0.01), H - 0.01] { box(V3(w + 0.004, 0.022, size.z + 0.004), V3(0, y, 0), "plastic.matte:0D0E10") }
        m.add(Prim.cylinder(radius: 0.012, height: 0.16, bevel: 0.002, segments: 10, material: "rubber.seal"),
              Xform(translation: V3(0, -0.06, 0)))
        for y in [Float(0.2), 0.9, 1.6] { m.add(Prim.cylinder(radius: 0.008, height: 0.01, bevel: 0.002, segments: 8, material: "metal.stainless"),
              Xform(translation: V3(0, y, -hz - 0.005), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }
        return LODModel(m)
    }
}
