import simd
import Foundation

/// Farmhouse oak dining table, 180 x 76 x 90 cm: five 32 mm oak planks with hairline joints between two
/// breadboard ends pegged through the top, four legs tapered on their inner faces, 25 mm aprons flush with
/// the leg faces, two cross rails and diagonal corner braces under the top.
public struct DiningTable: RealAsset {
    public static let id = "dining-table"
    public static let summary = "Oak dining table, 1.8 m: plank top with breadboard ends and pegs, tapered legs, aprons, cross rails and corner braces."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "interior"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 20, distance: 2.6, studio: true)

    /// Overall size in meters (x length, y height, z width).
    public var size = V3(1.8, 0.76, 0.9)
    /// Top thickness in meters.
    public var topThickness: Float = 0.032
    /// Oak base tints for the five top planks (varied boards from one tree).
    public var plankTints = ["B79A6C", "AD9064", "BC9F72", "A98B60", "B49768"]
    /// Frame and leg oak tint.
    public var frameTint = "A38559"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z, t = topThickness
        let underTop = H - t
        let frame: MaterialKey = "wood.oak:\(frameTint)"
        let seg = detail ? 2 : 1
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: seg, material: mat), Xform(translation: p, rotation: rot).jittered(&rng, deg: 0.03, offset: 0.0001))
        }

        // Top: breadboard ends 90 mm wide, planks between them with 0.8 mm joints.
        let bb: Float = 0.09, plankLen = W - 2 * bb - 0.004
        let n = 5, gap: Float = 0.0008
        let pw = (D - Float(n - 1) * gap) / Float(n)
        for i in 0..<n {
            let z = -D / 2 + pw / 2 + Float(i) * (pw + gap)
            let tint = plankTints[i % plankTints.count]
            m.add(plank(plankLen, pw, t, bevel: 0.0025, material: "wood.oak:\(tint)"),
                  Xform(translation: V3(0, underTop + t / 2 + rng.float(-0.0003...0.0003), z)))
        }
        for s: Float in [-1, 1] {
            // Breadboard: built along X then turned 90 degrees so the grain runs along Z.
            m.add(Prim.roundedBox(V3(D, t, bb), radius: 0.003, bevelSegments: seg, material: "wood.oak:\(plankTints[s < 0 ? 3 : 1])"),
                  Xform(translation: V3(s * (W / 2 - bb / 2), underTop + t / 2, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        // Pegs: four oak dowels per end, endgrain heads on the top face of each breadboard.
        if detail {
            for s: Float in [-1, 1] {
                for z: Float in [-0.32, -0.11, 0.11, 0.32] {
                    m.add(Prim.cylinder(radius: 0.0075, height: 0.0012, bevel: 0.0004, segments: 12, bevelSegments: 1, material: "wood.endgrain:5A3F26"),
                          Xform(translation: V3(s * (W / 2 - bb / 2), H - 0.0004, z)))
                }
            }
            // Knots: dark oval swirls on two planks, long axis along the grain.
            for (x, z, rx, rz) in [(Float(-0.42), Float(-0.18), Float(0.026), Float(0.013)), (0.31, 0.27, 0.02, 0.011), (0.1, -0.36, 0.014, 0.008)] {
                m.add(Prim.extrude(Shape2D.circle(rx, ry: rz, segments: 14), depth: 0.0004, bevel: 0.0001, bevelSegments: 1, material: "wood.endgrain:4B3220"),
                      Xform(translation: V3(x, H + 0.0001, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // Hairline end-grain strips where plank ends meet the breadboard tongues.
            for s: Float in [-1, 1] {
                m.add(cuboid(V3(0.0012, 0.0006, D - 0.012), material: "plastic.black"), Xform(translation: V3(s * (W / 2 - bb - 0.0004), H - 0.0003, 0)))
            }
        }

        // Legs: 70 mm top, tapering to 45 mm on the inner faces only (outer faces stay plumb).
        let legH = underTop - 0.001
        let cx = W / 2 - 0.12 - 0.0375, cz = D / 2 - 0.06 - 0.0375
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let top = Shape2D.roundedRect(0.075, 0.075, radius: 0.003, segments: seg)
                let bot = Shape2D.roundedRect(0.052, 0.052, radius: 0.003, segments: seg)
                let dx = sx * (0.075 - 0.052) / 2 * -1, dz = sz * (0.075 - 0.052) / 2 * -1
                let r0 = Prim.ring(bot, y: 0.0, offset: V3(sx * cx + dx, 0, sz * cz + dz))
                let r2 = Prim.ring(top, y: legH, offset: V3(sx * cx, 0, sz * cz))
                var leg = Prim.loft([r0, r2], capStart: true, capEnd: true, material: frame).flipped()
                leg.uvs = leg.uvs.map { V2($0.y, $0.x) }; leg.computeTangents()
                m.add(leg)
                // Rubber glide under each foot.
                m.add(Prim.cylinder(radius: 0.019, height: 0.004, bevel: 0.0012, segments: 12, bevelSegments: 1, material: "rubber.plate"),
                      Xform(translation: V3(sx * cx + dx, -0.0, sz * cz + dz)))
            }
        }
        // Aprons: 85 x 25 mm, flush with the leg outer faces, tenoned 10 mm into each leg.
        let ah: Float = 0.085, ay = underTop - ah / 2 - 0.0015
        let ox = W / 2 - 0.12, oz = D / 2 - 0.06            // outer faces of legs
        let legW: Float = 0.075
        let lenX = 2 * (cx - legW / 2) + 0.02, lenZ = 2 * (cz - legW / 2) + 0.02
        for sz: Float in [-1, 1] { box(V3(lenX, ah, 0.025), V3(0, ay, sz * (oz - 0.0125)), frame, r: 0.0015) }
        for sx: Float in [-1, 1] { box(V3(0.025, ah, lenZ), V3(sx * (ox - 0.0125), ay, 0), frame, r: 0.0015) }
        // Cross rails across the width at +/- 0.45 m, 40 x 70 mm, resting against the top underside.
        for x: Float in [-0.45, 0.45] {
            box(V3(0.04, 0.07, 2 * (oz - 0.025) + 0.001), V3(x, underTop - 0.035 - 0.0015, 0), frame, r: 0.0015)
        }
        // Diagonal corner braces: 45 degree boards across each corner, with a screw head each end.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let p = V3(sx * (ox - 0.025 - 0.055), underTop - 0.0015 - 0.0425, sz * (oz - 0.025 - 0.055))
                box(V3(0.2, 0.085, 0.022), p, frame, r: 0.0015, rot: simd_quatf(degrees: sx * sz > 0 ? -45 : 45, axis: .up))
                if detail {
                    for d: Float in [-0.075, 0.075] {
                        let a = Float.pi / 4 * (sx * sz > 0 ? -1 : 1)
                        let off = V3(cos(a) * d, 0, -sin(a) * d)
                        m.add(Prim.cylinder(radius: 0.0045, height: 0.0014, bevel: 0.0005, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                              Xform(translation: p + off + V3(0, -0.0003, 0)))
                    }
                }
            }
        }

        groundAO(&m, height: 0.18, floor: 0.55)
        return m
    }
}
