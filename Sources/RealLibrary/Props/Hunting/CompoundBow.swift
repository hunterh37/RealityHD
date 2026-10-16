import simd
import Foundation

/// Compound bow, 0.76 m axle to axle: camo-dipped aluminum riser with sight window, split limbs, two
/// rotating cams, pin sight, 8 in stabilizer, cable guard. Design space has +X toward the target and
/// the bow plane in XY. Articulated: `draw` slides the nock point 540 mm toward the shooter, both
/// cams rotate with it (`cam-top`, `cam-bottom` mimic `draw`) and the `string` swaps through seven
/// draw-length meshes. States: rest, half-draw, full-draw.
public struct CompoundBow: RealArticulated {
    public static let id = "compound-bow"
    public static let summary = "Compound bow, 0.76 m axle to axle: camo riser, split limbs, rotating cams, articulated string draw."
    public static let tags = ["prop", "hunting", "handheld", "articulated", "metal", "plastic"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 345, elevation: 10, distance: 1.1, studio: true)

    /// Axle-to-axle length in meters.
    public var axleToAxle: Float = 0.762
    /// Draw length from the rest nock point in meters (full draw 28.5 in).
    public var drawLength: Float = 0.54
    /// Riser, limb and sight finishes.
    public var riser: MaterialKey = "paint.bow-camo"
    public var hardware: MaterialKey = "metal.anodized-gunmetal:1A1B1E"
    public var string: MaterialKey = "fabric.bowstring"
    public var grip: MaterialKey = "plastic.stock-synthetic"
    public init() {}

    static let levels = 7

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let h = axleToAxle / 2, ax: Float = -0.030
        let P = Placer(off: V3(-0.02, h + 0.037, 0))
        let nockY: Float = 0.025, brace: Float = 0.190
        let camAngle: Float = 200
        let hardM = hardware, riserM = riser

        rig.part("draw", pivot: P.p(V3(-brace, nockY, 0)), joint: .slide(axis: V3(-1, 0, 0), 0...drawLength, duration: 0.9))
        rig.part("cam-top", pivot: P.p(V3(ax, h, 0)), joint: Joint(.revolute, axis: V3(0, 0, 1), range: -camAngle...camAngle, mimic: .init("draw", ratio: camAngle / drawLength)))
        rig.part("cam-bottom", pivot: P.p(V3(ax, -h, 0)), joint: Joint(.revolute, axis: V3(0, 0, 1), range: -camAngle...camAngle, mimic: .init("draw", ratio: -camAngle / drawLength)))
        rig.part("string", pivot: P.p(V3(-brace, nockY, 0)), joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...0), options: Self.levels)
        rig.optionLinks = [RigOptionLink(part: "string", joint: "draw", thresholds: (1..<Self.levels).map { (Float($0) - 0.5) * drawLength / Float(Self.levels - 1) })]

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod
            // Riser: C-shaped, window on the target side, extruded across Z.
            let outline: [V2] = [V2(-0.016, -0.195), V2(0.030, -0.195), V2(0.034, -0.120), V2(0.004, -0.112), V2(0.004, 0.055), V2(0.040, 0.070), V2(0.034, 0.195), V2(-0.016, 0.195)]
            var rs = Prim.extrude(Shape2D.rounded(outline, radius: 0.016, segments: 6), depth: 0.030, bevel: 0.010, bevelSegments: 3, material: riserM)
            rs.uvs = rs.positions.map { V2($0.x, $0.y) }; rs.computeTangents()
            rig.base[lod].add(rs, P.at())
            rig.base[lod].add(HuntKit.box(V3(-0.0225, -0.040, 0), V3(0.013, 0.100, 0.038), r: 0.004, grip), P.at())
            // Limb pockets and limb bolts.
            for s: Float in [1, -1] {
                rig.base[lod].add(HuntKit.box(V3(0.000, s * 0.192, 0), V3(0.042, 0.030, 0.050), r: 0.004, hardM), P.at())
                if hi { rig.base[lod].add(HuntKit.cyl(V3(0.012, s * 0.215, -0.030), V3(0.012, s * 0.215, 0.030), r: 0.0042, bevel: 0.0008, seg: 12, "metal.bolt-bright"), P.at()) }
                // Split limbs, one pair per end, swept from pocket to axle.
                let path: [V3] = [V3(0.008, s * 0.205, 0), V3(0.002, s * 0.255, 0), V3(-0.012, s * 0.320, 0), V3(ax - 0.002, s * (h - 0.006), 0)]
                for z: Float in [-0.0185, 0.0185] {
                    let pts = catmull(path.map { V3($0.x, $0.y, z) }, per: hi ? 8 : 4)
                    let limb = Prim.sweep(Shape2D.roundedRect(0.0170, 0.0115, radius: 0.0025, segments: 3), along: pts, up: V3(0, 0, 1), scales: nil, caps: true, grainAlongPath: true, material: riserM)
                    rig.base[lod].add(limb, P.at())
                }
                // Axle through both limbs.
                rig.base[lod].add(HuntKit.cyl(V3(ax, s * h, -0.0290), V3(ax, s * h, 0.0290), r: 0.0036, bevel: 0.0008, seg: hi ? 14 : 8, "metal.bolt-bright"), P.at())
            }
            // Cable guard, cables (static), stabilizer, sight, rest.
            rig.base[lod].add(HuntKit.rod(V3(-0.016, -0.050, 0), V3(-0.046, -0.050, 0.034), r: 0.0030, sides: hi ? 8 : 6, hardM), P.at())
            for s: Float in [1, -1] {
                rig.base[lod].add(HuntKit.wire([V3(ax - 0.004, h - 0.016, s * 0.020), V3(-0.040, 0.20, s * 0.034), V3(-0.046, 0.0, s * 0.034), V3(-0.040, -0.20, s * 0.034), V3(ax - 0.004, -h + 0.016, s * 0.020)],
                                               r: 0.0016, per: 5, sides: 6, string), P.at())
            }
            rig.base[lod].add(HuntKit.cyl(V3(0.034, -0.065, 0), V3(0.240, -0.065, 0), r: 0.0055, bevel: 0.001, seg: hi ? 14 : 8, hardM), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(0.205, -0.065, 0), V3(0.245, -0.065, 0), r: 0.0125, bevel: 0.002, seg: hi ? 20 : 10, hardM), P.at())
            rig.base[lod].add(HuntKit.cyl(V3(0.245, -0.065, 0), V3(0.262, -0.065, 0), r: 0.0100, bevel: 0.002, seg: hi ? 20 : 10, "rubber.recoil-pad"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.046, 0.040, 0.030), V3(0.028, 0.012, 0.030), r: 0.002, hardM), P.at())
            rig.base[lod].add(HuntKit.axial([(0, 0.0175), (0, 0.0198), (0.014, 0.0198), (0.014, 0.0175), (0, 0.0175)], at: V3(0.056, 0.040, 0.046), seg: hi ? 28 : 12, hardM), P.at())
            if hi {
                for (i, c) in ["7FD01A", "E0561A", "7FD01A", "E0561A"].enumerated() {
                    let py = 0.040 + 0.0125 - Float(i) * 0.0085
                    rig.base[lod].add(HuntKit.rod(V3(0.058, py, 0.046), V3(0.068, 0.040 + (py - 0.040) * 0.4, 0.046), r: 0.0005, sides: 5, "plastic.fletching:" + c), P.at())
                }
            }
            rig.base[lod].add(HuntKit.wire([V3(0.004, 0.006, 0), V3(0.020, 0.012, 0), V3(0.034, 0.024, 0)], r: 0.0016, sides: 6, "metal.bolt-bright"), P.at())
            rig.base[lod].add(HuntKit.box(V3(0.034, 0.0245, 0), V3(0.016, 0.004, 0.012), r: 0.001, "metal.bolt-bright"), P.at())

            // Field wear: dried mud caked on the stabilizer weight and lower limb tips.
            rig.base[lod].add(HuntKit.axial([(0, 0.0128), (0.004, 0.0136), (0.010, 0.0130), (0.016, 0.0138), (0.022, 0.0126), (0.022, 0.0120), (0, 0.0120)], at: V3(0.222, -0.065, 0), seg: hi ? 14 : 8, tile: 0.01, "plastic.grime"), P.at())
            for (i, (y, z)) in ([(-0.262, 0.012), (-0.285, -0.011), (-0.305, 0.010), (-0.322, -0.009)] as [(Float, Float)]).enumerated() {
                rig.base[lod].add(Prim.superellipsoid(V3(0.013, 0.016, 0.010), exponent: 2.6, subdivisions: hi ? 5 : 3, material: "plastic.grime"),
                                  P.at(V3(-0.010 - Float(i) * 0.0015, y, z)))
            }
            // Cams: eccentric disks with a string groove, between the limb pair.
            for (name, s) in [("cam-top", Float(1)), ("cam-bottom", Float(-1))] {
                var pts: [V2] = []
                let n = hi ? 40 : 20
                for i in 0..<n {
                    let t = Float(i) / Float(n) * 2 * .pi
                    let lobe = pow(max(0, cos(t - 2.6)), 2.0)
                    pts.append(V2(cos(t), s * sin(t)) * (0.031 + 0.014 * lobe))
                }
                var cam = Prim.extrude(pts, depth: 0.0150, bevel: 0.002, bevelSegments: 2, material: hardM)
                cam.uvs = cam.positions.map { V2($0.x, $0.y) }; cam.computeTangents()
                rig.add(cam, P.at(V3(ax, s * h, 0)), to: name, lods: L)
                rig.add(Prim.cylinder(radius: 0.0100, height: 0.0166, bevel: 0.002, segments: hi ? 20 : 10, material: "metal.bolt-bright").transformed(Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))),
                        P.at(V3(ax, s * h, -0.0083)), to: name, lods: L)
            }
            // Serving and nocking point ride the draw.
            rig.add(HuntKit.cyl(V3(-brace, nockY - 0.050, 0), V3(-brace, nockY + 0.050, 0), r: 0.0021, bevel: 0.0006, seg: 8, "fabric.bowstring:2A2218"), P.at(), to: "draw", lods: L)
            rig.add(HuntKit.cyl(V3(-brace, nockY + 0.0125, -0.003), V3(-brace, nockY + 0.0125, 0.003), r: 0.0028, bevel: 0.0006, seg: 8, "metal.cartridge-brass"), P.at(), to: "draw", lods: L)
            rig.add(HuntKit.cyl(V3(-brace, nockY - 0.0125, -0.003), V3(-brace, nockY - 0.0125, 0.003), r: 0.0028, bevel: 0.0006, seg: 8, "metal.cartridge-brass"), P.at(), to: "draw", lods: L)
            if hi { rig.add(Prim.torus(major: 0.011, minor: 0.0013, segments: 20, sides: 6, material: "fabric.bowstring:3A2A1A"), P.at(V3(-brace - 0.004, nockY - 0.002, 0), simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: "draw", lods: L) }
            // String meshes per draw level (cams pay out string as the nock travels).
            for k in 0..<Self.levels {
                let d = Float(k) * drawLength / Float(Self.levels - 1)
                let a = V3(ax - 0.026, h - 0.012, 0), b = V3(-brace - d, nockY, 0), c = V3(ax - 0.026, -h + 0.012, 0)
                let str = Prim.tube([a, b, c], radii: [0.0013, 0.0013, 0.0013], sides: hi ? 8 : 5, seamTile: 0.01, material: string, capEnd: true)
                rig.add(str, P.at(), to: "string", option: k, lods: L)
            }
        }
        rig.states = [RigState("rest"),
                      RigState("half-draw", ["draw": drawLength / 2], options: ["string": 3]),
                      RigState("full-draw", ["draw": drawLength], options: ["string": 6])]
        groundAO(&rig, height: 0.1, floor: 0.7)
        return rig
    }
}
