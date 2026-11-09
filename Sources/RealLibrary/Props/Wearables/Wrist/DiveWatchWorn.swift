import simd
import Foundation

/// Stainless dive watch worn on the left wrist: 42 mm case with brushed flanks and drilled lugs, 48 click knurled bezel with a
/// faded aluminium insert and lume pip, domed sapphire crystal, applied lume indices, date window, sword hands, screw-down crown
/// with guards, and a three-piece Oyster style bracelet with end links and a fold-over clasp. Hinge gaps carry grime, the case has a
/// nick at 4 o'clock and the bezel is turned off zero.
public struct DiveWatchWorn: RealAsset {
    public static let id = "dive-watch-worn"
    public static let summary = "Worn stainless dive watch: knurled bezel, domed crystal, applied lume indices, hands, Oyster bracelet and clasp."
    public static let tags = ["prop", "wearable", "worn", "metal", "glass", "watch"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 24, distance: 1.0, ground: false, studio: true)

    /// Brushed case and bracelet metal.
    public var steel: MaterialKey = "metal.stainless"
    /// Polished and knocked metal.
    public var polished: MaterialKey = "metal.nickel-worn"
    /// Bracelet centre links.
    public var centre: MaterialKey = "metal.nickel-worn"
    /// Bezel insert.
    public var insert: MaterialKey = "metal.anodized-worn"
    /// Lacquer dial.
    public var dial: MaterialKey = "plastic.gloss:07080B"
    /// Lume paint.
    public var lume: MaterialKey = "plastic.white:E6E0B4"
    /// Dirt in hinge gaps and under the bezel.
    public var grime: MaterialKey = "plastic.grime"
    /// Sapphire crystal.
    public var glass: MaterialKey = "glass.pane"
    /// Height of the watch centre above the wrist joint (m).
    public var lift: Float = 0.016
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var w = Model(name: "watch")
        let Y = V3(0, 1, 0)
        let caseZ: Float = 0.0222
        func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: Y) }
        func hex(_ r: Float, _ y: Float) -> V3 { V3(r, y, 0) }

        // Case middle with brushed flanks, a nick at 4 o'clock and fine scratches.
        var mid = Prim.lathe([V2(0, 0), V2(0.0160, 0), V2(0.0166, 0.0010), V2(0.0196, 0.0014), V2(0.0208, 0.0030), V2(0.0210, 0.0052),
                              V2(0.0210, 0.0090), V2(0.0206, 0.0102), V2(0.0180, 0.0106)], segments: 96, seamTile: 0.05, material: steel)
        let nick = V3(0.0182, 0.0072, 0.0105)
        mid.displace { p, _ in
            0.00018 * Noise.fbm(V3(p.x * 220, p.y * 40, p.z * 220), octaves: 2) - 0.00055 * exp(-simd_length_squared(p - nick) / 0.0000025)
        }
        w.add(mid)
        w.add(Prim.lathe([V2(0.0206, 0.0099), V2(0.0211, 0.0100), V2(0.0211, 0.0102), V2(0.0206, 0.0102)], segments: 72, seamTile: 0.05, material: grime))

        // Knurled unidirectional bezel.
        var bezel = Prim.lathe([V2(0.0172, 0.0098), V2(0.0212, 0.0098), V2(0.0216, 0.0104), V2(0.0216, 0.0120), V2(0.0213, 0.0123),
                                V2(0.0206, 0.0123), V2(0.0206, 0.0121), V2(0.0172, 0.0121)], segments: 144, seamTile: 0.05, material: polished)
        bezel.displace { p, _ in
            let r = hypot(p.x, p.z)
            guard r > 0.0213, p.y < 0.0122, p.y > 0.0100 else { return 0 }
            let th = atan2(p.x, p.z) / (2 * Float.pi) * 48
            let g = abs((th - floor(th)) * 2 - 1)
            return 0.00055 * (g - 0.5) + 0.00012 * Noise.fbm(p * 300, octaves: 2)
        }
        w.add(bezel)
        // Bezel and case wear: hairline scratches across the steel.
        for _ in 0..<14 {
            let a = rng.float(0...(2 * Float.pi))
            w.add(WristKit.box(V3(rng.float(0.0015...0.0035), 0.00004, 0.00010), material: "metal.mirror-polish"),
                  Xform(translation: V3(sin(a) * 0.0200, 0.0121, -cos(a) * 0.0200), rotation: yaw(Float.pi - a + rng.float(-0.9...0.9))))
        }
        let turn: Float = 0.52
        var ins = Prim.lathe([V2(0.0206, 0.01215), V2(0.0203, 0.0125), V2(0.0180, 0.0125), V2(0.0177, 0.01215)], segments: 96, seamTile: 0.03, material: insert)
        ins.displace { p, _ in 0.00008 * Noise.fbm(p * 400, octaves: 2) }
        w.add(ins)
        for k in 0..<60 {
            let a = turn + Float(k) * 2 * Float.pi / 60
            let major = k % 5 == 0
            if k == 0 { continue }
            let len: Float = major ? 0.0030 : 0.0020, wid: Float = major ? 0.0011 : 0.0004
            let rr: Float = 0.0191 + (major ? 0.0002 : 0.0006)
            w.add(WristKit.box(V3(wid, 0.0003, len), material: lume),
                  Xform(translation: V3(sin(a) * rr, 0.0127, -cos(a) * rr), rotation: yaw(Float.pi - a)))
        }
        // Zero pip.
        w.add(Prim.cylinder(radius: 0.0016, height: 0.0004, bevel: 0.0002, segments: 20, bevelSegments: 1, material: lume),
              Xform(translation: V3(sin(turn) * 0.0190, 0.0125, -cos(turn) * 0.0190)))

        // Dial, chapter ring and applied indices.
        w.add(Prim.lathe([V2(0.0170, 0.0080), V2(0.0165, 0.0084), V2(0, 0.0084)], segments: 72, seamTile: 0.03, material: dial))
        w.add(Prim.lathe([V2(0.0173, 0.0086), V2(0.0172, 0.0092), V2(0.0168, 0.0092), V2(0.0166, 0.0088)], segments: 72, seamTile: 0.03, material: polished))
        for k in 0..<12 {
            let a = Float(k) * Float.pi / 6
            if k == 3 { continue }
            let rr: Float = 0.0136
            let q = yaw(Float.pi - a)
            let pos = V3(sin(a) * rr, 0.0089, -cos(a) * rr)
            if k == 0 {
                for s: Float in [-1, 1] {
                    let c = pos + V3(s * 0.0016, 0, 0)
                    w.add(WristKit.chamfer(V3(0.0021, 0.0008, 0.0056), 0.0002, material: polished), Xform(translation: c))
                    w.add(WristKit.box(V3(0.0013, 0.0004, 0.0047), material: lume), Xform(translation: c + V3(0, 0.0005, 0)))
                }
                continue
            }
            let big = k % 3 == 0
            w.add(WristKit.chamfer(V3(big ? 0.0028 : 0.0021, 0.0008, big ? 0.0060 : 0.0050), 0.0002, material: polished),
                  Xform(translation: pos, rotation: q))
            w.add(WristKit.box(V3(big ? 0.0020 : 0.0013, 0.0004, big ? 0.0051 : 0.0041), material: (k == 5 || k == 8) ? "plastic.white:BDA568" : lume),
                  Xform(translation: pos + V3(0, 0.0005, 0), rotation: q))
        }
        // Date window at 3.
        w.add(WristKit.chamfer(V3(0.0062, 0.0007, 0.0050), 0.0002, material: polished), Xform(translation: V3(0.0134, 0.0088, 0)))
        w.add(WristKit.box(V3(0.0050, 0.0004, 0.0040), material: "plastic.white"), Xform(translation: V3(0.0134, 0.0092, 0)))
        w.add(WristKit.box(V3(0.0010, 0.0003, 0.0022), material: "plastic.black"), Xform(translation: V3(0.0128, 0.0094, 0)))
        w.add(WristKit.box(V3(0.0010, 0.0003, 0.0022), material: "plastic.black"), Xform(translation: V3(0.0140, 0.0094, 0)))
        // Printed text bars.
        w.add(WristKit.box(V3(0.0070, 0.0002, 0.0007), material: polished), Xform(translation: V3(0, 0.0086, -0.0066)))
        w.add(WristKit.box(V3(0.0042, 0.0002, 0.0004), material: lume), Xform(translation: V3(0, 0.0086, 0.0058)))
        w.add(WristKit.box(V3(0.0030, 0.0002, 0.0004), material: lume), Xform(translation: V3(0, 0.0086, 0.0066)))

        // Hands, 10:09:36.
        let qx = simd_quatf(angle: -Float.pi / 2, axis: V3(1, 0, 0))
        func hand(_ pts: [V2], _ y: Float, _ ang: Float, lumed: Bool) {
            let x = Xform(translation: V3(0, y, 0), rotation: yaw(-ang) * qx)
            w.add(Prim.extrude(pts, depth: 0.0004, bevel: 0.00012, bevelSegments: 1, material: polished), x)
            if lumed {
                var xl = x; xl.translation.y += 0.0002
                w.add(Prim.extrude(Shape2D.offset(pts, -0.00035), depth: 0.0004, bevel: 0.00005, bevelSegments: 1, material: lume), xl)
            }
        }
        let rad = Float.pi / 180
        hand([V2(-0.0017, -0.0024), V2(0.0017, -0.0024), V2(0.0020, 0.0040), V2(0, 0.0096), V2(-0.0020, 0.0040)], 0.0102, 304.5 * rad, lumed: true)
        hand([V2(-0.0011, -0.0026), V2(0.0011, -0.0026), V2(0.0013, 0.0090), V2(0, 0.0150), V2(-0.0013, 0.0090)], 0.0108, 54 * rad, lumed: true)
        hand([V2(-0.0003, -0.0038), V2(0.0003, -0.0038), V2(0.0003, 0.0160), V2(-0.0003, 0.0160)], 0.0114, 222 * rad, lumed: false)
        w.add(Prim.cylinder(radius: 0.0012, height: 0.0006, bevel: 0.0002, segments: 24, bevelSegments: 1, material: polished), Xform(translation: V3(0, 0.0112, 0)))
        w.add(Prim.cylinder(radius: 0.0010, height: 0.0004, bevel: 0.00015, segments: 20, bevelSegments: 1, material: polished),
              Xform(translation: V3(0, 0.0108, 0)) )

        // Hairline scratches on the crystal.
        for k in 0..<4 {
            w.add(WristKit.box(V3(rng.float(0.0030...0.0060), 0.00004, 0.00010), material: "plastic.white"),
                  Xform(translation: V3(rng.float(-0.004...0.004), 0.01592, rng.float(-0.004...0.004)), rotation: yaw(Float(k) * 0.9 + rng.float(0...0.4))))
        }
        // Domed crystal.
        w.add(Prim.lathe([V2(0.0173, 0.0116), V2(0.0173, 0.0126), V2(0.0160, 0.0141), V2(0.0120, 0.0152), V2(0.0070, 0.0158), V2(0, 0.0160)],
                         segments: 72, seamTile: 0.04, material: glass))

        // Crown, guards and button seat at 3 o'clock.
        var crown = Prim.lathe([V2(0, 0), V2(0.0038, 0), V2(0.0043, 0.0006), V2(0.0043, 0.0044), V2(0.0038, 0.0050), V2(0, 0.0050)], segments: 40, seamTile: 0.02, material: polished)
        crown.displace { p, _ in
            guard hypot(p.x, p.z) > 0.0041, p.y > 0.0008, p.y < 0.0044 else { return 0 }
            let th = atan2(p.x, p.z) / (2 * Float.pi) * 20
            return 0.00035 * (abs((th - floor(th)) * 2 - 1) - 0.5)
        }
        let cq = simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1))
        w.add(crown, Xform(translation: V3(0.0222, 0.0058, 0), rotation: cq))
        w.add(Prim.cylinder(radius: 0.0027, height: 0.0020, bevel: 0.0004, segments: 24, bevelSegments: 1, material: steel),
              Xform(translation: V3(0.0207, 0.0058, 0), rotation: cq))
        for s: Float in [-1, 1] {
            w.add(Prim.roundedBox(V3(0.0046, 0.0074, 0.0030), radius: 0.0010, bevelSegments: 1, material: steel), Xform(translation: V3(0.0216, 0.0058, s * 0.0070)))
        }

        // Lugs with drilled spring-bar holes.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let q = simd_quatf(angle: sz * 0.30, axis: V3(1, 0, 0))
            w.add(Prim.roundedBox(V3(0.0038, 0.0062, 0.0096), radius: 0.0012, bevelSegments: 1, material: steel),
                  Xform(translation: V3(sx * 0.0119, 0.0044, sz * 0.0202), rotation: q))
            w.add(Prim.cylinder(radius: 0.0004, height: 0.0001, bevel: 0.00005, segments: 10, bevelSegments: 1, material: grime),
                  Xform(translation: V3(sx * 0.0100, 0.0026, sz * 0.0236), rotation: simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1))))
        }}

        m.add(w, Xform(translation: V3(0, 0, caseZ), rotation: WristKit.watchRot))

        // Oyster bracelet: end links, centre and outer links, grime under the gaps, fold-over clasp.
        let path = WristKit.strapPath(x0: 0.0240, tipZ: caseZ + 0.0028, y: 0, off: 0.0018, count: 90)
        let cum = WristKit.lengths(path)
        let total = cum.last!
        let n = Int(total / 0.0072)
        let pitch = total / Float(n)
        let fr = WristKit.K.frames(path, normal: { simd_normalize(V3($0.x / (WristKit.a * WristKit.a), 0, $0.z / (WristKit.b * WristKit.b))) })
        m.add(WristKit.K.ribbon(fr, width: 0.0194, thick: 0.0014, radius: 0.0004, segments: 1, material: "metal.stainless"))
        for i in 0..<n {
            let s = (Float(i) + 0.5) * pitch
            let (p, t, nrm) = WristKit.at(path, cum, s)
            let q = WristKit.K.basis(t, nrm)
            let isEnd = i == 0 || i == n - 1
            let len = pitch + 0.0009
            let jig = rng.float(-0.0006...0.0006)
            if isEnd {
                m.add(WristKit.chamfer(V3(len, 0.0030, 0.0198), 0.0008, material: steel), Xform(translation: p, rotation: q))
                continue
            }
            m.add(WristKit.chamfer(V3(len, 0.0040, 0.0090), 0.0010, material: centre), Xform(translation: p + t * jig, rotation: q))
            m.add(WristKit.box(V3(len - 0.0016, 0.0003, 0.0030), material: polished), Xform(translation: p + nrm * 0.0021 + t * jig, rotation: q))
            if i % 3 == 1 {
                m.add(WristKit.box(V3(0.0016, 0.0002, 0.0007), material: "metal.rust-grime"), Xform(translation: p + nrm * 0.0016 + V3(0, 0.0074, 0), rotation: q))
            }
            for sy: Float in [-1, 1] {
                m.add(WristKit.chamfer(V3(len - 0.0004, 0.0038, 0.0054), 0.0010, material: steel),
                      Xform(translation: p + V3(0, sy * 0.0075, 0) - t * jig * 0.5, rotation: q))
            }
        }
        // Hairline scratches across the outer links and clasp.
        for _ in 0..<14 {
            let (p, t, nrm) = WristKit.at(path, cum, rng.float(0.02...(total - 0.02)))
            m.add(WristKit.box(V3(rng.float(0.0020...0.0060), 0.00005, 0.00012), material: "metal.mirror-polish"),
                  Xform(translation: p + nrm * 0.0016 + V3(0, rng.float(-0.0090...0.0090), 0), rotation: WristKit.K.basis(t, nrm) * simd_quatf(angle: rng.float(-0.5...0.5), axis: V3(0, 1, 0))))
        }
        // Wear: pale scratch slivers on the links and polished edge strips on the outer links.
        for _ in 0..<90 {
            let (p, t, nrm) = WristKit.at(path, cum, rng.float(0.02...0.98) * total)
            let q = simd_quatf(angle: rng.float(-0.7...0.7), axis: nrm) * WristKit.K.basis(t, nrm)
            m.add(WristKit.box(V3(rng.float(0.0020...0.0060), 0.00005, 0.00016), material: "metal.mirror-polish"),
                  Xform(translation: p + nrm * 0.0017 + V3(0, rng.float(-0.0085...0.0085), 0), rotation: q))
        }
        for i in 1..<(n - 1) {
            let (p, t, nrm) = WristKit.at(path, cum, (Float(i) + 0.5) * pitch)
            let q = WristKit.K.basis(t, nrm)
            for sy: Float in [-1, 1] {
                m.add(WristKit.box(V3(pitch - 0.0020, 0.0003, 0.0007), material: "metal.mirror-polish"),
                      Xform(translation: p + V3(0, sy * 0.0096, 0) + nrm * 0.0013, rotation: q))
            }
        }
        // Clasp at the back of the wrist.
        let ph = Float.pi
        let cp = WristKit.P(ph, 0, 0.0034)
        let cq2 = WristKit.onSurface(ph)
        m.add(WristKit.chamfer(V3(0.0300, 0.0040, 0.0192), 0.0014, material: steel), Xform(translation: cp, rotation: cq2))
        m.add(WristKit.chamfer(V3(0.0220, 0.0010, 0.0140), 0.0004, material: polished),
              Xform(translation: cp + WristKit.N(ph) * 0.0022, rotation: cq2))
        for s: Float in [-1, 1] {
            m.add(WristKit.box(V3(0.0003, 0.0004, 0.0150), material: grime), Xform(translation: cp + WristKit.N(ph) * 0.0027 + WristKit.T(ph) * (s * 0.0082), rotation: cq2))
        }
        return LODModel(m.transformed(Xform(translation: V3(0, lift, 0))))
    }
}
