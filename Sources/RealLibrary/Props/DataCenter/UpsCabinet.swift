import simd
import Foundation

/// Floor-standing double-conversion UPS cabinet, 0.8 x 2.0 x 0.9 m: powder-coat body, hinged front door with vent slots, LCD panel, status LEDs, top exhaust grille, rear cable gland plate.
public struct UpsCabinet: RealArticulated {
    public static let id = "ups-cabinet"
    public static let summary = "Floor-standing UPS cabinet: dark grey powder-coat body, hinged front door with vent slots and LCD panel, status LEDs, top fan grille, plinth and cable gland plate."
    public static let tags = ["prop", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.8, 2.0, 0.9)
    /// Body powder-coat material.
    public var bodyMaterial: MaterialKey = "metal.powdercoat:5B6066"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let body = bodyMaterial
        let dark: MaterialKey = "plastic.matte:101113", panel: MaterialKey = "metal.powdercoat:2A2D31"
        let hx = size.x / 2, hz = size.z / 2, H = size.y, base: Float = 0.08
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, to part: String? = nil) {
            let surf = cuboid(s, material: mat)
            if let part { rig.add(surf, Xform(translation: c), to: part) } else { rig.base[0].add(surf, Xform(translation: c)) }
        }
        // Plinth, shell, top.
        box(V3(size.x, base, size.z), V3(0, base / 2, 0), dark)
        box(V3(0.02, H - base - 0.04, size.z), V3(-hx + 0.01, (H + base - 0.04) / 2, 0), body)
        box(V3(0.02, H - base - 0.04, size.z), V3(hx - 0.01, (H + base - 0.04) / 2, 0), body)
        box(V3(size.x, H - base - 0.04, 0.02), V3(0, (H + base - 0.04) / 2, -hz + 0.01), body)
        box(V3(size.x, 0.02, size.z), V3(0, base + 0.01, 0), body)
        box(V3(size.x, 0.04, size.z), V3(0, H - 0.02, 0), body)
        // Top exhaust grille with fan hubs.
        for i in 0..<10 { box(V3(0.5, 0.006, 0.012), V3(0, H + 0.003, -0.2 + 0.045 * Float(i)), dark) }
        for sx: Float in [-1, 1] { box(V3(0.1, 0.012, 0.1), V3(sx * 0.2, H + 0.006, -0.35), dark) }
        // Internal cabinet face behind the door (power modules, breaker row).
        box(V3(size.x - 0.06, H - base - 0.12, 0.01), V3(0, (H + base) / 2 - 0.02, hz - 0.06), panel)
        for i in 0..<5 {
            let y = 0.35 + 0.28 * Float(i)
            box(V3(0.66, 0.2, 0.012), V3(0, y + 0.4, hz - 0.052), dark)
            for k in 0..<4 { box(V3(0.06, 0.03, 0.008), V3(-0.2 + 0.13 * Float(k), y + 0.4, hz - 0.044), "plastic.matte:C8CACD") }
        }
        // Rear cable gland plate.
        box(V3(0.4, 0.2, 0.006), V3(0, 0.22, -hz - 0.003), panel)
        for i in 0..<4 { rig.base[0].add(Prim.cylinder(radius: 0.022, height: 0.02, bevel: 0.003, segments: 10, material: dark),
                                         Xform(translation: V3(-0.12 + 0.08 * Float(i), 0.22, -hz - 0.016), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }
        // Front door, hinged on the left.
        let dw = size.x - 0.02, dh = H - base - 0.06
        let pivot = V3(-hx + 0.005, base + 0.02, hz + 0.01)
        rig.part("front-door", pivot: pivot, joint: .hinge(axis: .up, -110...0, duration: 1.1))
        func put(_ s: V3, _ t: V3, _ mat: MaterialKey) { box(s, pivot + t, mat, to: "front-door") }
        put(V3(dw, dh, 0.02), V3(dw / 2, dh / 2, 0), body)
        put(V3(dw - 0.1, 0.5, 0.004), V3(dw / 2, 0.45, 0.012), dark)
        for i in 0..<12 { put(V3(dw - 0.2, 0.008, 0.004), V3(dw / 2, 0.22 + 0.032 * Float(i), 0.013), "plastic.matte:060607") }
        for i in 0..<8 { put(V3(dw - 0.2, 0.008, 0.004), V3(dw / 2, 1.1 + 0.032 * Float(i), 0.013), "plastic.matte:060607") }
        // LCD panel and keys.
        put(V3(0.34, 0.2, 0.01), V3(dw / 2, dh - 0.25, 0.014), dark)
        put(V3(0.26, 0.12, 0.004), V3(dw / 2, dh - 0.23, 0.021), "glass.lamp")
        for i in 0..<4 { put(V3(0.035, 0.02, 0.006), V3(dw / 2 - 0.075 + 0.05 * Float(i), dh - 0.34, 0.019), "plastic.matte:C8CACD") }
        // Status LEDs.
        for i in 0..<3 { put(V3(0.014, 0.014, 0.004), V3(dw / 2 - 0.05 + 0.05 * Float(i), dh - 0.08, 0.014), "glass.lamp") }
        // Handle and badge.
        put(V3(0.02, 0.2, 0.03), V3(dw - 0.05, dh / 2, 0.025), "metal.stainless")
        put(V3(0.16, 0.04, 0.002), V3(dw / 2, dh - 0.45, 0.012), "metal.stainless")
        rig.states = [RigState("closed"), RigState("open", ["front-door": -100])]
        return rig
    }
}
