import simd
import Foundation

/// Cable TV junction box: NEMA 3R sheet-steel enclosure on four mounting ears, drip-lip hinged door on two
/// barrel hinges, quarter-turn latch and padlock hasp with a brass padlock, two bottom hubs with coax drops
/// and a green bonding conductor on a ground lug. Wall plane at z = 0, bottom on y = 0.
public struct CableTvJunctionBox: RealAsset {
    public static let id = "cable-tv-junction-box"
    public static let summary = "Cable TV junction box: NEMA 3R sheet steel enclosure with drip-lip hinged door, barrel hinges, quarter-turn latch with padlock hasp, mounting ears, bottom hubs with coax drops and ground lug."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 0.9)

    /// Enclosure paint.
    public var paint: MaterialKey = "metal.painted:8F9296"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w: Float = 0.25, y0: Float = 0.04, y1: Float = 0.397, h = y1 - y0, cy = (y0 + y1) / 2
        // Back box with folded return flange, and mounting ears with slotted screw holes.
        FA.box(&m, V3(w, h, 0.088), V3(0, cy, 0.044), paint, r: 0.004)
        FA.box(&m, V3(w + 0.008, h + 0.008, 0.012), V3(0, cy, 0.006), paint, r: 0.003)
        for sy in [Float(-1), 1] {
            for sx in [Float(-1), 1] {
                FA.box(&m, V3(0.036, 0.022, 0.0025), V3(sx * 0.132, cy + sy * (h / 2 - 0.02), 0.00125), "metal.galvanized", r: 0.001)
                FS.screw(&m, at: V3(sx * 0.136, cy + sy * (h / 2 - 0.02), 0.0025), r: 0.0034)
                FA.box(&m, V3(0.018, 0.016, 0.0035), V3(sx * 0.118, cy + sy * (h / 2 - 0.02), 0.00175), "metal.galvanized", r: 0.001)
            }
        }
        // Door: panel with drip-lip flange, stiffening emboss, rolled edge.
        FA.box(&m, V3(w + 0.012, h + 0.012, 0.016), V3(0, cy, 0.096), paint, r: 0.005)
        FA.box(&m, V3(w - 0.02, h - 0.02, 0.004), V3(0, cy, 0.105), "metal.powdercoat:858890", r: 0.003)
        FA.box(&m, V3(w + 0.016, 0.004, 0.006), V3(0, y1 + 0.004, 0.092), paint, r: 0.0015)      // top drip shield
        FA.box(&m, V3(w + 0.016, 0.0025, 0.002), V3(0, cy + h / 2 - 0.0, 0.1042), "plastic.black", r: 0.0008)
        // Barrel hinges on the left: knuckles, pin heads, leaf plates.
        for y in [y1 - 0.06, y0 + 0.06] {
            FA.box(&m, V3(0.028, 0.06, 0.003), V3(-w / 2 - 0.006, y, 0.092), "metal.galvanized", r: 0.001)
            FS.cyl(&m, r: 0.0065, h: 0.062, at: V3(-w / 2 - 0.0105, y - 0.031, 0.1), axis: FA.Y, "metal.stainless", bevel: 0.001, segments: 12)
            for k in 0..<3 { FS.cyl(&m, r: 0.0072, h: 0.002, at: V3(-w / 2 - 0.0105, y - 0.028 + Float(k) * 0.028, 0.1), axis: FA.Y, "metal.galvanized-aged", bevel: 0.0006, segments: 12) }
            FS.screws(&m, [V3(-w / 2 + 0.0, y + 0.02, 0.1065), V3(-w / 2 + 0.0, y - 0.02, 0.1065)], r: 0.0028)
        }
        // Quarter-turn latch with wing cam and padlock hasp on the right.
        let lx = w / 2 - 0.03
        FS.cyl(&m, r: 0.016, h: 0.006, at: V3(lx, cy + 0.02, 0.1055), axis: FA.Z, "metal.galvanized", bevel: 0.0015, segments: 20)
        FS.nut(&m, at: V3(lx, cy + 0.02, 0.1135), axis: FA.Z, af: 0.016, h: 0.008, "metal.stainless")
        FA.box(&m, V3(0.006, 0.05, 0.004), V3(lx, cy + 0.02, 0.101), "metal.galvanized", r: 0.0012, rot: FA.q(-90, FA.Z))
        FA.box(&m, V3(0.034, 0.05, 0.002), V3(lx, cy - 0.06, 0.1075), "metal.galvanized", r: 0.0012)
        FA.box(&m, V3(0.014, 0.014, 0.012), V3(lx, cy - 0.075, 0.1155), "metal.galvanized", r: 0.002)
        FS.screws(&m, [V3(lx, cy - 0.045, 0.1085), V3(lx, cy - 0.085, 0.1085)], r: 0.003)
        // Brass padlock hanging from the hasp: body, shackle, keyway.
        let pb = V3(lx, cy - 0.105, 0.1125)
        FA.box(&m, V3(0.034, 0.03, 0.014), pb, "metal.brass-aged", r: 0.005)
        m.add(Prim.torus(major: 0.0095, minor: 0.0026, segments: 18, sides: 6, arc: .pi, material: "metal.stainless"),
              Xform(translation: pb + V3(0, 0.015, 0), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.004, 0.009, 0.0016), pb + V3(0, -0.003, 0.0072), "plastic.black", r: 0.0006)
        // Warning label (sun-faded yellow) and an identification plate.
        FA.box(&m, V3(0.07, 0.045, 0.0012), V3(-0.045, cy + 0.085, 0.1072), "metal.painted:C9A92E", r: 0.0005)
        FA.box(&m, V3(0.05, 0.004, 0.0013), V3(-0.045, cy + 0.085, 0.1079), "plastic.black", r: 0.0003)
        FA.box(&m, V3(0.05, 0.004, 0.0013), V3(-0.045, cy + 0.095, 0.1079), "plastic.black", r: 0.0003)
        FA.box(&m, V3(0.065, 0.026, 0.0015), V3(-0.045, cy - 0.03, 0.1074), "metal.aluminum-brushed", r: 0.0006)
        FS.screws(&m, [V3(-0.073, cy - 0.03, 0.1082), V3(-0.017, cy - 0.03, 0.1082)], r: 0.0018)
        // Bottom hubs with locknuts, coax drops with drip loops, ground lug and bonding wire.
        for (i, x) in [Float(-0.05), 0.0].enumerated() {
            FS.cyl(&m, r: 0.017, h: 0.016, at: V3(x + 0.03, y0 - 0.013, 0.05), axis: FA.Y, "metal.galvanized", bevel: 0.002)
            FS.nut(&m, at: V3(x + 0.03, y0 - 0.002, 0.05), axis: FA.Y, af: 0.034, h: 0.009, "metal.galvanized-aged")
            let cx = x + 0.03
            FA.path(&m, catmull([V3(cx, y0 - 0.01, 0.05), V3(cx, 0.028, 0.05), V3(cx + 0.008 * (i == 0 ? -1 : 1), 0.016, 0.058), V3(cx + 0.02 * (i == 0 ? -1 : 1), 0.008, 0.07), V3(cx + 0.034 * (i == 0 ? -1 : 1), 0.0045, 0.085)], per: 6), r: 0.0042, "plastic.black", sides: 8)
        }
        FA.box(&m, V3(0.014, 0.014, 0.012), V3(-w / 2 + 0.014, y0 + 0.016, 0.064), "metal.brass-aged", r: 0.002)
        FA.path(&m, catmull([V3(-w / 2 + 0.014, y0 + 0.006, 0.064), V3(-w / 2 + 0.0, 0.022, 0.07), V3(-w / 2 - 0.006, 0.01, 0.075), V3(-w / 2 - 0.01, 0.0035, 0.085)], per: 5), r: 0.0028, "paint.cylinder-green", sides: 8)
        // Weathering: rust at the lower seam and ear screws, drip streaks under the top shield, scuffed door corners.
        FA.box(&m, V3(w - 0.03, 0.004, 0.0014), V3(0, y0 + 0.004, 0.1075), "metal.rust", r: 0.0005)
        for x in [Float(-0.09), 0.02, 0.1] {
            FS.streak(&m, x: x + rng.float(-0.01...0.01), top: y1 - 0.01, w: 0.004, h: rng.float(0.03...0.07), z: 0.1072, "metal.painted:7E8185")
        }
        FA.box(&m, V3(0.018, 0.018, 0.0013), V3(w / 2 - 0.012, y1 - 0.014, 0.1075), "metal.painted:A8A39A", r: 0.0005)
        groundAO(&m, height: 0.04, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
