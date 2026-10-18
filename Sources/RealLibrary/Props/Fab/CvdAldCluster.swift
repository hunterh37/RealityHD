import simd
import Foundation

/// CVD/ALD cluster tool, generic, 4 x 2.5 x 4 m. Variant of ClusterTool: four aluminum chambers with heated showerhead
/// lids (insulation jacket, heater leads, gas feed manifold), a precursor ampoule cabinet under each gas tray and extra
/// gas sticks. Named parts: lid-1...lid-4.
public struct CvdAldCluster: RealArticulated {
    public static let id = "cvd-ald-cluster"
    public static let summary = "CVD/ALD cluster: hex transfer chamber, 4 chambers with heated showerhead lids, precursor ampoule cabinets, 8 gas sticks each, EFEM."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.0, studio: true)

    /// EFEM and load lock skin powdercoat (sRGB hex).
    public var color: UInt32 = 0xE8EAE6
    /// Gas sticks per chamber.
    public var gasSticks = 7
    /// Showerhead jacket tape color (sRGB hex).
    public var jacketColor: UInt32 = 0xC9963A
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        var spec = ClusterSpec()
        spec.skinMat = MaterialKey(stringLiteral: "metal.powdercoat:" + String(format: "%06X", color))
        spec.gasSticks = gasSticks
        spec.matchBoxes = false
        let jacket = MaterialKey(stringLiteral: "plastic.matte:" + String(format: "%06X", jacketColor))
        spec.chamberExtra = { k, c, d, t, top, ln, _ in
            let steel: MaterialKey = "metal.stainless", brass: MaterialKey = "metal.brass", black: MaterialKey = "plastic.matte:1E2023"
            let yaw = 90 - Float(atan2(d.z, d.x)) * 180 / .pi
            // Heated showerhead lid: insulation jacket, heater ring, gas feed manifold, heater leads.
            k.cyl(0.3, 0.07, V3(c.x, top + 0.115 + 0.035, c.z), jacket, seg: k.hi ? 12 : 6, name: ln)
            k.cyl(0.31, 0.012, V3(c.x, top + 0.115 + 0.076, c.z), steel, seg: k.hi ? 12 : 6, name: ln)
            k.cyl(0.07, 0.14, V3(c.x, top + 0.115 + 0.15, c.z), steel, seg: 9, name: ln)
            k.bx(V3(0.3, 0.05, 0.06), V3(c.x, top + 0.115 + 0.19, c.z), steel, r: 0.003, yaw: yaw, name: ln)
            for q: Float in [-1, 1] {
                let p = c + t * q * 0.15
                k.cyl(0.018, 0.1, V3(p.x, top + 0.115 + 0.24, p.z), brass, seg: 8, name: ln)
                k.bx(V3(0.05, 0.05, 0.05), V3(p.x, top + 0.115 + 0.3, p.z), black, r: 0.004, yaw: yaw, name: ln)
                let h = c + d * 0.22 + t * q * 0.11
                k.bx(V3(0.06, 0.06, 0.06), V3(h.x, top + 0.115 + 0.05, h.z), "metal.anodized", r: 0.004, yaw: yaw, name: ln)
            }
            // Precursor ampoule cabinet under the gas tray.
            let gc = c + d * (0.46 + 0.2), cy: Float = 0.12
            let ch = top + 0.14 - cy
            k.bx(V3(0.48, ch, 0.3), V3(gc.x, cy + ch / 2, gc.z), "metal.powdercoat:D4D6D2", r: 0.004, yaw: yaw)
            k.bx(V3(0.4, ch * 0.78, 0.01), V3(gc.x, cy + ch * 0.5, gc.z) + d * 0.152, "metal.powdercoat:C2C5C2", r: 0.002, yaw: yaw)
            k.bx(V3(0.3, 0.36, 0.008), V3(gc.x, cy + ch * 0.62, gc.z) + d * 0.158, "glass.window-tint", r: 0.002, yaw: yaw)
            k.bx(V3(0.012, 0.16, 0.02), V3(gc.x, cy + ch * 0.35, gc.z) + d * 0.165 + t * 0.17, steel, r: 0.003, yaw: yaw)
            k.bx(V3(0.36, 0.05, 0.008), V3(gc.x, cy + ch - 0.07, gc.z) + d * 0.155, "plastic.matte:2A2C2F", r: 0.001, yaw: yaw)
            k.bx(V3(0.07, 0.015, 0.004), V3(gc.x + t.x * 0.1, cy + ch * 0.2, gc.z + t.z * 0.1) + d * 0.158, "glass.lamp:40E060", r: 0.0005, yaw: yaw)
            if k.hi {
                for q: Float in [-1, 1] {
                    let p = gc + t * q * 0.1 - d * 0.02
                    k.cyl(0.04, 0.2, V3(p.x, cy + ch * 0.62 - 0.05, p.z), steel, seg: 9)
                    k.cyl(0.015, 0.06, V3(p.x, cy + ch * 0.62 + 0.08, p.z), brass, seg: 7)
                }
            }
            // Heated delivery line (jacket wrapped) from the cabinet side to the chamber body.
            let a0 = gc + t * 0.25 + V3(0, ch * 0.75 + cy, 0)
            k.tube([a0, a0 + d * 0.0 + t * 0.07 + V3(0, 0.08, 0), c + t * 0.34 + d * 0.15 + V3(0, top - 0.08, 0), c + t * 0.4 + V3(0, top - 0.1, 0)], 0.016, jacket, sides: 6)
        }
        ClusterTool.declareParts(&rig, spec)
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            ClusterTool.assemble(k, spec, status: V3(1.3, 0, 1.3))
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"),
                      RigState("lids-open", (1...4).reduce(into: [String: Float]()) { $0["lid-\($1)"] = -100 })]
        return rig
    }
}
