import simd
import Foundation

/// Solar thermal collector: flat plate panel, 1.0 x 2.0 m, 100 mm deep. Anodised aluminium frame of four mitred
/// extrusions on corner keys, 4 mm low-iron toughened glass bedded in an EPDM gasket under a 12 mm retaining lip,
/// blued selective-coated copper absorber with ten 8 mm riser tubes brazed to 22 mm top and bottom headers, four
/// compression stubs with olive nuts, aluminium back sheet with weep holes, and two floor feet. Dust film pools
/// along the lower glass edge and water-spot streaks run from the weep line.
public struct SolarThermalCollector: RealAsset {
    public static let id = "solar-thermal-collector"
    public static let summary = "Flat plate solar thermal collector: anodised frame, toughened glass, blued absorber, copper risers and headers, compression stubs."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.0)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.0, 2.0, 0.1)
    public var frame: MaterialKey = "metal.anodized-worn"
    public var absorber: MaterialKey = "metal.anodized-black"
    public var copper: MaterialKey = "metal.copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.96, H: Float = 1.96, D: Float = 0.1, fw: Float = 0.04, y0: Float = 0.03
        let cx: Float = 0, cy = y0 + H / 2
        // Frame: four members, front lip 12 mm (profile z out), mitred by overlapping at corners with corner keys.
        let side: [V2] = [V2(0, 0), V2(D, 0), V2(D, fw), V2(D - 0.004, fw), V2(D - 0.004, 0.012), V2(0.012, 0.012), V2(0.012, fw), V2(0, fw)]
        _ = side
        for s: Float in [-1, 1] {
            FA.box(&m, V3(fw, H, D), V3(cx + s * (W / 2 - fw / 2), cy, D / 2), frame, r: 0.0025)
        }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(W - 2 * fw + 0.002, fw, D), V3(cx, cy + s * (H / 2 - fw / 2), D / 2), frame, r: 0.0025)
        }
        // Glass in a gasket: recess it 3 mm behind the lip.
        FA.box(&m, V3(W - 2 * fw + 0.018, H - 2 * fw + 0.018, 0.004), V3(cx, cy, D - 0.008), "glass.tinted", r: 0.0006)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.006, H - 2 * fw + 0.016, 0.006), V3(cx + s * (W / 2 - fw - 0.002), cy, D - 0.006), "rubber.silicone", r: 0.0012)
            FA.box(&m, V3(W - 2 * fw + 0.016, 0.006, 0.006), V3(cx, cy + s * (H / 2 - fw - 0.002), D - 0.006), "rubber.silicone", r: 0.0012)
        }
        // Absorber: blued sheet, ten riser tubes with laser-welded fins, headers.
        FA.box(&m, V3(W - 2 * fw - 0.01, H - 2 * fw - 0.1, 0.0008), V3(cx, cy, 0.05), absorber, r: 0.0002)
        let rx0 = -(W / 2 - fw - 0.05), pitch = (W - 2 * fw - 0.1) / 9
        for i in 0..<10 {
            let x = cx + rx0 + Float(i) * pitch
            FA.rod(&m, V3(x, y0 + fw + 0.02, 0.0525), V3(x, y0 + H - fw - 0.02, 0.0525), r: 0.004, copper, sides: 8)
            FA.box(&m, V3(0.006, H - 2 * fw - 0.1, 0.0015), V3(x, cy, 0.0512), "metal.copper-patina", r: 0.0003)
        }
        for i in 0..<9 {   // laser-welded fin strips between risers, alternate sheets slightly different coating batch
            let x = cx + rx0 + (Float(i) + 0.5) * pitch
            FA.box(&m, V3(pitch - 0.014, H - 2 * fw - 0.1, 0.0004), V3(x, cy, 0.0509), i % 2 == 0 ? "metal.anodized-gunmetal-worn" : "metal.anodized-black", r: 0.0001)
        }
        for s: Float in [-1, 1] {
            let hy = cy + s * (H / 2 - fw - 0.04)
            FA.rod(&m, V3(-(W / 2 - fw + 0.02), hy, 0.056), V3(W / 2 - fw + 0.02, hy, 0.056), r: 0.0115, copper, sides: 12)
            // Compression stubs with olive nuts through the side members.
            for e: Float in [-1, 1] {
                FA.rod(&m, V3(e * (W / 2 - fw), hy, 0.056), V3(e * (W / 2 + 0.03), hy, 0.056), r: 0.0115, copper, sides: 12)
                m.add(Prim.extrude(Shape2D.rounded(Shape2D.polygon(sides: 6, radius: 0.0165), radius: 0.001, segments: 1), depth: 0.016, bevel: 0.0015, bevelSegments: 1, material: "metal.brass-aged"),
                      Xform(translation: V3(e * (W / 2 + 0.006), hy, 0.056), rotation: FA.q(90, FA.Y)))
                // Insulation sleeve (black foam) on the stub.
                m.add(Prim.cylinder(radius: 0.0155, height: 0.02, bevel: 0.002, segments: 12, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: V3(e * (W / 2 + 0.014), hy, 0.056), rotation: FA.q(-90 * e, FA.Z)))
            }
            // Brazed joints at the header and riser T's (copper-rust bloom).
            for i in 0..<10 {
                m.add(Prim.cylinder(radius: 0.0062, height: 0.012, bevel: 0.001, segments: 6, bevelSegments: 1, material: "metal.brass"), Xform(translation: V3(cx + rx0 + Float(i) * pitch, hy - 0.006, 0.0525)))
            }
        }
        // Back sheet with weep holes and two rear rails, rivets.
        FA.box(&m, V3(W - 0.004, H - 0.004, 0.0015), V3(cx, cy, 0.0008), "metal.aluminum", r: 0.0003)
        for i in 0..<5 { FC.slab(&m, V3(0.008, 0.008, 0.002), V3(-0.3 + Float(i) * 0.15, y0 + 0.02, 0.0), "wood.charred") }
        for y in [0.5, 1.5] as [Float] {
            FA.box(&m, V3(W - 0.1, 0.04, 0.02), V3(cx, y, -0.01), "metal.aluminum-brushed", r: 0.002)
        }
        // Corner key screws and the glazing retaining screws on the head and sill.
        for sx: Float in [-1, 1] {
            for sy: Float in [-1, 1] {
                rivet(&m, at: V3(cx + sx * (W / 2 - fw / 2), cy + sy * (H / 2 - fw / 2), D), normal: FA.Z, radius: 0.0045, height: 0.0025, segments: 8, material: "metal.screw-zinc")
            }
        }
        for x in stride(from: Float(-0.36), through: 0.36, by: 0.18) {
            for s: Float in [-1, 1] {
                rivet(&m, at: V3(cx + x, cy + s * (H / 2 - fw / 2), D), normal: FA.Z, radius: 0.0032, height: 0.002, segments: 6, material: rng.chance(0.2) ? "metal.rust" : "metal.screw-zinc")
            }
        }
        // Floor feet: two angle brackets bolted through the sill.
        for x: Float in [-0.32, 0.32] {
            FA.box(&m, V3(0.12, 0.03, 0.12), V3(cx + x, 0.015, 0.05), "metal.galvanized", r: 0.0025)
            hexBolt(&m, at: V3(cx + x, 0.03, 0.05), normal: FA.Y, size: 0.016, material: "metal.rust")
        }
        // Wear: dust film pooled along the lower glass, water-spot streaks, white aluminium bloom, bird dropping.
        for _ in 0..<22 {   // dust and pollen drifts caught against the glazing lip
            FC.slab(&m, V3(rng.float(0.02...0.09), rng.float(0.004...0.012), 0.0007), V3(rng.float(-0.42...0.42), y0 + fw + 0.004 + rng.float(0...0.015), D - 0.0054), "soil.potting")
        }
        for _ in 0..<5 {   // water spots
            FC.slab(&m, V3(rng.float(0.004...0.01), rng.float(0.08...0.3), 0.0006), V3(rng.float(-0.4...0.4), y0 + fw + 0.1 + rng.float(0...0.8), D - 0.0054), "concrete.smooth")
        }
        groundAO(&m, height: 0.4, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
