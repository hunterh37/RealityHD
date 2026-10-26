import simd
import Foundation

/// Building integrated PV tile: 1 m square glass-glass roof module, 40 mm deep. 3.2 mm toughened front glass
/// with a black screen-printed border, 36 monocrystalline half-cut cells with busbars and cell gaps, 2 mm
/// white back glass, black anodised frame with an interlocking head lap and side rebate, gasket, junction box with
/// three bypass diodes and two cable glands, 4 mm solar cable with MC4 connectors clipped to the frame, a rating
/// plate and drain notches. One cell shows a hot-spot burn, another a hairline micro-crack; dust and a bird
/// dropping gather on the sill edge.
public struct BuildingIntegratedPvTile: RealAsset {
    public static let id = "building-integrated-pv-tile"
    public static let summary = "Glass-glass BIPV roof module: 36 mono cells, black frame with lap, junction box, MC4 leads, hot-spot cell and dust."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 28, distance: 1.9)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.0, 1.0, 0.04)
    public var frame: MaterialKey = "metal.anodized-black"
    public var cells: MaterialKey = "solar.cell:16243C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.98, H: Float = 0.98, z0: Float = 0.012, z1: Float = 0.04, fw: Float = 0.026
        // Frame: four members 26 mm wide, 28 mm deep; head lap and right rebate step 6 mm.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(fw, H, z1 - z0), V3(s * (W / 2 - fw / 2), H / 2, (z0 + z1) / 2), frame, r: 0.0025)
            FA.box(&m, V3(W - 2 * fw + 0.002, fw, z1 - z0), V3(0, H / 2 + s * (H / 2 - fw / 2), (z0 + z1) / 2), frame, r: 0.0025)
        }
        FA.box(&m, V3(0.026, 0.9, 0.006), V3(W / 2 + 0.008, H / 2, z0 + 0.003), frame, r: 0.0012)   // rebate lip
        FA.box(&m, V3(0.9, 0.026, 0.006), V3(0, H + 0.008, z1 - 0.003), frame, r: 0.0012)          // head lap
        // Laminate: back glass, cell slab (36 cells via the cell texture), front glass with black frit border.
        FA.box(&m, V3(W - 2 * fw + 0.006, H - 2 * fw + 0.006, 0.002), V3(0, H / 2, z0 + 0.012), "plastic.white", r: 0.0004)
        FC.slab(&m, V3(0.936, 0.936, 0.0006), V3(0, H / 2, z0 + 0.0135), cells)
        FA.box(&m, V3(W - 2 * fw + 0.006, H - 2 * fw + 0.006, 0.0032), V3(0, H / 2, z1 - 0.006), "glass.tinted", r: 0.0005)
        let fr = z1 - 0.0043
        for s: Float in [-1, 1] {
            FC.slab(&m, V3(0.024, H - 2 * fw, 0.0004), V3(s * (W / 2 - fw - 0.002), H / 2, fr), "plastic.black")
            FC.slab(&m, V3(W - 2 * fw - 0.044, 0.024, 0.0004), V3(0, H / 2 + s * (H / 2 - fw - 0.002), fr), "plastic.black")
        }
        // Gasket bead under the front lip.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.004, H - 2 * fw + 0.004, 0.003), V3(s * (W / 2 - fw), H / 2, z1 - 0.0045), "rubber.silicone", r: 0.001)
            FA.box(&m, V3(W - 2 * fw + 0.004, 0.004, 0.003), V3(0, H / 2 + s * (H / 2 - fw), z1 - 0.0045), "rubber.silicone", r: 0.001)
        }
        // Junction box on the back, with lid screws, two glands and the rating plate.
        FA.box(&m, V3(0.12, 0.07, 0.022), V3(0, 0.78, z0 - 0.011 + 0.0005), "plastic.black", r: 0.004)
        FA.box(&m, V3(0.112, 0.062, 0.003), V3(0, 0.78, z0 - 0.022), "plastic.black", r: 0.002)
        for x: Float in [-0.05, 0.05] {
            for y: Float in [0.755, 0.805] {
                rivet(&m, at: V3(x, y, z0 - 0.0235), normal: V3(0, 0, -1), radius: 0.0025, height: 0.0015, segments: 6, material: "metal.screw-zinc")
            }
        }
        for x: Float in [-0.035, 0.035] {
            m.add(Prim.cylinder(radius: 0.0085, height: 0.022, bevel: 0.001, segments: 8, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(x, 0.742, z0 - 0.011), rotation: FA.q(90, FA.Z)))
        }
        FC.slab(&m, V3(0.1, 0.03, 0.0006), V3(0.2, 0.5, z0 + 0.0003 - 0.0016), "plastic.white")
        for i in 0..<5 { FC.slab(&m, V3(0.08 - Float(i % 2) * 0.02, 0.0025, 0.0004), V3(0.2, 0.5 + 0.008 - Float(i) * 0.004, z0 + 0.0003 - 0.0021), "plastic.black") }
        // Cables: 4 mm leads from the glands along the frame to MC4 connectors with locking collars.
        for (x, sx) in [(Float(-0.035), Float(-1)), (0.035, 1)] {
            let path = catmull([V3(x, 0.742, z0 - 0.011), V3(x * 1.8, 0.7, z0 - 0.018), V3(sx * 0.2, 0.62, z0 - 0.016), V3(sx * 0.36, 0.5, z0 - 0.012), V3(sx * 0.4, 0.3, z0 - 0.01)], per: 5)
            m.add(Prim.tube(path, radii: Array(repeating: 0.002, count: path.count), sides: 6, seamTile: 0.05, material: "plastic.black", capEnd: true))
            let e = V3(sx * 0.4, 0.3, z0 - 0.01)
            FA.rod(&m, e, e + V3(0, -0.05, 0), r: 0.0048, "plastic.black", sides: 8)
            FA.rod(&m, e + V3(0, -0.012, 0), e + V3(0, -0.032, 0), r: 0.0062, sx > 0 ? "metal.brass" : "plastic.black", sides: 8)
        }
        // Cable clips on the frame.
        for y: Float in [0.62, 0.45] {
            FA.box(&m, V3(0.012, 0.01, 0.012), V3(-0.36, y, z0 - 0.008), "plastic.black", r: 0.0015)
        }
        // Drain notches in the lower rebate.
        for x in [-0.3, 0.0, 0.3] as [Float] {
            FC.slab(&m, V3(0.018, 0.006, 0.004), V3(x, 0.0125, z0 + 0.012), "wood.charred")
        }
        // Wear: hot-spot burn cell, hairline crack, snail-trail curves, dust at the sill, bird dropping, scuffed frame corners.
        FC.slab(&m, V3(0.15, 0.15, 0.0004), V3(0.156, 0.37, z1 - 0.0045), "plastic.matte:3A2A1E")
        for i in 0..<3 {
            let a = rng.float(-0.8...0.8)
            m.add(Prim.extrude(Shape2D.rect(0.002, rng.float(0.08...0.14)), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.white"),
                  Xform(translation: V3(rng.float(-0.38...0.38), rng.float(0.2...0.8), z1 - 0.0044), rotation: FA.q(a * 57, FA.Z)))
            _ = i
        }
        for _ in 0..<18 {
            FC.slab(&m, V3(rng.float(0.02...0.08), rng.float(0.003...0.009), 0.0005), V3(rng.float(-0.44...0.44), fw + 0.004 + rng.float(0...0.012), z1 - 0.0044), "soil.potting")
        }
        FC.slab(&m, V3(0.03, 0.02, 0.0006), V3(0.24, 0.31, z1 - 0.0044), "plastic.white")
        for (sx, sy) in [(Float(-1), Float(0)), (1, 0), (-1, 1), (1, 1)] {
            FC.slab(&m, V3(0.02, 0.012, 0.001), V3(sx * (W / 2 - 0.012), sy * (H - 0.012) + 0.006, z1 + 0.0003), "metal.aluminum-brushed")
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.fit(m, size))
    }
}
