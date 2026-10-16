import simd
import Foundation

/// Bolt-action sporter, 1.12 m: oiled walnut stock with rubber pad, hot-blued 24 in barrel and receiver,
/// 3-9x40 scope on two rings. Articulated: `bolt` slides rearward, `bolt-handle` lifts about the bolt
/// axis, `trigger` pulls, `floorplate` drops. States: closed, lifted, open, floorplate-open, trigger.
public struct BoltActionRifle: RealArticulated {
    public static let id = "bolt-action-rifle"
    public static let summary = "Bolt-action hunting rifle, 1.12 m: walnut stock, blued barrel and receiver, 3-9x40 scope, articulated bolt (handle lift, draw back, close)."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.1, studio: true)

    /// Overall length in meters, butt pad to muzzle.
    public var length: Float = 1.12
    /// Barrel length in meters from the receiver face.
    public var barrelLength: Float = 0.56
    /// Stock wood.
    public var wood: MaterialKey = "wood.walnut-stock"
    /// Barrel and receiver steel.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Bolt, trigger and small parts.
    public var bright: MaterialKey = "metal.bolt-bright"
    public var pad: MaterialKey = "rubber.recoil-pad"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(-length / 2, 0.152, 0))
        let steelM = steel, brightM = bright
        let recvX0: Float = 0.30, recvX1: Float = 0.56

        rig.part("bolt", pivot: P.p(V3(0.34, 0, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...0.09, duration: 0.35))
        rig.part("bolt-handle", parent: "bolt", pivot: P.p(V3(0.405, 0, 0)), joint: .hinge(axis: V3(1, 0, 0), -95...0, duration: 0.3))
        rig.part("trigger", pivot: P.p(V3(0.415, -0.050, 0)), joint: .hinge(axis: V3(0, 0, 1), -16...0, duration: 0.15))
        rig.part("floorplate", pivot: P.p(V3(0.470, -0.080, 0)), joint: .hinge(axis: V3(0, 0, 1), 0...70, duration: 0.3))

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod, seg = hi ? 28 : 12
            // Stock: heel, comb, wrist, grip, belly, forend. Taper width: 40 mm at the butt, 31 at the wrist, 42 at the forend.
            let outline: [V2] = [V2(0, -0.040), V2(0.06, -0.031), V2(0.15, -0.024), V2(0.24, -0.028), V2(0.30, -0.022), V2(0.36, -0.012),
                                 V2(0.60, -0.009), V2(0.835, -0.008), V2(0.850, -0.020), V2(0.848, -0.044), V2(0.835, -0.053),
                                 V2(0.62, -0.058), V2(0.50, -0.070), V2(0.42, -0.084), V2(0.388, -0.095), V2(0.368, -0.125),
                                 V2(0.338, -0.142), V2(0.306, -0.128), V2(0.290, -0.100), V2(0.250, -0.094), V2(0.150, -0.112),
                                 V2(0.040, -0.140), V2(0.0, -0.152)]
            let stock = HuntKit.profileSolid(outline, radius: 0.03, width: { x in
                x < 0.05 ? 0.040 : x < 0.30 ? lerp(0.040, 0.031, smoothstep(0.05, 0.30, x)) : lerp(0.031, 0.042, smoothstep(0.30, 0.55, x))
            }, wood)
            rig.base[lod].add(stock, P.at())
            rig.base[lod].add(HuntKit.box(V3(0.012, -0.096, 0), V3(0.024, 0.114, 0.0415), r: 0.004, pad), P.at())
            // Forend tip cap and pistol grip cap in dark polymer, with a white-line spacer under each.
            rig.base[lod].add(HuntKit.box(V3(0.844, -0.0315, 0), V3(0.013, 0.046, 0.0435), r: 0.0035, "plastic.stock-synthetic"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.322, -0.137, 0), V3(0.036, 0.009, 0.034), r: 0.0035, rot: simd_quatf(degrees: -24, axis: V3(0, 0, 1)), "plastic.stock-synthetic"), P.at())
            // Barrel: tapered, with a recessed crown.
            let b0: Float = 0.48, bl = 0.56 + barrelLength - b0
            var prof: [(Float, Float)] = [(0, 0), (0, 0.0128)]
            for i in 0...10 {
                let t = Float(i) / 10
                prof.append((0.08 + (bl - 0.08 - 0.008) * t, lerp(0.0128, 0.0094, pow(t, 0.8))))
            }
            prof += [(bl - 0.002, 0.0090), (bl, 0.0076), (bl, 0.0040), (bl - 0.012, 0.0040), (bl - 0.012, 0)]
            rig.base[lod].add(HuntKit.axial(prof, at: V3(b0, 0, 0), seg: seg, steelM), P.at())
            // Front sight ramp and bead.
            rig.base[lod].add(HuntKit.box(V3(1.060, 0.0112, 0), V3(0.020, 0.008, 0.005), r: 0.0012, steelM), P.at())
            // Receiver with ejection port, front ring and rear bridge.
            let recv: [(Float, Float)] = [(0, 0), (0, 0.0160), (0.012, 0.0172), (0.040, 0.0168), (recvX1 - recvX0 - 0.03, 0.0168),
                                          (recvX1 - recvX0 - 0.012, 0.0176), (recvX1 - recvX0, 0.0160), (recvX1 - recvX0, 0)]
            rig.base[lod].add(HuntKit.axial(recv, at: V3(recvX0, 0, 0), seg: seg, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.455, 0.002, 0.0166), V3(0.080, 0.012, 0.0030), r: 0.001, "metal.parkerized"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.445, -0.012, 0), V3(0.130, 0.012, 0.030), r: 0.003, steelM), P.at())
            // Trigger guard (steel loop) and floorplate surround.
            rig.base[lod].add(HuntKit.wire([V3(0.384, -0.090, 0), V3(0.390, -0.116, 0), V3(0.416, -0.126, 0), V3(0.446, -0.114, 0), V3(0.460, -0.086, 0)],
                                           r: 0.0034, per: 6, sides: hi ? 10 : 6, steelM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.470, -0.0775, 0), V3(0.075, 0.003, 0.028), r: 0.001, steelM), P.at())
            // Scope: eyepiece bell, tube, turret housing, objective bell, rings and mount bases.
            let sx: Float = 0.345, sy: Float = 0.0425
            let scope: [(Float, Float)] = [(0, 0), (0, 0.0135), (0.003, 0.0168), (0.045, 0.0174), (0.068, 0.0140), (0.080, 0.0127),
                                           (0.195, 0.0127), (0.235, 0.0150), (0.250, 0.0220), (0.258, 0.0230), (0.318, 0.0230),
                                           (0.320, 0.0212), (0.320, 0.0205), (0.316, 0.0205), (0.316, 0)]
            rig.base[lod].add(HuntKit.axial(scope, at: V3(sx, sy, 0), seg: hi ? 36 : 16, "metal.anodized-gunmetal:15171A"), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0148), (0.024, 0.0148), (0.026, 0.0136), (0.040, 0.0136), (0.040, 0)], at: V3(sx + 0.080, sy, 0), seg: hi ? 24 : 10, "rubber.recoil-pad"), P.at())
            for rx in [sx + 0.03, sx + 0.215] {
                rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0165), (0.016, 0.0165), (0.016, 0)], at: V3(rx, sy, 0), seg: hi ? 24 : 10, steelM), P.at())
                rig.base[lod].add(HuntKit.box(V3(rx + 0.008, 0.0285, 0), V3(0.016, 0.026, 0.020), r: 0.002, steelM), P.at())
            }
            if hi {
                rig.base[lod].add(HuntKit.lensDisc(at: V3(sx - 0.0006, sy, 0), r: 0.0120), P.at())
                rig.base[lod].add(HuntKit.lensDisc(at: V3(sx + 0.3165, sy, 0), r: 0.0204), P.at())
            }
            rig.base[lod].add(HuntKit.cyl(V3(sx + 0.15, sy + 0.012, 0), V3(sx + 0.15, sy + 0.030, 0), r: 0.0095, bevel: 0.0012, seg: hi ? 20 : 8, "metal.anodized-gunmetal:15171A"), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(sx + 0.15, sy, 0.012), V3(sx + 0.15, sy, 0.030), r: 0.0095, bevel: 0.0012, seg: hi ? 20 : 8, "metal.anodized-gunmetal:15171A"), P.at())
            // Sling swivel studs.
            if hi {
                rig.base[lod].add(HuntKit.swivel(at: V3(0.620, -0.058, 0)), P.at())
                rig.base[lod].add(HuntKit.swivel(at: V3(0.190, -0.115, 0)), P.at())
            }

            // Bolt: body, shroud with cocking piece (slides). Handle swings about the bolt axis.
            rig.add(HuntKit.axial([(0, 0), (0, 0.0078), (0.20, 0.0078), (0.20, 0)], at: V3(0.30, 0, 0), seg: hi ? 20 : 10, brightM), P.at(), to: "bolt", lods: L)
            rig.add(HuntKit.axial([(0, 0), (0, 0.0105), (0.004, 0.0120), (0.040, 0.0120), (0.044, 0.0104), (0.052, 0.0104), (0.056, 0.0070), (0.070, 0.0070), (0.074, 0.0045), (0.074, 0)],
                                  at: V3(0.250, 0, 0), seg: hi ? 24 : 10, "metal.parkerized"), P.at(), to: "bolt", lods: L)
            let neck = HuntKit.wire([V3(0.405, 0, 0.0070), V3(0.402, -0.002, 0.020), V3(0.395, -0.008, 0.036), V3(0.388, -0.015, 0.047)], r: 0.0042, sides: hi ? 10 : 6, brightM)
            rig.add(neck, P.at(), to: "bolt-handle", lods: L)
            rig.add(Prim.superellipsoid(V3(0.020, 0.020, 0.028), exponent: 2, subdivisions: hi ? 16 : 8, material: brightM), P.at(V3(0.386, -0.019, 0.058)), to: "bolt-handle", lods: L)
            // Trigger and floorplate.
            rig.add(HuntKit.box(V3(0.415, -0.075, 0), V3(0.006, 0.050, 0.0035), r: 0.0012, rot: simd_quatf(degrees: -6, axis: V3(0, 0, 1)), brightM), P.at(), to: "trigger", lods: L)
            rig.add(HuntKit.box(V3(0.470, -0.0775, 0), V3(0.068, 0.0028, 0.022), r: 0.001, brightM), P.at(), to: "floorplate", lods: L)
        }
        rig.states = [RigState("closed"),
                      RigState("lifted", ["bolt-handle": -90]),
                      RigState("open", ["bolt-handle": -90, "bolt": 0.09]),
                      RigState("floorplate-open", ["floorplate": 65]),
                      RigState("trigger", ["trigger": -14])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
