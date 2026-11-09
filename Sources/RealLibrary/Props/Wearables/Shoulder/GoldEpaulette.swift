import simd
import Foundation

/// Dress-uniform epaulette: a padded navy wool shoulder board that follows the trapezius and deltoid, red piping, a twisted
/// gold cord border, soutache diamond lattice, two brass rank stars, a domed gold button at the neck end and a bullion
/// fringe hanging off the outer end from a heading bar.
public struct GoldEpaulette: RealAsset {
    public static let id = "gold-epaulette"
    public static let summary = "Worn gold dress epaulette: padded navy board, braid border, lattice, rank stars, bullion fringe."
    public static let tags = ["prop", "wearable", "worn", "fabric", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 0.55, ground: false, studio: true)

    /// Board cloth.
    public var cloth: MaterialKey = "fabric.felt:1F2B4A"
    /// Piping cloth.
    public var piping: MaterialKey = "fabric.felt:5C1F27"
    /// Bullion, braid and lattice gold.
    public var gold: MaterialKey = "metal.gold"
    /// Aged gold for twist marks and stars.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias S = ShoulderKit
        var rng = SeededRNG(seed: seed)
        let sMax: Float = 0.058
        func edgeE(_ v: Float) -> Float { abs(2 * v - 1) }
        func B(_ u: Float, _ v: Float, widen: Float = 1, lift: Float = 0) -> V3 {
            let e = edgeE(v)
            let s0 = -0.082 + 0.010 * e * e, s1 = sMax - 0.016 * pow(e, 2.4)
            let s = s0 + u * (s1 - s0)
            let w = (0.044 + 0.036 * smoothstep(0, 0.75, u)) * widen
            let off = 0.0045 + 0.0035 * (1 - e * e) + lift
            return S.surf(s, (v - 0.5) * w / 0.06, off)
        }
        let inside = V3(0, 0, 0)
        m.add(S.shell(cols: 30, rows: 8, thick: 0.004, centre: inside, material: cloth) { u, v in B(u, v) })
        m.add(S.shell(cols: 30, rows: 8, thick: 0.0016, centre: inside, material: piping) { u, v in B(u, v, widen: 1.07, lift: -0.0022) })

        // Twisted gold cord border and twist marks.
        var border: [V3] = []
        let iu: Float = 0.035, iv: Float = 0.085
        for k in 0...20 { border.append(B(iu + (1 - 2 * iu) * Float(k) / 20, iv, lift: 0.0017)) }
        for k in 1...8 { border.append(B(1 - iu, iv + (1 - 2 * iv) * Float(k) / 8, lift: 0.0017)) }
        for k in 1...20 { border.append(B(1 - iu - (1 - 2 * iu) * Float(k) / 20, 1 - iv, lift: 0.0017)) }
        for k in 1..<8 { border.append(B(iu, 1 - iv - (1 - 2 * iv) * Float(k) / 8, lift: 0.0017)) }
        border.append(border[0])
        let bs = catmull(border, per: 3)
        m.add(Prim.tube(bs, radii: bs.map { _ in 0.0017 }, sides: 6, seamTile: 0.01, material: brass, capEnd: false))
        m.add(stitches(along: bs, normal: { p in S.bodyNormal(p) }, pitch: 0.0034, thread: 0.0006, material: brass))

        // Soutache diamond lattice.
        for dir: Float in [0, 1] {
            for k in 0..<7 {
                let u0 = 0.14 + 0.10 * Float(k)
                let ua = dir == 0 ? u0 : u0 + 0.10, ub = dir == 0 ? u0 + 0.10 : u0
                guard ua < 0.88, ub < 0.88 else { continue }
                let pts = (0...4).map { j -> V3 in let t = Float(j) / 4; return B(ua + (ub - ua) * t, 0.24 + 0.52 * t, lift: 0.0011) }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.00095 }, sides: 4, seamTile: 0.01, material: brass, capEnd: false))
            }
        }

        // Rank stars.
        func starOutline(_ r1: Float, _ r2: Float) -> [V2] {
            (0..<10).map { i -> V2 in let a = Float.pi / 2 + Float.pi * Float(i) / 5; let r = i % 2 == 0 ? r1 : r2; return V2(cos(a) * r, sin(a) * r) }
        }
        for u: Float in [0.56, 0.78] {
            let p = B(u, 0.5, lift: 0.0006)
            let t = simd_normalize(B(u + 0.01, 0.5) - B(u - 0.01, 0.5))
            let n = simd_normalize(S.bodyNormal(p))
            let yy = simd_cross(n, t)
            m.add(Prim.extrude(starOutline(0.0108, 0.0046), depth: 0.0018, bevel: 0.0005, bevelSegments: 1, material: u < 0.6 ? gold : "metal.nickel-worn"),
                  Xform(translation: p + n * 0.0009, rotation: ChestKit.basis(t, yy)))
        }

        // Neck-end button: domed gold with a milled rim and a shank.
        let bp = B(0.07, 0.5, lift: 0.0006)
        let bn = simd_normalize(S.bodyNormal(bp))
        let button = Prim.lathe([V2(0, 0), V2(0.0092, 0), V2(0.0095, 0.0012), V2(0.0082, 0.0022), V2(0.0078, 0.0028), V2(0.0066, 0.0037),
                                 V2(0.0042, 0.0052), V2(0.0, 0.0058)], segments: 28, seamTile: 0.05, material: gold)
        m.add(button, Xform(translation: bp, rotation: facing(bn)))
        let rim = (0..<28).map { k -> V3 in let a = 2 * Float.pi * Float(k) / 28; return V3(cos(a) * 0.0088, 0.0014, sin(a) * 0.0088) }
        m.add(Prim.sweep(Shape2D.circle(0.0009, segments: 5), along: rim, up: V3(0, 1, 0), closedPath: true, caps: false, material: brass),
              Xform(translation: bp, rotation: facing(bn)))

        // Heading bar at the outer end and the bullion fringe.
        let head = (0...16).map { k -> V3 in B(1.0, 0.04 + 0.92 * Float(k) / 16, lift: -0.001) }
        let hp = head.map { $0 + V3(0.0035, -0.0012, 0) }
        m.add(Prim.tube(hp, radii: hp.map { _ in 0.0052 }, sides: 9, seamTile: 0.01, material: brass))
        m.add(stitches(along: hp, normal: { _ in simd_normalize(V3(1, 0.5, 0)) }, pitch: 0.0034, thread: 0.0007, material: brass))
        let cords = 36
        for k in 0..<cords {
            let v = 0.05 + 0.90 * (Float(k) + 0.5) / Float(cords)
            let base = B(1.0, v, lift: -0.0015) + V3(0.0045, -0.003, 0)
            let len = 0.056 + rng.float(-0.008...0.006)
                        let sway = rng.float(-0.003...0.003) + (k % 9 == 4 ? 0.012 : 0)
            let n = 12
            var pts: [V3] = [], rad: [Float] = []
            for j in 0..<n {
                let t = Float(j) / Float(n - 1)
                pts.append(base + V3(0.006 * sin(t * 1.6) + sway * t * t, -len * t, (v - 0.5) * 0.014 * t))
                rad.append(0.0027 * (j % 2 == 0 ? 1 : 0.8) * (1 - 0.16 * t))
            }
            m.add(Prim.tube(pts, radii: rad, sides: 5, seamTile: 0.01, material: k % 2 == 1 ? brass : gold))
        }
        // Loose threads where a few bullion strands have come unwound.
        for k in 0..<6 {
            let v = 0.2 + 0.12 * Float(k)
            let base = B(1.0, v, lift: -0.0015) + V3(0.0045, -0.05, 0)
            m.add(stitches(along: [base, base + V3(0.006, -0.012, (Float(k) - 2.5) * 0.004)], normal: { _ in V3(0, 0, 1) }, pitch: 0.02, thread: 0.0005, material: brass))
        }
        return LODModel(m)
    }
}
