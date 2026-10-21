import simd
import Foundation

/// Lithium-ion battery rack, 0.6 x 2.0 x 0.8 m: open steel frame holding 12 stacked battery modules with handles and status LEDs, DC busbar column, breaker box, hinged mesh-free front door.
public struct BatteryRackLi: RealArticulated {
    public static let id = "battery-rack-li"
    public static let summary = "Lithium-ion battery rack: powder-coat frame, 12 stacked battery modules with handles and status LEDs, DC busbar, breaker box, hinged front door."
    public static let tags = ["prop", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.0, 0.8)
    /// Number of battery modules.
    public var modules = 12
    /// Frame powder-coat material.
    public var frameMaterial: MaterialKey = "metal.powdercoat:2F4A6B"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let frame = frameMaterial
        let dark: MaterialKey = "plastic.matte:15171A", mod: MaterialKey = "metal.powdercoat:3A3E44"
        let hx = size.x / 2, hz = size.z / 2, H = size.y, base: Float = 0.08
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, to part: String? = nil) {
            let surf = cuboid(s, material: mat)
            if let part { rig.add(surf, Xform(translation: c), to: part) } else { rig.base[0].add(surf, Xform(translation: c)) }
        }
        box(V3(size.x, base, size.z), V3(0, base / 2, 0), dark)
        // Posts, top and bottom rails, rear panel.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            box(V3(0.04, H - base, 0.04), V3(sx * (hx - 0.02), (H + base) / 2, sz * (hz - 0.02)), frame)
        } }
        for sy in [base + 0.02, H - 0.02] { box(V3(size.x, 0.04, size.z), V3(0, sy, 0), frame) }
        box(V3(size.x - 0.08, H - base - 0.08, 0.008), V3(0, (H + base) / 2, -hz + 0.004), "metal.powdercoat:1E2024")
        for sx: Float in [-1, 1] { box(V3(0.006, H - base - 0.08, size.z - 0.08), V3(sx * (hx - 0.003), (H + base) / 2, 0), "metal.powdercoat:1E2024") }
        // Module shelves and modules, 3U each.
        let top = H - 0.2, pitch = (top - base - 0.12) / Float(modules)
        for i in 0..<modules {
            let y = base + 0.1 + pitch * (Float(i) + 0.5)
            box(V3(size.x - 0.1, 0.008, size.z - 0.14), V3(0, y - pitch / 2 + 0.004, 0.01), frame)
            box(V3(size.x - 0.2, pitch - 0.03, size.z - 0.2), V3(-0.02, y, 0), mod)
            box(V3(size.x - 0.2, pitch - 0.04, 0.012), V3(-0.02, y, hz - 0.1), dark)
            box(V3(0.14, 0.012, 0.016), V3(-0.08, y, hz - 0.09), "metal.stainless")
            for k in 0..<2 { box(V3(0.012, 0.012, 0.006), V3(0.08 + 0.03 * Float(k), y + 0.01, hz - 0.095), "glass.lamp") }
            box(V3(0.036, 0.02, 0.02), V3(0.18, y - 0.01, hz - 0.085), "plastic.matte:B02A20")
            box(V3(0.036, 0.02, 0.02), V3(0.22, y - 0.01, hz - 0.085), dark)
        }
        // DC busbar column at the rear right.
        for (k, c) in ["metal.copper", "metal.copper"].enumerated() {
            box(V3(0.03, H - base - 0.3, 0.008), V3(hx - 0.07 - 0.04 * Float(k), (H + base) / 2 - 0.1, -hz + 0.05), c)
        }
        // Breaker box on top.
        box(V3(0.4, 0.14, 0.3), V3(0, H - 0.11, 0.05), "metal.powdercoat:C9CCD0")
        for i in 0..<4 { box(V3(0.03, 0.05, 0.016), V3(-0.12 + 0.08 * Float(i), H - 0.11, 0.208), "plastic.matte:101113") }
        box(V3(0.016, 0.016, 0.006), V3(0.15, H - 0.08, 0.2), "glass.lamp")
        // Front door.
        let dw = size.x - 0.02, dh = H - base - 0.28
        let pivot = V3(-hx + 0.005, base + 0.04, hz + 0.01)
        rig.part("front-door", pivot: pivot, joint: .hinge(axis: .up, -110...0, duration: 1.0))
        func put(_ s: V3, _ t: V3, _ mat: MaterialKey) { box(s, pivot + t, mat, to: "front-door") }
        put(V3(dw, dh, 0.018), V3(dw / 2, dh / 2, 0), frame)
        put(V3(dw - 0.12, 0.55, 0.004), V3(dw / 2, dh - 0.5, 0.011), dark)
        for i in 0..<10 { put(V3(dw - 0.2, 0.008, 0.004), V3(dw / 2, 0.3 + 0.03 * Float(i), 0.011), "plastic.matte:060607") }
        put(V3(0.2, 0.08, 0.002), V3(dw / 2, dh - 0.16, 0.01), "plastic.yellow")
        put(V3(0.02, 0.16, 0.026), V3(dw - 0.05, dh / 2, 0.022), "metal.stainless")
        rig.states = [RigState("closed"), RigState("open", ["front-door": -100])]
        return rig
    }
}
