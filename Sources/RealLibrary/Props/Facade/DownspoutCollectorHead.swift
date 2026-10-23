import simd
import Foundation

/// Downspout collector head: architectural facade customizer, Georgian, painted galvanized collector head (conductor head) with embossed panel, ear straps and downspout stub. Parts: tapered hopper body, embossed front panel, top rim and overflow notch, wall ear straps, downspout stub and pipe clips, splash block, seam solder and fasteners.
public struct DownspoutCollectorHead: RealAsset {
    public static let id = "downspout-collector-head"
    public static let summary = "Downspout collector head, 0.25 x 0.35 x 0.2 m: Georgian tapered hopper with embossed panel, downspout and splash block."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Head top width in meters.
    public var width: Float = 0.25
    /// Painted body material key.
    public var paint: MaterialKey = "metal.painted:40564A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let inner: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", sol: MaterialKey = "metal.solder"
        let y0: Float = 0.13, y1: Float = 0.35, W = width
        func ring(_ w: Float, _ d: Float, _ cz: Float, _ r: Float, _ y: Float) -> [V3] {
            Prim.ring(Shape2D.roundedRect(w, d, radius: r), y: y, offset: V3(0, 0, cz))
        }
        // Hopper: outer skin, inner galvanized liner, rolled top rim.
        m.add(Prim.loft([ring(0.074, 0.074, 0.042, 0.006, y0), ring(0.13, 0.11, 0.058, 0.01, 0.20), ring(W, 0.18, 0.10, 0.012, y1)], material: paint))
        m.add(Prim.loft([ring(0.066, 0.066, 0.042, 0.005, y0 - 0.004), ring(W - 0.012, 0.168, 0.10, 0.01, y1 - 0.002)], material: inner).flipped())
        m.add(Prim.loft([ring(W + 0.004, 0.184, 0.10, 0.013, y1 - 0.004), ring(W + 0.006, 0.186, 0.10, 0.013, y1 + 0.003), ring(W - 0.014, 0.166, 0.10, 0.01, y1 + 0.003), ring(W - 0.012, 0.168, 0.10, 0.01, y1 - 0.004)], material: paint))
        // Embossed front panel on the sloped face (leans forward 27.6 degrees).
        let th: Float = 27.6 * .pi / 180
        let up = V3(0, cos(th), sin(th)), nrm = V3(0, -sin(th), cos(th)), c0 = V3(0, 0.245, 0.1385)
        func P(_ u: Float, _ v: Float, _ n: Float = 0) -> V3 { c0 + V3(u, 0, 0) + up * v + nrm * n }
        let rot = FA.q(27.6, FA.X)
        FA.box(&m, V3(0.17, 0.115, 0.004), P(0, 0, 0.001), inner, r: 0.0012, rot: rot)
        for (u, v, w, h) in [(0, 0.052, 0.17, 0.006), (0, -0.052, 0.17, 0.006), (-0.082, 0, 0.006, 0.115), (0.082, 0, 0.006, 0.115)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, 0.004), P(u, v, 0.004), paint, r: 0.0015, rot: rot)
        }
        FA.box(&m, V3(0.07, 0.034, 0.004), P(0, -0.012, 0.005), paint, r: 0.002, rot: rot)
        m.add(Prim.lathe([V2(0, 0.006), V2(0.024, 0.004), V2(0.03, 0.002), V2(0.03, 0), V2(0, 0)], segments: 16, seamTile: 0.1, material: inner), Xform(translation: P(0, 0.028, 0.005), rotation: FA.q(27.6 + 90, FA.X)))
        FA.box(&m, V3(0.055, 0.014, 0.003), P(0, -0.012, 0.008), "metal.brass-aged", r: 0.001, rot: rot)
        for i in 0..<8 { // rivet dots around the panel
            let u = -0.075 + Float(i) * 0.15 / 7
            m.add(Prim.cylinder(radius: 0.0028, height: 0.003, bevel: 0.0008, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: P(u, 0.043, 0.0045), rotation: rot))
            m.add(Prim.cylinder(radius: 0.0028, height: 0.003, bevel: 0.0008, segments: 6, bevelSegments: 1, material: i == 3 ? rust : zinc), Xform(translation: P(u, -0.043, 0.0045), rotation: rot))
        }
        // Side seam laps with solder beads and wall ear straps.
        for s: Float in [-1, 1] {
            for y: Float in [0.24, 0.31] {
                FA.box(&m, V3(0.03, 0.07, 0.003), V3(s * 0.05, y, 0.0016), paint, r: 0.0012)
                FA.cylZ(&m, r: 0.0045, h: 0.003, at: V3(s * 0.05, y, 0.003), y > 0.27 ? rust : zinc, bevel: 0.0007, segments: 8)
            }
        }
        // Bead rolls around the body and a cornice moulding under the rim.
        m.add(Prim.loft([ring(0.15, 0.125, 0.0645, 0.009, 0.232), ring(0.156, 0.131, 0.0645, 0.009, 0.236), ring(0.15, 0.125, 0.0645, 0.009, 0.24)], material: paint))
        m.add(Prim.loft([ring(W + 0.002, 0.182, 0.10, 0.013, y1 - 0.03), ring(W + 0.008, 0.188, 0.10, 0.013, y1 - 0.024), ring(W + 0.002, 0.182, 0.10, 0.013, y1 - 0.018)], material: inner))
        // Overflow notch lip on the rim.
        FA.box(&m, V3(0.05, 0.006, 0.014), V3(0, y1 + 0.004, 0.194), paint, r: 0.0015)
        // Downspout stub, clip band, shoe and splash block.
        FA.box(&m, V3(0.07, 0.09, 0.07), V3(0, 0.1, 0.042), paint, r: 0.004)
        FA.box(&m, V3(0.078, 0.012, 0.078), V3(0, 0.105, 0.042), inner, r: 0.0025)
        FA.box(&m, V3(0.03, 0.01, 0.034), V3(0, 0.105, 0.0035), inner, r: 0.0012)
        FA.cylZ(&m, r: 0.0042, h: 0.003, at: V3(0, 0.105, 0.0035), zinc, bevel: 0.0007, segments: 8)
        FA.box(&m, V3(0.07, 0.05, 0.12), V3(0, 0.055, 0.082), paint, r: 0.004, rot: FA.q(-8, FA.X))
        FA.box(&m, V3(0.062, 0.0015, 0.07), V3(0, 0.0295, 0.12), "metal.rust-grime", r: 0.0006)
        FA.box(&m, V3(0.2, 0.03, 0.19), V3(0, 0.015, 0.105), "stone.cast-stone", r: 0.004)
        FA.box(&m, V3(0.07, 0.003, 0.15), V3(0, 0.0315, 0.12), "stone.limestone-sooted", r: 0.0012)
        for i in 0..<4 { // leaf litter on the block
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.026), 0.003, rng.float(0.008...0.016)), exponent: 2, subdivisions: 6, material: i % 2 == 0 ? "wood.weathered" : "metal.rust"),
                  Xform(translation: V3(rng.float(-0.08...0.08), 0.033, rng.float(0.05...0.19)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        // Stains: run-off streaks below the rim and under the panel.
        for _ in 0..<3 {
            let x = rng.float(-0.07...0.07)
            FA.box(&m, V3(rng.float(0.004...0.01), rng.float(0.05...0.1), 0.0012), P(x, rng.float(-0.04...0.0), 0.0066), rust, r: 0.0004, rot: rot)
        }
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
