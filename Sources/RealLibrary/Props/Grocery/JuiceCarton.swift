import simd
import Foundation

/// 64 oz gable-top orange juice carton, 9.5 x 26 x 9.5 cm: coated board body printed on all four panels,
/// two gable roof panels, gable ends folded in with a diamond crease, a sealed crimped top fin with a date
/// stamp, and a screw cap with tamper ring on the front slope. Invented brand SOLARA.
public struct JuiceCarton: RealAsset {
    public static let id = "juice-carton"
    public static let summary = "64 oz gable-top juice carton, 26 cm: printed board, folded gable ends, sealed fin, screw cap spout."
    public static let tags = ["prop", "grocery", "food", "paper", "container", "handheld"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.3, studio: true)

    /// Body width/depth (x, z) and body height to the gable fold (y).
    public var size = V3(0.095, 0.195, 0.095)
    /// Gable rise from the fold to the ridge, fin height.
    public var rise: Float = 0.044
    public var fin: Float = 0.02
    /// Brand field color.
    public var color: UInt32 = 0x1E7A3C
    public var brand = "SOLARA"
    public var capKey: MaterialKey = "plastic.gloss:F08A1C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, yb = size.y, ridge = yb + rise
        let print = GroceryKit.tint("pkg.carton-gloss", color)
        let board = GroceryKit.tint("paper.sheet", color)
        GroceryKit.box(&m, V3(size.x, yb, size.z), V3(0, yb / 2, 0), board, r: 0.0028)
        // Printed panels: lower 0.14 m holds the full design, upper band the brand field.
        let lower: Float = 0.14, off: Float = 0.0004, bulge: Float = hi ? 0.0022 : 0
        for k in 0..<4 {
            let rot = simd_quatf(angle: Float(k) * .pi / 2, axis: .up)
            let half = k % 2 == 0 ? hz : hx, w = (k % 2 == 0 ? size.x : size.z) - 0.0056
            let crop: (Float, Float) = k % 2 == 0 ? (0, 1) : (0, 0.5)
            let n = hi ? 6 : 1
            m.add(GroceryKit.sheet(cols: n, rows: n, print, crop: (crop.0, crop.1, 0, 1)) { u, v in
                V3((u - 0.5) * w, 0.002 + v * (lower - 0.002), half + off + bulge * sin(.pi * u) * sin(.pi * (0.1 + 0.9 * v))) },
                Xform(rotation: rot))
            m.add(GroceryKit.sheet(cols: n, rows: n, print, crop: (0.02, 0.12, 0.965, 0.995)) { u, v in
                V3((u - 0.5) * w, lower + v * (yb - lower - 0.0015), half + off + bulge * sin(.pi * u) * sin(.pi * (0.55 + 0.45 * v))) },
                Xform(rotation: rot))
            // Orange keyline over the band joint.
            m.add(GroceryKit.sheet(cols: n, rows: 1, "paper.sheet:F08A1C") { u, v in
                V3((u - 0.5) * w, lower - 0.0016 + v * 0.0032, half + off + 0.0002 + bulge * sin(.pi * u) * 0.75) }, Xform(rotation: rot))
        }
        // Gable roof: front and back slopes from the fold to the ridge, printed with the brand field.
        for s: Float in [1, -1] {
            let roof = GroceryKit.sheet(cols: 1, rows: 1, print, crop: (0.02, 0.12, 0.965, 0.995)) { u, v in
                V3((u - 0.5) * size.x, yb + v * rise, hz * (1 - v)) }
            m.add(s > 0 ? roof : roof.transformed(Xform(rotation: simd_quatf(angle: .pi, axis: .up))))
        }
        // Gable ends folded in: four facets around a diamond crease.
        for s: Float in [1, -1] {
            var e = Surface(material: board)
            let tuck: Float = 0.013
            let f = V3(s * hx, yb, hz), b = V3(s * hx, yb, -hz), apex = V3(s * hx, ridge, 0)
            let c = V3(s * hx, yb, 0), p = V3(s * (hx - tuck), yb + rise * 0.62, 0)
            for (a, bb, cc) in [(f, p, apex), (p, b, apex), (f, c, p), (c, b, p)] {
                var (x, y, z) = (a, bb, cc)
                if simd_cross(y - x, z - x).x * s < 0 { swap(&y, &z) }
                let nrm = simd_normalize(simd_cross(y - x, z - x))
                let i0 = e.add(x, nrm, V2(x.z, x.y)), i1 = e.add(y, nrm, V2(y.z, y.y)), i2 = e.add(z, nrm, V2(z.z, z.y))
                e.tri(i0, i1, i2)
            }
            e.computeTangents()
            m.add(e)
        }
        // Glued manufacturer's lap seam down the back left corner.
        GroceryKit.box(&m, V3(0.012, yb - 0.004, 0.0005), V3(-hx + 0.006, yb / 2, -hz - off - 0.0002), print, r: 0.0002)
        // Sealed fin: crimped double board standing on the ridge, with a printed date stamp.
        let crimp = DD1LPantry.crimp(w: size.x - 0.001, h: fin, thick: 0.0028, period: 0.0032, amp: 0.00025, detail: hi, material: board)
        m.add(crimp, Xform(translation: V3(0, ridge + fin / 2 - 0.001, 0)))
        if hi {
            GroceryKit.printSmooth(&m, "JUN 14 B2", height: 0.0042, at: V3(-0.018, ridge + 0.004, 0.0018), "plastic.matte:1C1C1E", maxWidth: 0.04, weight: 0.9)
        }
        // Screw cap with tamper ring and flange on the front slope.
        let n = simd_normalize(V3(0, hz, rise))
        let base = V3(0, yb + rise * 0.42, hz * 0.58)
        let q = simd_quatf(from: .up, to: n)
        m.add(Prim.lathe([V2(0.0001, 0.0018), V2(0.021, 0.0018), V2(0.0222, 0.0008), V2(0.0215, 0)], segments: hi ? 32 : 12,
                         seamTile: 0.05, material: capKey), Xform(translation: base, rotation: q))
        m.add(GroceryKit.cyl(0.0158, 0.003, seg: hi ? 32 : 12, capKey, bevel: 0.0006), Xform(translation: base + n * 0.0016, rotation: q))
        m.add(GroceryKit.knurledCap(r: 0.0165, h: 0.0125, seg: hi ? 64 : 16, rib: 0.0005, capKey), Xform(translation: base + n * 0.0046, rotation: q))
        // Wordmark across the upper band, product line in the logo pill.
        let fz = hz + off + 0.0003 + bulge * 0.9
        // Condensation beads from the fridge on the front panel.
        if hi {
            var rng = SeededRNG(seed: 4411)
            let bead = Prim.superellipsoid(V3(1, 1.3, 0.5), exponent: 2, subdivisions: 2, material: "plastic.clear")
            var drops = Surface(material: "plastic.clear")
            for _ in 0..<46 {
                let x = rng.float(-0.042...0.042), y = rng.float(0.01...0.12), d = rng.float(0.0016...0.0036)
                let u = x / 0.092 + 0.5, v = (y - 0.002) / 0.138
                drops.append(bead, Xform(translation: V3(x, y, hz + off + bulge * sin(.pi * u) * sin(.pi * (0.1 + 0.9 * v)) + 0.0003), scale: V3(d, d, d)))
            }
            m.add(drops)
        }
        GroceryKit.printSmooth(&m, brand, height: 0.02, at: V3(0, lower + 0.016, fz), "plastic.gloss:FFF8EC", maxWidth: 0.082, weight: 1.3)
        GroceryKit.printSmooth(&m, "ORANGE", height: 0.008, at: V3(0.2 * (size.x - 0.003), 0.85 * lower - 0.004, fz), "plastic.gloss:FFF8EC",
                               maxWidth: 0.036, weight: 1.2)
        return m
    }
}
