import simd
import Foundation

/// Western trophy belt buckle on a 38 mm tan leather belt: 92 x 66 mm cast nickel oval with a raised rim, a ring of
/// domed studs, a brass centre plate with mirrored scroll engraving and a raised five-point star, rear belt hooks,
/// saddle-stitched belt with a tooled border, punched tail through two keepers and a nickel tip.
public struct WesternBeltBuckle: RealAsset {
    public static let id = "western-belt-buckle"
    public static let summary = "Worn western belt: cast nickel trophy buckle with brass scroll plate and star, tooled tan leather belt."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal", "brass"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 12, elevation: 6, distance: 0.8, ground: false, studio: true)

    /// Belt leather.
    public var leather: MaterialKey = "leather.tan"
    /// Cast buckle body.
    public var nickel: MaterialKey = "metal.nickel-worn"
    /// Centre plate.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias H = HipsKit
        typealias K = ChestKit
        let bw: Float = 0.038, t: Float = 0.0042
        let thread: MaterialKey = "fabric.canvas:E3D5AA"
        let nf: (V3) -> V3 = { H.normal($0) }

        // ---- Belt ring, tooled border grooves ----
        H.band(&m, y: 0, width: bw, thick: t, radius: 0.0016, segments: 1, stitchInset: 0.0036, pitch: 0.0085, thread: thread, material: leather)
        for side: Float in [-1, 1] {
            let pts = (0..<72).map { k -> V3 in H.torso(2 * Float.pi * Float(k) / 72, side * (bw / 2 - 0.0072), t + 0.0001) }
            m.add(Prim.tube(pts + [pts[0]], radii: pts.map { _ in 0.00042 } + [0.00042], sides: 4, seamTile: 0.01, material: "leather.oxblood"))
        }
        // Tail overlapping the belt toward the wearer's left, tapering to a point-rounded end.
        let tA: Float = -0.05, tB: Float = 0.97
        let tailPts = (0...48).map { H.torso(tA + (tB - tA) * Float($0) / 48, 0, t * 1.5 + 0.0003) }
        let tailF = K.frames(tailPts, normal: nf)
        m.add(K.ribbon(tailF, width: bw - 0.0008, thick: t, radius: 0.0016, segments: 1,
                       widthScale: { 1 - 0.42 * smoothstep(0.86, 1.0, $0) }, material: "leather.tan"))
        for side: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(tailF, w: side * (bw / 2 - 0.0036), n: t / 2 + 0.0003).dropFirst(10).map { $0 }, normal: nf, pitch: 0.0085, thread: 0.00047, material: thread))
        }
        for th in [Float(0.50), 0.60] {
            let x = H.place(th, 0, t * 2.5 + 0.0004)
            m.add(Prim.cylinder(radius: 0.0022, height: 0.0005, bevel: 0.0002, segments: 20, bevelSegments: 1, material: "leather.oxblood"),
                  Xform(translation: x.translation - nf(x.translation) * 0.0002, rotation: simd_quatf(from: .up, to: nf(x.translation))))
        }
        // Keepers: one fixed on the belt, one sliding over belt and tail.
        H.keeper(&m, th: -0.40, y: 0, beltWidth: bw, beltThick: t, material: leather)
        H.keeper(&m, th: 0.40, y: 0, beltWidth: bw, beltThick: t * 2, material: leather)
        // Nickel tip with a stamped rim.
                let tipS = Prim.extrude(Shape2D.roundedRect(0.044, 0.0265, radius: 0.0100, segments: 6), depth: 0.0054, bevel: 0.0016, bevelSegments: 3, material: nickel)
        m.add(H.wrapped(tipS.transformed(Xform(translation: V3(0, 0, t * 2.5 + 0.0003))), th: 0.83, y: 0, off: 0), Xform(translation: .zero))
        // Stamped border lines and a cast centre rib on the tip.
        let ribPts = (0...10).map { k in V3(-0.012 + 0.030 * Float(k) / 10, 0, t * 2.5 + 0.0003 + 0.0029) }
        m.add(H.wrapped(Prim.tube(ribPts, radii: ribPts.map { _ in 0.0008 }, sides: 6, seamTile: 0.01, material: brass), th: 0.83, y: 0, off: 0))
        for e: Float in [-1, 1] {
            let ep = (0...10).map { k in V3(-0.016 + 0.034 * Float(k) / 10, e * 0.0085, t * 2.5 + 0.0003 + 0.0028) }
            m.add(H.wrapped(Prim.tube(ep, radii: ep.map { _ in 0.00045 }, sides: 4, seamTile: 0.01, material: "metal.cast-iron-seasoned"), th: 0.83, y: 0, off: 0))
        }

        // ---- Buckle, placed on the belt front ----
        let zc = t * 2.5 + 0.0012 + 0.0024
        let bx = Xform(translation: H.torso(0, 0, zc))
        func put(_ s: Surface, z: Float = 0, rot: simd_quatf = .identity, at p: V3 = .zero) { m.add(s, Xform(translation: bx.translation + p + V3(0, 0, z), rotation: rot)) }
        let W: Float = 0.092, Hh: Float = 0.066
        put(Prim.extrude(Shape2D.superellipse(W, Hh, exponent: 2.9, segments: 56), depth: 0.0048, bevel: 0.0014, bevelSegments: 3, material: nickel))
        // Raised rim, rope-like by alternating swell.
        let rimOutline = Shape2D.superellipse(W - 0.0042, Hh - 0.0042, exponent: 2.9, segments: 56).map { V3($0.x, $0.y, 0) }
        put(Prim.sweep(Shape2D.circle(0.00205, ry: 0.0019, segments: 8), along: rimOutline, up: V3(0, 0, 1), closedPath: true, caps: false, material: nickel), z: 0.0027)
        let inner = Shape2D.superellipse(W - 0.0235, Hh - 0.0235, exponent: 2.9, segments: 56).map { V3($0.x, $0.y, 0) }
        put(Prim.sweep(Shape2D.circle(0.0011, ry: 0.0012, segments: 6), along: inner, up: V3(0, 0, 1), closedPath: true, caps: false, material: nickel), z: 0.0029)
        // Brass recessed plate.
        put(Prim.extrude(Shape2D.superellipse(W - 0.0250, Hh - 0.0250, exponent: 2.9, segments: 64), depth: 0.0016, bevel: 0.0005, bevelSegments: 2, material: brass), z: 0.0028)
        // Engraved border line between rim and studs, and a dark inlay ring around the star.
        let engr = Shape2D.superellipse(W - 0.0192, Hh - 0.0192, exponent: 2.9, segments: 56).map { V3($0.x, $0.y, 0) }
        put(Prim.sweep(Shape2D.circle(0.0004, ry: 0.0004, segments: 4), along: engr, up: V3(0, 0, 1), closedPath: true, caps: false, material: "metal.cast-iron-seasoned"), z: 0.0030)
        // Border studs.
        let studPath = Shape2D.superellipse(W - 0.0125, Hh - 0.0125, exponent: 2.9, segments: 140).map { V3($0.x, $0.y, 0.0032) }
        for p in resample(studPath + [studPath[0]], spacing: 0.0118) {
            rivet(&m, at: bx.translation + p, normal: V3(0, 0, 1), radius: 0.0021, segments: 8, material: nickel)
        }
        // Raised star with a ring.
        var star: [V2] = []
        for k in 0..<10 {
            let a = Float.pi / 2 + Float(k) * Float.pi / 5, r: Float = k % 2 == 0 ? 0.0145 : 0.0066
            star.append(V2(cos(a), sin(a)) * r)
        }
        put(Prim.extrude(Shape2D.rounded(star, radius: 0.0007), depth: 0.0022, bevel: 0.0007, bevelSegments: 2, material: nickel), z: 0.0044)
        put(Prim.torus(major: 0.0185, minor: 0.0011, segments: 56, sides: 8, material: nickel), z: 0.0043, rot: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        // Mirrored scroll engraving (raised thin wire in nickel over the brass).
        func spiral(_ c: V2, _ r0: Float, _ turns: Float, _ dir: Float, _ a0: Float) -> [V3] {
            let n = Int(turns * 14)
            return (0...n).map { k -> V3 in
                let f = Float(k) / Float(n), a = a0 + dir * f * turns * 2 * .pi, r = r0 * (1 - 0.86 * f)
                return V3(c.x + cos(a) * r, c.y + sin(a) * r, 0)
            }
        }
        let scrolls: [(V2, Float, Float, Float, Float)] = [
            (V2(0.0245, 0.0098), 0.0092, 1.6, 1, 0.3), (V2(0.0335, -0.0090), 0.0068, 1.5, -1, 2.6),
            (V2(0.0195, -0.0105), 0.0056, 1.3, 1, 3.5), (V2(0.0290, 0.0035), 0.0050, 1.2, -1, 5.6)]
        for (c, r0, turns, dir, a0) in scrolls {
            for sx: Float in [1, -1] {
                let pts = spiral(V2(c.x * sx, c.y), r0, turns, dir * sx, sx > 0 ? a0 : .pi - a0).map { V3($0.x, $0.y, 0.0044) }
                let r = pts.indices.map { 0.00058 * (0.55 + 0.45 * Float(pts.count - $0) / Float(pts.count)) }
                m.add(Prim.tube(pts, radii: r, sides: 5, seamTile: 0.01, material: nickel), Xform(translation: bx.translation))
            }
        }
        // Rear belt hooks and bar.
        let back: Float = -0.0026
        m.add(Prim.tube([V3(-0.030, -0.0185, back), V3(-0.030, 0.0185, back)], radii: [0.0018, 0.0018], sides: 12, seamTile: 0.01, material: nickel), Xform(translation: bx.translation))
        let hook = catmull([V3(0.030, -0.014, back), V3(0.030, 0.0, back - 0.001), V3(0.0305, 0.014, back)], per: 5)
        m.add(Prim.tube(hook, radii: hook.map { _ in 0.0015 }, sides: 8, seamTile: 0.01, material: nickel), Xform(translation: bx.translation))
        return LODModel(m)
    }
}
