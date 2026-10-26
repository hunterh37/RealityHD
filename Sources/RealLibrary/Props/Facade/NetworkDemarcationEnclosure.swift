import simd
import Foundation

/// Network demarcation enclosure: UV-stabilised ABS wall cabinet (back plate plus snap-fit cover with a
/// drip hood), louver band, smoked status window with an LED row, two side snap latches and a tamper screw
/// with a seal strap, bottom rubber-grommet glands with fiber (yellow) and coax drops, ground lug.
/// Wall plane at z = 0, bottom on y = 0.
public struct NetworkDemarcationEnclosure: RealAsset {
    public static let id = "network-demarcation-enclosure"
    public static let summary = "Network demarcation enclosure: UV-stabilised ABS wall cabinet, snap-latched cover with louver band, smoked status window with LEDs, tamper screw with seal, bottom grommet glands with fiber and coax drops, ground lug."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 10, distance: 0.95)

    /// Cabinet plastic.
    public var shell: MaterialKey = "plastic.white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y0: Float = 0.05, y1: Float = 0.4, h = y1 - y0, cy = (y0 + y1) / 2, w: Float = 0.29
        // Back plate with moulded ribs, and the cover shell with a parting line.
        m.add(Prim.extrude(Shape2D.roundedRect(w + 0.01, h + 0.01, radius: 0.022), depth: 0.026, bevel: 0.004, bevelSegments: 1, material: "plastic.medical-grey"),
              Xform(translation: V3(0, cy, 0.013)))
        m.add(Prim.extrude(Shape2D.roundedRect(w, h, radius: 0.034), depth: 0.116, bevel: 0.014, bevelSegments: 3, material: shell),
              Xform(translation: V3(0, cy, 0.026 + 0.058)))
        FA.box(&m, V3(w + 0.004, 0.0022, 0.0022), V3(0, cy + h / 2 - 0.045, 0.0268), "plastic.black", r: 0.0006)
        // Drip hood over the top edge.
        FA.box(&m, V3(w - 0.03, 0.01, 0.034), V3(0, y1 - 0.009, 0.116), "metal.painted:DDD7BE", r: 0.004)
        // Louver band near the top: moulded slots with sloped blades.
        for i in 0..<7 {
            let y = y1 - 0.045 - Float(i) * 0.0125
            FA.box(&m, V3(0.19, 0.0055, 0.003), V3(0, y, 0.1428), "plastic.black", r: 0.0012)
            FA.box(&m, V3(0.19, 0.0038, 0.0028), V3(0, y + 0.0042, 0.1432), shell, r: 0.0012, rot: FA.q(-18, FA.X))
        }
        // Smoked status window with bezel, LED row, label and a second plate.
        FS.plate(&m, 0.15, 0.062, 0.004, radius: 0.008, at: V3(0, cy + 0.01, 0.1428), "plastic.black", bevel: 0.0012)
        FS.plate(&m, 0.14, 0.052, 0.003, radius: 0.006, at: V3(0, cy + 0.01, 0.1447), "glass.tinted", bevel: 0.0006)
        for (i, c) in ["emissive.led-green", "emissive.led-green", "emissive.amber", "emissive.led-green", "emissive.led-green"].enumerated() {
            FA.cylZ(&m, r: 0.0032, h: 0.0015, at: V3(-0.048 + Float(i) * 0.024, cy + 0.01, 0.1452), c, bevel: 0.0004, segments: 10)
        }
        FA.box(&m, V3(0.11, 0.032, 0.0012), V3(0, cy - 0.06, 0.1427), "metal.painted:C8CBCC", r: 0.0005)
        FA.box(&m, V3(0.08, 0.003, 0.0013), V3(-0.01, cy - 0.055, 0.1434), "plastic.black", r: 0.0003)
        FA.box(&m, V3(0.06, 0.003, 0.0013), V3(-0.02, cy - 0.065, 0.1434), "plastic.black", r: 0.0003)
        // Snap latches on both sides: flexure tab and catch.
        for sx in [Float(-1), 1] {
            FA.box(&m, V3(0.006, 0.05, 0.02), V3(sx * (w / 2 - 0.0005), cy + 0.06, 0.07), "plastic.medical-grey", r: 0.002)
            FA.box(&m, V3(0.006, 0.05, 0.02), V3(sx * (w / 2 - 0.0005), cy - 0.08, 0.07), "plastic.medical-grey", r: 0.002)
            FA.box(&m, V3(0.002, 0.036, 0.006), V3(sx * (w / 2 + 0.0035), cy + 0.06, 0.07), "plastic.black", r: 0.0008)
        }
        // Tamper screw in a recess with a yellow seal strap through a moulded eye.
        FA.cylZ(&m, r: 0.011, h: 0.0012, at: V3(0, y0 + 0.032, 0.1427), "plastic.black", bevel: 0.0008, segments: 18)
        hexBolt(&m, at: V3(0, y0 + 0.032, 0.1436), normal: FA.Z, size: 0.008, material: "metal.stainless")
        FA.path(&m, catmull([V3(0.012, y0 + 0.032, 0.1468), V3(0.03, y0 + 0.04, 0.1483), V3(0.04, y0 + 0.02, 0.1483), V3(0.022, y0 + 0.016, 0.1468)], per: 5), r: 0.0018, "plastic.yellow", sides: 6)
        FA.box(&m, V3(0.014, 0.01, 0.003), V3(0.03, y0 + 0.04, 0.148), "plastic.yellow", r: 0.001)
        // Bottom glands: grommet, locknut, drops (fiber, coax, patch) with drip loops, ground lug and bond wire.
        let drops: [(Float, MaterialKey, Float)] = [(-0.06, "plastic.yellow", 0.0035), (0.0, "plastic.black", 0.0045), (0.06, "plastic.medical-grey", 0.003)]
        for (i, d) in drops.enumerated() {
            let gx = d.0, gz: Float = 0.072
            FS.cyl(&m, r: 0.015, h: 0.012, at: V3(gx, y0 - 0.006, gz), axis: FA.Y, "rubber.silicone", bevel: 0.002, segments: 14)
            FS.nut(&m, at: V3(gx, y0 - 0.002, gz), axis: FA.Y, af: 0.03, h: 0.008, "plastic.medical-grey")
            let sgn: Float = i == 1 ? -1 : 1
            FA.path(&m, catmull([V3(gx, y0, gz), V3(gx, 0.03, gz), V3(gx + sgn * 0.006, 0.018, gz + 0.008), V3(gx + sgn * 0.018, 0.008, gz + 0.02), V3(gx + sgn * 0.034, 0.004, gz + 0.03)], per: 6), r: d.2 * 1.35, d.1, sides: 8)
        }
        FA.box(&m, V3(0.014, 0.012, 0.012), V3(-w / 2 + 0.018, y0 + 0.012, 0.045), "metal.brass-aged", r: 0.002)
        FA.path(&m, catmull([V3(-w / 2 + 0.018, y0 + 0.006, 0.045), V3(-w / 2 + 0.03, 0.03, 0.05), V3(-w / 2 + 0.024, 0.012, 0.06), V3(-w / 2 + 0.036, 0.0035, 0.07)], per: 5), r: 0.0026, "paint.cylinder-green", sides: 8)
        // Ear screws through the back plate corners and rating label on the base.
        FS.screws(&m, [V3(-0.14, y1 - 0.0, 0.026), V3(0.14, y1 - 0.0, 0.026)], r: 0.0035)
        FA.box(&m, V3(0.05, 0.022, 0.0012), V3(0.09, cy - 0.12, 0.1427), "metal.painted:C8CBCC", r: 0.0004)
        // Weathering: UV chalking and yellowing, dust streaks below the hood, mildew at the lower edge.
        FA.box(&m, V3(w - 0.07, 0.01, 0.0012), V3(0, y0 + 0.0065, 0.1428), "metal.painted:A4A38B", r: 0.0004)
        // Corner screw bosses with snap-in cap plugs, moulded panel border and a fiber caution label.
        for (x, y) in [(-0.123, y1 - 0.027), (0.123, y1 - 0.027), (-0.123, y0 + 0.027), (0.123, y0 + 0.027)] as [(Float, Float)] {
            FA.cylZ(&m, r: 0.0085, h: 0.0016, at: V3(x, y, 0.1424), "plastic.medical-grey", bevel: 0.0006, segments: 14)
            FA.box(&m, V3(0.008, 0.0012, 0.0012), V3(x, y, 0.1442), "plastic.black", r: 0.0003)
        }
        FA.box(&m, V3(0.236, 0.0016, 0.0012), V3(0, y1 - 0.02, 0.1427), "plastic.medical-grey", r: 0.0004)
        FA.box(&m, V3(0.236, 0.0016, 0.0012), V3(0, y0 + 0.02, 0.1427), "plastic.medical-grey", r: 0.0004)
        FA.box(&m, V3(0.04, 0.026, 0.0013), V3(-0.095, cy - 0.12, 0.1428), "plastic.yellow", r: 0.0005)
        FA.box(&m, V3(0.026, 0.003, 0.0014), V3(-0.095, cy - 0.12, 0.1435), "plastic.black", r: 0.0003)
        FA.box(&m, V3(0.026, 0.003, 0.0014), V3(-0.095, cy - 0.128, 0.1435), "plastic.black", r: 0.0003)
        // Rain-splash mud flecks on the lower front and a grime band along the bottom lip.
        FA.box(&m, V3(w - 0.05, 0.012, 0.0012), V3(0, y0 + 0.018, 0.1428), "metal.painted:B7B29D", r: 0.0004)
        for _ in 0..<34 {
            let yy = y0 + 0.01 + rng.float(0...1) * rng.float(0...1) * 0.12
            FC.bead(&m, r: rng.float(0.0012...0.003), at: V3(rng.float(-0.12...0.12), yy, 0.1424), "metal.painted:7D7660", sub: 2)
        }
        groundAO(&m, height: 0.04, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
