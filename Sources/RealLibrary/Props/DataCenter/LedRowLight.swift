import simd
import Foundation

/// LED row light: Data hall linear fixture, brushed aluminum housing, frosted diffuser, aircraft-cable hangers. Parts: housing, diffuser, end caps, hangers, power lead.
public struct LedRowLight: RealAsset {
    public static let id = "led-row-light"
    public static let summary = "2.4 m aluminum linear LED fixture with frosted diffuser, end caps, aircraft-cable hangers and an emissive on/off knob."
    public static let tags = ["prop"]
    public static let budget = 1200
    public static let author = "realityhd"

    /// Overall size in meters (x length, y height, z width). Hanger cables rise above y = size.y.
    public var size = V3(2.4, 0.06, 0.12)
    /// Emissive on (true) or off (false); off swaps the diffuser to unlit frosted plastic.
    public var on = true
    /// Cable length from fixture top to ceiling plate in meters.
    public var cableDrop: Float = 0.3
    /// Housing material.
    public var housing: MaterialKey = "metal.aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let L = size.x, H = size.y, W = size.z
        let steel: MaterialKey = "metal.stainless"
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0) {
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Housing: top spine and two side walls forming a channel, open at the bottom.
        let t: Float = 0.0025
        box(V3(L - 0.04, t, W), V3(0, H - t / 2, 0), housing, r: 0.002)
        for s: Float in [-1, 1] {
            box(V3(L - 0.04, H * 0.8, t), V3(0, H * 0.6, s * (W / 2 - t / 2)), housing)
            // Lower lip folded inward to hold the diffuser.
            box(V3(L - 0.04, t, 0.012), V3(0, H * 0.2, s * (W / 2 - 0.006)), housing)
        }
        // Diffuser: slightly domed frosted lens sitting in the lip.
        let diff: MaterialKey = on ? "emissive.panel" : "plastic.matte:D8D9D6"
        m.add(Prim.roundedBox(V3(L - 0.044, 0.012, W - 0.026), radius: 0.004, bevelSegments: 1, material: diff), Xform(translation: V3(0, 0.014, 0)))
        // Driver cover and ribs on the spine top.
        box(V3(0.28, 0.012, 0.05), V3(0.7, H + 0.006, 0), "metal.aluminum-brushed", r: 0.002)
        for i in 0..<6 {
            box(V3(0.0015, 0.004, W - 0.03), V3(-L / 2 + 0.2 + Float(i) * 0.36, H + 0.002, 0), housing, r: 0)
        }
        // End caps with a screw each.
        for s: Float in [-1, 1] {
            box(V3(0.018, H, W + 0.004), V3(s * (L / 2 - 0.009), H / 2, 0), "plastic.matte:C9CBC9", r: 0)
            m.add(Prim.cylinder(radius: 0.003, height: 0.002, bevel: 0, segments: 6, bevelSegments: 1, material: steel),
                  Xform(translation: V3(s * (L / 2 - 0.0005), H * 0.55, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Aircraft-cable hangers at 1/4 and 3/4: clamp block, two crossed cables up to a ceiling plate.
        for s: Float in [-1, 1] {
            let x = s * L * 0.3
            box(V3(0.03, 0.014, 0.03), V3(x, H + 0.007, 0), steel, r: 0.002)
            for c: Float in [-1, 1] {
                let top = V3(x + c * 0.045, H + cableDrop, 0)
                m.add(Prim.tube([V3(x + c * 0.004, H + 0.012, 0), top], radii: [0.0012, 0.0012], sides: 6, seamTile: 0.1, material: steel), Xform())
            }
            box(V3(0.14, 0.004, 0.05), V3(x, H + cableDrop + 0.002, 0), "metal.galvanized", r: 0.001)
            m.add(Prim.cylinder(radius: 0.008, height: 0.012, bevel: 0, segments: 6, bevelSegments: 1, material: steel), Xform(translation: V3(x, H + cableDrop - 0.004, 0)))
        }
        // Rating label on the spine and a lens edge glow strip along the front.
        box(V3(0.07, 0.0006, 0.03), V3(-0.5, H + 0.0003, 0), "plastic.matte:E8E8E4")
        box(V3(L - 0.05, 0.004, 0.003), V3(0, 0.03, W / 2 + 0.0008), on ? "emissive.panel" : "plastic.matte:D8D9D6")
        // Power lead from the driver cover.
        m.add(Prim.tube(catmull([V3(0.56, H + 0.008, 0), V3(0.5, H + 0.04, 0.01), V3(0.2, H + 0.05, 0.005), V3(-0.3, H + 0.03, 0)], per: 2), radii: Array(repeating: 0.0025, count: 7), sides: 4, seamTile: 0.1, material: "rubber.tubing:1A1A1A"), Xform())
        return LODModel(m)
    }
}
