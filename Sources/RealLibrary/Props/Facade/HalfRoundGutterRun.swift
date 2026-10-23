import simd
import Foundation

/// Half-round gutter run: architectural facade customizer, Georgian, half-round gutter run on rafter brackets with end caps and outlet. Parts: half-round trough, bead rim, strap brackets, end caps, joint collar, outlet.
public struct HalfRoundGutterRun: RealAsset {
    public static let id = "half-round-gutter-run"
    public static let summary = "Half-round gutter run, 3.0 x 0.12 x 0.1 m: galvanized trough on strap brackets with end caps."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Run length in meters.
    public var length: Float = 2.99
    /// Trough radius in meters.
    public var radius: Float = 0.042
    /// Bracket spacing in meters.
    public var bracketSpacing: Float = 0.75
    /// Trough metal.
    public var metal: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let aged: MaterialKey = "metal.galvanized-aged", iron: MaterialKey = "metal.cast-iron", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", sol: MaterialKey = "metal.solder"
        let R = radius, cy: Float = 0.068, L = length, wall: Float = 0.0016
        var p: [V2] = []
        for k in 0...24 {
            let a = Float.pi + Float.pi * Float(k) / 24
            p.append(V2(R + R * cos(a), cy + R * sin(a)))
        }
        GutterKit.band(&m, p, 0, wall, x: 0, len: L, metal, bevel: 0.0004)
        GutterKit.band(&m, p, wall, wall + 0.0009, x: 0, len: L - 0.004, "metal.galvanized", bevel: 0.0003)
        // Rolled bead on both rims.
        for z in [Float(0), 2 * R] {
            FA.rod(&m, V3(-L / 2, cy, z), V3(L / 2, cy, z), r: 0.0034, metal, sides: 8)
        }
        for s: Float in [-1, 1] {
            GutterKit.cap(&m, p, x: s * (L / 2 + 0.0016), thick: 0.003, aged)
            FA.cylX(&m, r: 0.0034, h: 0.0042, at: V3(s * (L / 2 - 0.001), cy, 0), iron, bevel: 0.0005, segments: 10)
        }
        // Strap brackets: wrap under the trough, tail up the rafter with two screws.
        let n = Int(L / bracketSpacing)
        for i in 0...n {
            let x = (Float(i) - Float(n) / 2) * bracketSpacing
            GutterKit.band(&m, p, -0.0042, -0.0006, x: x, len: 0.024, iron, bevel: 0.0007)
            FA.box(&m, V3(0.024, 0.0042, 0.016), V3(x, cy + 0.0028, -0.0075), iron, r: 0.0008)
            FA.box(&m, V3(0.024, 0.066, 0.0042), V3(x, cy + 0.0357, -0.0095), iron, r: 0.0008)
            for y: Float in [cy + 0.02, cy + 0.055] {
                FA.cylZ(&m, r: 0.0055, h: 0.003, at: V3(x, y, -0.0125), (i + Int(y * 100)) % 5 == 0 ? rust : zinc, bevel: 0.0008, segments: 8)
            }
            // Rust bloom beneath each bracket.
            GutterKit.band(&m, p, -0.0046, -0.0042, x: x + rng.float(-0.012...0.012), len: rng.float(0.01...0.03), rust, bevel: 0.0001)
        }
        // Slip joint with soldered seam, and interior silt and stains.
        GutterKit.band(&m, p, -0.0032, -0.0006, x: 0.62, len: 0.07, aged, bevel: 0.0004)
        for d: Float in [-0.035, 0.035] { GutterKit.band(&m, p, -0.0044, -0.0032, x: 0.62 + d, len: 0.004, sol, bevel: 0.0008) }
        for _ in 0..<3 {
            GutterKit.band(&m, p, wall + 0.0009, wall + 0.0015, x: rng.float(-1.3...1.3), len: rng.float(0.03...0.14), rust, bevel: 0.0002)
        }
        // Weather staining outside, and a second riveted lap with a patch.
        let lower = p.filter { $0.y < cy - 0.01 }
        for i in 0..<4 {
            GutterKit.band(&m, lower, -0.0020, -0.0007, x: rng.float(-1.4...1.4), len: rng.float(0.006...0.022), i % 3 == 0 ? "metal.rust" : rust, bevel: 0.0001)
        }
        GutterKit.band(&m, p, -0.0030, -0.0006, x: -0.45, len: 0.06, "metal.galvanized", bevel: 0.0004)
        for k in 0..<5 {
            let a = Float.pi * (1.12 + 0.76 * Float(k) / 4)
            let c = V3(-0.45 - 0.022 + (k % 2 == 0 ? 0 : 0.044), cy + R * sin(a) * 1.0 - 0.0035 * sin(a), R + R * cos(a) + 0.0035 * cos(a))
            m.add(Prim.superellipsoid(V3(0.0045, 0.0045, 0.0045), exponent: 2, subdivisions: 3, material: zinc), Xform(translation: c))
        }
        // Outlet: collar, rim bead and dark drain.
        let ox: Float = -1.15, oz = R
        m.add(Prim.lathe([V2(0.021, 0.0), V2(0.021, -0.012), V2(0.0195, -0.012), V2(0.0195, 0.0)], segments: 16, seamTile: 0.1, material: aged), Xform(translation: V3(ox, cy - R + 0.002, oz)))
        m.add(Prim.torus(major: 0.0225, minor: 0.0016, segments: 16, sides: 5, material: sol), Xform(translation: V3(ox, cy - R + 0.0032, oz)))
        m.add(Prim.cylinder(radius: 0.018, height: 0.0007, bevel: 0.0003, segments: 20, bevelSegments: 1, material: rust), Xform(translation: V3(ox, cy - R + wall + 0.0010, oz)))
        for i in 0..<6 {
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.016), 0.004, rng.float(0.006...0.012)), exponent: 2, subdivisions: 6, material: i % 3 == 0 ? "metal.rust" : "wood.weathered"),
                  Xform(translation: V3(rng.float(0.3...1.4), cy - R + 0.004, oz + rng.float(-0.01...0.01)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
