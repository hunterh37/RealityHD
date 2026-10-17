import simd
import Foundation

/// English longbow, 1.82 m tip to tip: 70 in yew self bow with a D-section stave (flat belly, rounded pale
/// sapwood back), dark horn nocks, leather-wrapped grip with an arrow pass and a hemp string with serving.
/// Design space has +X toward the target and the bow plane in XY. Articulated: `draw` slides the nock point
/// 600 mm toward the shooter from a 165 mm brace height; the `limbs` and `string` parts swap through seven
/// bend and draw-length meshes, the stave bending in one continuous arc. States: rest, half-draw, full-draw.
public struct Longbow: RealArticulated {
    public static let id = "longbow"
    public static let summary = "English longbow, 1.8 m: D-section hickory-backed yew stave, horn nocks, leather-wrapped grip, hemp string, articulated draw."
    public static let tags = ["prop", "archery", "handheld", "articulated", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 345, elevation: 8, distance: 2.6, studio: true)

    /// Draw length from the rest nock point in meters.
    public var drawLength: Float = 0.60
    /// Brace height (grip pivot to nock point at rest) in meters.
    public var brace: Float = 0.165
    /// Yew heartwood (belly), sapwood (back), grip wrap, horn and string.
    public var heartwood: MaterialKey = "wood.lumber-oak:A6702E"
    public var sapwood: MaterialKey = "wood.maple-natural:E3CB93"
    public var grip: MaterialKey = "leather.tan:5A3A22"
    public var horn: MaterialKey = "plastic.matte:2A1E14"
    public var string: MaterialKey = "fabric.bowstring"
    public init() {}

    static let levels = 7
    static let halfLen: Float = 0.90
    static let nockY: Float = 0.084

    /// Full stave centerline (lower tip to upper tip, design space) at bend level k: straight handle, then
    /// a smooth arc toward the shooter that deepens with draw.
    static func stavePath(_ k: Int, ctrl: Int, per: Int) -> [V3] {
        let f = Float(k) / Float(levels - 1)
        let Y = halfLen - 0.045 * f
        let c = 0.135 + 0.165 * f
        var pts: [V3] = []
        for i in 0..<ctrl {
            let t = Float(i) / Float(ctrl - 1) * 2 - 1
            let y = t * Y
            let g = max(0, (abs(y) - 0.09) / (Y - 0.09))
            let reflex = 0.004 * exp(-pow((abs(y) - 0.12) / 0.10, 2))
            pts.append(V3(-c * g * g + reflex, y, 0))
        }
        return catmull(pts, per: per)
    }

    static let heartProfile: [V2] = [V2(-0.015, -0.012), V2(-0.007, -0.0125), V2(0.007, -0.0125), V2(0.015, -0.012), V2(0.0158, -0.004), V2(0.0148, 0.004),
                                     V2(-0.0148, 0.004), V2(-0.0158, -0.004)]
    static let sapProfile: [V2] = [V2(-0.0148, 0.004), V2(0.0148, 0.004), V2(0.0128, 0.0095), V2(0.0078, 0.0120), V2(0, 0.0128),
                                   V2(-0.0078, 0.0120), V2(-0.0128, 0.0095)]

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let P = Placer(off: V3(0.075, Self.halfLen + 0.012, 0))
        let nockY = Self.nockY
        let heartM = heartwood, sapM = sapwood, gripM = grip, hornM = horn, strM = string
        let drawL = drawLength, brace = brace

        rig.part("draw", pivot: P.p(V3(-brace, nockY, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...drawL, duration: 0.9))
        rig.part("limbs", pivot: P.p(.zero), joint: .fixed, options: Self.levels)
        rig.part("string", pivot: P.p(V3(-brace, nockY, 0)), joint: .fixed, options: Self.levels)
        let th = (1..<Self.levels).map { (Float($0) - 0.5) * drawL / Float(Self.levels - 1) }
        rig.optionLinks = [RigOptionLink(part: "string", joint: "draw", thresholds: th),
                           RigOptionLink(part: "limbs", joint: "draw", thresholds: th)]

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod
            // Leather grip wrap with stitched seam, pass pad and horn arrow plate.
            rig.base[lod].add(HuntKit.box(V3(0.001, 0, 0), V3(0.034, 0.150, 0.038), r: 0.011, gripM), P.at())
            for y: Float in [-0.078, 0.078] {
                rig.base[lod].add(HuntKit.box(V3(0.001, y, 0), V3(0.036, 0.007, 0.040), r: 0.003, "leather.tan:3A2414"), P.at())
            }
            rig.base[lod].add(HuntKit.box(V3(0.0, 0.0755, 0), V3(0.030, 0.005, 0.034), r: 0.0015, gripM), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.010, 0.0775, 0), V3(0.010, 0.002, 0.012), r: 0.0007, hornM), P.at())
            // Stave per bend level: heartwood belly, sapwood back, horn nocks.
            for k in 0..<Self.levels {
                let pts = Self.stavePath(k, ctrl: hi ? 15 : 9, per: hi ? 3 : 2)
                let n = pts.count
                let scales = (0..<n).map { i -> Float in
                    let t = abs(Float(i) / Float(n - 1) * 2 - 1)
                    return (1 - 0.46 * pow(t, 1.6)) * (1 + 0.12 * exp(-pow(t / 0.12, 2)))
                }
                for (prof, mat) in [(Self.heartProfile, heartM), (Self.sapProfile, sapM)] {
                    var s = Prim.sweep(prof, along: pts, up: V3(0, 0, 1), scales: scales, caps: true, grainAlongPath: true, material: mat)
                    s.computeTangents()
                    rig.add(s, P.at(), to: "limbs", option: k, lods: L)
                }
                for (tip, prev) in [(pts[n - 1], pts[n - 2]), (pts[0], pts[1])] {
                    let dir = simd_normalize(tip - prev)
                    rig.add(HuntKit.rod(tip - dir * 0.034, tip + dir * 0.010, r: 0.0088, sides: hi ? 12 : 6, hornM), P.at(), to: "limbs", option: k, lods: L)
                    let ring = tip - dir * 0.004
                    rig.add(HuntKit.rod(ring - dir * 0.0025, ring + dir * 0.0025, r: 0.0104, sides: hi ? 12 : 6, hornM), P.at(), to: "limbs", option: k, lods: L)
                }
            }
            // Serving and nocking points ride the draw.
            rig.add(HuntKit.cyl(V3(-brace, nockY - 0.075, 0), V3(-brace, nockY + 0.075, 0), r: 0.0022, bevel: 0.0005, seg: 8, "fabric.bowstring:2A2218"), P.at(), to: "draw", lods: L)
            for dy: Float in [0.0125, -0.0125] {
                rig.add(HuntKit.cyl(V3(-brace, nockY + dy, -0.003), V3(-brace, nockY + dy, 0.003), r: 0.0028, bevel: 0.0006, seg: 8, "fabric.bowstring:7A5A30"), P.at(), to: "draw", lods: L)
            }
            // String per draw level, anchored at the horn nocks of the matching bend.
            for k in 0..<Self.levels {
                let d = Float(k) * drawL / Float(Self.levels - 1)
                let lp = Self.stavePath(k, ctrl: 3, per: 1)
                let up = lp[lp.count - 1], lo = lp[0]
                let a = V3(up.x - 0.008, up.y, 0), c = V3(lo.x - 0.008, lo.y, 0), b = V3(-brace - d, nockY, 0)
                rig.add(Prim.tube([a, b, c], radii: [0.0016, 0.0016, 0.0016], sides: hi ? 8 : 5, seamTile: 0.01, material: strM, capEnd: true), P.at(), to: "string", option: k, lods: L)
            }
        }
        rig.states = [RigState("rest"),
                      RigState("half-draw", ["draw": drawL / 2], options: ["string": 3, "limbs": 3]),
                      RigState("full-draw", ["draw": drawL], options: ["string": 6, "limbs": 6])]
        groundAO(&rig, height: 0.1, floor: 0.7)
        return rig
    }
}
