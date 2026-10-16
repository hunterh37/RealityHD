import simd
import Foundation

/// Crossbow, 0.86 m long with a 0.68 m limb span: synthetic stock with pistol grip, aluminum flight rail,
/// camo recurve limbs on an alloy prod, foot stirrup, 4x32 scope. Design space has +X toward the muzzle.
/// Articulated: `draw` slides the string carriage back to the latch (300 mm), the limbs flex
/// (`limb-right`, `limb-left` mimic `draw`), `string` swaps through six draw-length meshes, `trigger`
/// pulls, `safety` slides. States: fired, half-cocked, cocked, trigger-pulled.
public struct Crossbow: RealArticulated {
    public static let id = "crossbow"
    public static let summary = "Crossbow, 0.86 m: synthetic stock, recurve limbs, scope, articulated string (cocked and fired)."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "metal", "plastic"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 38, distance: 1.7, studio: true)

    /// Draw length from the fired nock position to the latch in meters.
    public var drawLength: Float = 0.30
    /// Limb flex at full draw in degrees.
    public var limbFlex: Float = 10
    public var stock: MaterialKey = "plastic.stock-synthetic:2A2E22"
    public var limbs: MaterialKey = "paint.bow-camo"
    public var hardware: MaterialKey = "metal.anodized-gunmetal:1A1B1E"
    public var string: MaterialKey = "fabric.bowstring"
    public init() {}

    static let levels = 6

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(-0.43, 0.150, 0))
        let hardM = hardware, stockM = stock, limbM = limbs
        let pivotR = V3(0.725, 0, 0.075), pivotL = V3(0.725, 0, -0.075)
        let tipRest = V3(0.705, 0, 0.345)
        let nockRest: Float = 0.68, sy: Float = 0.012

        rig.part("draw", pivot: P.p(V3(nockRest, sy, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...drawLength, duration: 0.8))
        rig.part("limb-right", pivot: P.p(pivotR), joint: Joint(.revolute, axis: V3(0, 1, 0), range: -(limbFlex + 2)...(limbFlex + 2), mimic: .init("draw", ratio: -limbFlex / drawLength)))
        rig.part("limb-left", pivot: P.p(pivotL), joint: Joint(.revolute, axis: V3(0, 1, 0), range: -(limbFlex + 2)...(limbFlex + 2), mimic: .init("draw", ratio: limbFlex / drawLength)))
        rig.part("string", pivot: P.p(V3(nockRest, sy, 0)), joint: Joint(.revolute, axis: V3(0, 1, 0), range: 0...0), options: Self.levels)
        rig.part("trigger", pivot: P.p(V3(0.392, -0.040, 0)), joint: .hinge(axis: V3(0, 0, 1), -16...0, duration: 0.15))
        rig.part("safety", pivot: P.p(V3(0.380, -0.022, 0.0215)), joint: .slide(axis: V3(1, 0, 0), 0...0.008, duration: 0.1))
        rig.optionLinks = [RigOptionLink(part: "string", joint: "draw", thresholds: (1..<Self.levels).map { (Float($0) - 0.5) * drawLength / Float(Self.levels - 1) })]

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod
            // Stock: butt, pistol grip, trigger housing, forearm under the rail.
            let outline: [V2] = [V2(0, -0.030), V2(0.08, -0.022), V2(0.20, -0.020), V2(0.27, -0.020), V2(0.78, -0.020), V2(0.800, -0.032),
                                 V2(0.78, -0.050), V2(0.52, -0.052), V2(0.45, -0.075), V2(0.43, -0.090), V2(0.41, -0.145), V2(0.370, -0.155),
                                 V2(0.322, -0.142), V2(0.300, -0.100), V2(0.270, -0.085), V2(0.18, -0.100), V2(0.08, -0.128), V2(0, -0.134)]
            rig.base[lod].add(HuntKit.profileSolid(outline, radius: 0.006, width: { x in
                x < 0.10 ? 0.040 : x < 0.30 ? lerp(0.040, 0.034, smoothstep(0.10, 0.30, x)) : x < 0.46 ? 0.040 : lerp(0.040, 0.030, smoothstep(0.46, 0.60, x))
            }, stockM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.006, -0.082, 0), V3(0.014, 0.108, 0.0415), r: 0.004, "rubber.recoil-pad"), P.at())
            // Flight rail with arrow groove, trigger housing, latch, trigger guard.
            rig.base[lod].add(HuntKit.box(V3(0.570, -0.010, 0), V3(0.600, 0.020, 0.036), r: 0.003, hardM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.570, 0.0003, 0), V3(0.600, 0.0016, 0.0060), r: 0.0005, "plastic.stock-synthetic"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.375, -0.032, 0), V3(0.130, 0.036, 0.042), r: 0.005, hardM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.380, 0.0056, 0), V3(0.044, 0.012, 0.030), r: 0.003, "metal.bolt-bright"), P.at())
            rig.base[lod].add(HuntKit.wire([V3(0.350, -0.050, 0), V3(0.352, -0.075, 0), V3(0.385, -0.086, 0), V3(0.420, -0.082, 0), V3(0.436, -0.052, 0)],
                                           r: 0.0034, per: 6, sides: hi ? 10 : 6, hardM), P.at())
            // Prod riser, limb pockets, stirrup, barrel-end bolt retainer.
            rig.base[lod].add(HuntKit.box(V3(0.752, 0.0, 0), V3(0.090, 0.046, 0.100), r: 0.006, hardM), P.at())
            for s: Float in [1, -1] { rig.base[lod].add(HuntKit.box(V3(0.738, 0, s * 0.082), V3(0.056, 0.040, 0.044), r: 0.005, hardM), P.at()) }
            rig.base[lod].add(Prim.torus(major: 0.046, minor: 0.0045, segments: hi ? 36 : 16, sides: hi ? 10 : 6, material: hardM).transformed(Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1)))),
                              P.at(V3(0.870, -0.012, 0)))
            // Scope.
            let sx: Float = 0.300, sy2: Float = 0.050
            let scope: [(Float, Float)] = [(0, 0), (0, 0.0128), (0.003, 0.0155), (0.030, 0.0158), (0.048, 0.0128), (0.130, 0.0128), (0.152, 0.0150),
                                           (0.160, 0.0196), (0.166, 0.0204), (0.212, 0.0204), (0.214, 0.0190), (0.214, 0.0182), (0.210, 0.0182), (0.210, 0)]
            rig.base[lod].add(HuntKit.axial(scope, at: V3(sx, sy2, 0), seg: hi ? 32 : 14, "metal.anodized-gunmetal:15171A"), P.at())
            for rx in [sx + 0.040, sx + 0.150] {
                rig.base[lod].add(HuntKit.axial([(0, 0), (0, 0.0160), (0.014, 0.0160), (0.014, 0)], at: V3(rx, sy2, 0), seg: hi ? 22 : 10, hardM), P.at())
                rig.base[lod].add(HuntKit.box(V3(rx + 0.007, 0.0295, 0), V3(0.014, 0.040, 0.020), r: 0.002, hardM), P.at())
            }
            if hi {
                rig.base[lod].add(HuntKit.lensDisc(at: V3(sx - 0.0006, sy2, 0), r: 0.0116), P.at())
                rig.base[lod].add(HuntKit.lensDisc(at: V3(sx + 0.2135, sy2, 0), r: 0.0185), P.at())
                rig.base[lod].add(HuntKit.cyl(V3(sx + 0.095, sy2 + 0.010, 0), V3(sx + 0.095, sy2 + 0.026, 0), r: 0.0085, bevel: 0.0012, seg: 18, "metal.anodized-gunmetal:15171A"), P.at())
                rig.base[lod].add(HuntKit.cyl(V3(sx + 0.095, sy2, 0.010), V3(sx + 0.095, sy2, 0.026), r: 0.0085, bevel: 0.0012, seg: 18, "metal.anodized-gunmetal:15171A"), P.at())
                rig.base[lod].add(HuntKit.swivel(at: V3(0.14, -0.105, 0)), P.at())
            }

            // Limbs: flat recurve blades swept outward from the pockets, tips curling forward.
            for (name, s, pv) in [("limb-right", Float(1), pivotR), ("limb-left", Float(-1), pivotL)] {
                let path = catmull([V3(0.738, 0, s * 0.070), V3(0.728, 0, s * 0.130), V3(0.714, 0, s * 0.210), V3(0.698, 0, s * 0.285), V3(tipRest.x, 0, s * 0.345)], per: hi ? 8 : 4)
                let limb = Prim.sweep(Shape2D.roundedRect(0.030, 0.0085, radius: 0.0025, segments: 3), along: path, up: V3(0, 1, 0), scales: nil, caps: true, grainAlongPath: true, material: limbM)
                rig.add(limb, P.at(), to: name, lods: L)
                rig.add(HuntKit.box(V3(tipRest.x - 0.002, 0, s * 0.348), V3(0.014, 0.020, 0.016), r: 0.003, hardM), P.at(), to: name, lods: L)
                rig.add(HuntKit.cyl(pv + V3(0, -0.024, 0), pv + V3(0, 0.024, 0), r: 0.0040, bevel: 0.0008, seg: hi ? 12 : 8, "metal.bolt-bright"), P.at(), to: name, lods: L)
            }
            // String carriage (serving, nocking beads) rides the draw.
            rig.add(HuntKit.cyl(V3(nockRest, sy, -0.022), V3(nockRest, sy, 0.022), r: 0.0030, bevel: 0.0008, seg: 10, "fabric.bowstring:2A2218"), P.at(), to: "draw", lods: L)
            // String meshes per draw level, ends following the flexing limb tips.
            for k in 0..<Self.levels {
                let d = Float(k) * drawLength / Float(Self.levels - 1)
                let alpha = limbFlex * d / drawLength
                func tip(_ s: Float) -> V3 {
                    let pv = s > 0 ? pivotR : pivotL, a = (-s * alpha) * .pi / 180
                    let v = tipRest.withZ(s * tipRest.z) - pv
                    let x = v.x * cos(a) + v.z * sin(a), z = -v.x * sin(a) + v.z * cos(a)
                    return V3(pv.x + x, sy, pv.z + z)
                }
                let str = Prim.tube([tip(1), V3(nockRest - d, sy, 0), tip(-1)], radii: [0.0017, 0.0017, 0.0017], sides: hi ? 8 : 5, seamTile: 0.01, material: string, capEnd: true)
                rig.add(str, P.at(), to: "string", option: k, lods: L)
            }
            // Trigger blade and safety button.
            rig.add(HuntKit.box(V3(0.392, -0.064, 0), V3(0.006, 0.034, 0.0035), r: 0.0012, rot: simd_quatf(degrees: -8, axis: V3(0, 0, 1)), "metal.bolt-bright"), P.at(), to: "trigger", lods: L)
            rig.add(HuntKit.box(V3(0.380, -0.022, 0.0230), V3(0.014, 0.008, 0.004), r: 0.0012, "plastic.fletching:C03020"), P.at(), to: "safety", lods: L)
        }
        rig.states = [RigState("fired"),
                      RigState("half-cocked", ["draw": drawLength / 2], options: ["string": 3]),
                      RigState("cocked", ["draw": drawLength], options: ["string": 5]),
                      RigState("trigger-pulled", ["draw": drawLength, "trigger": -14], options: ["string": 5])]
        groundAO(&rig, height: 0.1, floor: 0.7)
        return rig
    }
}

private extension V3 {
    func withZ(_ z: Float) -> V3 { V3(x, y, z) }
}
