import simd
import Foundation

/// Glove design. Raw value is the wire value; do not reorder.
public enum GloveStyle: Int, CaseIterable, Sendable { case classic, twoTone, stripe, laceUp, vintage }

/// Boxing glove, 14 oz competition style, as worn: +Z runs from the wrist toward the knuckles, +Y is the back
/// of the hand, the thumb sits on +X (left hand; `leftHand = false` mirrors it). Red leather with a curled
/// padded fist, a sewn-on thumb, piping and saddle stitching on every panel seam, a creased wrist break, and a
/// cuff with a white velcro strap around a dark lining. The model is lifted so it rests on the table:
/// `restLift(seed:)` is the height of the wrist-frame origin above the floor.
public struct BoxingGlove: RealAsset {
    public static let id = "boxing-glove"
    public static let summary = "14 oz red leather boxing glove: curled padded fist, sewn thumb, piped and stitched seams, white velcro wrist strap."
    public static let tags = ["prop", "sports", "leather"]
    public static let budget = 15000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, distance: 0.8, studio: true)

    /// Leather key (tint with `leather.oxblood:RRGGBB`).
    public var leather: MaterialKey = "leather.oxblood:B80D10"
    /// Piping and thumb-gusset leather.
    public var piping: MaterialKey = "leather.oxblood:8A0A0C"
    /// Strap and cuff band fabric.
    public var strap: MaterialKey = "fabric.webbing:F1F0EC"
    /// Lining inside the cuff.
    public var lining: MaterialKey = "leather.black"
    /// Stitching thread.
    public var thread: MaterialKey = "thread.white"
    /// Glove for the left hand (thumb on +X); false mirrors it for the right hand.
    public var leftHand = true
    /// Scale of the whole glove (1 = 14 oz, about 0.30 m long).
    public var scale: Float = 0.92
    /// Design variant.
    public var style: GloveStyle = .classic
    /// Accent panels, stripes and laces colour.
    public var accent: MaterialKey = "leather.oxblood:F1F0EC"
    public init() {}

    /// One cross-section of the body or thumb loft.
    struct Station { var z: Float, x: Float = 0, y: Float, curl: Float, w: Float, h: Float, p: Float }

    static let body: [Station] = [
        Station(z: -0.128, y: 0, curl: 0, w: 0.090, h: 0.092, p: 2.0),
        Station(z: -0.105, y: 0, curl: 0, w: 0.092, h: 0.094, p: 2.0),
        Station(z: -0.065, y: 0.001, curl: 0, w: 0.097, h: 0.098, p: 2.1),
        Station(z: -0.025, y: 0.005, curl: 3, w: 0.112, h: 0.110, p: 2.3),
        Station(z: 0.015, y: 0.012, curl: 6, w: 0.134, h: 0.126, p: 2.7),
        Station(z: 0.065, y: 0.021, curl: 10, w: 0.148, h: 0.142, p: 3.0),
        Station(z: 0.112, y: 0.024, curl: 24, w: 0.152, h: 0.146, p: 3.1),
        Station(z: 0.150, y: 0.014, curl: 52, w: 0.146, h: 0.136, p: 3.0),
        Station(z: 0.178, y: -0.010, curl: 82, w: 0.132, h: 0.116, p: 2.8),
        Station(z: 0.190, y: -0.038, curl: 108, w: 0.108, h: 0.086, p: 2.5),
        Station(z: 0.184, y: -0.066, curl: 132, w: 0.078, h: 0.056, p: 2.2),
        Station(z: 0.170, y: -0.082, curl: 152, w: 0.040, h: 0.028, p: 2.0),
        Station(z: 0.160, y: -0.086, curl: 160, w: 0.006, h: 0.005, p: 2.0),
    ]

    static let thumb: [Station] = [
        Station(z: 0.000, x: 0.050, y: -0.016, curl: 0, w: 0.040, h: 0.038, p: 2.2),
        Station(z: 0.040, x: 0.058, y: -0.020, curl: 6, w: 0.050, h: 0.048, p: 2.4),
        Station(z: 0.085, x: 0.060, y: -0.022, curl: 18, w: 0.054, h: 0.050, p: 2.5),
        Station(z: 0.122, x: 0.056, y: -0.028, curl: 40, w: 0.048, h: 0.044, p: 2.4),
        Station(z: 0.148, x: 0.048, y: -0.042, curl: 75, w: 0.036, h: 0.034, p: 2.2),
        Station(z: 0.157, x: 0.042, y: -0.054, curl: 100, w: 0.016, h: 0.014, p: 2.0),
    ]

    /// Catmull-Rom between stations, `per` samples per span.
    static func resampled(_ s: [Station], per: Int) -> [Station] {
        func cr(_ a: Float, _ b: Float, _ c: Float, _ d: Float, _ t: Float) -> Float {
            0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t)
        }
        var out: [Station] = []
        for i in 0..<(s.count - 1) {
            let a = s[max(0, i - 1)], b = s[i], c = s[i + 1], d = s[min(s.count - 1, i + 2)]
            for k in 0..<per {
                let t = Float(k) / Float(per)
                out.append(Station(z: cr(a.z, b.z, c.z, d.z, t), x: cr(a.x, b.x, c.x, d.x, t), y: cr(a.y, b.y, c.y, d.y, t),
                                   curl: cr(a.curl, b.curl, c.curl, d.curl, t), w: cr(a.w, b.w, c.w, d.w, t),
                                   h: cr(a.h, b.h, c.h, d.h, t), p: cr(a.p, b.p, c.p, d.p, t)))
            }
        }
        out.append(s[s.count - 1])
        return out
    }

    @inline(__always) static func sgnpow(_ v: Float, _ e: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), e) }

    /// Ring of `n` points for a station; angle 0 = +X side, 90 = back of hand.
    static func ring(_ s: Station, n: Int, grow: Float = 0) -> [V3] {
        let th = s.curl * .pi / 180
        let up = V3(0, cos(th), sin(th))
        let e = 2 / s.p
        return (0..<n).map { k in
            let a = 2 * Float.pi * Float(k) / Float(n)
            let lx = (s.w / 2 + grow) * sgnpow(cos(a), e), ly = (s.h / 2 + grow) * sgnpow(sin(a), e)
            return V3(s.x + lx, s.y, s.z) + up * ly
        }
    }

    /// Point on the body surface at station `i`, ring angle index `k`.
    static func at(_ rings: [[V3]], _ i: Int, _ k: Int) -> V3 { rings[i][k % rings[i].count] }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, lod: 0), model(seed: seed, lod: 1)], switchDistances: [3])
    }

    /// Height of the wrist-frame origin above the resting surface (m).
    public func restLift(seed: UInt64 = 1) -> Float { -rawModel(seed: seed, lod: 0).bounds.min.y }

    func model(seed: UInt64, lod: Int) -> Model {
        var m = rawModel(seed: seed, lod: lod)
        let lift = -m.bounds.min.y
        m = m.transformed(Xform(translation: V3(0, lift, 0)))
        return m
    }

    func rawModel(seed: UInt64, lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = lod == 0 ? 56 : 32, per = lod == 0 ? 5 : 3
        let st = Self.resampled(Self.body, per: per)
        let rings = st.map { Self.ring($0, n: n) }
        let laced = style == .laceUp || style == .vintage
        let pipe = style == .vintage ? accent : piping
        let sides = lod == 0 ? 8 : 5
        func nearest(_ z: Float) -> Int { st.indices.min(by: { abs(st[$0].z - z) < abs(st[$1].z - z) })! }

        // Body: loft skin, then leather feel: wrist-break creases, soft padding sag, piping grooves.
        var body = Prim.loft(rings, capStart: false, capEnd: true, material: leather)
        let creaseSeed = Float(rng.float(0...6.28))
        body.displace { p, _ in
            // Compression creases where the cuff meets the fist, fading in and out.
            let band = smooth(-0.06, -0.015, p.z) * (1 - smooth(0.02, 0.07, p.z))
            let creases = 0.0011 * band * sin(p.z * 330 + 2.2 * sin(p.x * 60 + creaseSeed)) * (0.5 + 0.5 * sin(atan2(p.y, p.x) * 3 + creaseSeed))
            // Seam grooves: back centre line and the knuckle break across the fist.
            let centre = exp(-pow(p.x / 0.0032, 2)) * smooth(0.02, 0.05, p.z) * (1 - smooth(0.13, 0.15, p.z)) * (p.y > 0 ? 1 : 0)
            let knuckle = exp(-pow((p.z - 0.133) / 0.0032, 2)) * (p.y > 0 ? 1 : 0.5)
            // Fine pebble grain.
            let g = 0.00035 * sin(p.x * 900 + p.z * 700) * sin(p.y * 800 - p.x * 500) * sin(p.z * 1100)
            return creases - 0.0016 * (centre + knuckle) + g
        }
        m.add(body)

        // Thumb with its own gusset seam.
        let tst = Self.resampled(Self.thumb, per: per + 1)
        var thumbS = Prim.loft(tst.map { Self.ring($0, n: lod == 0 ? 32 : 20) }, capStart: false, capEnd: true, material: leather)
        thumbS.displace { p, _ in 0.00035 * sin(p.x * 900 + p.z * 700) * sin(p.y * 800) * sin(p.z * 1100) }
        m.add(thumbS)

        // Cuff lining visible through the opening.
        let liningRings = st.prefix(per * 2 + 1).map { Self.ring($0, n: lod == 0 ? 32 : 20, grow: -0.0075) }
        m.add(Prim.loft(Array(liningRings), capStart: false, capEnd: true, material: lining).flipped())
        // Rolled opening edge: a piping torus around the cuff mouth.
        m.add(Prim.loft([Self.ring(st[0], n: n, grow: 0.0006), Self.ring(st[0], n: n, grow: -0.0075)].map { r in r }, capStart: false, capEnd: false, material: pipe))

        // Strap: white velcro band wrapped over the cuff with a tab.
        let bandIdx = st.indices.filter { st[$0].z > -0.088 && st[$0].z < -0.046 }
        if !laced, let f = bandIdx.first, let l = bandIdx.last {
            var strapS = Prim.loft((f...l).map { Self.ring(st[$0], n: n, grow: 0.0028) }, capStart: false, capEnd: false, material: strap)
            strapS.displace { p, _ in 0.0003 * sin(p.z * 1400) }
            m.add(strapS)
            // Velcro tab with a hem stitch on top of the band.
            let c = V3(0, st[(f + l) / 2].y + st[(f + l) / 2].h / 2 + 0.0034, st[(f + l) / 2].z)
            m.add(Prim.roundedBox(V3(0.05, 0.003, 0.05), radius: 0.0012, bevelSegments: 2, material: strap), Xform(translation: c))
        }
        // Cuff mouth band in white.
        let mouth = st.indices.filter { st[$0].z < -0.1 }
        if let f = mouth.first, let l = mouth.last, l > f {
            m.add(Prim.loft((f...l).map { Self.ring(st[$0], n: n, grow: 0.0018) }, capStart: false, capEnd: false, material: laced ? accent : strap))
        }

        // Piping along both side seams and the knuckle break, with saddle stitching either side.
        func sideLine(_ k: Int, from z0: Float, to z1: Float) -> [V3] {
            st.indices.filter { st[$0].z >= z0 && st[$0].z <= z1 && st[$0].curl < 100 }.map { rings[$0][k] }
        }
        for k in [0, n / 2] {
            let line = sideLine(k, from: 0.0, to: 0.19)
            guard line.count > 2 else { continue }
            let path = catmull(line, per: 3)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0029 }, sides: 6, seamTile: 0.02, material: pipe, capEnd: false))
            for off: Float in [-0.0075, 0.0075] {
                let side = path.map { p in p + V3(0, 0, off) }
                m.add(stitches(along: side, normal: { _ in V3(k == 0 ? 1 : -1, 0.4, 0) }, pitch: 0.0045, material: thread))
            }
        }
        // Centre back seam and knuckle break stitching (top half of the fist).
        let centre = st.indices.filter { st[$0].z > 0.03 && st[$0].z < 0.14 }.map { rings[$0][n / 4] }
        if centre.count > 2 {
            for off: Float in [-0.0065, 0.0065] {
                m.add(stitches(along: centre.map { $0 + V3(off, 0, 0) }, normal: { _ in V3(0, 1, 0) }, pitch: 0.0045, material: thread))
            }
        }
        if let ki = st.indices.min(by: { abs(st[$0].z - 0.133) < abs(st[$1].z - 0.133) ? true : false }) {
            let arc = (0...(n / 2)).map { rings[ki][$0] }
            for off: Float in [-0.0065, 0.0065] {
                m.add(stitches(along: arc.map { $0 + V3(0, 0, off) }, normal: { p in V3(p.x * 2, p.y - st[ki].y + 0.02, 0) }, pitch: 0.0045, material: thread))
            }
        }
        // Thumb attachment stitching.
        let attach = tst.indices.map { Self.ring(tst[$0], n: 32)[24] }
        m.add(stitches(along: attach, normal: { _ in V3(0.3, -1, 0) }, pitch: 0.0045, material: thread))

        // Maker patch on the back of the fist.
        if style != .vintage {
            let pi = st.indices.min(by: { abs(st[$0].z - 0.06) < abs(st[$1].z - 0.06) })!
            let top = V3(0, st[pi].y + st[pi].h / 2 + 0.0012, st[pi].z)
            m.add(Prim.roundedBox(V3(0.07, 0.0016, 0.026), radius: 0.0007, bevelSegments: 1, material: strap), Xform(translation: top, rotation: simd_quatf(angle: -0.17, axis: V3(1, 0, 0))))
        }

        // Style extras in the accent colour.
        switch style {
        case .classic: break
        case .twoTone:
            // Knuckle-break band and a wide thumb-gusset panel.
            let kj = nearest(0.118)
            let band = catmull((0...(n / 2)).map { Self.ring(st[kj], n: n, grow: 0.0015)[$0] }, per: 2)
            m.add(Prim.tube(band, radii: band.map { _ in 0.006 }, sides: sides, seamTile: 0.02, material: accent, capEnd: false))
            let gus = catmull(tst.indices.map { Self.ring(tst[$0], n: 32, grow: 0.0015)[24] }, per: 2)
            m.add(Prim.tube(gus, radii: gus.map { _ in 0.006 }, sides: sides, seamTile: 0.02, material: accent, capEnd: false))
            let cuffIdx = st.indices.filter { st[$0].z > -0.128 && st[$0].z < -0.1 }
            if let f = cuffIdx.first, let l = cuffIdx.last, l > f {
                m.add(Prim.loft((f...l).map { Self.ring(st[$0], n: n, grow: 0.0032) }, capStart: false, capEnd: false, material: accent))
            }
        case .stripe:
            let zr = st.indices.filter { st[$0].z >= 0.02 && st[$0].z <= 0.15 }
            let cl = zr.map { rings[$0][n / 4] }
            if cl.count > 2 {
                let path = catmull(cl, per: 2)
                m.add(Prim.tube(path, radii: path.map { _ in 0.010 }, sides: sides, seamTile: 0.02, material: accent, capEnd: false))
            }
            for k in [0, n / 2] {
                let line = zr.map { rings[$0][k] }
                guard line.count > 2 else { continue }
                let path = catmull(line, per: 2)
                m.add(Prim.tube(path, radii: path.map { _ in 0.005 }, sides: sides, seamTile: 0.02, material: accent, capEnd: false))
            }
        case .laceUp, .vintage:
            // Cross laces zigzagging across the back of the cuff.
            let levels = 6
            for j in 0..<(levels - 1) {
                let zl = -0.095 + 0.05 * Float(j) / Float(levels - 1)
                let zr = -0.095 + 0.05 * Float(j + 1) / Float(levels - 1)
                let (a, b) = j % 2 == 0 ? (zl, zr) : (zr, zl)
                let pts: [V3] = (0...10).map { t in
                    let f = Float(t) / 10
                    let i = nearest(a + (b - a) * f)
                    return rings[i][n / 4 - 5 + t] + V3(0, 0.0028, 0)
                }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.0022 }, sides: 6, seamTile: 0.02, material: accent, capEnd: false))
            }
        }

        let sc = style == .vintage ? scale * 1.08 : scale
        if sc != 1 { m = m.transformed(Xform(scale: V3(repeating: sc))) }
        if !leftHand {
            var mirrored = Model(name: m.name)
            for var sf in m.surfaces {
                sf.positions = sf.positions.map { V3(-$0.x, $0.y, $0.z) }
                sf.normals = sf.normals.map { V3(-$0.x, $0.y, $0.z) }
                for t in stride(from: 0, to: sf.indices.count, by: 3) { sf.indices.swapAt(t + 1, t + 2) }
                sf.computeTangents()
                mirrored.add(sf)
            }
            m = mirrored
        }
        return m
    }
}

private func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float { let t = min(1, max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t) }
