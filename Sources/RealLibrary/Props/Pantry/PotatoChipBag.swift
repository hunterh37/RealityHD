import simd
import Foundation

/// Foil potato chip bag 30 cm tall: air-filled pillow body with wrinkles, crimped top and bottom seals,
/// ribbed back fin seam, printed color blocks and chip illustrations as raised patches, and a torn corner.
public struct PotatoChipBag: RealAsset {
    public static let id = "potato-chip-bag"
    public static let summary = "Foil potato chip bag 30 cm tall, pillow shape with crimped top and bottom seals, back fin seam and air-filled bulge."
    public static let tags = ["prop", "interior", "pantry", "plastic", "metal"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, studio: true)

    /// Bag width (x), height (y), inflated depth (z) in meters.
    public var size = V3(0.20, 0.30, 0.055)
    /// Gold foil body.
    public var foil: MaterialKey = "metal.aluminum-brushed:D4A21E"
    /// Red print.
    public var red: MaterialKey = "plastic.gloss:B3261E"
    /// Cream print.
    public var cream: MaterialKey = "plastic.matte:EDEBE4"
    /// Chip color.
    public var chip: MaterialKey = "plastic.matte:E7B84A"
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bag = DD1LBag(w: size.x, h: size.y, depth: size.z, topSeal: 0.026, botSeal: 0.026, pillow: true, seed: UInt32(truncatingIfNeeded: seed) &+ 9, material: foil)
        m.add(bag.surface(detail: detail, sides: detail ? 56 : 24))
        let cols = detail ? 12 : 4, rows = detail ? 8 : 3
        // Red lower field and cream oval label.
        m.add(bag.patch(w: 0.18, h: 0.112, cy: 0.100, lift: 0.0012, cols: cols, rows: rows, material: red))
        m.add(bag.patch(w: 0.150, h: 0.092, cy: 0.178, lift: 0.0006, round: true, cols: cols, rows: rows, material: cream))
        m.add(bag.patch(w: 0.136, h: 0.080, cy: 0.178, lift: 0.0011, round: true, cols: cols, rows: rows, material: red))
        // Chip illustrations: three rippled ovals.
        for (i, (x, y, a, b)) in [(-0.032 as Float, 0.188 as Float, 0.052 as Float, 0.034 as Float), (0.030, 0.176, 0.048, 0.032), (-0.004, 0.156, 0.044, 0.030)].enumerated() {
            m.add(bag.patch(w: a, h: b, cx: x, cy: y, lift: 0.0020 + Float(i) * 0.0006, round: true, ripple: 0.0009, cols: cols, rows: rows, material: chip))
        }
        // Gold band across the red field, cream rules.
        m.add(bag.patch(w: 0.18, h: 0.010, cy: 0.128, lift: 0.0007, cols: cols, rows: 1, material: foil))
        m.add(bag.patch(w: 0.18, h: 0.003, cy: 0.070, lift: 0.0007, cols: cols, rows: 1, material: cream))
        m.add(bag.patch(w: 0.12, h: 0.006, cy: 0.092, lift: 0.0009, cols: cols, rows: 1, material: cream))
        m.add(bag.patch(w: 0.07, h: 0.008, cy: 0.050, lift: 0.0009, cols: cols, rows: 1, material: cream))
        // Back: nutrition panel.
        m.add(bag.patch(w: 0.07, h: 0.09, cx: -0.04, cy: 0.12, lift: 0.0014, back: true, cols: cols, rows: rows, material: cream))
        // Back fin seam: crimped strip standing out along the back centre.
        let finLen = size.y - 0.052
        let fin = DD1LPantry.crimp(w: 0.012, h: finLen, thick: 0.0034, period: 0.0045, amp: 0.0006, detail: detail, material: foil, shift: { ly in bag.d(size.y / 2 + ly) / 2 + 0.004 })
        m.add(fin, Xform(translation: V3(0, size.y / 2, 0), rotation: DD1LPantry.q(.pi / 2, V3(0, 1, 0))))
        // Story detail: torn corner at the top right with a ragged foil edge and a crease.
        let nx = size.x / 2
        m.add(Prim.extrude([V2(0, 0), V2(0.014, 0.0), V2(0.008, 0.006), V2(0.0, 0.0105)], depth: 0.0016, bevel: 0.0003, bevelSegments: 1, material: "plastic.matte:2A2018"),
              Xform(translation: V3(nx - 0.016, size.y - 0.0118, 0.0014)))
        m.add(DD1LPantry.crimp(w: 0.012, h: 0.003, thick: 0.0026, period: 0.002, amp: 0.0002, detail: false, material: foil), Xform(translation: V3(nx - 0.010, size.y - 0.004, 0)))
        _ = rng.float()
        groundAO(&m, height: 0.012, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
