import simd
import Foundation

/// Spaghetti box, 60 x 280 x 40 mm: panel-built carton with a film window over a bundle of strands, printed bands, nutrition table and barcode, glue seam, front top flap hinged open with strands poking out.
public struct PastaBox: RealAsset {
    public static let id = "pasta-box"
    public static let summary = "Tall printed cardboard spaghetti box with a clear window showing dry strands, folded flaps and glue seam."
    public static let tags = ["prop", "interior", "pantry", "paper", "glass"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Carton width, height, depth (m).
    public var size = V3(0.058, 0.2715, 0.038)
    /// Printed colors (sRGB hex): box, band, window frame.
    public var boxColor: UInt32 = 0x1F4E96
    public var bandColor: UInt32 = 0xF2C230
    public var inkColor: UInt32 = 0xFFF8E4
    public var strandCount = 30
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let w = size.x, h = size.y, d = size.z, t: Float = 0.0010
        let c = DD1JKit.Carton(w: w, h: h, d: d, crush: nil, bulge: 0)
        let boxM = DD1JKit.tint("plastic.matte", boxColor)
        let raw: MaterialKey = DD1JKit.tint("paper.screwbox-kraft", 0xC9A66B)
        var m = Model(name: Self.id)
        let wx: Float = 0.0215, wy0: Float = 0.070, wy1: Float = 0.196
        func wall(_ size: V3, _ pos: V3, _ mat: MaterialKey? = nil) {
            m.add(Prim.roundedBox(size, radius: 0.0003, bevelSegments: 1, material: mat ?? boxM), Xform(translation: pos))
        }
        // Panels around the window (no hole in a single skin, so the front is built from four strips).
        wall(V3(w, h, t), V3(0, h / 2, -d / 2 + t / 2))
        wall(V3(t, h, d - 2 * t), V3(-w / 2 + t / 2, h / 2, 0))
        wall(V3(t, h, d - 2 * t), V3(w / 2 - t / 2, h / 2, 0))
        wall(V3(w, h - wy1, t), V3(0, (h + wy1) / 2, d / 2 - t / 2))
        wall(V3(w, wy0, t), V3(0, wy0 / 2, d / 2 - t / 2))
        wall(V3(w / 2 - wx, wy1 - wy0, t), V3(-(w / 2 + wx) / 2, (wy0 + wy1) / 2, d / 2 - t / 2))
        wall(V3(w / 2 - wx, wy1 - wy0, t), V3((w / 2 + wx) / 2, (wy0 + wy1) / 2, d / 2 - t / 2))
        // Window film.
        m.add(Prim.roundedBox(V3(2 * wx + 0.004, wy1 - wy0 + 0.004, 0.0004), radius: 0.0001, bevelSegments: 1, material: "glass.clear"),
              Xform(translation: V3(0, (wy0 + wy1) / 2, d / 2 - t - 0.0003)))
        // Pasta bundle behind the window: rows of strands, one front strand bowed.
        let strand = Prim.cylinder(radius: 0.00105, height: 0.262, bevel: 0.0003, segments: detail ? 7 : 4, bevelSegments: 1, material: "food.pasta-dry")
        let n = detail ? strandCount : 10
        for i in 0..<n {
            let col = i % 10, row = i / 10
            let x = -0.0225 + Float(col) * 0.0050 + rng.float(-0.0008...0.0008)
            let z = d / 2 - t - 0.0026 - Float(row) * 0.0095 + rng.float(-0.0008...0.0008)
            let lean = rng.float(-0.012...0.012)
            m.add(strand, Xform(translation: V3(x, 0.0035, z), rotation: simd_quatf(angle: lean, axis: V3(0, 0, 1)) * simd_quatf(angle: rng.float(-0.01...0.01), axis: V3(1, 0, 0))))
        }
        func patch(_ face: Int, _ u0: Float, _ u1: Float, _ v0: Float, _ v1: Float, _ col: UInt32, off: Float = 0.0006) {
            m.add(DD1JKit.facePatch(c, face: face, u0: u0, u1: u1, v0: v0, v1: v1, offset: off, material: DD1JKit.tint("plastic.matte", col), detail: detail, cols: 1, rows: 1))
        }
        // Front print: top band, title bars, window frame lines, bottom band, small print.
        patch(0, -w / 2 + 0.003, w / 2 - 0.003, h - 0.060, h - 0.012, bandColor)
        for k in 0..<3 { patch(0, -0.021 + Float(k) * 0.002, 0.021 - Float(k) * 0.004, h - 0.026 - Float(k) * 0.011, h - 0.017 - Float(k) * 0.011, boxColor, off: 0.0010) }
        for (u0, u1, v0, v1) in [(-wx - 0.0035, -wx, wy0 - 0.003, wy1 + 0.003), (wx, wx + 0.0035, wy0 - 0.003, wy1 + 0.003),
                                 (-wx - 0.0035, wx + 0.0035, wy1, wy1 + 0.003), (-wx - 0.0035, wx + 0.0035, wy0 - 0.003, wy0)] {
            patch(0, u0, u1, v0, v1, inkColor, off: 0.0008)
        }
        patch(0, -w / 2 + 0.003, w / 2 - 0.003, 0.012, 0.050, bandColor)
        for k in 0..<2 { patch(0, -0.019, 0.019 - Float(k) * 0.007, 0.036 - Float(k) * 0.012, 0.043 - Float(k) * 0.012, boxColor, off: 0.0010) }
        patch(0, -w / 2 + 0.003, w / 2 - 0.003, 0, 0.0045, 0x5A4A32, off: 0.0005)
        patch(0, 0.006, 0.0225, 0.054, 0.0575, inkColor, off: 0.0008)
        // Sides: full-height stripe and nutrition table; back: barcode and glue seam.
        patch(2, -0.012, 0.012, 0.030, h - 0.030, bandColor)
        patch(3, -0.015, 0.015, 0.040, 0.230, inkColor)
        for k in 0..<(detail ? 14 : 5) { patch(3, -0.012, 0.012 - (k % 3 == 0 ? 0 : 0.006), 0.215 - Float(k) * 0.0125, 0.2175 - Float(k) * 0.0125, 0x2A2420, off: 0.0010) }
        patch(1, -0.020, 0.020, 0.030, 0.080, inkColor)
        for k in 0..<(detail ? 14 : 5) { patch(1, -0.012 + Float(k) * 0.0018, -0.012 + Float(k) * 0.0018 + (k % 3 == 0 ? 0.0011 : 0.0006), 0.038, 0.066, 0x1C1A18, off: 0.0010) }
        patch(1, 0.0215, 0.0222, 0.002, h - 0.002, 0x0A2A55, off: 0.0010)
        m.add(DD1JKit.facePatch(c, face: 1, u0: 0.0222, u1: 0.0255, v0: 0.002, v1: h - 0.002, offset: 0.0010, material: raw, detail: false))
        // Top: closed back and side flaps, front flap hinged open with strands poking out; bottom plate seam.
        wall(V3(w - 0.002, 0.0008, d * 0.52), V3(0, h + 0.0001, -d * 0.24), raw)
        wall(V3(w - 0.002, 0.0008, d - 2 * t), V3(0, h - 0.0011, 0), raw)
        let hinge = V3(0, h + 0.0002, d / 2 - 0.0005)
        let flapLen = d * 0.40
        m.add(Prim.roundedBox(V3(w - 0.002, 0.0008, flapLen), radius: 0.0003, bevelSegments: 1, material: boxM),
              Xform(translation: hinge + V3(0, sin(0.32) * flapLen / 2, -cos(0.32) * flapLen / 2), rotation: simd_quatf(angle: 0.32, axis: V3(1, 0, 0))))
        for (i, x) in [Float(-0.012), -0.006, 0.0, 0.007].enumerated() {
            let ext: Float = 0.0015 + 0.0015 * Float(i % 2)
            m.add(Prim.cylinder(radius: 0.00105, height: ext + 0.004, bevel: 0.0003, segments: detail ? 7 : 4, bevelSegments: 1, material: "food.pasta-dry"),
                  Xform(translation: V3(x, h - 0.004, d / 2 - 0.0095), rotation: simd_quatf(angle: Float(i) * 0.05 - 0.07, axis: V3(0, 0, 1))))
        }
        // Crease: a light vertical scuff on the front stripe plus a dented bottom corner mark.
        patch(0, w / 2 - 0.010, w / 2 - 0.0085, 0.080, 0.190, 0xE9E4D8, off: 0.0011)
        patch(2, -d / 2 + 0.003, -d / 2 + 0.014, 0.0, 0.014, 0xDCD3BC, off: 0.0010)
        // Water stain creeping up from the base, a worn-through front corner and a crushed bottom edge.
        patch(0, -w / 2 + 0.003, 0.004, 0.0, 0.016, 0xB9B1A0, off: 0.0011)
        patch(0, -w / 2 + 0.003, -w / 2 + 0.010, 0.004, 0.030, 0xCBC3AE, off: 0.0012)
        patch(3, -0.012, 0.012, 0.0, 0.020, 0xC9C0AA, off: 0.0011)
        patch(1, -0.020, 0.020, h - 0.050, h - 0.012, 0x16396F, off: 0.0010)
        patch(0, w / 2 - 0.016, w / 2 - 0.003, h - 0.018, h - 0.002, 0xE6D7A5, off: 0.0012)
        groundAO(&m, height: 0.02, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
