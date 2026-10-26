import simd
import Foundation

/// Italianate cast iron window cap, 1.3 x 0.35 x 0.12 m: cast lintel section with a bottom flange and a moulded cap, raised
/// panel with a bead border and hex bolt bosses, a dentil band under the cap, two scrolled console brackets with volute feet and
/// leaf tops, and an anthemion crest with side rings and small palmettes at the ends. Painted umber with rust showing through
/// at the arrises, bolt heads and the casting seam.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct CastIronWindowCapLintel: RealAsset {
    public static let id = "cast-iron-window-cap-lintel"
    public static let summary = "Italianate cast iron window cap, 1.3 m: moulded lintel, raised panel with bolts, dentil band, console brackets, anthemion crest."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 2.4)

    /// Painted surface.
    public var paint: MaterialKey = "metal.painted:2E2B28"
    /// Bare cast iron showing at chips and joints.
    public var bare: MaterialKey = "metal.cast-iron"
    /// Rust bleed.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    /// Palmette petal: teardrop outline `len` long, `w` wide, base at the origin pointing +Y.
    private func petal(_ len: Float, _ w: Float) -> [V2] {
        [V2(0, 0), V2(w * 0.3, 0.12 * len), V2(w * 0.5, 0.45 * len), V2(w * 0.38, 0.78 * len), V2(0, len),
         V2(-w * 0.38, 0.78 * len), V2(-w * 0.5, 0.45 * len), V2(-w * 0.3, 0.12 * len)]
    }

    private func palmette(_ m: inout Model, at c: V3, count: Int, len: Float, spread: Float, _ mat: MaterialKey) {
        for k in 0..<count {
            let t = count == 1 ? 0 : Float(k) / Float(count - 1) * 2 - 1
            let a = t * spread
            let l = len * (1 - 0.3 * abs(t))
            m.add(Prim.extrude(petal(l, len * 0.34), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: mat),
                  Xform(translation: c, rotation: FA.q(-a, FA.Z)))
        }
        FC.bead(&m, r: len * 0.1, at: c + V3(0, len * 0.04, 0.006), mat, sub: 3)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 1.3
        let face: Float = 0.036

        // Cast section: bottom flange, face block, moulded cap (x out from the wall, y up).
        let sec: [V2] = [V2(0, 0), V2(0.07, 0), V2(0.07, 0.014), V2(face, 0.014), V2(face, 0.17), V2(0.07, 0.175), V2(0.088, 0.185),
                         V2(0.088, 0.196), V2(0.074, 0.201), V2(0.112, 0.207), V2(0.118, 0.214), V2(0.118, 0.225), V2(0, 0.225)]
        // Cast in one piece; a vertical seam line is cut at midspan.
        FA.run(&m, sec, length: L, at: .zero, paint, bevel: 0.0025)
        FA.box(&m, V3(0.003, 0.16, 0.002), V3(0, 0.095, face + 0.001), bare, r: 0.0005)

        // Raised panel with a bead border and hex bolt bosses.
        m.add(Prim.extrude(Shape2D.roundedRect(0.9, 0.105, radius: 0.008), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: paint),
              Xform(translation: V3(0, 0.082, face + 0.006)))
        let loop: [V3] = [V3(-0.45, 0.03, face + 0.0125), V3(0.45, 0.03, face + 0.0125), V3(0.45, 0.135, face + 0.0125),
                          V3(-0.45, 0.135, face + 0.0125), V3(-0.45, 0.03, face + 0.0125)]
        FA.path(&m, loop, r: 0.0045, paint, sides: 6)
        for s: Float in [-1, 1] {
            for y in [Float(0.055), 0.11] {
                FA.cylZ(&m, r: 0.011, h: 0.008, at: V3(s * 0.4, y, face + 0.012), bare, bevel: 0.0015, segments: 6)
                FO.streak(&m, x: s * 0.4, top: y - 0.008, w: 0.006, h: rng.float(0.02...0.04), z: face + 0.013, rust)
            }
        }
        // Dentil band under the cap, between the consoles.
        FO.comb(&m, count: 31, pitch: 0.03, w: 0.018, h: 0.03, bar: 0.004, y0: 0.14, z0: face, depth: 0.028, paint)

        // Console brackets: scrolled outline, volute rings on the front, leaf tops.
        let half: [V2] = [V2(0.06, 0.17), V2(0.058, 0.12), V2(0.05, 0.08), V2(0.042, 0.05), V2(0.036, 0.025), V2(0.022, 0.005)]
        let cons = FO.ccw(half.map { V2(-$0.x, $0.y) }.reversed() + half)
        for s: Float in [-1, 1] {
            let x = s * 0.585
            m.add(Prim.extrude(cons, depth: 0.064, bevel: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3(x, 0, face + 0.032)))
            m.add(Prim.torus(major: 0.022, minor: 0.008, segments: 14, sides: 5, material: paint),
                  Xform(translation: V3(x + s * 0.012, 0.04, face + 0.066), rotation: FA.q(90, FA.X)))
            m.add(Prim.torus(major: 0.013, minor: 0.006, segments: 12, sides: 5, material: paint),
                  Xform(translation: V3(x - s * 0.018, 0.075, face + 0.066), rotation: FA.q(90, FA.X)))
            for k in 0..<3 {
                m.add(Prim.superellipsoid(V3(0.02, 0.05, 0.022), exponent: 2, subdivisions: 2, material: paint),
                      Xform(translation: V3(x + Float(k - 1) * 0.034, 0.145, face + 0.068), rotation: FA.q(Float(k - 1) * -18, FA.Z)))
            }
            // Console bolt.
            FA.cylZ(&m, r: 0.008, h: 0.006, at: V3(x, 0.165, face + 0.064), bare, bevel: 0.001, segments: 6)
        }

        // Crest: anthemion over the centre, two side rings, small palmettes on the cap and at the ends.
        let capTop: Float = 0.225
        FA.box(&m, V3(0.12, 0.02, 0.07), V3(0, capTop + 0.01, 0.06), paint, r: 0.003)
        palmette(&m, at: V3(0, capTop + 0.02, 0.054), count: 9, len: 0.105, spread: 82, paint)
        for s: Float in [-1, 1] {
            m.add(Prim.torus(major: 0.03, minor: 0.007, segments: 14, sides: 5, material: paint),
                  Xform(translation: V3(s * 0.105, capTop + 0.06, 0.06), rotation: FA.q(90, FA.X)))
            FA.rod(&m, V3(s * 0.06, capTop + 0.02, 0.06), V3(s * 0.085, capTop + 0.045, 0.06), r: 0.006, paint, sides: 6)
            palmette(&m, at: V3(s * 0.33, capTop + 0.01, 0.054), count: 5, len: 0.07, spread: 60, paint)
            palmette(&m, at: V3(s * 0.595, capTop + 0.01, 0.054), count: 5, len: 0.07, spread: 42, paint)
        }

        // Wear: rust through the paint along the cap arris and the flange, blistered patches on the panel, runs under the cap.
        for _ in 0..<9 {
            FO.streak(&m, x: rng.float(-0.6...0.6), top: 0.14, w: rng.float(0.01...0.03), h: rng.float(0.03...0.1), z: face, rust)
        }
        for _ in 0..<7 {
            FA.box(&m, V3(rng.float(0.02...0.07), rng.float(0.006...0.02), 0.002), V3(rng.float(-0.6...0.6), 0.082, face + 0.0125), bare, r: 0.0005)
        }
        for _ in 0..<5 {
            FA.box(&m, V3(rng.float(0.03...0.09), 0.003, 0.003), V3(rng.float(-0.64...0.64), 0.0145, 0.07), rust, r: 0.0005)
        }

        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
