import simd
import Foundation

/// Over-and-under 12 gauge, 1.12 m: walnut pistol-grip stock with pad, silvered action with top lever,
/// two 28 in blued barrels with ribs and brass bead, walnut forend. Articulated: `barrels` (with forend)
/// hinge down about the pin under the action, `top-lever` swings right, `trigger` pulls.
/// States: closed, open, lever, trigger.
public struct BreakActionShotgun: RealArticulated {
    public static let id = "break-action-shotgun"
    public static let summary = "Over-and-under 12 gauge, 1.12 m: walnut stock and forend, blued barrels, articulated break hinge and top lever."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "wood", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.1, studio: true)

    /// Overall length in meters, butt pad to muzzle.
    public var length: Float = 1.12
    /// Stock and forend wood.
    public var wood: MaterialKey = "wood.walnut-stock"
    /// Barrel steel.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Silvered action.
    public var action: MaterialKey = "metal.bolt-bright"
    public var pad: MaterialKey = "rubber.recoil-pad"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(-length / 2, 0.162, 0))
        let steelM = steel, actM = action
        let hinge = V3(0.425, -0.040, 0)

        rig.part("barrels", pivot: P.p(hinge), joint: .hinge(axis: V3(0, 0, 1), -32...0, duration: 0.5))
        rig.part("top-lever", pivot: P.p(V3(0.400, 0.0305, 0)), joint: .hinge(axis: V3(0, 1, 0), 0...28, duration: 0.25))
        rig.part("trigger", pivot: P.p(V3(0.372, -0.040, 0)), joint: .hinge(axis: V3(0, 0, 1), -14...0, duration: 0.15))

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod, seg = hi ? 28 : 12
            // Pistol-grip stock.
            let outline: [V2] = [V2(0, -0.040), V2(0.08, -0.030), V2(0.18, -0.026), V2(0.26, -0.030), V2(0.30, -0.022), V2(0.33, -0.020),
                                 V2(0.35, -0.045), V2(0.352, -0.100), V2(0.336, -0.135), V2(0.306, -0.146), V2(0.281, -0.125),
                                 V2(0.262, -0.100), V2(0.20, -0.095), V2(0.12, -0.118), V2(0.04, -0.142), V2(0, -0.154)]
            rig.base[lod].add(HuntKit.profileSolid(outline, radius: 0.03, width: { x in
                x < 0.05 ? 0.042 : lerp(0.042, 0.034, smoothstep(0.05, 0.28, x)) + 0.006 * smoothstep(0.28, 0.33, x)
            }, wood), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.012, -0.097, 0), V3(0.024, 0.116, 0.0435), r: 0.004, pad), P.at())
            // Action body (silvered), top tang, hinge pin, guard.
            rig.base[lod].add(HuntKit.box(V3(0.365, -0.011, 0), V3(0.130, 0.060, 0.040), r: 0.008, actM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.300, 0.014, 0), V3(0.040, 0.008, 0.022), r: 0.003, actM), P.at())
            rig.base[lod].add(HuntKit.wire([V3(0.335, -0.040, 0), V3(0.336, -0.062, 0), V3(0.362, -0.072, 0), V3(0.396, -0.068, 0), V3(0.420, -0.042, 0)],
                                           r: 0.0034, per: 6, sides: hi ? 10 : 6, actM), P.at())
            rig.base[lod].add(HuntKit.cyl(hinge + V3(0, 0, -0.0215), hinge + V3(0, 0, 0.0215), r: 0.0050, bevel: 0.001, seg: 16, steelM), P.at())
            if hi {
                rig.base[lod].add(HuntKit.box(V3(0.365, 0.0, 0.0205), V3(0.100, 0.002, 0.0015), r: 0.0005, "metal.blued-steel"), P.at()) // engraved border band
                rig.base[lod].add(HuntKit.swivel(at: V3(0.18, -0.110, 0)), P.at())
            }
            // Barrel pair with breech block, ribs, bead and side bands (hinged group).
            var prof: [(Float, Float)] = [(0, 0), (0, 0.0100)]
            let bl = length - 0.41
            for i in 0...10 { let t = Float(i) / 10; prof.append((0.05 + (bl - 0.07) * t, lerp(0.0100, 0.0092, t))) }
            prof += [(bl - 0.004, 0.0092), (bl - 0.002, 0.0098), (bl, 0.0088), (bl, 0.0070), (bl - 0.02, 0.0070), (bl - 0.02, 0)]
            for y: Float in [0, -0.0255] {
                rig.add(HuntKit.axial(prof, at: V3(0.41, y, 0), seg: seg, steelM), P.at(), to: "barrels", lods: L)
            }
            rig.add(HuntKit.box(V3(0.765, -0.0128, 0), V3(0.710, 0.010, 0.0072), r: 0.0012, steelM), P.at(), to: "barrels", lods: L)
            rig.add(HuntKit.box(V3(0.765, 0.0105, 0), V3(0.710, 0.0028, 0.0075), r: 0.0007, steelM), P.at(), to: "barrels", lods: L)
            rig.add(HuntKit.box(V3(0.435, -0.0128, 0), V3(0.050, 0.040, 0.028), r: 0.004, steelM), P.at(), to: "barrels", lods: L) // breech block
            rig.add(HuntKit.cyl(V3(1.085, 0.0100, 0), V3(1.085, 0.0150, 0), r: 0.0024, bevel: 0.0008, seg: 10, "metal.cartridge-brass"), P.at(), to: "barrels", lods: L)
            let fore: [V2] = [V2(0.585, -0.031), V2(0.82, -0.031), V2(0.835, -0.044), V2(0.822, -0.058), V2(0.60, -0.060), V2(0.570, -0.050)]
            rig.add(HuntKit.profileSolid(fore, radius: 0.02, width: { _ in 0.040 }, wood), P.at(), to: "barrels", lods: L)
            rig.add(HuntKit.cyl(V3(0.575, -0.0425, -0.0225), V3(0.575, -0.0425, 0.0225), r: 0.0030, bevel: 0.0008, seg: 10, actM), P.at(), to: "barrels", lods: L)
            // Top lever: pivot boss and blade pointing toward the shooter.
            rig.add(HuntKit.cyl(V3(0.400, 0.0180, 0), V3(0.400, 0.0305, 0), r: 0.0045, bevel: 0.001, seg: 14, actM), P.at(), to: "top-lever", lods: L)
            rig.add(HuntKit.box(V3(0.368, 0.0292, 0), V3(0.062, 0.0035, 0.0100), r: 0.0012, actM), P.at(), to: "top-lever", lods: L)
            // Single selective trigger, gold.
            rig.add(HuntKit.box(V3(0.372, -0.060, 0), V3(0.006, 0.034, 0.0035), r: 0.0012, rot: simd_quatf(degrees: -8, axis: V3(0, 0, 1)), "metal.cartridge-brass"), P.at(), to: "trigger", lods: L)
        }
        rig.states = [RigState("closed"), RigState("open", ["barrels": -32]), RigState("lever", ["top-lever": 26]), RigState("trigger", ["trigger": -12])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
