import simd
import Foundation

/// Rice bag, 190 x 320 x 70 mm: woven polypropylene sack with pillow body, flattened top folded over a hem and stitched twice, raised printed panels, wrinkles, scuffed corner and a few grains spilled at the base.
public struct RiceBag: RealAsset {
    public static let id = "rice-bag"
    public static let summary = "Woven polypropylene rice bag with a stitched folded top seam, pillow body folds, label patch and one scuffed corner."
    public static let tags = ["prop", "interior", "pantry", "fabric", "paper"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Bag width, height and depth at the base (m).
    public var bagWidth: Float = 0.19
    public var bagHeight: Float = 0.32
    public var bagDepth: Float = 0.068
    /// Woven body and printed colors (sRGB hex).
    public var weave: UInt32 = 0xEDE7D6
    public var printColor: UInt32 = 0x2E7D4F
    public var accent: UInt32 = 0xC8302A
    /// Grains spilled beside the base.
    public var grains = 26
    public init() {}

    func depth(_ y: Float) -> Float {
        let t = DD1JKit.sm((y - 0.52 * bagHeight) / (0.46 * bagHeight))
        let bulge = 1 + 0.10 * sin(min(1, y / (0.6 * bagHeight)) * .pi / 2)
        return max(0.007, bagDepth * bulge * (1 - t) + 0.007 * t)
    }
    func width(_ y: Float) -> Float { bagWidth * (1 + 0.025 * sin(min(1, y / bagHeight) * .pi) - 0.05 * DD1JKit.sm((y - 0.75 * bagHeight) / (0.25 * bagHeight))) }
    func expo(_ y: Float) -> Float { 5 + 6 * DD1JKit.sm((y - 0.5 * bagHeight) / (0.4 * bagHeight)) }

    /// Wrinkle height at (x, y): folds running from the corners, stronger low on the bag.
    func wrinkle(_ x: Float, _ y: Float, seed: UInt32) -> Float {
        let n = Noise.ridged(V3(x * 34, y * 20, 0.3), octaves: 3, seed: seed) - 0.45
        let diag = 0.0006 * sin((x * 0.8 + y) * 95 + Noise.perlin(V3(x * 12, y * 9, 1), seed: seed) * 4)
        return (0.0014 * n + diag) * DD1JKit.sm(y / 0.03) * (1 - 0.6 * DD1JKit.sm((y - 0.8 * bagHeight) / (0.2 * bagHeight)))
    }
    func frontZ(_ x: Float, _ y: Float, sd: UInt32) -> Float {
        let a = width(y) / 2, e = expo(y)
        let k = max(0, 1 - pow(min(1, abs(x) / a), e))
        return depth(y) / 2 * pow(k, 1 / e) + wrinkle(x, y, seed: sd)
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...9999))
        let H = bagHeight
        var m = Model(name: Self.id)
        let rows = detail ? 44 : 10, pn = detail ? 64 : 24
        let rings: [[V3]] = (0...rows).map { i in
            let y = H * Float(i) / Float(rows)
            let inset: Float = i == 0 ? 0.004 : 0
            return Prim.ring(Shape2D.superellipse(width(y) - inset, depth(y) - inset, exponent: expo(y), segments: pn), y: y)
        }
        var s = Prim.loft(rings, capStart: true, capEnd: true, material: DD1JKit.tint("fabric.canvas", weave))
        if detail { s.displace { p, n in abs(n.z) > 0.3 ? wrinkle(p.x, p.y, seed: sd) * abs(n.z) : 0 } }
        m.add(s)
        func patch(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ col: UInt32, off: Float = 0.0008, back: Bool = false) {
            let sgn: Float = back ? -1 : 1
            m.add(DD1JKit.grid(u0: x0, u1: x1, v0: y0, v1: y1, cols: detail ? 6 : 1, rows: detail ? 6 : 1, material: DD1JKit.tint("fabric.canvas", col),
                               pos: { u, v in V3(u * sgn, v, sgn * (frontZ(u, v, sd: detail ? sd : 0) * (detail ? 1 : 1) + off)) }, normal: { _, _ in V3(0, 0, sgn) }))
        }
        let w = bagWidth
        // Front print: green top band, cream oval label with title bars, red accent stripe, grain relief.
        patch(-w * 0.44, w * 0.44, H * 0.78, H * 0.90, printColor)
        for k in 0..<3 { patch(-w * 0.34 + Float(k) * 0.006, w * 0.34 - Float(k) * 0.016, H * 0.865 - Float(k) * 0.009, H * 0.876 - Float(k) * 0.009, 0xFFF3D6, off: 0.0012) }
        patch(-w * 0.34, w * 0.34, H * 0.40, H * 0.72, 0xFBF1D2)
        patch(-w * 0.34, w * 0.34, H * 0.66, H * 0.72, accent, off: 0.0012)
        for k in 0..<2 { patch(-w * 0.26, w * 0.26 - Float(k) * 0.030, H * 0.625 - Float(k) * 0.012, H * 0.633 - Float(k) * 0.012, 0x2A2420, off: 0.0014) }
        patch(-w * 0.44, w * 0.44, H * 0.08, H * 0.13, accent)
        patch(-w * 0.44, w * 0.44, H * 0.135, H * 0.150, printColor, off: 0.0010)
        var gr = rng.fork(9)
        // Mound of rice on the label: flattened dome of grains with a few loose ones around it.
        let mound = Prim.superellipsoid(V3(0.080, 0.036, 0.007), exponent: 2.4, subdivisions: detail ? 3 : 1, material: "food.rice")
        m.add(mound, Xform(translation: V3(0, H * 0.50, frontZ(0, H * 0.50, sd: sd) + 0.0016)))
        let grain = Prim.superellipsoid(V3(0.0100, 0.0030, 0.0030), exponent: 2.2, subdivisions: 1, material: "food.rice")
        for i in 0..<(detail ? 10 : 0) {
            let x = (Float(i) - 4.5) * 0.0105 + gr.float(-0.002...0.002), y = H * 0.435 + gr.float(-0.003...0.003)
            m.add(grain, Xform(translation: V3(x, y, frontZ(x, y, sd: sd) + 0.0014), rotation: simd_quatf(angle: gr.float(-1.2...1.2), axis: V3(0, 0, 1))))
        }
        // Back: barcode panel and recipe text bars.
        patch(-w * 0.34, w * 0.34, H * 0.55, H * 0.75, 0xFBF1D2, back: true)
        for k in 0..<4 { patch(-w * 0.28, w * 0.28 - Float(k % 2) * 0.03, H * 0.72 - Float(k) * 0.018, H * 0.725 - Float(k) * 0.018, 0x2A2420, off: 0.0012, back: true) }
        for k in 0..<(detail ? 16 : 6) { patch(-0.022 + Float(k) * 0.0028, -0.022 + Float(k) * 0.0028 + (k % 3 == 0 ? 0.0016 : 0.0008), H * 0.58, H * 0.63, 0x1C1A18, off: 0.0012, back: true) }
        // Top: hem folded over and stitched twice; thread ends hang loose at one corner.
        let hy = H - 0.017
        m.add(Prim.roundedBox(V3(width(hy) * 0.995, 0.026, depth(hy) + 0.0026), radius: 0.0010, bevelSegments: 2, material: DD1JKit.tint("fabric.canvas", weave ^ 0x0A0A0A)),
              Xform(translation: V3(0, hy - 0.0, 0)))
        m.add(Prim.roundedBox(V3(width(H) * 0.97, 0.0050, 0.0140), radius: 0.0012, bevelSegments: 2, material: DD1JKit.tint("fabric.canvas", weave ^ 0x0A0A0A)),
              Xform(translation: V3(0, H - 0.0030, 0)))
        for (k, yy) in [Float(H - 0.0105), H - 0.0215].enumerated() {
            let zf = depth(hy) / 2 + 0.0013
            let path = stride(from: -width(hy) * 0.46, through: width(hy) * 0.46, by: 0.004).map { V3($0, yy, zf) }
            m.add(stitches(along: path, normal: { _ in V3(0, 0, 1) }, pitch: 0.0045, thread: 0.0006, material: DD1JKit.tint("plastic.matte", 0xB8B2A2)))
            let pb = path.map { V3($0.x, $0.y, -$0.z) }
            m.add(stitches(along: pb, normal: { _ in V3(0, 0, -1) }, pitch: 0.0045, thread: 0.0006, material: DD1JKit.tint("plastic.matte", 0xB8B2A2)))
            _ = k
        }
        for i in 0..<3 {
            m.add(Prim.tube([V3(width(hy) * 0.46, H - 0.0105, depth(hy) / 2 + 0.002), V3(width(hy) * 0.46 + 0.006 + Float(i) * 0.002, H - 0.014 - Float(i) * 0.004, depth(hy) / 2 + 0.003 + Float(i) * 0.001),
                              V3(width(hy) * 0.46 + 0.010 + Float(i) * 0.004, H - 0.026 - Float(i) * 0.006, depth(hy) / 2 + 0.002)],
                             radii: [0.0005, 0.0005, 0.0004], sides: 4, seamTile: 0.01, material: DD1JKit.tint("plastic.matte", 0xB8B2A2)))
        }
        // Scuffed lower corner: grey-brown rubbed patch with a frayed hem.
        patch(w * 0.28, w * 0.46, 0.0, H * 0.10, 0xB7AC93, off: 0.0014)
        patch(-w * 0.46, -w * 0.40, 0.0, H * 0.35, 0xDDD6C2, off: 0.0010)
        // Spilled rice beside the base.
        var sr = rng.fork(21)
        let spill = Prim.superellipsoid(V3(0.0068, 0.0022, 0.0022), exponent: 2.2, subdivisions: 1, material: "food.rice")
        for _ in 0..<(detail ? grains : 8) {
            let a = sr.float(-0.5...1.4), r = 0.006 + 0.020 * sqrt(sr.float())
            let x = w / 2 + 0.006 + r * cos(a) * 0.9, z = 0.008 + r * sin(a) * 0.9
            m.add(spill, Xform(translation: V3(x, 0.0012, z), rotation: simd_quatf(angle: sr.float(0...6.28), axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.02, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
