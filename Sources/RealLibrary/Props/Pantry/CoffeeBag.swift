import simd
import Foundation

/// Foil coffee bag 22 cm tall: gusseted flat-bottom body in brushed foil with wrinkles, crimped top seal
/// with a tin-tie strip, round degassing valve, printed label patches conforming to the front, and a coffee ring stain.
public struct CoffeeBag: RealAsset {
    public static let id = "coffee-bag"
    public static let summary = "Foil coffee bag 22 cm tall with flat bottom gussets, crimped top seal, folded tin tie and degassing valve."
    public static let tags = ["prop", "interior", "pantry", "paper", "metal", "plastic"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 15, studio: true)

    /// Bag width (x), depth (z) and height (y) in meters.
    public var size = V3(0.12, 0.22, 0.065)
    /// Dark roast foil.
    public var foil: MaterialKey = "metal.aluminum-brushed:3A2A22"
    /// Cream label.
    public var label: MaterialKey = "paper.sheet:E9DFC8"
    /// Print ink.
    public var ink: MaterialKey = "paper.sheet:2A1C16"
    /// Gold print.
    public var gold: MaterialKey = "metal.brass-aged"
    /// Valve plastic.
    public var valve: MaterialKey = "plastic.matte:EDEBE4"
    /// Tin tie.
    public var tinTie: MaterialKey = "metal.galvanized-aged"
    public init() {}

    func level(detail: Bool, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let bag = DD1LBag(w: size.x, h: size.y, depth: size.z, topSeal: 0.020, botSeal: 0, pillow: false, seed: UInt32(truncatingIfNeeded: seed) &+ 3, material: foil)
        m.add(bag.surface(detail: detail, sides: detail ? 56 : 24))
        let cols = detail ? 16 : 4, rows = detail ? 12 : 3
        // Label and print.
        m.add(bag.patch(w: 0.078, h: 0.086, cy: 0.092, lift: 0.0014, cols: cols, rows: rows, material: label))
        m.add(bag.patch(w: 0.070, h: 0.0028, cy: 0.1285, lift: 0.0021, cols: cols, rows: 1, material: ink))
        for (k, ww) in [Float(0.052), 0.040, 0.046].enumerated() {
            m.add(bag.patch(w: ww, h: 0.0042, cy: 0.1105 - Float(k) * 0.0085, lift: 0.0021, cols: cols, rows: 1, material: ink))
        }
        m.add(bag.patch(w: 0.030, h: 0.030, cy: 0.066, lift: 0.0021, round: true, cols: cols, rows: rows, material: gold))
        m.add(bag.patch(w: 0.020, h: 0.020, cy: 0.066, lift: 0.0027, round: true, cols: cols, rows: rows, material: ink))
        m.add(bag.patch(w: 0.1135, h: 0.0034, cy: 0.032, lift: 0.0014, cols: cols, rows: 1, material: gold))
        m.add(bag.patch(w: 0.1135, h: 0.0034, cy: 0.0255, lift: 0.0014, cols: cols, rows: 1, material: gold))
        // Back: ingredient panel and seam strip.
        m.add(bag.patch(w: 0.07, h: 0.06, cy: 0.10, lift: 0.0014, back: true, cols: cols, rows: rows, material: label))
        // Degassing valve on the front upper panel.
        let vy: Float = 0.1555, vz = bag.frontZ(0.034, vy) + 0.0030
        let tilt = atan2(bag.frontZ(0.034, vy - 0.01) - bag.frontZ(0.034, vy + 0.01), 0.02)
        m.add(Prim.cylinder(radius: 0.0100, height: 0.0014, bevel: 0.0005, segments: detail ? 28 : 10, bevelSegments: 1, material: valve),
              Xform(translation: V3(0.034, vy, vz), rotation: DD1LPantry.q(.pi / 2 - tilt, V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0052, height: 0.0020, bevel: 0.0007, segments: detail ? 20 : 8, bevelSegments: 1, material: valve),
              Xform(translation: V3(0.034, vy, vz + 0.0010), rotation: DD1LPantry.q(.pi / 2 - tilt, V3(1, 0, 0))))
        if detail { for k in 0..<5 {
            let a = Float(k) / 5 * 2 * .pi
            m.add(Prim.cylinder(radius: 0.0007, height: 0.0004, bevel: 0.0001, segments: 6, bevelSegments: 1, material: "plastic.matte:1A1A1A"),
                  Xform(translation: V3(0.034 + 0.0033 * cos(a), vy + 0.0033 * sin(a), vz + 0.0030), rotation: DD1LPantry.q(.pi / 2 - tilt, V3(1, 0, 0))))
        } }
        // Tin tie strip across the top seal, bent ends wrapped over the sides.
        let ty = size.y - 0.0085
        m.add(Prim.roundedBox(V3(size.x * 0.93, 0.0050, 0.0050), radius: 0.0012, bevelSegments: 2, material: tinTie), Xform(translation: V3(0, ty, 0)))
        for sx in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(0.0012, 0.0050, 0.0052), radius: 0.0004, bevelSegments: 1, material: tinTie), Xform(translation: V3(sx * size.x * 0.465, ty - 0.0014, 0)))
        }
        // Story detail: coffee ring stain on the label.
        m.add(Prim.torus(major: 0.0105, minor: 0.00055, segments: detail ? 32 : 12, sides: 5, material: "plastic.matte:6B4A2C"),
              Xform(translation: V3(-0.020, 0.074, bag.frontZ(-0.020, 0.074) + 0.0015), rotation: DD1LPantry.q(.pi / 2, V3(1, 0, 0)), scale: V3(1, 0.5, 1)))
        groundAO(&m, height: 0.012, floor: 0.6)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
