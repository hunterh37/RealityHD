import simd
import Foundation

/// Pint of ice cream, 9.4 x 10 cm: tapered printed paperboard cup with a rolled top lip and a recessed
/// bottom inside a crimped foot, a slip-on lid with a printed top and a rolled rim, a clear tamper band with a
/// pull tab, frost on the lower wall and the invented brand NORTHFIELD.
public struct IceCreamPint: RealAsset {
    public static let id = "ice-cream-pint"
    public static let summary = "Pint of ice cream, 10 cm: tapered printed paperboard cup, slip-on lid with printed top and tamper band."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 1.3, studio: true)

    /// Brand field color of cup and lid.
    public var cup: UInt32 = 0x4A2416
    public var brand = "NORTHFIELD"
    public var flavor = "FUDGE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 64 : 20
        let r0: Float = 0.0412, r1: Float = 0.0452, y0: Float = 0.006, y1: Float = 0.086
        func rAt(_ y: Float) -> Float { r0 + (r1 - r0) * (y - y0) / (y1 - y0) }
        let print = GroceryKit.tint("pkg.paper-label", cup)
        let board = GroceryKit.tint("plastic.matte", GroceryKit.shade(cup, 0.9))
        // Crimped foot and recessed bottom.
        m.add(Prim.lathe([V2(0.0001, 0.0045), V2(0.037, 0.0045), V2(0.0392, 0.0035), V2(0.0398, 0.0005), V2(0.0404, 0),
                          V2(0.0412, 0.0004), V2(r0, y0)], segments: seg, seamTile: 0.05, material: board))
        // Printed wall.
        m.add(GroceryKit.printLathe([V2(r0, y0), V2(rAt(0.046), 0.046), V2(rAt(0.08), 0.08)], seg: seg, print, y0: y0, y1: 0.08))
        // Lid: rolled rim, skirt, printed domed top.
        let lid = GroceryKit.tint("plastic.matte", GroceryKit.shade(cup, 0.85))
        let skirtR: Float = r1 + 0.0016
        m.add(Prim.lathe([V2(skirtR - 0.0004, 0.0745), V2(skirtR + 0.0008, 0.0752), V2(skirtR + 0.0012, 0.0765), V2(skirtR, 0.078),
                          V2(skirtR, 0.0965), V2(skirtR - 0.0006, 0.0985), V2(skirtR - 0.0022, 0.0995), V2(skirtR - 0.004, 0.0985),
                          V2(skirtR - 0.0046, 0.0975)], segments: seg, seamTile: 0.05, material: lid))
        let topR = skirtR - 0.0046
        let lidTop = GroceryKit.tint("pkg.carton-gloss", cup)
        m.add(GroceryKit.sheet(cols: hi ? 16 : 6, rows: hi ? 16 : 6, lidTop, crop: (0.02, 0.14, 0.86, 0.98)) { u, v in
            var a = u * 2 - 1, b = v * 2 - 1
            let ra = a * sqrt(max(0, 1 - b * b / 2)); b = b * sqrt(max(0, 1 - a * a / 2)); a = ra
            let rr = min(1, sqrt(a * a + b * b))
            return V3(a * topR, 0.0975 + 0.0012 * (1 - rr * rr), -b * topR)
        })
        // Clear tamper band over the lid joint, with a pull tab at the front.
        let band = Prim.lathe([V2(rAt(0.072) + 0.0004, 0.072), V2(skirtR + 0.0003, 0.0775), V2(skirtR + 0.0003, 0.083)],
                              segments: seg, seamTile: 0.05, material: "pkg.shrink-film")
        m.add(band)
        GroceryKit.box(&m, V3(0.012, 0.009, 0.0005), simd_quatf(angle: -1.1, axis: .up).act(V3(0.0, 0.0755, skirtR + 0.0014)), "plastic.gloss:D8262B", r: 0.0002,
                       rot: simd_quatf(angle: -1.1, axis: .up) * simd_quatf(angle: 0.12, axis: V3(1, 0, 0)))
        // Wordmarks: brand on the wall pill, big brand and flavor on the lid.
        let pillY = y0 + 0.85 * (0.08 - y0)
        GroceryKit.wrapPrintSmooth(&m, brand, height: 0.0068, radius: rAt(pillY) + 0.0002, y: pillY - 0.0034, "plastic.gloss:F6EFE2",
                                   maxWidth: 0.044, weight: 1.15)
        GroceryKit.wrapPrintSmooth(&m, flavor, height: 0.012, radius: rAt(0.046) + 0.0002, y: 0.04, "plastic.gloss:F2C230",
                                   maxWidth: 0.05, weight: 1.35)
        let up = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
        GroceryKit.printSmooth(&m, brand, height: 0.01, at: V3(0, 0.0989, 0.002), "plastic.gloss:F6EFE2", rot: up, maxWidth: 0.072, weight: 1.25)
        GroceryKit.printSmooth(&m, flavor, height: 0.009, at: V3(0, 0.0988, 0.018), "plastic.gloss:F2C230", rot: up, maxWidth: 0.05, weight: 1.25)
        GroceryKit.printSmooth(&m, "PREMIUM ICE CREAM", height: 0.004, at: V3(0, 0.0988, -0.014), "plastic.gloss:F6EFE2", rot: up, maxWidth: 0.06, weight: 0.9)
        if hi {
            // Frost bloom on the lower wall.
            var rng = SeededRNG(seed: 9031)
            let fleck = Prim.superellipsoid(V3(1, 0.7, 0.3), exponent: 2, subdivisions: 1, material: "plastic.white:E4ECF0")
            var frost = Surface(material: "plastic.white:E4ECF0")
            for _ in 0..<70 {
                let a = rng.float(0...(2 * .pi)), y = y0 + 0.002 + pow(rng.float(0...1), 2) * 0.02, d = rng.float(0.0006...0.0014)
                let rr = rAt(y) + 0.0003
                frost.append(fleck, Xform(translation: V3(rr * sin(a), y, rr * cos(a)), rotation: simd_quatf(angle: a, axis: .up), scale: V3(d, d, d)))
            }
            frost.uvs = frost.positions.map { V2($0.x + $0.z, $0.y) }
            m.add(frost)
        }
        return m
    }
}
