import simd
import Foundation

/// Black harness leather chest harness: 25 mm straps (3.6 mm thick) from a nickel O-ring on the sternum over both
/// shoulders to a back ring, a 32 mm under-chest band closed by a roller buckle with punched tail and keeper at the
/// left side, a centre strap with riveted ends, shoulder-strap roller buckles and a row of domed studs. Edges are
/// saddle stitched.
public struct LeatherChestHarness: RealAsset {
    public static let id = "leather-chest-harness"
    public static let summary = "Worn black leather chest harness: sternum O-ring, shoulder straps, riveted band with roller buckle."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 8, distance: 1.1, ground: false, studio: true)

    /// Strap leather.
    public var leather: MaterialKey = "leather.black"
    /// Rings, buckles and studs.
    public var steel: MaterialKey = "metal.nickel-worn"
    /// Worn leather for the tail.
    public var worn: MaterialKey = "leather.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let sw: Float = 0.025, bw: Float = 0.032, t: Float = 0.0036
        let thread: MaterialKey = "fabric.canvas:D7C79C"
        let nf: (V3) -> V3 = { K.bodyNormal($0) }
        let bandY: Float = -0.085
        func P(_ th: Float, _ y: Float, _ off: Float) -> V3 { K.torso(th, y, off) }

        // ---- Under-chest band: closed loop plus overlapping tail, buckle and keeper at the left side ----
        let nb = 112
        let bandPath = (0..<nb).map { P(2 * Float.pi * Float($0) / Float(nb), bandY, t / 2) }
        m.add(K.ribbon(K.frames(bandPath, normal: nf, closed: true), width: bw, thick: t, radius: 0.0014, segments: 1, closed: true, material: leather))
        func bandStitch(_ lo: Float, _ hi: Float, _ pitch: Float) {
            for side: Float in [-1, 1] {
                let pts = (0...80).map { k -> V3 in P(lo + (hi - lo) * Float(k) / 80, bandY + side * (bw / 2 - 0.0034), t + 0.0003) }
                m.add(K.stitch(along: pts, normal: nf, pitch: pitch, thread: 0.00048, material: thread))
            }
        }
        bandStitch(-1.9, 1.9, 0.0062)
        bandStitch(1.9, 2 * Float.pi - 1.9, 0.02)
        let half = Float.pi / 2
        let tA = half - 0.66, tB = half + 0.14
        let tailPath = (0...44).map { P(tA + (tB - tA) * Float($0) / 44, bandY, t * 1.5 + 0.0004) }
        m.add(K.ribbon(K.frames(tailPath, normal: nf), width: bw - 0.001, thick: t, radius: 0.0014, segments: 1,
                       widthScale: { 0.42 + 0.58 * sqrt(smoothstep(0, 0.16, $0)) }, material: worn))
        for side: Float in [-1, 1] {
            let pts = (7...44).map { k -> V3 in P(tA + (tB - tA) * Float(k) / 44, bandY + side * (bw / 2 - 0.0034), t * 2.5 + 0.0007) }
            m.add(K.stitch(along: pts, normal: nf, pitch: 0.0062, thread: 0.00048, material: thread))
        }
        for k in 0..<5 {
            let p = P(tA + 0.22 + Float(k) * 0.075, bandY, t * 2.5 + 0.0005)
            m.add(Prim.cylinder(radius: 0.0021, height: 0.0004, bevel: 0.0002, segments: 24, bevelSegments: 1, material: "leather.black"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: simd_quatf(from: .up, to: nf(p))))
        }
        // Roller buckle behind the tail end, tongue pin through the tail.
        func bandFrame(_ th: Float, _ off: Float) -> K.Frame { K.frames([P(th - 0.01, bandY, off), P(th, bandY, off), P(th + 0.01, bandY, off)], normal: nf)[1] }
        let fb = bandFrame(half + 0.32, t * 0.5)
        let bq = K.basis(fb.t, fb.w)
        m.add(Prim.sweep(Shape2D.circle(0.0016, segments: 12), along: K.loopPath(0.022, bw + 0.005, radius: 0.003), up: V3(0, 0, 1), closedPath: true, caps: false, material: steel),
              Xform(translation: fb.p, rotation: bq))
        m.add(Prim.tube([V3(0, -(bw + 0.005) / 2 + 0.002, 0.0006), V3(0, (bw + 0.005) / 2 - 0.002, 0.0006)], radii: [0.0016, 0.0016], sides: 12, seamTile: 0.01, material: steel),
              Xform(translation: fb.p + fb.t * -0.0003, rotation: bq))
        let pin = catmull([V3(-0.006, 0, 0.0), V3(0.0, 0.0, 0.0022), V3(0.0105, 0, 0.0018)], per: 6)
        m.add(Prim.tube(pin, radii: pin.map { _ in 0.0011 }, sides: 8, seamTile: 0.01, material: steel),
              Xform(translation: fb.p + fb.n * (t * 1.1), rotation: bq))
        let kp = (0...8).map { P(half + 0.045 - 0.04 + 0.08 * Float($0) / 8, bandY, t * 2.5 + 0.0016) }
        m.add(K.ribbon(K.frames(kp, normal: nf), width: bw + 0.0016, thick: 0.002, radius: 0.0008, segments: 1, material: worn))

        // Front studs on the band.
        let studPts = (0...40).map { P(-0.95 + 1.9 * Float($0) / 40, bandY, t + 0.0003) }
        for p in resample(studPts, spacing: 0.036) { rivet(&m, at: p, normal: nf(p), radius: 0.0042, segments: 10, material: steel) }

        // ---- Shoulder straps: (azimuth, height) control points mapped onto the torso ----
        let ctrl: [V3] = [V3(0.10, 0.034, 0), V3(0.30, 0.095, 0), V3(0.72, 0.165, 0), V3(1.20, 0.205, 0), V3(1.57, 0.228, 0),
                          V3(1.95, 0.205, 0), V3(2.40, 0.150, 0), V3(2.80, 0.085, 0), V3(3.0, 0.045, 0)]
        let ctrlPts = catmull(ctrl, per: 6)
        var strapFrames: [[K.Frame]] = []
        for s: Float in [1, -1] {
            let path = ctrlPts.map { P(s * $0.x, $0.y, t / 2) }
            let f = K.frames(path, normal: nf)
            strapFrames.append(f)
            m.add(K.ribbon(f, width: sw, thick: t, radius: 0.0013, segments: 1, material: leather))
            for e: Float in [-1, 1] {
                m.add(K.stitch(along: K.offset(f, w: e * (sw / 2 - 0.0031), n: t / 2 + 0.0003), normal: nf, pitch: 0.0068, thread: 0.00046, material: thread))
            }
        }
        // Roller buckles and keepers on the shoulder straps.
        for (i, f) in strapFrames.enumerated() {
            let fr = f[Int(Float(f.count) * 0.19)]
            let q = K.basis(fr.t, fr.w)
            m.add(Prim.sweep(Shape2D.circle(0.0014, segments: 12), along: K.loopPath(0.019, 0.032, radius: 0.0035), up: V3(0, 0, 1), closedPath: true, caps: false, material: steel),
                  Xform(translation: fr.p + fr.n * (t / 2 + 0.0013), rotation: q))
            m.add(Prim.tube([V3(0, -0.014, 0), V3(0, 0.014, 0)], radii: [0.0014, 0.0014], sides: 10, seamTile: 0.01, material: steel), Xform(translation: fr.p + fr.n * (t / 2 + 0.0013) + fr.t * 0.0004, rotation: q))
            let k2 = f[Int(Float(f.count) * 0.19) + 4]
            let kk = (-2...2).map { j -> V3 in let g = f[Int(Float(f.count) * 0.19) + 4 + j]; return g.p + g.n * (t / 2 + 0.0012) }
            _ = k2; _ = i
            m.add(K.ribbon(K.frames(kk, normal: nf), width: sw + 0.0016, thick: 0.002, radius: 0.0008, segments: 1, material: worn))
        }

        // ---- Sternum O-ring with riveted tab wraps, back ring ----
        let ringFront = V3(0, 0.014, 0.1262)
        m.add(K.ring(0.052, 0.052, wire: 0.0042, radius: 0.026, sides: 14, material: steel), Xform(translation: ringFront))
        let ringBack = V3(0, 0.040, -0.1175)
        m.add(K.ring(0.046, 0.046, wire: 0.0040, radius: 0.023, sides: 14, material: steel), Xform(translation: ringBack))
        // Brass padlock hanging from the back ring.
        let lk = ringBack + V3(0, -0.044, -0.003)
        let lq = simd_quatf(angle: .pi, axis: V3(0, 1, 0))
        m.add(Prim.roundedBox(V3(0.026, 0.022, 0.010), radius: 0.0035, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: lk, rotation: lq))
        m.add(Prim.torus(major: 0.0075, minor: 0.0015, segments: 14, sides: 6, arc: .pi, material: steel), Xform(translation: lk + V3(0, 0.0105, 0), rotation: lq * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0022, height: 0.0006, bevel: 0.0002, segments: 14, material: "metal.nickel-worn"), Xform(translation: lk + V3(0, -0.0015, -0.0049), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        for s: Float in [1, -1] {
            // Folded tab around the front ring with two cap rivets.
            let c = P(s * 0.12, 0.030, t * 1.5)
            for (dy, dx) in [(Float(0), Float(0)), (0.011, 0.002)] {
                rivet(&m, at: c + V3(s * dx, dy, 0.0008), normal: nf(c), radius: 0.0042, segments: 10, material: steel)
            }
            let cb = P(Float.pi - s * 0.12, 0.052, t * 1.5)
            rivet(&m, at: cb, normal: nf(cb), radius: 0.0042, segments: 10, material: steel)
        }
        // Centre strap from the front ring down to the band, riveted both ends.
        let cs = (0...18).map { P(0, -0.012 + (bandY + 0.012) * Float($0) / 18, t * 1.5 + 0.0006) }
        let csF = K.frames(cs, normal: nf)
        m.add(K.ribbon(csF, width: sw, thick: t, radius: 0.0013, segments: 1, material: leather))
        for e: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(csF, w: e * (sw / 2 - 0.0031), n: t / 2 + 0.0003), normal: nf, pitch: 0.0068, thread: 0.00046, material: thread))
        }
        for y in [Float(-0.020), -0.072] {
            let p = P(0, y, t * 2 + 0.0006)
            rivet(&m, at: p + V3(-0.006, 0, 0), normal: nf(p), radius: 0.0042, segments: 10, material: steel)
            rivet(&m, at: p + V3(0.006, 0, 0), normal: nf(p), radius: 0.0042, segments: 10, material: steel)
        }
        return LODModel(m)
    }
}
