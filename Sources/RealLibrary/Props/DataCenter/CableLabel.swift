import simd
import Foundation

/// Cable label: white self-laminating wrap label with printed ID text and a clear laminate tail. Parts: white printed panel, clear laminate flap, printed ID text, die-cut corners.
public struct CableLabel: RealAsset {
    public static let id = "cable-label"
    public static let summary = "White self-laminating cable wrap label printed with ID A07-09-PA and a clear laminate tail."
    public static let tags = ["prop"]
    public static let budget = 600
    public static let author = "realityhd"

    /// Overall size in meters (x length, y height, z thickness).
    public var size = V3(0.03, 0.012, 0.001)
    /// Printed ID.
    public var text = "A07-09-PA"
    /// Label stock.
    public var stock: MaterialKey = "plastic.matte:FFFFFF"
    /// Ink.
    public var ink: MaterialKey = "plastic.matte:111214"
    public init() {}

    static let font: [Character: [UInt8]] = [
        "A": [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "P": [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000],
        "0": [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110],
        "7": [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000],
        "9": [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100],
        "-": [0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000],
    ]

    /// Printed text as horizontal pixel runs facing +Z, centered on x = cx, glyph bottom at y0.
    static func decal(_ text: String, cx: Float, y0: Float, z: Float, height h: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let px = h / 7
        let adv = 6 * px
        var gx = cx - (Float(text.count) * adv - px) / 2
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
        let w = size.x, h = size.y, t = size.z
        let tail: Float = 0.0075
        let pw = w - tail
        // Printed panel (left) and clear laminate flap (right), base at y = 0.
        m.add(cuboid(V3(pw, h, t * 0.6), material: stock), Xform(translation: V3(-w / 2 + pw / 2, h / 2, 0)))
        m.add(cuboid(V3(tail, h, t * 0.35), material: "glass.polycarbonate"), Xform(translation: V3(w / 2 - tail / 2, h / 2, 0)))
        // Printed ID, one small warm-white margin line above and below.
        let zf = t * 0.3 + 0.00005
        m.add(Self.decal(text, cx: -w / 2 + pw / 2, y0: (h - 0.0027) / 2, z: zf, height: 0.0027, material: ink))
        // Laminate edge line where the flap meets the panel, and a slight stock shade offset.
        m.add(cuboid(V3(0.0003, h * 0.96, 0.0001), material: "plastic.matte:D9DCE0"), Xform(translation: V3(w / 2 - tail, h / 2, zf)))
        // Story detail: tiny ink smear speck near the lower corner.
        let sx = -w / 2 + 0.002 + Float(rng.next() % 30) / 10000
        m.add(cuboid(V3(0.0012, 0.0004, 0.0001), material: "plastic.matte:5A5D61"), Xform(translation: V3(sx, 0.0008, zf)))
        m.add(cuboid(V3(0.0045, 0.0035, 0.0001), material: "plastic.matte:ECEEF0"), Xform(translation: V3(w / 2 - tail - 0.004, h - 0.003, zf)))
        m.add(cuboid(V3(pw, 0.0004, 0.0001), material: "plastic.matte:E2E4E7"), Xform(translation: V3(-w / 2 + pw / 2, 0.0004, zf)))
        return LODModel(m)
    }
}
