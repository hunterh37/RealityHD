import simd
import Foundation

/// Aisle sign: ceiling-hung data-center row sign. White matte plastic panel in a thin aluminum frame, two threaded-rod hangers, bold row code and a cold-aisle strip. Parts: panel, frame, hangers, row code, aisle strip.
public struct AisleSign: RealAsset {
    public static let id = "aisle-sign"
    public static let summary = "Ceiling-hung data-center row sign: white plastic panel in an aluminum frame on two threaded-rod hangers, with a bold row code and a blue COLD AISLE strip."
    public static let tags = ["prop"]
    public static let budget = 1500
    public static let author = "realityhd"

    /// Panel size in meters (x width, y height, z depth); hangers add `hangerLength` above.
    public var size = V3(0.6, 0.25, 0.02)
    /// Rod length above the panel top in meters.
    public var hangerLength: Float = 0.3
    /// Row code printed large on the panel.
    public var rowCode = "A07"
    /// Strip caption.
    public var label = "COLD AISLE"
    /// Panel material.
    public var plastic: MaterialKey = "plastic.matte:F2F2F2"
    /// Frame and hanger metal.
    public var metal: MaterialKey = "metal.aluminum"
    /// Strip color.
    public var stripe: MaterialKey = "plastic.matte:1F5FA8"

    public init() {}

    /// 5x7 bitmap glyphs, rows top to bottom, 1 = filled.
    static let font: [Character: [UInt8]] = [
        "A": [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "0": [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110],
        "7": [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000],
        "C": [0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110],
        "O": [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
        "L": [0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111],
        "D": [0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110],
        "I": [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b11111],
        "S": [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110],
        "E": [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111],
        "1": [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
        "2": [0b01110, 0b10001, 0b00001, 0b00110, 0b01000, 0b10000, 0b11111],
        "3": [0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110],
        "4": [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010],
        "5": [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110],
        "6": [0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110],
        "8": [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110],
        "9": [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100],
        "B": [0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110],
        "H": [0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "T": [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100],
    ]

    /// Printed decal: horizontal pixel runs as flat quads facing +Z, centered on x = cx, glyph bottom at y0.
    static func decal(_ text: String, cx: Float, y0: Float, z: Float, height h: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let px = h / 7
        let adv = 6 * px
        let total = Float(text.count) * adv - px
        var gx = cx - total / 2
        for ch in text {
            if let rows = font[ch] {
                for (r, bits) in rows.enumerated() {
                    let y = y0 + Float(6 - r) * px
                    var c = 0
                    while c < 5 {
                        if bits & (1 << UInt8(4 - c)) == 0 { c += 1; continue }
                        var e = c
                        while e < 5 && bits & (1 << UInt8(4 - e)) != 0 { e += 1 }
                        let x0 = gx + Float(c) * px, x1 = gx + Float(e) * px
                        let n = V3(0, 0, 1)
                        let a = s.add(V3(x0, y, z), n, V2(x0, y)), b = s.add(V3(x1, y, z), n, V2(x1, y))
                        let cc = s.add(V3(x1, y + px, z), n, V2(x1, y + px)), d = s.add(V3(x0, y + px, z), n, V2(x0, y + px))
                        s.quad(a, b, cc, d)
                        c = e
                    }
                }
            }
            gx += adv
        }
        s.computeTangents()
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let fw: Float = 0.010          // frame face width
        let pt: Float = 0.012          // panel plate thickness
        // Panel sits with its bottom at y = 0, centered in z.
        func box(_ s: V3, _ c: V3, r: Float, mat: MaterialKey) {
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        m.add(cuboid(V3(w - 2 * fw + 0.004, h - 2 * fw + 0.004, pt), material: plastic), Xform(translation: V3(0, h / 2, 0)))
        // Thin aluminum frame: four bars, full depth, front lip.
        box(V3(w, fw, d), V3(0, fw / 2, 0), r: 0.0015, mat: metal)
        box(V3(w, fw, d), V3(0, h - fw / 2, 0), r: 0.0015, mat: metal)
        for s: Float in [-1, 1] {
            box(V3(fw, h - 2 * fw + 0.002, d), V3(s * (w / 2 - fw / 2), h / 2, 0), r: 0.0015, mat: metal)
        }
        // Hangers: threaded rods from a top-edge eye bolt to a ceiling plate, with nuts.
        let rx = w / 2 - 0.06
        let topY = h + hangerLength
        for s: Float in [-1, 1] {
            let x = s * rx
            m.add(turned([(0, h), (0.0028, h), (0.0028, topY), (0, topY)], segments: 6, material: metal, seamTile: 0.25, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            // Ridges near both ends stand in for the thread.
            for i in 0..<3 {
                let yy = h + 0.02 + Float(i) * 0.006
                m.add(turned([(0, yy), (0.0036, yy), (0.0036, yy + 0.0025), (0, yy + 0.0025)], segments: 6, material: metal), Xform(translation: V3(x, 0, 0)))
            }
            // Nuts above and below the frame cap.
            for ny in [h + 0.0045, h + 0.07] {
                m.add(turned([(0, ny - 0.004), (0.0075, ny - 0.004), (0.0075, ny + 0.004), (0, ny + 0.004)], segments: 6, material: metal), Xform(translation: V3(x, 0, 0)))
            }
            // Ceiling clip plate.
            m.add(cuboid(V3(0.03, 0.003, 0.016), material: metal), Xform(translation: V3(x, topY + 0.0015, 0)))
            // Angle bracket where the rod meets the frame top.
            m.add(cuboid(V3(0.024, 0.0025, 0.014), material: metal), Xform(translation: V3(x, h + 0.0013, 0)))
            m.add(cuboid(V3(0.002, 0.012, 0.014), material: metal), Xform(translation: V3(x + 0.011, h + 0.006, 0)))
            m.add(cuboid(V3(0.002, 0.012, 0.014), material: metal), Xform(translation: V3(x - 0.011, h + 0.006, 0)))
        }
        // Printed decals on the front face.
        let zf = pt / 2 + 0.0004
        let stripH: Float = 0.062
        m.add(cuboid(V3(w - 2 * fw - 0.008, stripH, 0.0008), material: stripe), Xform(translation: V3(0, fw + 0.008 + stripH / 2, zf)))
        m.add(Self.decal(rowCode, cx: 0, y0: fw + stripH + 0.03, z: zf + 0.0005, height: 0.1, material: "plastic.matte:101214"))
        m.add(Self.decal(label, cx: 0, y0: fw + 0.008 + (stripH - 0.034) / 2, z: zf + 0.0006, height: 0.034, material: "plastic.matte:F7F7F7"))
        // Story detail: scuff on the lower corner of the plate.
        let j = Float(rng.next() % 100) / 100
        m.add(cuboid(V3(0.02 + 0.015 * j, 0.0012, 0.0003), material: "plastic.matte:D2D2D0"), Xform(translation: V3(w / 2 - 0.05, h - fw - 0.012, zf + 0.0002)))
        // Printed hairline border inside the plate, a yellowed edge band and a sticker.
        let bx = w / 2 - fw - 0.006
        m.add(cuboid(V3(2 * bx, 0.0014, 0.0005), material: "plastic.matte:101214"), Xform(translation: V3(0, h - fw - 0.006, zf + 0.0001)))
        m.add(cuboid(V3(0.05, 0.026, 0.0004), material: "plastic.matte:E7E3C8"), Xform(translation: V3(-w / 2 + 0.06, h - fw - 0.026, zf + 0.0002)))
        m.add(cuboid(V3(0.036, 0.0012, 0.0005), material: "plastic.matte:5A5C5E"), Xform(translation: V3(-w / 2 + 0.06, h - fw - 0.02, zf + 0.0003)))
        m.add(cuboid(V3(0.036, 0.0012, 0.0005), material: "plastic.matte:5A5C5E"), Xform(translation: V3(-w / 2 + 0.06, h - fw - 0.026, zf + 0.0003)))
        m.add(cuboid(V3(w - 2 * fw - 0.004, 0.003, 0.0004), material: "plastic.matte:DCDAD2"), Xform(translation: V3(0, h - fw - 0.0016, zf + 0.0001)))
        m.add(cuboid(V3(0.012 + 0.01 * j, 0.0012, 0.0003), material: "plastic.matte:C4C4C2"), Xform(translation: V3(-0.11, fw + stripH + 0.02, zf + 0.0002)))
        // Hanging prop: bottom at y = 0, nothing to shift.
        return LODModel(m)
    }
}
