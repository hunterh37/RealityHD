import simd
import Foundation

/// Recurve bow, 1.62 m tip to tip: take-down 62 in Olympic-style recurve with a walnut and maple laminated
/// riser, arrow shelf, plunger, leather grip, black fiberglass limbs with recurved tips and a served string.
/// Design space has +X toward the target and the bow plane in XY. Articulated: `draw` slides the nock point
/// 560 mm toward the shooter from a 190 mm brace height; the `limbs` and `string` parts swap through seven
/// bend and draw-length meshes. States: rest, half-draw, full-draw.
public struct RecurveBow: RealArticulated {
    public static let id = "recurve-bow"
    public static let summary = "Take-down recurve bow, 1.62 m: walnut riser with shelf and plunger, fiberglass limbs with tip recurve, leather grip, articulated string draw."
    public static let tags = ["prop", "archery", "handheld", "articulated", "wood", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 345, elevation: 8, distance: 1.9, studio: true)

    /// Draw length from the rest nock point in meters.
    public var drawLength: Float = 0.56
    /// Brace height (grip pivot to nock point at rest) in meters.
    public var brace: Float = 0.190
    /// Riser woods, limb finish, grip and hardware.
    public var riserWood: MaterialKey = "wood.walnut"
    public var laminate: MaterialKey = "wood.maple-natural"
    public var limb: MaterialKey = "plastic.gloss:15161A"
    public var grip: MaterialKey = "leather.tan"
    public var hardware: MaterialKey = "metal.anodized"
    public var string: MaterialKey = "fabric.bowstring"
    public init() {}

    static let levels = 7
    static let tipY: Float = 0.795

    /// Limb centerline (upper limb, design space) at bend level k.
    static func limbPath(_ k: Int, per: Int) -> [V3] {
        let f = Float(k) / Float(levels - 1)
        let base: [V2] = [V2(0.012, 0.225), V2(0.004, 0.340), V2(-0.002, 0.505), V2(0.014, 0.655), V2(0.044, tipY)]
        let w: [Float] = [0, 0.22, 0.62, 0.93, 1.0]
        var pts: [V3] = []
        for (i, b) in base.enumerated() {
            let x = b.x - 0.165 * f * w[i]
            let y = b.y - 0.160 * f * w[i] * w[i]
            pts.append(V3(x, y, 0))
        }
        return catmull(pts, per: per)
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(0.065, Self.tipY + 0.012, 0))
        let nockY: Float = 0.025
        let hardM = hardware, riserM = riserWood, lamM = laminate, gripM = grip, limbM = limb, strM = string
        let drawL = drawLength, brace = brace

        rig.part("draw", pivot: P.p(V3(-brace, nockY, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...drawL, duration: 0.9))
        rig.part("limbs", pivot: P.p(.zero), joint: .fixed, options: Self.levels)
        rig.part("string", pivot: P.p(V3(-brace, nockY, 0)), joint: .fixed, options: Self.levels)
        let th = (1..<Self.levels).map { (Float($0) - 0.5) * drawL / Float(Self.levels - 1) }
        rig.optionLinks = [RigOptionLink(part: "string", joint: "draw", thresholds: th),
                           RigOptionLink(part: "limbs", joint: "draw", thresholds: th)]

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod
            // Riser: laminated walnut core with maple veneers, window cut toward the target.
            let outline: [V2] = [V2(-0.018, -0.215), V2(0.030, -0.215), V2(0.035, -0.150), V2(0.016, -0.090), V2(0.004, -0.030),
                                 V2(0.004, 0.062), V2(0.026, 0.080), V2(0.036, 0.140), V2(0.030, 0.215), V2(-0.018, 0.215),
                                 V2(-0.024, 0.120), V2(-0.020, 0.0), V2(-0.026, -0.110)]
            let slices: [(Float, MaterialKey)] = [(0.0080, riserM), (0.0016, lamM), (0.0036, riserM), (0.0016, lamM), (0.0100, riserM),
                                                  (0.0016, lamM), (0.0036, riserM), (0.0016, lamM), (0.0080, riserM)]
            var z: Float = -slices.reduce(0) { $0 + $1.0 } / 2
            for (d, mat) in slices {
                var rs = Prim.extrude(Shape2D.rounded(outline, radius: 0.012, segments: hi ? 3 : 2), depth: d, bevel: 0.0007, bevelSegments: 1, material: mat)
                rs.uvs = rs.positions.map { V2($0.y, $0.x) }; rs.computeTangents()
                rig.base[lod].add(rs, P.at(V3(0, 0, z + d / 2)))
                z += d
            }
            // Leather grip wrap, arrow shelf and plunger.
            rig.base[lod].add(HuntKit.box(V3(-0.018, -0.048, 0), V3(0.020, 0.098, 0.036), r: 0.008, gripM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.022, 0.0145, 0), V3(0.036, 0.0100, 0.022), r: 0.002, hardM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.034, 0.0215, -0.0085), V3(0.012, 0.0030, 0.0050), r: 0.0008, "rubber.recoil-pad"), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(0.003, 0.034, -0.030), V3(0.003, 0.034, -0.010), r: 0.0050, bevel: 0.001, seg: hi ? 14 : 8, hardM), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(0.003, 0.034, -0.010), V3(0.003, 0.034, -0.0052), r: 0.0030, bevel: 0.0008, seg: hi ? 12 : 6, "metal.cartridge-brass"), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(0.003, 0.034, -0.036), V3(0.003, 0.034, -0.030), r: 0.0075, bevel: 0.001, seg: hi ? 16 : 8, "metal.bolt-bright"), P.at())
            // Stabilizer bushing on the front of the lower riser.
            rig.base[lod].add(HuntKit.axial([(0, 0.0080), (0.004, 0.0100), (0.016, 0.0100), (0.018, 0.0070), (0.018, 0)], at: V3(0.033, -0.135, 0), seg: hi ? 18 : 8, hardM), P.at())
            // Limb pockets, bolts and limb bolt heads.
            for s: Float in [1, -1] {
                rig.base[lod].add(HuntKit.box(V3(0.008, s * 0.2150, 0), V3(0.046, 0.040, 0.048), r: 0.005, hardM), P.at())
                rig.base[lod].add(HuntKit.cyl(V3(-0.020, s * 0.176, 0), V3(0.040, s * 0.176, 0), r: 0.0042, bevel: 0.0008, seg: hi ? 12 : 6, "metal.bolt-bright"), P.at())
                rig.base[lod].add(HuntKit.cyl(V3(-0.026, s * 0.176, 0), V3(-0.018, s * 0.176, 0), r: 0.0085, bevel: 0.0015, seg: hi ? 14 : 8, hardM), P.at())
            }
            // Limbs per bend level, tapered fiberglass with tip overlays.
            for k in 0..<Self.levels {
                for s: Float in [1, -1] {
                    let pts = Self.limbPath(k, per: hi ? 6 : 3).map { V3($0.x, s * $0.y, 0) }
                    let n = pts.count
                    let scales = (0..<n).map { 1 - 0.42 * pow(Float($0) / Float(n - 1), 1.5) }
                    var ls = Prim.sweep(Shape2D.roundedRect(0.0420, 0.0120, radius: 0.0030, segments: 2), along: pts, up: V3(0, 0, 1), scales: scales, caps: true, grainAlongPath: true, material: limbM)
                    ls.computeTangents()
                    rig.add(ls, P.at(), to: "limbs", option: k, lods: L)
                    let tip = pts[n - 1], prev = pts[n - 2]
                    let dir = simd_normalize(tip - prev)
                    rig.add(HuntKit.rod(tip - dir * 0.026, tip + dir * 0.008, r: 0.0072, sides: hi ? 12 : 6, "plastic.black"), P.at(), to: "limbs", option: k, lods: L)
                    if hi { rig.add(HuntKit.rod(tip - dir * 0.004 + V3(0, 0, -0.012), tip - dir * 0.004 + V3(0, 0, 0.012), r: 0.0020, sides: 6, "metal.bolt-bright"), P.at(), to: "limbs", option: k, lods: L) }
                }
            }
            // Serving and nocking points ride the draw.
            rig.add(HuntKit.cyl(V3(-brace, nockY - 0.055, 0), V3(-brace, nockY + 0.055, 0), r: 0.0019, bevel: 0.0005, seg: 8, "fabric.bowstring:2A2218"), P.at(), to: "draw", lods: L)
            rig.add(HuntKit.cyl(V3(-brace, nockY + 0.0125, -0.003), V3(-brace, nockY + 0.0125, 0.003), r: 0.0026, bevel: 0.0006, seg: 8, "metal.cartridge-brass"), P.at(), to: "draw", lods: L)
            rig.add(HuntKit.cyl(V3(-brace, nockY - 0.0125, -0.003), V3(-brace, nockY - 0.0125, 0.003), r: 0.0026, bevel: 0.0006, seg: 8, "metal.cartridge-brass"), P.at(), to: "draw", lods: L)
            // String per draw level, anchored at the limb tips of the matching bend.
            for k in 0..<Self.levels {
                let d = Float(k) * drawL / Float(Self.levels - 1)
                let lp = Self.limbPath(k, per: 2)
                let tp = lp[lp.count - 1]
                let a = V3(tp.x - 0.004, tp.y - 0.012, 0), c = V3(tp.x - 0.004, -tp.y + 0.012, 0), b = V3(-brace - d, nockY, 0)
                rig.add(Prim.tube([a, b, c], radii: [0.0012, 0.0012, 0.0012], sides: hi ? 8 : 5, seamTile: 0.01, material: strM, capEnd: true), P.at(), to: "string", option: k, lods: L)
                if hi {
                    for s: Float in [1, -1] {
                        let e = V3(a.x, s * a.y, 0), dir = simd_normalize(b - e)
                        rig.add(HuntKit.rod(e, e + dir * 0.045, r: 0.0017, sides: 6, "fabric.bowstring:2A2218"), P.at(), to: "string", option: k, lods: L)
                    }
                }
            }
        }
        rig.states = [RigState("rest"),
                      RigState("half-draw", ["draw": drawL / 2], options: ["string": 3, "limbs": 3]),
                      RigState("full-draw", ["draw": drawL], options: ["string": 6, "limbs": 6])]
        groundAO(&rig, height: 0.1, floor: 0.7)
        return rig
    }
}
