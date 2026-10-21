import simd
import Foundation

/// Network patch panel: 1U 24-port Cat6A panel in black powdercoat with keystone jacks, port labels and rear cable-management bar.
public struct NetworkPatchPanel: RealAsset {
    public static let id = "network-patch-panel"
    public static let summary = "1U 24-port patch panel: black powdercoat plate, two rows of keystone jacks with white label strips, rail ears, rear cable bar."
    public static let tags = ["prop"]
    public static let budget = 4000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.48, 0.044, 0.1)
    /// Plate material.
    public var plate: MaterialKey = "metal.powdercoat:1B1C1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let zf = d / 2
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0) {
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Front plate and rail ears with slots.
        box(V3(w, h - 0.001, 0.003), V3(0, h / 2, zf - 0.0015), plate, r: 0.001)
        for s: Float in [-1, 1] {
            box(V3(0.01, 0.012, 0.0008), V3(s * (w / 2 - 0.009), h / 2, zf + 0.0004), "plastic.matte:050505")
        }
        // Rear tray and side walls.
        box(V3(w - 0.04, 0.0015, d - 0.01), V3(0, 0.003, -0.005), plate)
        for s: Float in [-1, 1] { box(V3(0.002, h - 0.006, d - 0.01), V3(s * (w / 2 - 0.021), h / 2, -0.005), plate) }
        // 24 keystone jacks in two rows of 12, each with a dark body, port opening and contact strip.
        let pitch: Float = 0.0345, x0 = -pitch * 5.5
        for row in 0..<2 {
            let y = h * (row == 0 ? 0.68 : 0.3)
            for i in 0..<12 {
                let x = x0 + Float(i) * pitch
                box(V3(0.0145, 0.0145, 0.004), V3(x, y, zf + 0.0005), "plastic.matte:262729", r: 0.0008)
                box(V3(0.0115, 0.0095, 0.0016), V3(x, y - 0.0005, zf + 0.0023), "plastic.matte:050505")
                box(V3(0.008, 0.0012, 0.0008), V3(x, y - 0.0028, zf + 0.0026), "metal.brass")
                box(V3(0.0145, 0.0012, 0.0016), V3(x, y + 0.0095, zf + 0.0004), (i / 6 + row) % 2 == 0 ? "plastic.matte:2A5CB8" : "plastic.matte:E8E8E4")
            }
        }
        // Rear cable-management bar with four posts, plus rear jack stubs.
        box(V3(w - 0.08, 0.006, 0.004), V3(0, h / 2, -zf + 0.012), plate)
        for k in 0..<4 { box(V3(0.004, 0.004, 0.02), V3(-0.15 + Float(k) * 0.1, h / 2, -zf + 0.022), plate) }
        for i in 0..<12 { box(V3(0.012, 0.012, 0.01), V3(x0 + Float(i) * pitch, h * 0.5, 0.0), "plastic.matte:3A3B3D") }
        groundAO(&m)
        return LODModel(m)
    }
}
