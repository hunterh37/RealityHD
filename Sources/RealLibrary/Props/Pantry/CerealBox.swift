import simd
import Foundation

/// Cereal box, 200 x 300 x 65 mm: printed carton with a slight liner bulge, tuck flap and slot, side flap seams, raised printed banner, starburst and bowl art as geometry, nutrition table, barcode, glue seam, crushed top corner, rubbed base.
public struct CerealBox: RealAsset {
    public static let id = "cereal-box"
    public static let summary = "Printed cardboard cereal carton with tucked top flaps, side glue seam, raised printed panels and one crushed corner."
    public static let tags = ["prop", "interior", "pantry", "paper", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Carton width, height, depth (m).
    public var size = V3(0.20, 0.30, 0.060)
    /// Printed colors (sRGB hex): box, banner, accent.
    public var boxColor: UInt32 = 0xF2B632
    public var bannerColor: UInt32 = 0xD6282B
    public var accentColor: UInt32 = 0xFFF4D6
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let w = size.x, h = size.y, d = size.z
        let c = DD1JKit.Carton(w: w, h: h, d: d, crush: V3(w / 2 - 0.003, h - 0.003, -d / 2 + 0.003))
        var m = Model(name: Self.id)
        m.add(DD1JKit.cartonBody(c, material: DD1JKit.tint("plastic.matte", boxColor), detail: detail))
        let raw: MaterialKey = DD1JKit.tint("paper.screwbox-kraft", 0xC9A66B)
        func patch(_ face: Int, _ u0: Float, _ u1: Float, _ v0: Float, _ v1: Float, _ col: UInt32, off: Float = 0.0006, mat: String = "plastic.matte") {
            m.add(DD1JKit.facePatch(c, face: face, u0: u0, u1: u1, v0: v0, v1: v1, offset: off, material: DD1JKit.tint(mat, col), detail: detail, cols: 3, rows: 3))
        }
        // Front: red banner with title blocks, starburst, bowl of loops, grime and scuffs along the base.
        patch(0, -w / 2 + 0.006, w / 2 - 0.006, h - 0.088, h - 0.012, bannerColor)
        for i in 0..<6 {
            let x0 = -0.078 + Float(i) * 0.0275
            patch(0, x0, x0 + 0.021, h - 0.066, h - 0.030, 0xFFF4D6, off: 0.0010)
            patch(0, x0 + 0.005, x0 + 0.016, h - 0.058, h - 0.038, bannerColor, off: 0.0014)
        }
        patch(0, -0.090, 0.090, h - 0.0865, h - 0.0805, 0xF7D154, off: 0.0010)
        if detail {
            var pts: [V2] = []
            for i in 0..<16 { let a = Float(i) * .pi / 8, r: Float = i % 2 == 0 ? 0.026 : 0.017; pts.append(V2(cos(a) * r, sin(a) * r)) }
            let star = Prim.extrude(pts, depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0xFFFFFF))
            m.add(star, Xform(translation: V3(-0.062, 0.090, d / 2 + c.shift(V3(-0.062, 0.09, d / 2), V3(0, 0, 1)) + 0.0012)))
            let inner = Prim.extrude(pts.map { $0 * 0.72 }, depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", 0x2E8B3A))
            m.add(inner, Xform(translation: V3(-0.062, 0.090, d / 2 + c.shift(V3(-0.062, 0.09, d / 2), V3(0, 0, 1)) + 0.0018)))
        }
        // Bowl (flattened lathe relief) heaped with cereal loops.
        let bowlZ = d / 2 + 0.0010
        let bowl: [V2] = [V2(0, 0), V2(0.012, 0.0005), V2(0.024, 0.0070), V2(0.034, 0.0220), V2(0.0370, 0.0285), V2(0.0355, 0.0295), V2(0.0330, 0.0275), V2(0, 0.0275)]
        m.add(Prim.lathe(bowl, segments: detail ? 36 : 14, seamTile: 0.1, material: "ceramic.vitreous"),
              Xform(translation: V3(0.0, 0.092, bowlZ), scale: V3(1.55, 1.55, 0.14)))
        m.add(Prim.lathe([V2(0, 0.0262), V2(0.0334, 0.0268), V2(0.0330, 0.0276), V2(0, 0.0276)], segments: detail ? 36 : 14, seamTile: 0.1, material: "food.milk"),
              Xform(translation: V3(0.0, 0.092, bowlZ), scale: V3(1.55, 1.55, 0.14)))
        let loop = Prim.torus(major: 0.0062, minor: 0.0023, segments: detail ? 11 : 8, sides: detail ? 5 : 4, material: "food.bread-crust")
        var lr = rng.fork(3)
        for i in 0..<(detail ? 30 : 10) {
            let t = sqrt(lr.float(0...1)), a = lr.float(0...6.28)
            let x = t * 0.036 * cos(a), y = 0.134 + 0.020 * t * sin(a) * 0.8 - 0.010 * t * t
            m.add(loop, Xform(translation: V3(x, y, bowlZ + 0.0016), rotation: simd_quatf(angle: lr.float(0.3...1.3), axis: V3(1, 0, 0)) * simd_quatf(angle: lr.float(0...3), axis: V3(0, 0, 1))))
        }
        // Lower banner: serving line and small print.
        patch(0, -w / 2 + 0.006, w / 2 - 0.006, 0.010, 0.040, bannerColor)
        for i in 0..<3 { patch(0, -0.070 + Float(i) * 0.050, -0.030 + Float(i) * 0.050, 0.020, 0.030, 0xFFF4D6, off: 0.0010) }
        patch(0, -w / 2 + 0.006, w / 2 - 0.006, 0, 0.005, 0x5A4A32, off: 0.0005)
        for (x, v, wd) in [(Float(-0.082), Float(0.045), Float(0.020)), (0.070, 0.050, 0.014), (0.010, 0.0485, 0.009)] {
            patch(0, x, x + wd, v, v + 0.0035, 0xF6E8C8, off: 0.0010)
        }
        // Back: panel with barcode, nutrition table on the right side.
        patch(1, -0.080, 0.080, h - 0.085, h - 0.015, bannerColor)
        patch(1, -0.060, 0.060, 0.020, 0.075, 0xFFF4D6)
        for k in 0..<(detail ? 22 : 8) { patch(1, -0.020 + Float(k) * 0.0018, -0.020 + Float(k) * 0.0018 + (k % 3 == 0 ? 0.0012 : 0.0006), 0.028, 0.050, 0x1C1A18, off: 0.0010) }
        patch(2, -0.026, 0.026, 0.060, 0.215, 0xFFF4D6)
        for k in 0..<(detail ? 12 : 4) { patch(2, -0.022, 0.022 - (k % 3 == 0 ? 0 : 0.008), 0.200 - Float(k) * 0.0115, 0.2025 - Float(k) * 0.0115, 0x2A2420, off: 0.0010) }
        // Glue flap seam down the back-left edge, with raw cardboard showing.
        patch(1, 0.062, 0.0635, 0.004, h - 0.004, 0x5A4630, off: 0.0009)
        m.add(DD1JKit.facePatch(c, face: 1, u0: 0.0635, u1: 0.0675, v0: 0.004, v1: h - 0.004, offset: 0.0009, material: raw, detail: detail, cols: 1, rows: 6))
        // Top: tuck flap overlapping the back flap, side flap seams, tuck slot on the front face.
        m.add(Prim.roundedBox(V3(w - 0.006, 0.0008, d * 0.52), radius: 0.0003, bevelSegments: 1, material: DD1JKit.tint("plastic.matte", boxColor ^ 0x080808)),
              Xform(translation: V3(0, h + 0.0001, d * 0.22)))
        m.add(Prim.roundedBox(V3(w - 0.006, 0.0006, d * 0.42), radius: 0.0003, bevelSegments: 1, material: raw),
              Xform(translation: V3(0, h - 0.0005, -d * 0.24)))
        for sx in [Float(-1), 1] {
            DD1JKit.line(&m, from: V3(sx * (w / 2 - 0.0035), h + 0.0001, 0), size: V3(0.0009, 0.0006, d - 0.006), material: DD1JKit.tint("plastic.matte", 0x5A4630))
        }
        DD1JKit.line(&m, from: V3(0, h - 0.013, d / 2 + 0.0008), size: V3(0.044, 0.0014, 0.0006), material: DD1JKit.tint("plastic.matte", 0x3A2D1C))
        DD1JKit.line(&m, from: V3(0, h - 0.0145, d / 2 + 0.0008), size: V3(0.050, 0.0006, 0.0006), material: DD1JKit.tint("plastic.matte", 0x7A5E34))
        // Bottom edge: dirty tint and a rubbed corner (scuffed print shows the lighter board).
        patch(0, w / 2 - 0.040, w / 2 - 0.006, 0.0, 0.028, 0xF0DDA8, off: 0.0010)
        patch(2, -d / 2 + 0.004, -d / 2 + 0.020, 0.0, 0.030, 0xEAD6A0, off: 0.0010)
        groundAO(&m, height: 0.02, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
