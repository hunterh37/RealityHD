import simd
import Foundation

/// PVD sputter cluster tool, generic, 4 x 2.5 x 4 m. Variant of ClusterTool: four aluminum chambers with magnetron
/// cathode lids (magnet housing, rotation motor, HV feedthrough, water lines), tall cryopump cylinders under the
/// gas trays with gate valves, helium lines to the floor. Named parts: lid-1...lid-4.
public struct PvdCluster: RealArticulated {
    public static let id = "pvd-cluster"
    public static let summary = "PVD cluster: hex transfer chamber, 4 sputter chambers with magnetron cathode lids, tall cryopumps, load locks, EFEM."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.0, studio: true)

    /// EFEM and load lock skin powdercoat (sRGB hex).
    public var color: UInt32 = 0xE4E6E8
    /// Gas sticks per chamber.
    public var gasSticks = 3
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        var spec = ClusterSpec()
        spec.skinMat = MaterialKey(stringLiteral: "metal.powdercoat:" + String(format: "%06X", color))
        spec.gasSticks = gasSticks
        spec.matchBoxes = false
        spec.chamberExtra = { k, c, d, t, top, ln, _ in
            let steel: MaterialKey = "metal.stainless", brass: MaterialKey = "metal.brass", black: MaterialKey = "plastic.matte:1E2023"
            let yaw = 90 - Float(atan2(d.z, d.x)) * 180 / .pi
            let lt = top + 0.115
            // Magnetron cathode: housing, cooling cap, rotation motor, HV feedthrough, water lines.
            k.cyl(0.19, 0.03, V3(c.x, lt + 0.015, c.z), steel, seg: k.hi ? 12 : 6, name: ln)
            k.cyl(0.165, 0.2, V3(c.x, lt + 0.13, c.z), "metal.anodized", seg: k.hi ? 12 : 6, name: ln)
            k.cyl(0.175, 0.016, V3(c.x, lt + 0.238, c.z), steel, seg: k.hi ? 12 : 6, name: ln)
            k.cyl(0.055, 0.16, V3(c.x, lt + 0.33, c.z), "metal.powdercoat:2A2C2F", seg: 9, name: ln)
            let hv = c + d * 0.1
            k.cyl(0.03, 0.1, V3(hv.x, lt + 0.3, hv.z), "plastic.matte:E8E4D8", seg: 9, name: ln)
            k.cyl(0.038, 0.02, V3(hv.x, lt + 0.355, hv.z), brass, seg: 9, name: ln)
            k.cyl(0.02, 0.07, V3(hv.x, lt + 0.4, hv.z), black, seg: 8, name: ln)
            for q: Float in [-1, 1] {
                let w = c - d * 0.08 + t * q * 0.11
                k.cyl(0.014, 0.12, V3(w.x, lt + 0.3, w.z), "rubber.tubing", seg: 8, name: ln)
                k.bx(V3(0.03, 0.03, 0.03), V3(w.x, lt + 0.37, w.z), brass, r: 0.003, yaw: yaw, name: ln)
            }
            k.bx(V3(0.24, 0.02, 0.02), V3(c.x + t.x * 0.0, lt + 0.45, c.z + t.z * 0.0) - d * 0.1, black, r: 0.002, yaw: yaw, name: ln)
            // Tall cryopump under the gas tray, gate valve to the chamber, helium lines to the floor.
            let gc = c + d * (0.46 + 0.2), py: Float = 0.12
            let ph = top + 0.12 - py
            k.cyl(0.15, ph, V3(gc.x, py + ph / 2, gc.z), steel, seg: k.hi ? 12 : 6)
            k.cyl(0.18, 0.03, V3(gc.x, py + ph - 0.015, gc.z), steel, seg: k.hi ? 12 : 6)
            k.cyl(0.18, 0.025, V3(gc.x, py + 0.0125, gc.z), steel, seg: k.hi ? 12 : 6)
            let gv = c + d * 0.58
            k.bx(V3(0.14, 0.2, 0.2), V3(gv.x, top - 0.16, gv.z), "metal.anodized", r: 0.004, yaw: yaw)
            k.bx(V3(0.06, 0.06, 0.05), V3(gv.x + t.x * 0.1, top - 0.16, gv.z + t.z * 0.1), black, r: 0.003, yaw: yaw)
            k.tube([V3(gc.x, top - 0.16, gc.z), V3(gv.x, top - 0.16, gv.z)], 0.04, steel, sides: 10)
            if k.hi {
                for q: Float in [-1, 1] {
                    let p = gc + t * q * 0.1 + V3(0, py + 0.16, 0)
                    k.cyl(0.022, 0.08, V3(p.x, p.y, p.z), black, seg: 7)
                    k.tube([gc + t * q * 0.1 + V3(0, py + 0.2, 0), gc + t * q * 0.3 + V3(0, py + 0.2, 0), gc + t * q * 0.44 + V3(0, 0.05, 0)], 0.014, black, sides: 5)
                }
            }
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
