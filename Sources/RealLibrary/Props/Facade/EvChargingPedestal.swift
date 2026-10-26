import simd
import Foundation

/// Free-standing EV charging pedestal: graphite folded-steel column on a galvanized base flange with four
/// anchor bolts and a concrete footing, wider display head with glass screen, LED bar and RFID pad, two
/// J1772 handles docked in holsters with looped cables, lockable service door, vent louvers.
public struct EvChargingPedestal: RealAsset {
    public static let id = "ev-charging-pedestal"
    public static let summary = "Free-standing EV charging pedestal, 1.5 m: graphite steel column on anchor-bolted flange and concrete footing, display head, RFID pad, two docked J1772 handles with cables, locked service door."
    public static let tags = ["prop", "architecture", "facade", "metal", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.6)

    /// Column finish.
    public var column: MaterialKey = "metal.painted:5E636A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let by: Float = 0.062, bt: Float = 1.24   // body bottom and top
        let bh = bt - by
        // Concrete footing with chamfered top edge, galvanized flange, anchor bolts with nuts and washers.
        FA.box(&m, V3(0.35, 0.04, 0.30), V3(0, 0.02, 0), "concrete.rough", r: 0.006)
        FA.box(&m, V3(0.31, 0.012, 0.25), V3(0, 0.046, 0), "metal.galvanized-aged", r: 0.002)
        for (x, z) in [(-0.135, -0.105), (0.135, -0.105), (-0.135, 0.105), (0.135, 0.105)] as [(Float, Float)] {
            FA.cylZ(&m, r: 0.004, h: 0.001, at: V3(x, 0.06, z), "metal.galvanized")
            hexBolt(&m, at: V3(x, 0.052, z), normal: FA.Y, size: 0.02, material: "metal.galvanized-aged")
        }
        // Column body: folded sheet, front door seam, vent louvers on the sides.
        FA.box(&m, V3(0.30, bh, 0.24), V3(0, by + bh / 2, 0), column, r: 0.012)
        FA.box(&m, V3(0.31, 0.03, 0.25), V3(0, by + 0.02, 0), "metal.painted:25282B", r: 0.004)   // kick skirt
        FA.box(&m, V3(0.22, 0.46, 0.003), V3(0, 0.40, 0.1205), "metal.painted:50555B", r: 0.003)    // service door
        for dx in [Float(-0.1115), 0.1115] { FA.box(&m, V3(0.0016, 0.46, 0.0016), V3(dx, 0.40, 0.1225), "plastic.black", r: 0.0005) }
        FA.box(&m, V3(0.22, 0.0016, 0.0016), V3(0, 0.171, 0.1225), "plastic.black", r: 0.0005)
        FA.box(&m, V3(0.22, 0.0016, 0.0016), V3(0, 0.629, 0.1225), "plastic.black", r: 0.0005)
        FA.cylZ(&m, r: 0.011, h: 0.006, at: V3(0.075, 0.40, 0.122), "metal.stainless", bevel: 0.002, segments: 16)
        FA.box(&m, V3(0.003, 0.012, 0.008), V3(0.075, 0.40, 0.128), "plastic.black", r: 0.0006)
        for i in 0..<5 {
            for s in [Float(-1), 1] { FA.box(&m, V3(0.0025, 0.005, 0.12), V3(s * 0.1505, 0.2 + Float(i) * 0.025, 0.0), "plastic.black", r: 0.0012) }
        }
        // Head: wider cap, bevelled collar, glass screen, LED bar, RFID pad.
        let hy: Float = 1.37
        FA.box(&m, V3(0.35, 0.26, 0.29), V3(0, hy, 0), "metal.painted:8D9298", r: 0.03)
        FA.box(&m, V3(0.322, 0.012, 0.262), V3(0, bt + 0.002, 0), "plastic.black", r: 0.003)
        FS.plate(&m, 0.25, 0.14, 0.004, radius: 0.012, at: V3(0, hy + 0.02, 0.143), "plastic.black")
        FS.plate(&m, 0.232, 0.122, 0.004, radius: 0.008, at: V3(0, hy + 0.02, 0.1455), "glass.display", bevel: 0.0008)
        FA.box(&m, V3(0.16, 0.009, 0.003), V3(0, hy + 0.098, 0.1445), "emissive.led-green", r: 0.0015)
        FA.cylZ(&m, r: 0.034, h: 0.003, at: V3(0, hy - 0.083, 0.139), "plastic.black", bevel: 0.001, segments: 24)
        FS.ringZ(&m, r: 0.026, wire: 0.0012, at: V3(0, hy - 0.083, 0.143), "metal.stainless", segments: 24, sides: 5)
        // Charge-state light bar beside the RFID pad and a plug pictogram plate.
        FA.box(&m, V3(0.006, 0.07, 0.003), V3(0.1, hy - 0.083, 0.1405), "emissive.led-green", r: 0.0015)
        FA.box(&m, V3(0.05, 0.05, 0.0015), V3(-0.095, hy - 0.083, 0.1427), "plastic.medical-grey", r: 0.002)
        FA.cylZ(&m, r: 0.011, h: 0.0012, at: V3(-0.095, hy - 0.083, 0.1432), "plastic.black", bevel: 0.0004, segments: 12)
        // Rating label and caution plate below the screen.
        FA.box(&m, V3(0.07, 0.022, 0.0015), V3(0.09, bt + 0.005 - 0.018, 0.1213), "metal.painted:7E8183", r: 0.0004)
        // Holsters, docked handles and cable loops.
        for s in [Float(-1), 1] {
            let x = s * 0.075
            FA.box(&m, V3(0.082, 0.085, 0.01), V3(x, 0.775, 0.125), "plastic.black", r: 0.004)
            FS.screws(&m, [V3(x - 0.03, 0.8, 0.13), V3(x + 0.03, 0.8, 0.13)], r: 0.003)
            FS.dockedHandle(&m, base: V3(x, 0.735, 0.12))
            let top = V3(x, 0.735 + 0.16, 0.12)
            let cable = catmull([top, top + V3(s * 0.012, 0.02, 0.0), V3(s * 0.12, 1.0, 0.135), V3(s * 0.148, 0.96, 0.095), V3(s * 0.152, 0.9, 0.03)], per: 7)
            FA.path(&m, cable, r: 0.0075, "rubber.tubing", sides: 10)
        }
        // Weathering: kerb-strike scuff at the base, salt line, rust at the flange, drip under the head.
        FA.box(&m, V3(0.30, 0.05, 0.0015), V3(0, by + 0.05, 0.1203), "metal.painted:5B5A55", r: 0.0006)
        FA.box(&m, V3(0.12, 0.09, 0.0014), V3(-0.07, by + 0.075, 0.1225), "metal.painted:7C7870", r: 0.0006)
        FS.streak(&m, x: -0.11, top: 0.062, w: 0.012, h: 0.045, z: 0.1262, "metal.rust")
        FS.streak(&m, x: 0.12, top: 0.062, w: 0.01, h: 0.03, z: 0.1262, "metal.rust")
        FA.box(&m, V3(0.3, 0.01, 0.0015), V3(0, bt - 0.012, 0.1203), "metal.painted:23262A", r: 0.0006)
        // Water staining under the head overhang and grime along the door foot.
        FA.box(&m, V3(0.012, 0.11, 0.0013), V3(-0.09, bt - 0.07, 0.1204), "metal.painted:4E5258", r: 0.0005)
        FA.box(&m, V3(0.008, 0.07, 0.0013), V3(0.06, bt - 0.05, 0.1204), "metal.painted:4E5258", r: 0.0005)
        FA.box(&m, V3(0.22, 0.012, 0.0013), V3(0, 0.178, 0.1228), "metal.painted:44474C", r: 0.0005)
        // Rear: bolted access panel with lock, vent grille, rating plate, conduit gland at the foot.
        FS.plate(&m, 0.24, 0.5, 0.004, radius: 0.004, at: V3(0, 0.43, -0.122), "metal.painted:3D4247")
        for (x, y) in [(-0.105, 0.2), (0.105, 0.2), (-0.105, 0.66), (0.105, 0.66), (-0.105, 0.43), (0.105, 0.43)] as [(Float, Float)] {
            FS.screw(&m, at: V3(x, y, -0.1245), normal: V3(0, 0, -1), r: 0.0042)
        }
        for i in 0..<6 { FA.box(&m, V3(0.14, 0.006, 0.003), V3(0, 0.52 + Float(i) * 0.03, -0.1255), "plastic.black", r: 0.0014) }
        FA.box(&m, V3(0.08, 0.04, 0.0015), V3(0.05, 0.3, -0.1262), "metal.painted:8A8D8F", r: 0.0004)
        FA.cylZ(&m, r: 0.013, h: 0.006, at: V3(-0.06, 0.3, -0.1285), "metal.stainless", bevel: 0.002, segments: 14)
        FA.box(&m, V3(0.28, 0.015, 0.0015), V3(0, by + 0.12, -0.1212), "metal.painted:5B5A55", r: 0.0006)
        _ = rng.float(0...1)
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
