import simd
import Foundation

/// Lever-action carbine, 0.99 m: straight-grip walnut stock and slim forend, blued 20 in barrel over a
/// tube magazine, steel receiver with brass loading gate. Articulated: `lever` swings down (carrying
/// `trigger`), `bolt` slides back on the receiver top as the lever opens, `hammer` cocks.
/// States: closed, open, cocked, trigger.
public struct LeverActionRifle: RealArticulated {
    public static let id = "lever-action-rifle"
    public static let summary = "Lever-action carbine, 0.99 m: walnut stock and forend, blued barrel with tube magazine, articulated lever, bolt and hammer."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "wood", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.05, studio: true)

    /// Overall length in meters, butt plate to muzzle.
    public var length: Float = 0.99
    /// Stock and forend wood.
    public var wood: MaterialKey = "wood.walnut-stock"
    /// Barrel, receiver and magazine tube steel.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Lever, trigger and hammer finish.
    public var bright: MaterialKey = "metal.bolt-bright"
    public var butt: MaterialKey = "metal.blued-steel"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(-length / 2, 0.152, 0))
        let steelM = steel, brightM = bright
        let leverPivot = V3(0.388, -0.032, 0)

        rig.part("lever", pivot: P.p(leverPivot), joint: .hinge(axis: V3(0, 0, 1), -62...0, duration: 0.35))
        rig.part("trigger", parent: "lever", pivot: P.p(V3(0.415, -0.050, 0)), joint: .hinge(axis: V3(0, 0, 1), -14...0, duration: 0.15))
        rig.part("bolt", pivot: P.p(V3(0.40, 0.025, 0)), joint: Joint(.prismatic, axis: V3(-1, 0, 0), range: 0...0.05, mimic: .init("lever", ratio: -0.0008)))
        rig.part("hammer", pivot: P.p(V3(0.318, 0.012, 0)), joint: .hinge(axis: V3(0, 0, 1), -38...0, duration: 0.2))

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod, seg = hi ? 28 : 12
            // Straight-grip stock.
            let outline: [V2] = [V2(0, -0.038), V2(0.06, -0.028), V2(0.16, -0.024), V2(0.24, -0.020), V2(0.36, -0.016), V2(0.36, -0.072),
                                 V2(0.30, -0.074), V2(0.22, -0.090), V2(0.12, -0.125), V2(0.04, -0.148), V2(0, -0.152)]
            rig.base[lod].add(HuntKit.profileSolid(outline, radius: 0.03, width: { x in
                x < 0.06 ? 0.036 : lerp(0.036, 0.030, smoothstep(0.06, 0.30, x)) + 0.004 * smoothstep(0.30, 0.36, x)
            }, wood), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.005, -0.095, 0), V3(0.012, 0.113, 0.0375), r: 0.003, butt), P.at())
            // Forend.
            let fore: [V2] = [V2(0.500, -0.010), V2(0.795, -0.010), V2(0.805, -0.026), V2(0.797, -0.047), V2(0.62, -0.047), V2(0.500, -0.054)]
            rig.base[lod].add(HuntKit.profileSolid(fore, radius: 0.02, width: { _ in 0.034 }, wood), P.at())
            // Barrel and tube magazine.
            var prof: [(Float, Float)] = [(0, 0), (0, 0.0108)]
            for i in 0...8 { let t = Float(i) / 8; prof.append((0.1 + 0.382 * t, lerp(0.0108, 0.0098, t))) }
            prof += [(0.488, 0.0092), (0.490, 0.0078), (0.490, 0.0040), (0.478, 0.0040), (0.478, 0)]
            rig.base[lod].add(HuntKit.axial(prof, at: V3(0.50, 0, 0), seg: seg, steelM), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0085), (0.385, 0.0085), (0.388, 0.0075), (0.388, 0)], at: V3(0.50, -0.0215, 0), seg: seg, steelM), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0100), (0.012, 0.0100), (0.012, 0)], at: V3(0.800, -0.0215, 0), seg: hi ? 20 : 10, steelM), P.at())
            // Barrel band, front sight blade and hood base, buckhorn rear sight.
            rig.base[lod].add(HuntKit.box(V3(0.800, -0.0105, 0), V3(0.014, 0.043, 0.022), r: 0.003, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.955, 0.0125, 0), V3(0.016, 0.009, 0.004), r: 0.001, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.600, 0.0118, 0), V3(0.020, 0.008, 0.012), r: 0.0015, steelM), P.at())
            if hi {
                rig.base[lod].add(HuntKit.box(V3(0.600, 0.0178, 0.0045), V3(0.010, 0.010, 0.0025), r: 0.0007, brightM), P.at())
                rig.base[lod].add(HuntKit.box(V3(0.600, 0.0178, -0.0045), V3(0.010, 0.010, 0.0025), r: 0.0007, brightM), P.at())
            }
            // Receiver, loading gate, top ejection slot, tang.
            rig.base[lod].add(HuntKit.box(V3(0.400, -0.0055, 0), V3(0.200, 0.061, 0.032), r: 0.011, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.470, -0.006, 0.0165), V3(0.032, 0.022, 0.002), r: 0.0008, "metal.bolt-bright"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.400, 0.0252, 0), V3(0.120, 0.003, 0.013), r: 0.0008, "metal.parkerized"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.330, -0.020, 0), V3(0.080, 0.012, 0.022), r: 0.003, steelM), P.at())
            if hi {
                rig.base[lod].add(HuntKit.cyl(V3(0.370, -0.0055, 0.016), V3(0.370, -0.0055, 0.0185), r: 0.0042, bevel: 0.0006, seg: 12, brightM), P.at())
                rig.base[lod].add(HuntKit.cyl(V3(0.436, 0.012, 0.016), V3(0.436, 0.012, 0.0185), r: 0.0042, bevel: 0.0006, seg: 12, brightM), P.at())
                rig.base[lod].add(HuntKit.swivel(at: V3(0.700, -0.047, 0)), P.at())
                rig.base[lod].add(HuntKit.swivel(at: V3(0.150, -0.110, 0)), P.at())
            }
            // Lever loop and trigger.
            rig.add(HuntKit.wire([leverPivot, V3(0.430, -0.040, 0), V3(0.468, -0.058, 0), V3(0.474, -0.082, 0), V3(0.450, -0.102, 0),
                                  V3(0.410, -0.108, 0), V3(0.375, -0.098, 0), V3(0.358, -0.075, 0), V3(0.356, -0.055, 0)],
                                 r: 0.0045, per: 6, sides: hi ? 10 : 6, brightM), P.at(), to: "lever", lods: L)
            rig.add(HuntKit.cyl(leverPivot + V3(0, 0, -0.012), leverPivot + V3(0, 0, 0.012), r: 0.0042, bevel: 0.0007, seg: 12, brightM), P.at(), to: "lever", lods: L)
            rig.add(HuntKit.box(V3(0.415, -0.072, 0), V3(0.005, 0.040, 0.0035), r: 0.0012, rot: simd_quatf(degrees: -7, axis: V3(0, 0, 1)), brightM), P.at(), to: "trigger", lods: L)
            // Bolt bar on the receiver top.
            rig.add(HuntKit.box(V3(0.385, 0.0262, 0), V3(0.070, 0.003, 0.009), r: 0.0008, brightM), P.at(), to: "bolt", lods: L)
            // Hammer: pivot boss, neck and checkered spur.
            rig.add(HuntKit.wire([V3(0.318, 0.012, 0), V3(0.306, 0.018, 0), V3(0.292, 0.020, 0)], r: 0.0045, sides: hi ? 10 : 6, brightM), P.at(), to: "hammer", lods: L)
            rig.add(HuntKit.box(V3(0.289, 0.0225, 0), V3(0.014, 0.0045, 0.012), r: 0.0012, rot: simd_quatf(degrees: 18, axis: V3(0, 0, 1)), brightM), P.at(), to: "hammer", lods: L)
        }
        rig.states = [RigState("closed"),
                      RigState("open", ["lever": -62]),
                      RigState("cocked", ["hammer": -38]),
                      RigState("trigger", ["trigger": -12])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
