import simd
import Foundation

/// Running phone armband on the left forearm: 82 mm neoprene band with reflective stripes and a hook-and-loop overlap on the
/// inside, a padded pouch on the outer side holding a phone behind a stitched window trim (dark glass, bezel, camera pill), and
/// a white earphone cable leaving the pouch top and climbing the arm. Sweat-stained and frayed along the band edges.
public struct PhoneArmband: RealAsset {
    public static let id = "phone-armband"
    public static let summary = "Worn neoprene phone armband: padded pouch with window and phone, reflective stripes, earphone cable."
    public static let tags = ["prop", "wearable", "worn", "fabric", "plastic", "electronics", "sports"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 60, elevation: 8, distance: 0.6, ground: false, studio: true)

    /// Neoprene.
    public var neoprene: MaterialKey = "fabric.nylon:1B1D21"
    /// Band centre height (m).
    public var centreY: Float = -0.10
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias A = ArmKit
        let y = centreY, w: Float = 0.036, t: Float = 0.0035
        let base: Float = 0.0012 + t / 2
        let nf: (V3) -> V3 = { A.nrm($0) }
        let thread: MaterialKey = "fabric.canvas:8A8E96"

        // Two neoprene straps holding the pouch, reflective stripe on each, hook-and-loop closure on the inside.
        for yb in [y - 0.055, y + 0.055] {
            let f = A.K.frames(A.ring(y: yb, off: base, count: 72), normal: nf, closed: true)
            var bandS = A.K.ribbon(f, width: w, thick: t, radius: 0.0014, segments: 1, closed: true, material: neoprene)
            bandS.displace { p, _ in 0.0003 * Noise.fbm(p * 110, octaves: 2) }
            m.add(bandS)
            for s: Float in [-1, 1] {
                var pts = A.K.offset(f, w: s * (w / 2 - 0.0035), n: t / 2 + 0.0003)
                pts.append(pts[0])
                m.add(stitches(along: pts, normal: nf, pitch: 0.0062, thread: 0.0004, material: thread))
            }
            let fs = A.K.frames(A.ring(y: yb, off: base + t / 2 + 0.0006, count: 72), normal: nf, closed: true)
            m.add(A.K.ribbon(fs, width: 0.005, thick: 0.0012, radius: 0.0005, segments: 1, closed: true, material: "plastic.matte:7F848B"))
            let hp = -Float.pi / 2
            let over = (0...14).map { A.P(hp - 0.7 + 1.2 * Float($0) / 14, yb, base + t * 0.5 + 0.0016) }
            let oe = over.last!, tg = A.tangent(hp + 0.5), nn = A.nrm(oe)
            let tail = [oe, oe + tg * 0.008 + nn * 0.0015, oe + tg * 0.016 + nn * 0.0050]
            m.add(A.K.ribbon(A.K.frames(over + Array(tail.dropFirst()), normal: nf), width: w - 0.006, thick: 0.0020, radius: 0.0008, segments: 1, material: "fabric.nylon:34373D"))
        }

        // Pouch: radial bulge over the outer side, flat-topped.
        let hTop: Float = 0.0105, off0: Float = 0.0042, yc: Float = y + 0.005
        func wgt(_ a: Float, _ b: Float) -> Float { pow(max(0, 1 - pow(abs(a), 10)), 0.5) * pow(max(0, 1 - pow(abs(b), 12)), 0.5) }
        func pp(_ a: Float, _ b: Float, _ lift: Float = 0) -> V3 { A.P(Float.pi / 2 + 0.80 * a, yc + 0.084 * b, off0 + hTop * wgt(a, b) + lift) }
        var pouch = ShoulderKit.shell(cols: 20, rows: 24, thick: 0.003, centre: V3(0, yc, 0), material: neoprene) { u, v in pp(2 * u - 1, 2 * v - 1) }
        pouch.displace { p, _ in 0.0003 * Noise.fbm(p * 100, octaves: 2) }
        m.add(pouch)
        func rr(_ a: Float, _ b: Float) -> (Float, Float) { (a * (1 - 0.12 * b * b), b * (1 - 0.12 * a * a)) }
        let bez = ShoulderKit.shell(cols: 12, rows: 18, thick: 0.0008, centre: V3(0, yc, 0), material: "plastic.black") { u, v in
            let (a, b) = rr((2 * u - 1) * 0.80, (2 * v - 1) * 0.86); return pp(a, b, 0.0006)
        }
        m.add(bez)
        let scr = ShoulderKit.shell(cols: 12, rows: 18, thick: 0.0008, centre: V3(0, yc, 0), material: "plastic.gloss:1F3A66") { u, v in
            let (a, b) = rr((2 * u - 1) * 0.74, (2 * v - 1) * 0.82); return pp(a, b, 0.0011)
        }
        m.add(scr)
        // Window trim ribbon and stitching.
        func sq(_ c: Float, _ n: Float) -> Float { (c < 0 ? -1 : 1) * pow(abs(c), 2 / n) }
        let trim = (0..<72).map { k -> V3 in
            let ph = 2 * Float.pi * Float(k) / 72
            return pp(0.90 * sq(cos(ph), 6), 0.92 * sq(sin(ph), 6), 0.0010)
        }
        let tf = A.K.frames(trim, normal: nf, closed: true)
        m.add(A.K.ribbon(tf, width: 0.006, thick: 0.0018, radius: 0.0007, segments: 1, closed: true, material: neoprene))
        var stp = A.K.offset(tf, w: 0, n: 0.0010); stp.append(stp[0])
        m.add(stitches(along: stp, normal: nf, pitch: 0.0040, thread: 0.0004, material: thread))
        // Camera pill.
        let ip = pp(0, 0.70, 0.0012)
        m.add(Prim.tube([V3(0, 0, -0.0055), V3(0, 0, 0.0055)], radii: [0.0028, 0.0028], sides: 12, seamTile: 0.01, material: "plastic.black"),
              Xform(translation: ip, scale: V3(0.22, 1, 1)))
        // Lock screen clock bars.
        for (b, hgt, len) in [(Float(0.30), Float(0.0036), Float(0.034)), (0.18, 0.0012, Float(0.020))] {
            let cp = pp(0, b, 0.0016)
            m.add(Prim.tube([V3(0, 0, -len / 2), V3(0, 0, len / 2)], radii: [hgt, hgt], sides: 8, seamTile: 0.01, material: "plastic.matte:E4E8EE"),
                  Xform(translation: cp, scale: V3(0.2, 1, 1)))
        }
        // Pouch outline stitching.
        let out = (0..<84).map { k -> V3 in
            let ph = 2 * Float.pi * Float(k) / 84
            return pp(0.97 * sq(cos(ph), 8), 0.95 * sq(sin(ph), 8), 0.0003)
        }
        var op = out; op.append(op[0])
        m.add(stitches(along: op, normal: nf, pitch: 0.0056, thread: 0.0004, material: thread))

        // Earphone cable from the pouch top, climbing the arm.
        let cable = (0...20).map { k -> V3 in
            let s = Float(k) / 20
            return A.P(Float.pi / 2 + 0.25 + 0.30 * sin(s * 5), yc + 0.086 + 0.075 * s, 0.0045)
        }
        m.add(Prim.tube(cable, radii: cable.map { _ in 0.0016 }, sides: 6, seamTile: 0.01, material: "plastic.white", capEnd: true))

        // Sweat stains and frayed edges.
        for _ in 0..<12 {
            let p = A.P(rng.float(2.0...5.0), y + (rng.chance(0.5) ? -0.055 : 0.055) + rng.float(-0.008...0.008), base + t / 2 + 0.0002)
            let q = facing(A.nrm(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.026), 0.0007, rng.float(0.008...0.016)), exponent: 2, subdivisions: 2, material: rng.chance(0.5) ? "fabric.nylon:555A62" : "fabric.nylon:2A2D32"),
                  Xform(translation: p - A.nrm(p) * 0.0002, rotation: q))
        }
        for s: Float in [-1, 1] {
            let rim = A.ring(y: y + s * 0.073, off: base, count: 72)
            A.fray(&m, rng: &rng, from: rim, dir: { _ in V3(0, s, 0) }, count: 8, length: 0.003...0.008, radius: 0.00045, material: neoprene)
        }
        return LODModel(m)
    }
}
