import simd
import Foundation

/// Range hood wall cap: brushed stainless square plate with screws and a caulk bead, sloped roof with folded
/// cheeks and a bottom tray, open front closed by a bird screen in a folded frame, 6 inch galvanized duct collar
/// with a butterfly backdraft damper (two half-disc blades on a rod), grease staining. Wall plane at z = 0.
public struct RangeHoodWallCap: RealAsset {
    public static let id = "range-hood-wall-cap"
    public static let summary = "Range hood wall cap: stainless steel plate with sloped hood and cheeks, open front covered by a bird screen in a folded frame, 6 inch galvanized duct collar with butterfly backdraft damper, caulk bead, screws and grease staining."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 0.95)

    /// Hood metal.
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.15, W: Float = 0.3, D: Float = 0.2
        // Plate with caulk bead and screws.
        FS.plate(&m, W, W, 0.004, radius: 0.012, at: V3(0, cy, 0.002), "metal.stainless-smudged", bevel: 0.0015)
        FA.box(&m, V3(W + 0.002, 0.003, 0.003), V3(0, cy + W / 2, 0.0016), "plastic.white", r: 0.0012)
        FA.box(&m, V3(W + 0.002, 0.003, 0.003), V3(0, cy - W / 2, 0.0016), "plastic.white", r: 0.0012)
        for (x, y) in [(-0.132, 0.282), (0.132, 0.282), (-0.132, 0.018), (0.132, 0.018)] as [(Float, Float)] { FS.screw(&m, at: V3(x, y, 0.004), r: 0.0045) }
        // Duct collar (6 inch) with a rolled lip, backdraft damper: rod, two half-disc blades at slight opening angles.
        let dy: Float = 0.072
        FS.sleeveZ(&m, rOut: 0.0765, rIn: 0.0735, z0: 0.004, z1: 0.115, cy: dy, "metal.galvanized", segments: 36)
        m.add(Prim.torus(major: 0.0765, minor: 0.0028, segments: 38, sides: 6, material: "metal.galvanized"), Xform(translation: V3(0, dy, 0.1145), rotation: FA.q(90, FA.X)))
        FS.cyl(&m, r: 0.074, h: 0.003, at: V3(0, dy, 0.005), axis: FA.Z, "plastic.black", bevel: 0.0006, segments: 36)
        FA.cylX(&m, r: 0.0026, h: 0.152, at: V3(-0.076, dy, 0.07), "metal.aluminum-brushed", bevel: 0.0006, segments: 8)
        var arcPts: [V2] = []
        for i in 0...14 { let a = Float(i) / 14 * .pi; arcPts.append(V2(cos(a) * 0.071, sin(a) * 0.071)) }
        for (sgn, ang) in [(Float(1), Float(16)), (-1, Float(-12))] {
            let pts = arcPts.map { V2($0.x, $0.y * sgn) }
            m.add(Prim.extrude(pts, depth: 0.0016, bevel: 0.0005, bevelSegments: 1, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(0, dy, 0.0725), rotation: FA.q(-ang * sgn, FA.X)))
        }
        // Hood: cheeks from the side profile, sloped roof, tray, drip edge and frame for the bird screen.
        let prof: [V2] = [V2(0, 0.012), V2(D - 0.004, 0.012), V2(D - 0.004, 0.135), V2(0, 0.29)]
        for sx in [Float(-1), 1] { FA.run(&m, prof, length: 0.003, at: V3(sx * 0.1425, 0, 0), steel, bevel: 0.0008) }
        let slope = atan2(Float(0.155), Float(D - 0.004)) * 180 / .pi
        let rl = sqrt((D - 0.004) * (D - 0.004) + 0.155 * 0.155)
        FA.box(&m, V3(0.288, 0.003, rl), V3(0, (0.135 + 0.29) / 2 + 0.0004, (D - 0.004) / 2), steel, r: 0.0012, rot: FA.q(slope, FA.X))
        FA.box(&m, V3(0.288, 0.003, D - 0.004), V3(0, 0.0135, (D - 0.004) / 2), steel, r: 0.0012)
        FA.box(&m, V3(0.292, 0.006, 0.008), V3(0, 0.138, D - 0.008), steel, r: 0.0025)
        FA.box(&m, V3(0.292, 0.005, 0.008), V3(0, 0.0125, D - 0.006), steel, r: 0.0025)
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.008, 0.126, 0.005), V3(sx * 0.14, 0.0745, D - 0.003), steel, r: 0.0015) }
        FA.box(&m, V3(0.276, 0.122, 0.0012), V3(0, 0.0745, D - 0.0045), "glass.wire-mesh", r: 0.0003)
        for i in 1..<3 { FA.box(&m, V3(0.276, 0.0025, 0.003), V3(0, 0.0125 + Float(i) * 0.0405, D - 0.0045), "metal.aluminum-brushed", r: 0.0008) }
        // Weathering: grease runs on the tray and below the opening, soot at the roof lip, hard-water spotting.
        for x in [Float(-0.11), -0.04, 0.03, 0.1] {
            FS.streak(&m, x: x + rng.float(-0.01...0.01), top: 0.012, w: 0.01, h: rng.float(0.006...0.011), z: 0.0044, "metal.painted:5B4426")
        }
        FA.box(&m, V3(0.27, 0.009, 0.0016), V3(0, 0.0185, D - 0.0005), "metal.painted:5B4426", r: 0.0005)
        FA.box(&m, V3(0.27, 0.008, 0.0016), V3(0, 0.14, D - 0.0005), "metal.painted:3C3022", r: 0.0005)
        for _ in 0..<22 {
            FC.bead(&m, r: rng.float(0.001...0.002), at: V3(rng.float(-0.12...0.12), 0.0135 + 0.0016, rng.float(0.02...0.19)), "metal.painted:5B4426", sub: 2)
        }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
