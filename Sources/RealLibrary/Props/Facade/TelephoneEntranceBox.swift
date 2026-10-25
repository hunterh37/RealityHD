import simd
import Foundation

/// Telephone network interface box: grey ABS two-compartment cabinet on four mounting ears, a telco cover
/// with a tamper screw and seal, a customer door with a thumb latch and grip ribs, a rain hood, a bottom
/// drop-wire boot with a drip loop and a copper ground clamp. Wall plane at z = 0, bottom on y = 0.
public struct TelephoneEntranceBox: RealAsset {
    public static let id = "telephone-entrance-box"
    public static let summary = "Telephone network interface box: grey ABS two-compartment cabinet with telco and customer covers, tamper screw, thumb latch, rain hood, bottom drop-wire boot with drip loop, copper ground clamp and mounting ears."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 0.9)

    /// Cover plastic.
    public var cover: MaterialKey = "plastic.medical-grey"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y0: Float = 0.03, y1: Float = 0.295, h = y1 - y0, cy = (y0 + y1) / 2, w: Float = 0.165
        let F: Float = 0.092   // front plane of the covers
        // Base with mounting ears, then the cabinet shell.
        m.add(Prim.extrude(Shape2D.roundedRect(w + 0.01, h + 0.01, radius: 0.012), depth: 0.018, bevel: 0.003, bevelSegments: 1, material: "plastic.medical-grey-worn"),
              Xform(translation: V3(0, cy, 0.009)))
        for sy in [Float(-1), 1] {
            for sx in [Float(-1), 1] {
                FA.box(&m, V3(0.028, 0.018, 0.003), V3(sx * 0.0845, cy + sy * (h / 2 - 0.02), 0.0015), "plastic.medical-grey-worn", r: 0.001)
                FS.screw(&m, at: V3(sx * 0.0905, cy + sy * (h / 2 - 0.02), 0.003), r: 0.0034)
            }
        }
        m.add(Prim.extrude(Shape2D.roundedRect(w, h, radius: 0.014), depth: F - 0.018, bevel: 0.006, bevelSegments: 2, material: cover),
              Xform(translation: V3(0, cy, 0.018 + (F - 0.018) / 2)))
        // Parting line between the telco (upper) and customer (lower) compartments, and cover seams.
        let sy: Float = 0.145
        FA.box(&m, V3(w - 0.01, 0.0022, 0.002), V3(0, sy, F + 0.0004), "plastic.black", r: 0.0007)
        for x in [Float(-w / 2 + 0.008), w / 2 - 0.008] { FA.box(&m, V3(0.0022, h - 0.02, 0.002), V3(x, cy, F + 0.0004), "plastic.black", r: 0.0007) }
        // Telco cover: raised panel, tamper hex screw in a recess with seal strap, rating plate.
        FA.box(&m, V3(w - 0.04, 0.108, 0.003), V3(0, sy + 0.075, F + 0.0012), cover, r: 0.003)
        FA.cylZ(&m, r: 0.011, h: 0.0012, at: V3(0, y1 - 0.034, F + 0.0013), "plastic.black", bevel: 0.0006, segments: 16)
        hexBolt(&m, at: V3(0, y1 - 0.034, F + 0.0022), normal: FA.Z, size: 0.0085, material: "metal.stainless")
        FA.path(&m, catmull([V3(0.01, y1 - 0.034, F + 0.0065), V3(0.026, y1 - 0.026, F + 0.0075), V3(0.036, y1 - 0.045, F + 0.0075), V3(0.02, y1 - 0.05, F + 0.0065)], per: 5), r: 0.0016, "plastic.white", sides: 6)
        FA.box(&m, V3(0.075, 0.03, 0.0013), V3(0, sy + 0.05, F + 0.0033), "metal.painted:CFCABB", r: 0.0005)
        FA.box(&m, V3(0.055, 0.003, 0.0014), V3(-0.005, sy + 0.056, F + 0.0036), "plastic.black", r: 0.0003)
        FA.box(&m, V3(0.04, 0.003, 0.0014), V3(-0.012, sy + 0.047, F + 0.0036), "plastic.black", r: 0.0003)
        // Customer door: grip ribs, thumb latch with slotted screw, hinge knuckles at the bottom.
        FA.box(&m, V3(w - 0.036, 0.098, 0.0024), V3(0, sy - 0.062, F + 0.0009), cover, r: 0.003)
        for i in 0..<5 { FA.box(&m, V3(0.05, 0.0028, 0.0028), V3(0, sy - 0.032 + Float(i) * 0.0075, F + 0.0035), cover, r: 0.0012) }
        FA.box(&m, V3(0.03, 0.02, 0.006), V3(0, sy - 0.012, F + 0.0035), "plastic.medical-grey-worn", r: 0.003)
        FS.screw(&m, at: V3(0, sy - 0.012, F + 0.0065), r: 0.0036, mat: "metal.brass-aged")
        for x in [Float(-0.05), 0.05] { FS.cyl(&m, r: 0.0048, h: 0.03, at: V3(x - 0.015, y0 + 0.014, F - 0.003), axis: FA.X, "plastic.medical-grey-worn", bevel: 0.001, segments: 10) }
        // Rain hood over the top edge with drip lip.
        FA.box(&m, V3(w + 0.004, 0.012, 0.03), V3(0, y1 - 0.003, F - 0.012), cover, r: 0.004, rot: FA.q(4, FA.X))
        FA.box(&m, V3(w - 0.01, 0.003, 0.004), V3(0, y1 - 0.0085, F + 0.003), "plastic.black", r: 0.001)
        // Bottom entry: boss, rubber boot, two-conductor drop wire with drip loop.
        FS.cyl(&m, r: 0.018, h: 0.014, at: V3(0, y0 - 0.011, 0.055), axis: FA.Y, "plastic.medical-grey-worn", bevel: 0.002, segments: 16)
        FS.cyl(&m, r: 0.0125, h: 0.02, at: V3(0, y0 - 0.026, 0.055), axis: FA.Y, "rubber.silicone", bevel: 0.003, segments: 14)
        for dx in [Float(-0.0042), 0.0042] {
            let sg: Float = dx < 0 ? -1 : 1
            FA.path(&m, catmull([V3(dx, y0 - 0.02, 0.055), V3(dx, y0 - 0.026, 0.055), V3(dx, 0.014, 0.056), V3(dx + sg * 0.004, 0.006, 0.064), V3(dx + sg * 0.012, 0.0035, 0.08)], per: 5), r: 0.0034, "plastic.black", sides: 8)
        }
        // Copper ground clamp on the left side with green conductor.
        FA.box(&m, V3(0.014, 0.014, 0.012), V3(-w / 2 - 0.0015, y0 + 0.05, 0.055), "metal.copper", r: 0.002)
        hexBolt(&m, at: V3(-w / 2 - 0.0075, y0 + 0.05, 0.055), normal: V3(-1, 0, 0), size: 0.008, material: "metal.brass-aged")
        FA.path(&m, catmull([V3(-w / 2 - 0.004, y0 + 0.045, 0.058), V3(-w / 2 - 0.012, y0 + 0.03, 0.06), V3(-w / 2 - 0.01, y0 + 0.012, 0.064), V3(-w / 2 - 0.02, 0.003, 0.07)], per: 5), r: 0.0026, "paint.cylinder-green", sides: 8)
        // Weathering: UV-chalked grey top surfaces, cobweb dust in the lower corners, water streaks below the hood.
        for x in [Float(-0.05), 0.02, 0.06] {
            FS.streak(&m, x: x + rng.float(-0.008...0.008), top: y1 - 0.012, w: 0.0035, h: rng.float(0.03...0.07), z: F + 0.0004, "metal.painted:8A8F8A")
        }
        FA.box(&m, V3(w - 0.03, 0.012, 0.0012), V3(0, y0 + 0.012, F + 0.0004), "metal.painted:7D8079", r: 0.0004)
        for _ in 0..<24 {
            FC.bead(&m, r: rng.float(0.0012...0.0026), at: V3(rng.float(-0.075...0.075), y0 + 0.01 + rng.float(0...1) * rng.float(0...1) * 0.1, F + 0.0004), "metal.painted:6F6A58", sub: 2)
        }
        groundAO(&m, height: 0.04, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
