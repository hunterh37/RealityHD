import simd
import Foundation

/// Aluminium smartwatch worn on the left wrist: 45 x 38 mm case with rounded corners and chamfers, curved cover glass over a lit
/// display, ceramic back plate, knurled digital crown with ring, side button, speaker slots, and a fluoroelastomer sport band with a
/// tucked tail, hole row, keeper and pin closure. Sweat grime sits in the holes, the case corner is scuffed to bare metal and the
/// glass has hairline scratches.
public struct SmartwatchWorn: RealAsset {
    public static let id = "smartwatch-worn"
    public static let summary = "Worn smartwatch: anodised aluminium case, curved glass and lit display, digital crown, sport band with holes, keeper and pin."
    public static let tags = ["prop", "wearable", "worn", "glass", "rubber", "watch"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 24, distance: 1.0, ground: false, studio: true)

    /// Anodised case.
    public var alu: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Bare aluminium where the anodising is knocked off.
    public var bare: MaterialKey = "metal.aluminum"
    /// Sport band elastomer.
    public var band: MaterialKey = "rubber.silicone:3C5266"
    /// Cover glass.
    public var glass: MaterialKey = "glass.display"
    /// Lit screen.
    public var screen: MaterialKey = "screen.off"
    /// Hole grime.
    public var grime: MaterialKey = "plastic.grime"
    /// Height of the watch centre above the wrist joint (m).
    public var lift: Float = 0.016
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var w = Model(name: "watch")
        let qx = simd_quatf(angle: -Float.pi / 2, axis: V3(1, 0, 0))
        let caseZ: Float = 0.0238
        let ch: Float = 0.0098

        // Case shell. Outline x across, y toward 6 o'clock after the rotation.
        let outline = Shape2D.roundedRect(0.0380, 0.0450, radius: 0.0098, segments: 10)
        var shell = Prim.extrude(outline, depth: ch, bevel: 0.0014, bevelSegments: 3, material: alu)
        shell.displace { p, _ in 0.00012 * Noise.fbm(p * 260, octaves: 2) }
        w.add(shell, Xform(translation: V3(0, ch / 2, 0), rotation: qx))
        // Ceramic back with sensor window.
        w.add(Prim.extrude(Shape2D.roundedRect(0.0336, 0.0408, radius: 0.0086, segments: 8), depth: 0.0016, bevel: 0.0005, bevelSegments: 2, material: "plastic.black"),
              Xform(translation: V3(0, -0.0002, 0), rotation: qx))
        w.add(Prim.cylinder(radius: 0.0124, height: 0.0012, bevel: 0.0004, segments: 40, bevelSegments: 2, material: "glass.pane"), Xform(translation: V3(0, -0.0013, 0)))
        // Cover glass with edge roll-off, black border, lit display.
        w.add(Prim.extrude(Shape2D.roundedRect(0.0366, 0.0436, radius: 0.0091, segments: 10), depth: 0.0013, bevel: 0.0008, bevelSegments: 3, material: glass),
              Xform(translation: V3(0, ch + 0.0003, 0), rotation: qx))
        w.add(Prim.extrude(Shape2D.roundedRect(0.0326, 0.0400, radius: 0.0070, segments: 8), depth: 0.0003, bevel: 0.00008, bevelSegments: 1, material: screen),
              Xform(translation: V3(0, ch + 0.0010, 0), rotation: qx))
        // Always-on analogue face: lit ticks, hands and a complication ring.
        let fy = ch + 0.0014
        for k in 0..<12 {
            let a = Float(k) * Float.pi / 6
            let major = k % 3 == 0
            w.add(WristKit.box(V3(major ? 0.0014 : 0.0007, 0.0002, major ? 0.0042 : 0.0026), material: "emissive.signal-white"),
                  Xform(translation: V3(sin(a) * 0.0148, fy, -cos(a) * 0.0165), rotation: simd_quatf(angle: Float.pi - a, axis: V3(0, 1, 0))))
        }
        w.add(Prim.torus(major: 0.0052, minor: 0.00035, segments: 36, sides: 4, arc: 1.7 * Float.pi, material: "emissive.signal-orange"), Xform(translation: V3(0, fy, 0.0090)))
        func lit(_ len: Float, _ wd: Float, _ ang: Float, _ mat: MaterialKey) {
            let q = simd_quatf(angle: -ang, axis: V3(0, 1, 0))
            w.add(WristKit.box(V3(wd, 0.0003, len), material: mat), Xform(translation: q.act(V3(0, 0, -len / 2 + 0.0008)) + V3(0, fy + 0.0001, 0), rotation: q))
        }
        lit(0.0100, 0.0017, 5.3, "emissive.signal-white")
        lit(0.0150, 0.0012, 1.0, "emissive.signal-white")
        lit(0.0165, 0.0004, 3.9, "emissive.signal-orange")
        w.add(Prim.cylinder(radius: 0.0013, height: 0.0003, bevel: 0.0001, segments: 16, bevelSegments: 1, material: "emissive.signal-white"), Xform(translation: V3(0, fy + 0.0002, 0)))
        // Watch face drawn with light: activity rings, hour ticks, hands and a complication dot.
        let yf = ch + 0.0014
        func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: V3(0, 1, 0)) }
        for (r, arcv, mat) in [(Float(0.0148), Float(5.1), "emissive.signal-red"), (0.0126, 4.0, "emissive.led-green"), (0.0104, 3.2, "emissive.thruster-cyan")] as [(Float, Float, MaterialKey)] {
            w.add(Prim.torus(major: r, minor: 0.00075, segments: 40, sides: 5, arc: arcv, material: mat), Xform(translation: V3(0, yf, 0), rotation: yaw(Float.pi / 2 - arcv)))
        }
        for k in 0..<12 {
            let a = Float(k) * Float.pi / 6
            let big = k % 3 == 0
            w.add(WristKit.box(V3(0.0005, 0.0002, big ? 0.0020 : 0.0010), material: "emissive.bedside-white"),
                  Xform(translation: V3(sin(a) * 0.0156, yf, -cos(a) * 0.0188), rotation: yaw(Float.pi - a)))
        }
        for (len, ang, wd) in [(Float(0.0068), Float(304.5), Float(0.0011)), (0.0102, 54, 0.0008)] {
            let q = yaw(-ang * Float.pi / 180)
            w.add(WristKit.box(V3(wd, 0.0003, len), material: "emissive.bedside-white"),
                  Xform(translation: q.act(V3(0, 0, -len / 2)) + V3(0, yf + 0.0001, 0), rotation: q))
        }
        w.add(Prim.cylinder(radius: 0.0011, height: 0.0003, bevel: 0.0001, segments: 14, bevelSegments: 1, material: "emissive.amber"), Xform(translation: V3(0, yf + 0.0002, 0)))

        // Hairline scratches on the glass (thin pale slivers).
        for k in 0..<4 {
            let a = rng.float(-0.8...0.8)
            let c = V3(rng.float(-0.008...0.008), ch + 0.0017, rng.float(-0.012...0.012))
            w.add(WristKit.box(V3(0.0003, 0.00006, rng.float(0.006...0.011)), material: "plastic.white"),
                  Xform(translation: c, rotation: simd_quatf(angle: a + Float(k) * 0.4, axis: V3(0, 1, 0))))
        }
        // Bare-metal scuffs on the upper-right corner and edge.
        for k in 0..<5 {
            let t = Float(k) / 4
            let ang = -0.2 + t * 0.9
            let c = V3(0.0180 * cos(ang) , 0.0052 + rng.float(-0.0008...0.0008), -0.0205 + 0.012 * t)
            w.add(WristKit.box(V3(0.0006, 0.0001, rng.float(0.0016...0.0034)), material: bare),
                  Xform(translation: V3(0.0192, c.y, c.z), rotation: simd_quatf(angle: rng.float(-0.3...0.3), axis: V3(1, 0, 0))))
        }
        // More anodising chips on the corners and rim, and fine scratches across the glass edge.
        for k in 0..<12 {
            let sx: Float = rng.chance(0.5) ? 1 : -1, sz: Float = rng.chance(0.5) ? 1 : -1
            if k % 2 == 0 {
                w.add(WristKit.box(V3(0.00012, rng.float(0.0006...0.0014), rng.float(0.0008...0.0018)), material: bare),
                      Xform(translation: V3(sx * 0.0190, rng.float(0.0016...0.0080), sz * rng.float(0.004...0.0180))))
            } else {
                w.add(WristKit.box(V3(rng.float(0.0008...0.0018), rng.float(0.0006...0.0014), 0.00012), material: bare),
                      Xform(translation: V3(rng.float(-0.0120...0.0120), rng.float(0.0016...0.0080), sz * 0.0225)))
            }
        }
        // Fine scratches through the anodising on the case walls.
        for _ in 0..<16 {
            let side: Float = rng.chance(0.5) ? 1 : -1
            if rng.chance(0.7) {
                w.add(WristKit.box(V3(0.0002, 0.00010, rng.float(0.0030...0.0090)), material: bare),
                      Xform(translation: V3(side * 0.01904, rng.float(0.0016...0.0082), rng.float(-0.0110...0.0110)), rotation: simd_quatf(angle: rng.float(-0.12...0.12), axis: V3(1, 0, 0))))
            } else {
                w.add(WristKit.box(V3(rng.float(0.0030...0.0070), 0.00010, 0.0002), material: bare),
                      Xform(translation: V3(rng.float(-0.0085...0.0085), rng.float(0.0016...0.0082), side * 0.02254), rotation: simd_quatf(angle: rng.float(-0.12...0.12), axis: V3(0, 0, 1))))
            }
        }
        // Digital crown, ring and button.
        var crown = Prim.lathe([V2(0, 0), V2(0.0046, 0), V2(0.0050, 0.0005), V2(0.0050, 0.0040), V2(0.0046, 0.0045), V2(0, 0.0045)], segments: 48, seamTile: 0.02, material: alu)
        crown.displace { p, _ in
            guard hypot(p.x, p.z) > 0.0047, p.y > 0.0006, p.y < 0.0040 else { return 0 }
            let th = atan2(p.x, p.z) / (2 * Float.pi) * 24
            return 0.00025 * (abs((th - floor(th)) * 2 - 1) - 0.5)
        }
        let cq = simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1))
        w.add(crown, Xform(translation: V3(0.0198, 0.0058, -0.0100), rotation: cq))
        w.add(Prim.torus(major: 0.0049, minor: 0.00045, segments: 40, sides: 6, material: "metal.copper"), Xform(translation: V3(0.0193, 0.0058, -0.0100), rotation: cq))
        w.add(Prim.roundedBox(V3(0.0030, 0.0104, 0.0020), radius: 0.0007, bevelSegments: 2, material: alu), Xform(translation: V3(0.0192, 0.0050, 0.0122)))
        for s: Float in [-1, 1] {
            w.add(Prim.cylinder(radius: 0.00055, height: 0.0002, bevel: 0.0001, segments: 10, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0.0190, 0.0030, s * 0.0044 + 0.0000), rotation: cq))
        }
        for k in 0..<5 {
            w.add(WristKit.box(V3(0.0003, 0.0030, 0.0010), material: "plastic.black"), Xform(translation: V3(-0.0191, 0.0048, Float(k - 2) * 0.0022)))
        }
        // Band connectors.
        for sz: Float in [-1, 1] {
            w.add(Prim.roundedBox(V3(0.0240, 0.0066, 0.0046), radius: 0.0016, bevelSegments: 2, material: alu), Xform(translation: V3(0, 0.0040, sz * 0.0242)))
        }
        m.add(w, Xform(translation: V3(0, 0, caseZ), rotation: WristKit.watchRot))

        // Sport band round the wrist.
        let path = WristKit.strapPath(x0: 0.0262, tipZ: caseZ + 0.0040, y: 0, off: 0.0017, count: 80, spread: 0.0150)
        let cum = WristKit.lengths(path)
        let total = cum.last!
        let en: (V3) -> V3 = { simd_normalize(V3($0.x / (WristKit.a * WristKit.a), 0, $0.z / (WristKit.b * WristKit.b))) }
        let fr = WristKit.K.frames(path, normal: en)
        m.add(WristKit.K.ribbon(fr, width: 0.0222, thick: 0.0034, radius: 0.0013, segments: 2, material: band))
        // Sweat and dust dirt along both band edges.
        let edgeIdx = Array(stride(from: 4, to: fr.count - 4, by: 3))
        for sgn: Float in [-1, 1] {
            let pts = edgeIdx.map { fr[$0].p + fr[$0].w * (sgn * 0.0105) + fr[$0].n * 0.0014 }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.00042 }, sides: 3, seamTile: 0.01, material: grime, capEnd: false))
        }
        // Tucked tail on the outside with a hole row, tip rounded by a narrowing width.
        let tailStart = total - 0.062, tailEnd = total - 0.016
        var tail: [WristKit.K.Frame] = []
        for f in fr {
            let s = cum[tail.count]
            if s >= tailStart && s <= tailEnd { var g = f; g.p += f.n * 0.0033; tail.append(g) } else { tail.append(f); tail.removeLast() }
        }
        let sub = Array(fr.enumerated().filter { cum[$0.offset] >= tailStart && cum[$0.offset] <= tailEnd }.map { e -> WristKit.K.Frame in
            var g = e.element; g.p += g.n * 0.0033; return g })
        m.add(WristKit.K.ribbon(sub, width: 0.0212, thick: 0.0030, radius: 0.0012, segments: 2, widthScale: { 1 - 0.18 * smoothstep(0.85, 1, $0) }, material: band))
        // Hole row.
        for k in 0..<8 {
            let s = tailEnd - 0.004 - Float(k) * 0.0050
            let (p, t, n) = WristKit.at(path, cum, s)
            let q = WristKit.K.basis(t, n)
            let pp = p + n * (0.0033 + 0.0014)
            m.add(Prim.cylinder(radius: 0.0011, height: 0.0004, bevel: 0.0001, segments: 14, bevelSegments: 1, material: grime), Xform(translation: pp, rotation: q))
            m.add(Prim.torus(major: 0.0013, minor: 0.0003, segments: 16, sides: 5, material: band), Xform(translation: pp + n * 0.0003, rotation: q))
        }
        // Band wear: pale scuff marks and dark dirt streaks along the elastomer.
        for k in 0..<60 {
            let (p, t, n) = WristKit.at(path, cum, rng.float(0.03...0.90) * total)
            let q = simd_quatf(angle: rng.float(-0.5...0.5), axis: n) * WristKit.K.basis(t, n)
            let dirt = k % 3 == 0
            m.add(WristKit.box(V3(rng.float(0.0030...0.0090), 0.00006, 0.00040), material: dirt ? grime : "rubber.silicone:8FA6BA"),
                  Xform(translation: p + n * 0.0018 + V3(0, rng.float(-0.0095...0.0095), 0), rotation: q))
        }
        // Keeper loop at the tail start and pin closure disc.
        do {
            let (p, t, n) = WristKit.at(path, cum, tailStart - 0.004)
            let q = WristKit.K.basis(t, n)
            m.add(Prim.roundedBox(V3(0.0072, 0.0100, 0.0234), radius: 0.0030, bevelSegments: 3, material: band), Xform(translation: p + n * 0.0022, rotation: q))
            let (p2, t2, n2) = WristKit.at(path, cum, tailStart - 0.026)
            let q2 = WristKit.K.basis(t2, n2)
            m.add(Prim.cylinder(radius: 0.0042, height: 0.0015, bevel: 0.0005, segments: 24, bevelSegments: 2, material: alu), Xform(translation: p2 + n2 * 0.0017, rotation: q2))
            m.add(Prim.cylinder(radius: 0.0011, height: 0.0020, bevel: 0.0004, segments: 12, bevelSegments: 1, material: "metal.stainless"), Xform(translation: p2 + n2 * 0.0030, rotation: q2))
        }
        return LODModel(m.transformed(Xform(translation: V3(0, lift, 0))))
    }
}
