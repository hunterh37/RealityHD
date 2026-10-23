import simd
import Foundation

/// Shared stroke helpers for gutter profiles (x out from the wall, y up, travel back-top down, along the floor, up the front).
enum GutterKit {
    /// Offsets an open path to its left (the channel interior) by `t` meters; negative goes outside.
    static func offset(_ p: [V2], _ t: Float) -> [V2] {
        var out: [V2] = []
        for i in 0..<p.count {
            let a = p[max(i - 1, 0)], b = p[i], c = p[min(i + 1, p.count - 1)]
            func n(_ u: V2, _ v: V2) -> V2 { let d = v - u; let l = max(simd_length(d), 1e-6); return V2(-d.y / l, d.x / l) }
            var nn = (i == 0) ? n(b, c) : (i == p.count - 1 ? n(a, b) : n(a, b) + n(b, c))
            let l = max(simd_length(nn), 1e-6); nn /= l
            let k = i == 0 || i == p.count - 1 ? 1 : max(simd_dot(nn, n(a, b)), 0.5)
            out.append(b + nn * (t / k))
        }
        return out
    }
    /// Closed outline of the strip between two offsets of the path.
    static func strip(_ p: [V2], _ a: Float, _ b: Float) -> [V2] { offset(p, a) + offset(p, b).reversed() }
    /// Strip extruded along X for `len`, centered at `x`.
    static func band(_ m: inout Model, _ p: [V2], _ a: Float, _ b: Float, x: Float, len: Float, _ mat: MaterialKey, bevel: Float = 0.0004) {
        FA.run(&m, strip(p, a, b), length: len, at: V3(x, 0, 0), mat, bevel: bevel)
    }
    /// End cap: filled path polygon, slightly proud, at x.
    static func cap(_ m: inout Model, _ p: [V2], x: Float, thick: Float, _ mat: MaterialKey) {
        FA.side(&m, p, thick: thick, at: V3(x, 0, 0), mat, bevel: 0.0006)
    }
}

/// Ogee gutter run: architectural facade customizer, Victorian, galvanized ogee (K-style) gutter run with end caps, hangers and downspout outlet. Parts: ogee front profile, hanger straps, end caps, seam laps, outlet, fascia screws.
public struct OgeeGutterRun: RealAsset {
    public static let id = "ogee-gutter-run"
    public static let summary = "Ogee gutter run, 3.0 x 0.14 x 0.14 m: painted K-style gutter with hangers, end caps and outlet."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Run length in meters.
    public var length: Float = 2.99
    /// Hanger spacing in meters.
    public var hangerSpacing: Float = 0.6
    /// Outer paint material key.
    public var paint: MaterialKey = "metal.painted:4A5A48"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let inner: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", sol: MaterialKey = "metal.solder"
        // K-style profile: flat back, flat floor, S-curved front, rolled lip.
        var p: [V2] = [V2(0, 0.13), V2(0, 0.012), V2(0.003, 0.004), V2(0.011, 0), V2(0.07, 0)]
        for k in 0...16 {
            let t = Float(k) / 16
            p.append(V2(0.075 + 0.055 * t - 0.008 * sin(2 * .pi * t), 0.115 * t))
        }
        p += [V2(0.1300, 0.1215), V2(0.1275, 0.1262), V2(0.1230, 0.1290), V2(0.1150, 0.1292)]
        let wall: Float = 0.0018, L = length
        GutterKit.band(&m, p, 0, wall, x: 0, len: L, paint, bevel: 0.0005)
        GutterKit.band(&m, p, wall, wall + 0.0010, x: 0, len: L - 0.004, inner, bevel: 0.0003)
        for s: Float in [-1, 1] {
            GutterKit.cap(&m, p, x: s * (L / 2 + 0.0016), thick: 0.0032, paint)
            GutterKit.band(&m, p, -0.0018, -0.0004, x: s * (L / 2 - 0.004), len: 0.008, inner, bevel: 0.0003)
        }
        // Hanger straps and fascia screws on a 600 mm spacing.
        let n = Int(L / hangerSpacing)
        for i in 0...n {
            let x = (Float(i) - Float(n) / 2) * hangerSpacing
            GutterKit.band(&m, p, -0.0034, -0.0004, x: x, len: 0.022, i % 2 == 0 ? inner : "metal.galvanized", bevel: 0.0005)
            FA.cylZ(&m, r: 0.0048, h: 0.0028, at: V3(x, 0.112, -0.0008), zinc, bevel: 0.0007, segments: 10)
            FA.cylZ(&m, r: 0.0048, h: 0.0028, at: V3(x, 0.05, -0.0008), i == 2 ? rust : zinc, bevel: 0.0007, segments: 10)
            FA.rod(&m, V3(x, 0.124, 0.1186), V3(x, 0.124, 0.0), r: 0.0021, zinc, sides: 6)
        }
        // Lap joint with solder beads, and a stain run.
        GutterKit.band(&m, p, -0.0030, -0.0004, x: 0.43, len: 0.07, inner, bevel: 0.0004)
        for d: Float in [-0.035, 0.035] { GutterKit.band(&m, p, -0.0040, -0.0030, x: 0.43 + d, len: 0.004, sol, bevel: 0.0008) }
        for _ in 0..<3 {
            let x = rng.float(-1.3...1.3)
            GutterKit.band(&m, p, wall + 0.0010, wall + 0.0016, x: x, len: rng.float(0.03...0.12), rust, bevel: 0.0002)
        }
        // Outlet collar, drain hole, a story dent patch of debris.
        let ox: Float = -1.15, oz: Float = 0.042
        m.add(Prim.lathe([V2(0.0235, 0.008), V2(0.0235, -0.008), V2(0.0215, -0.008), V2(0.0215, 0.008)], segments: 24, seamTile: 0.1, material: inner), Xform(translation: V3(ox, 0, oz)))
        m.add(Prim.torus(major: 0.027, minor: 0.0017, segments: 24, sides: 6, material: sol), Xform(translation: V3(ox, 0.0031, oz)))
        m.add(Prim.cylinder(radius: 0.02, height: 0.0007, bevel: 0.0003, segments: 20, bevelSegments: 1, material: rust), Xform(translation: V3(ox, 0.0033, oz)))
        for i in 0..<7 {
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.016), 0.004, rng.float(0.006...0.012)), exponent: 2, subdivisions: 6, material: i % 3 == 0 ? "metal.rust" : "wood.weathered"),
                  Xform(translation: V3(rng.float(0.5...1.4), 0.0045, rng.float(0.03...0.07)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
