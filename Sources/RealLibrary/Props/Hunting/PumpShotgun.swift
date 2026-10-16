import simd
import Foundation

/// Pump-action 12 gauge, 1.26 m: walnut pistol-grip stock with rubber pad, steel receiver, 28 in
/// blued barrel with vent rib and brass bead over a tube magazine. Articulated: `pump` forend slides
/// 75 mm rearward on its action bars, `bolt` follows in the ejection port, `trigger` pulls.
/// States: closed, pumped, trigger.
public struct PumpShotgun: RealArticulated {
    public static let id = "pump-shotgun"
    public static let summary = "Pump-action 12 gauge shotgun, 1.26 m: walnut stock, blued barrel over tube magazine, articulated sliding pump forend."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "wood", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.1, studio: true)

    /// Overall length in meters, butt pad to muzzle.
    public var length: Float = 1.26
    /// Stock and forend wood.
    public var wood: MaterialKey = "wood.walnut-stock"
    /// Barrel and magazine steel.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Receiver finish.
    public var receiver: MaterialKey = "metal.blued-steel"
    public var bright: MaterialKey = "metal.bolt-bright"
    public var pad: MaterialKey = "rubber.recoil-pad"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(-length / 2, 0.152, 0))
        let steelM = steel, recvM = receiver, brightM = bright

        rig.part("pump", pivot: P.p(V3(0.74, -0.03, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...0.075, duration: 0.4))
        rig.part("bolt", pivot: P.p(V3(0.47, 0.004, 0)), joint: Joint(.prismatic, axis: V3(-1, 0, 0), range: 0...0.075, mimic: .init("pump", ratio: 1)))
        rig.part("trigger", pivot: P.p(V3(0.386, -0.040, 0)), joint: .hinge(axis: V3(0, 0, 1), -14...0, duration: 0.15))

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod, seg = hi ? 28 : 12
            // Pistol-grip stock.
            let outline: [V2] = [V2(0, -0.038), V2(0.08, -0.026), V2(0.18, -0.022), V2(0.26, -0.026), V2(0.30, -0.018), V2(0.33, -0.016),
                                 V2(0.36, -0.040), V2(0.362, -0.100), V2(0.345, -0.135), V2(0.315, -0.145), V2(0.290, -0.125),
                                 V2(0.268, -0.100), V2(0.20, -0.095), V2(0.12, -0.115), V2(0.04, -0.140), V2(0, -0.152)]
            rig.base[lod].add(HuntKit.profileSolid(outline, radius: 0.03, width: { x in
                x < 0.05 ? 0.040 : lerp(0.040, 0.032, smoothstep(0.05, 0.28, x))
            }, wood), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.012, -0.096, 0), V3(0.024, 0.114, 0.0415), r: 0.004, pad), P.at())
            // Receiver with ejection port, trigger plate and guard.
            rig.base[lod].add(HuntKit.box(V3(0.430, -0.012, 0), V3(0.260, 0.050, 0.034), r: 0.010, recvM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.455, 0.002, 0.0172), V3(0.095, 0.017, 0.0025), r: 0.0010, "metal.parkerized"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.390, -0.040, 0), V3(0.110, 0.008, 0.022), r: 0.002, recvM), P.at())
            rig.base[lod].add(HuntKit.wire([V3(0.352, -0.040, 0), V3(0.355, -0.064, 0), V3(0.380, -0.074, 0), V3(0.414, -0.070, 0), V3(0.436, -0.042, 0)],
                                           r: 0.0034, per: 6, sides: hi ? 10 : 6, recvM), P.at())
            if hi {
                rig.base[lod].add(HuntKit.cyl(V3(0.405, -0.045, -0.011), V3(0.405, -0.045, 0.011), r: 0.0042, bevel: 0.0008, seg: 14, "metal.parkerized"), P.at()) // safety
                rig.base[lod].add(HuntKit.cyl(V3(0.340, -0.0125, 0.017), V3(0.340, -0.0125, 0.0195), r: 0.0040, bevel: 0.0006, seg: 12, brightM), P.at())
            }
            // Barrel with chambered rear, vent rib and bead; magazine tube and cap.
            let b0: Float = 0.50, bl = length - b0
            var prof: [(Float, Float)] = [(0, 0), (0, 0.0135)]
            for i in 0...10 { let t = Float(i) / 10; prof.append((0.06 + (bl - 0.075) * t, lerp(0.0135, 0.0098, pow(t, 0.7)))) }
            prof += [(bl - 0.014, 0.0098), (bl - 0.002, 0.0105), (bl, 0.0092), (bl, 0.0072), (bl - 0.02, 0.0072), (bl - 0.02, 0)]
            rig.base[lod].add(HuntKit.axial(prof, at: V3(b0, 0, 0), seg: seg, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.915, 0.0128, 0), V3(0.680, 0.0030, 0.0075), r: 0.0007, steelM), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0108), (0.44, 0.0108), (0.446, 0.0095), (0.446, 0)], at: V3(0.56, -0.0235, 0), seg: seg, steelM), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0116), (0.014, 0.0116), (0.014, 0)], at: V3(0.986, -0.0235, 0), seg: hi ? 20 : 10, brightM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.990, -0.0105, 0), V3(0.020, 0.040, 0.018), r: 0.003, steelM), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(1.235, 0.0125, 0), V3(1.235, 0.0172, 0), r: 0.0025, bevel: 0.0008, seg: 10, "metal.cartridge-brass"), P.at())
            if hi { rig.base[lod].add(HuntKit.swivel(at: V3(0.18, -0.108, 0)), P.at()) }

            // Pump forend on action bars, with the bolt face visible in the port.
            let fore: [V2] = [V2(0.62, -0.016), V2(0.85, -0.016), V2(0.872, -0.030), V2(0.862, -0.052), V2(0.64, -0.058), V2(0.62, -0.050)]
            rig.add(HuntKit.profileSolid(fore, radius: 0.02, width: { x in lerp(0.040, 0.046, smoothstep(0.62, 0.80, x)) }, wood), P.at(), to: "pump", lods: L)
            for z: Float in [-0.0135, 0.0135] {
                rig.add(HuntKit.rod(V3(0.50, -0.0235, z), V3(0.70, -0.0235, z), r: 0.0030, sides: hi ? 8 : 6, brightM), P.at(), to: "pump", lods: L)
            }
            rig.add(HuntKit.box(V3(0.610, -0.0235, 0), V3(0.016, 0.018, 0.034), r: 0.002, steelM), P.at(), to: "pump", lods: L)
            if hi {
                for i in 0..<8 { // fine cross-hatch grooves on the forend
                    rig.add(HuntKit.box(V3(0.668 + Float(i) * 0.013, -0.057, 0), V3(0.0016, 0.0016, 0.034), r: 0.0004, "wood.walnut-stock:2A160C"), P.at(), to: "pump", lods: L)
                }
            }
            rig.add(HuntKit.box(V3(0.470, 0.004, 0.0170), V3(0.040, 0.010, 0.003), r: 0.001, brightM), P.at(), to: "bolt", lods: L)
            rig.add(HuntKit.box(V3(0.386, -0.062, 0), V3(0.006, 0.036, 0.0035), r: 0.0012, rot: simd_quatf(degrees: -8, axis: V3(0, 0, 1)), brightM), P.at(), to: "trigger", lods: L)
        }
        rig.states = [RigState("closed"), RigState("pumped", ["pump": 0.075]), RigState("trigger", ["trigger": -12])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
