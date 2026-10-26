import simd
import Foundation

/// Neoclassical fluted Ionic pilaster, 2.6 m: plinth, Attic base, a shaft of four stone drums with five
/// elliptical flutes, entasis and mortar joints, necking, astragal, egg-and-dart echinus, a volute capital
/// and a cyma abacus. Sooted base and a spalled plinth corner. Wall plane at z = 0.
public struct FlutedPilasterIonic: RealAsset {
    public static let id = "fluted-pilaster-ionic"
    public static let summary = "Neoclassical Ionic pilaster, 2.6 m: attic-style base with plinth, 20-flute shaft with arrises, Ionic capital with volutes and echinus, and abacus."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.2)

    /// Shaft and capital stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted base and plinth.
    public var shade: MaterialKey = "stone.limestone-sooted"
    /// Mortar joint colour.
    public var mortar: MaterialKey = "stone.limestone-sooted"
    public init() {}

    /// Fluted section for shaft width `w` at scale `s`: five flutes, front at `zf`, back on the wall.
    static func section(w: Float, zf: Float, s: Float) -> [V2] {
        let n = 5, pitch = w / Float(n), fillet: Float = 0.011, d: Float = 0.0085
        var pts: [V2] = [V2(-w / 2, -zf)]
        for i in 0..<n {
            let c = -w / 2 + pitch * (Float(i) + 0.5), hw = (pitch - fillet) / 2
            pts.append(V2(c - hw, -zf))
            for j in 1..<8 {
                let u = -1 + 2 * Float(j) / 8
                pts.append(V2(c + u * hw, -(zf - d * sqrt(max(0, 1 - u * u)))))
            }
            pts.append(V2(c + hw, -zf))
        }
        pts.append(V2(w / 2, -zf))
        pts += [V2(w / 2, 0), V2(-w / 2, 0)]
        return Shape2D.deduped(pts).map { V2($0.x * s, $0.y * s) }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.3, D: Float = 0.12, shaftW: Float = 0.22, shaftD: Float = 0.1
        let y0: Float = 0.22, y1: Float = 2.22
        // Plinth and Attic base: lower torus, scotia, upper torus, with fillets.
        FA.box(&m, V3(W, 0.12, D), V3(0, 0.06, D / 2), shade, r: 0.004)
        FA.box(&m, V3(0.1, 0.0, 0.0) + V3(0.17, 0.012, 0.114), V3(0, 0.126, 0.057), shade, r: 0.002)
        let baseProfile: [V2] = [V2(0, 0.132), V2(0.112, 0.132), V2(0.112, 0.145), V2(0.108, 0.158), V2(0.1, 0.165), V2(0.092, 0.168), V2(0.09, 0.172), V2(0.092, 0.175),
                                 V2(0.096, 0.186), V2(0.092, 0.197), V2(0.1, 0.205), V2(0.108, 0.212), V2(0.11, 0.22), V2(0, 0.22)]
        FA.run(&m, baseProfile, length: 0.27, at: .zero, shade, bevel: 0.0015)
        // Shaft drums with entasis and dark mortar beds between them.
        let bounds: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0].map { y0 + $0 * (y1 - y0) }
        func scale(_ y: Float) -> Float { let t = (y - y0) / (y1 - y0); return 1 - 0.1 * t + 0.012 * sin(.pi * t) }
        for k in 0..<4 {
            let a = bounds[k] + (k == 0 ? 0 : 0.0015), b = bounds[k + 1] - (k == 3 ? 0 : 0.0015)
            let rings = [a, (a + b) / 2, b].map { Prim.ring(Self.section(w: shaftW, zf: shaftD, s: scale($0)), y: $0) }
            m.add(Prim.loft(rings, capStart: true, capEnd: true, material: stone))
            if k < 3 {
                let yj = bounds[k + 1], s = scale(yj)
                FA.box(&m, V3(shaftW * s - 0.006, 0.0032, (shaftD - 0.008) * s), V3(0, yj, (shaftD - 0.008) * s / 2), mortar, r: 0.0005)
            }
        }
        // Necking, astragal bead and the egg-and-dart echinus.
        let st = scale(y1)
        FA.box(&m, V3(shaftW * st + 0.01, 0.035, shaftD * st + 0.005), V3(0, y1 + 0.0175, (shaftD * st + 0.005) / 2), stone, r: 0.003)
        FA.cylX(&m, r: 0.0085, h: shaftW * st + 0.034, at: V3(-(shaftW * st + 0.034) / 2, y1 + 0.043, shaftD * st / 2 + 0.003), stone, bevel: 0.002, segments: 12)
        let ey = y1 + 0.052
        let ech: [V2] = [V2(0, ey), V2(0.098, ey), V2(0.102, ey + 0.004), V2(0.112, ey + 0.016), V2(0.118, ey + 0.034), V2(0.12, ey + 0.05), V2(0, ey + 0.05)]
        FA.run(&m, ech, length: 0.25, at: .zero, stone, bevel: 0.0015)
        for i in 0..<8 {
            let x = -0.105 + Float(i) * 0.03
            m.add(Prim.superellipsoid(V3(0.021, 0.04, 0.022), exponent: 2, subdivisions: 3, material: stone),
                  Xform(translation: V3(x, ey + 0.023, 0.113), rotation: FA.q(-14, FA.X)))
            if i < 7 {
                m.add(Prim.lathe([V2(0.004, 0), V2(0.002, 0.015), V2(0, 0.032)], segments: 4, material: shade),
                      Xform(translation: V3(x + 0.015, ey + 0.006, 0.108), rotation: FA.q(-10, FA.X)))
            }
        }
        // Volute capital: channel band, two spiral volutes on backing discs, bolster and abacus.
        let cy = ey + 0.05 + 0.062, cap0 = ey + 0.05
        FA.box(&m, V3(0.285, 0.124, 0.1), V3(0, cap0 + 0.062, 0.05), stone, r: 0.004)
        FA.box(&m, V3(0.12, 0.04, 0.118), V3(0, cy + 0.01, 0.059), stone, r: 0.008)     // channel pulvinus
        FA.box(&m, V3(0.12, 0.012, 0.122), V3(0, cy + 0.022 + 0.006, 0.061), shade, r: 0.003)
        for s: Float in [-1, 1] {
            let cx = s * 0.093
            FA.cylZ(&m, r: 0.058, h: 0.12, at: V3(cx, cy, 0.0), stone, bevel: 0.004, segments: 26)
            let spiral = (0...64).map { i -> V3 in
                let a = Float(i) / 64 * 14
                let r = 0.046 - 0.0031 * a
                return V3(cx + r * cos(a * s + (s > 0 ? 0 : .pi)), cy + r * sin(a * s + (s > 0 ? 0 : .pi)), 0.119)
            }
            FA.path(&m, spiral, r: 0.0042, shade, sides: 6)
            FA.ball(&m, r: 0.0085, at: V3(cx, cy, 0.121), stone)
        }
        // Abacus: fillet, cyma and top fillet.
        let ay = cap0 + 0.124
        var abacus: [V2] = [V2(0, ay), V2(0.11, ay), V2(0.11, ay + 0.004)]
        abacus += FL.ogee(from: V2(0.11, ay + 0.004), to: V2(0.12, ay + 0.03), steps: 5)
        abacus += [V2(0.12, ay + 0.04), V2(0, ay + 0.04)]
        FA.run(&m, abacus, length: 0.3, at: .zero, stone, bevel: 0.0015)
        // Wear: spalled plinth corner, soot band above the plinth, rain streak down one flute, drip stains below the abacus.
        FA.box(&m, V3(0.035, 0.05, 0.03), V3(0.15 - 0.015, 0.02, 0.095), "stone.limestone", r: 0.004, rot: FA.q(-18, FA.Y))
        FA.box(&m, V3(0.21, 0.28, 0.0015), V3(0, 0.38, (shaftD - 0.012) * 0.97 + 0.0), shade, r: 0.0005)
        for _ in 0..<3 {
            let x = rng.float(-0.08...0.08)
            FA.box(&m, V3(0.006, rng.float(0.15...0.3), 0.001), V3(x, 2.0 - rng.float(0...0.3), 0.0955), shade, r: 0.0003)
        }
        for (x, w) in [(-0.1, 0.07), (0.09, 0.05)] as [(Float, Float)] {
            m.add(Prim.superellipsoid(V3(w, 0.014, 0.04), exponent: 2.4, subdivisions: 4, material: "moss.cushion"), Xform(translation: V3(x, 0.125, 0.085)))
        }
        groundAO(&m, height: 0.2, floor: 0.85)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
