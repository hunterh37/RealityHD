import simd
import Foundation

/// Metallised potato chip bag 30 cm tall: air-filled pillow body with wrinkles, crimped top and bottom
/// seals, ribbed back fin seam, printed film front and back (brand field, swoosh, chip art, copy, barcode),
/// a smooth outlined wordmark of the invented brand CRUNCHO, and a torn notch at the top right.
public struct PotatoChipBag: RealAsset {
    public static let id = "potato-chip-bag"
    public static let summary = "Metallised potato chip bag, 30 cm: air-filled pillow, crimped seals, back fin, printed film, smooth wordmark."
    public static let tags = ["prop", "interior", "pantry", "plastic", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, studio: true)

    /// Bag width (x), height (y), inflated depth (z) in meters.
    public var size = V3(0.20, 0.30, 0.055)
    /// Brand field color of the printed film.
    public var color: UInt32 = 0xF2B632
    public var brand = "CRUNCHO"
    public var flavor = "SEA SALT"
    /// Wordmark fill and outline.
    public var ink: MaterialKey = "plastic.gloss:C8201E"
    public var outline: MaterialKey = "plastic.gloss:FFFFFF"
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let film = GroceryKit.tint("pkg.film-bag", color)
        let bag = DD1LBag(w: size.x, h: size.y, depth: size.z, topSeal: 0.026, botSeal: 0.026, pillow: true, seed: UInt32(truncatingIfNeeded: seed) &+ 9, material: film)
        m.add(bag.surface(detail: detail, sides: detail ? 56 : 24))
        let cols = detail ? 12 : 8, rows = detail ? 18 : 10
        let (t, asp) = GroceryKit.printTile(film)
        let pw = size.x - 0.012, ph = size.y - 0.052, cy = size.y / 2
        // Printed front and back panels conforming to the pillow; one design per face.
        for back in [false, true] {
            var p = bag.patch(w: pw, h: ph, cy: cy, lift: 0.0005, back: back, cols: cols, rows: rows, material: film)
            for i in p.uvs.indices {
                let q = p.positions[i]
                let u = (q.x / pw + 0.5), v = (q.y - cy) / ph + 0.5
                p.uvs[i] = V2((back ? 1 - u : u) * t, (1 - v) * t * asp)
            }
            p.computeTangents()
            m.add(p)
        }
        // Wordmark: white outline under red fill, conformed to the front; flavor in the logo pill.
        func onFront(_ x0: Float, _ y0: Float, _ lift: Float) -> (Float, Float) -> Float {
            { x, y in
                let wx = x0 + x, wy = y0 + y, z = bag.frontZ(wx, wy)
                return z + lift + bag.wrinkle(V3(wx, wy, z))
            }
        }
        let wy = cy + (0.70 - 0.5) * ph - 0.012
        m.add(GroceryKit.conformedText(brand, height: 0.03, outline, maxWidth: 0.17, weight: 2.1, z: onFront(0, wy, 0.0010)),
              Xform(translation: V3(0, wy, 0)))
        m.add(GroceryKit.conformedText(brand, height: 0.03, ink, maxWidth: 0.17, weight: 1.35, z: onFront(0, wy, 0.0016)),
              Xform(translation: V3(0, wy, 0)))
        let px = (0.70 - 0.5) * pw, py = cy + (0.85 - 0.5) * ph - 0.0045
        m.add(GroceryKit.conformedText(flavor, height: 0.009, outline, maxWidth: 0.075, weight: 1.15, z: onFront(px, py, 0.0011)),
              Xform(translation: V3(px, py, 0)))
        // Back fin seam: crimped strip standing out along the back centre.
        let finLen = size.y - 0.052
        let fin = DD1LPantry.crimp(w: 0.012, h: finLen, thick: 0.0034, period: 0.0045, amp: 0.0006, detail: detail, material: film, shift: { ly in bag.d(size.y / 2 + ly) / 2 + 0.004 })
        m.add(fin, Xform(translation: V3(0, size.y / 2, 0), rotation: DD1LPantry.q(.pi / 2, V3(0, 1, 0))))
        // Story detail: torn corner at the top right with a ragged foil edge and a crease.
        let nx = size.x / 2
        m.add(Prim.extrude([V2(0, 0), V2(0.014, 0.0), V2(0.008, 0.006), V2(0.0, 0.0105)], depth: 0.0016, bevel: 0.0003, bevelSegments: 1, material: "plastic.matte:2A2018"),
              Xform(translation: V3(nx - 0.016, size.y - 0.0118, 0.0014)))
        m.add(DD1LPantry.crimp(w: 0.012, h: 0.003, thick: 0.0026, period: 0.002, amp: 0.0002, detail: false, material: film), Xform(translation: V3(nx - 0.010, size.y - 0.004, 0)))
        _ = rng.float()
        groundAO(&m, height: 0.012, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
