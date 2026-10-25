import simd
import Foundation

/// Mini-split heat pump condenser: 0.84 m galvanized cabinet in white powder coat on rubber-isolated base
/// rails, round front discharge with a stamped-wire fan guard and five-blade fan, wire coil guard on the
/// right side, valve cover with insulated copper line set on the left. Wall plane at z = 0.
public struct HeatPumpCondenserFan: RealAsset {
    public static let id = "heat-pump-condenser-fan"
    public static let summary = "Mini-split heat pump condenser, 0.9 x 0.8 m cabinet: front axial fan with wire guard, coil guard, valve cover, insulated line set, isolator feet."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 2.0)

    /// Cabinet powder coat.
    public var shell: MaterialKey = "metal.powder-white"
    /// Fan blade count.
    public var blades = 5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bx: Float = 0.03, bw: Float = 0.826, y0: Float = 0.07, y1: Float = 0.79, d: Float = 0.39
        let fz = d - 0.006, fy: Float = 0.43
        // Rubber isolator pads and galvanized base channel rails.
        for x in [Float(-0.3), 0.32] {
            FA.box(&m, V3(0.05, 0.012, 0.3), V3(x, 0.006, 0.2), "rubber.plate", r: 0.003)
            FA.box(&m, V3(0.05, 0.03, 0.34), V3(x, 0.027, 0.2), "metal.galvanized-aged", r: 0.002)
        }
        // Base pan with folded drip lip.
        FA.box(&m, V3(bw, 0.03, d - 0.02), V3(bx, 0.055, 0.2), "metal.galvanized", r: 0.003)
        FA.box(&m, V3(bw + 0.004, 0.008, d - 0.012), V3(bx, 0.072, 0.2), shell, r: 0.002)
        // Corner posts.
        for (x, z) in [(bx - bw / 2 + 0.02, Float(0.03)), (bx + bw / 2 - 0.02, 0.03), (bx - bw / 2 + 0.02, d - 0.02), (bx + bw / 2 - 0.02, d - 0.02)] {
            FA.box(&m, V3(0.04, y1 - y0, 0.04), V3(x, (y0 + y1) / 2, z), shell, r: 0.005)
        }
        // Front panel with round discharge opening, dark interior behind it.
        FS.roundHolePanel(&m, w: bw, h: y1 - y0 - 0.02, hole: 0.2, t: 0.012, at: V3(bx, fy, d - 0.006), shell, bevel: 0.002)
        FA.box(&m, V3(bw - 0.06, y1 - y0 - 0.06, 0.004), V3(bx, fy, 0.25), "plastic.black", r: 0.001)
        // Bell-mouth shroud ring and wire guard.
        FS.ringZ(&m, r: 0.2, wire: 0.007, at: V3(bx, fy, fz + 0.003), shell, segments: 48, sides: 8)
        FS.fanGuard(&m, r: 0.198, rings: 5, spokes: 16, wire: 0.0017, at: V3(bx, fy, d - 0.002), "metal.stainless")
        // Fan: hub, blades, retaining nut.
        let fc = V3(bx, fy, 0.30)
        FA.cylZ(&m, r: 0.04, h: 0.045, at: fc, "plastic.black", bevel: 0.006, segments: 24)
        FA.cylZ(&m, r: 0.012, h: 0.012, at: fc + V3(0, 0, 0.045), "metal.galvanized", bevel: 0.002, segments: 8)
        let off = rng.float(0...70)
        for k in 0..<blades {
            FS.blade(&m, length: 0.19, root: 0.08, tip: 0.11, thick: 0.004, angle: off + Float(k) * 360 / Float(blades), pitch: 28, at: fc + V3(0, 0, 0.012), "plastic.medical-grey")
        }
        // Stamped louvre slots on the right and left front strips.
        for i in 0..<7 {
            let y = y0 + 0.06 + Float(i) * 0.09
            FA.box(&m, V3(0.15, 0.006, 0.003), V3(bx + 0.33, y, d + 0.0005), "plastic.black", r: 0.0015)
        }
        // Top cover with overhang, recessed pull and screws.
        FA.box(&m, V3(bw + 0.012, 0.022, d - 0.004), V3(bx, y1 - 0.005, 0.2), shell, r: 0.005)
        FA.box(&m, V3(0.18, 0.004, 0.05), V3(bx, y1 + 0.007, 0.28), "plastic.black", r: 0.0015)
        FS.screws(&m, [V3(bx - 0.38, y1 + 0.006, 0.05), V3(bx + 0.38, y1 + 0.006, 0.05), V3(bx - 0.38, y1 + 0.006, 0.34), V3(bx + 0.38, y1 + 0.006, 0.34)], normal: FA.Y, r: 0.004)
        // Coil guard on the right side: vertical and horizontal wire.
        let rx = bx + bw / 2 + 0.002
        FA.box(&m, V3(0.006, y1 - y0 - 0.02, d - 0.05), V3(rx - 0.004, (y0 + y1) / 2, 0.2), "plastic.black", r: 0.001)
        for i in 0..<18 {
            FA.rod(&m, V3(rx + 0.002, y0 + 0.02, 0.04 + Float(i) * 0.0195), V3(rx + 0.002, y1 - 0.02, 0.04 + Float(i) * 0.0195), r: 0.0013, "metal.galvanized", sides: 5)
        }
        for i in 0..<10 {
            let y = y0 + 0.03 + Float(i) * 0.07
            FA.rod(&m, V3(rx + 0.0035, y, 0.036), V3(rx + 0.0035, y, d - 0.04), r: 0.0017, "metal.galvanized", sides: 6)
        }
        // Left side skin and rear coil: aluminum fin block, copper return bends, wire guard.
        FA.box(&m, V3(0.006, y1 - y0 - 0.02, d - 0.05), V3(bx - bw / 2 + 0.003, (y0 + y1) / 2, 0.2), shell, r: 0.002)
        FA.box(&m, V3(bw - 0.07, y1 - y0 - 0.06, 0.03), V3(bx, (y0 + y1) / 2, 0.055), "metal.aluminum-fins", r: 0.001)
        for i in 0..<12 {
            FA.cylX(&m, r: 0.004, h: bw - 0.05, at: V3(bx - (bw - 0.05) / 2, y0 + 0.05 + Float(i) * 0.057, 0.036), "metal.copper", bevel: 0.001, segments: 8)
        }
        for i in 0..<30 {
            FA.rod(&m, V3(bx - bw / 2 + 0.035 + Float(i) * 0.0258, y0 + 0.02, 0.028), V3(bx - bw / 2 + 0.035 + Float(i) * 0.0258, y1 - 0.02, 0.028), r: 0.0013, "metal.galvanized", sides: 5)
        }
        // Valve cover on the left, with screws and rating plate.
        FA.box(&m, V3(0.06, 0.32, d - 0.06), V3(-0.42, 0.24, 0.2), shell, r: 0.004)
        FA.box(&m, V3(0.002, 0.07, 0.11), V3(-0.4505, 0.30, 0.15), "metal.aluminum-brushed", r: 0.0005)
        FS.screws(&m, [V3(-0.4515, 0.12, 0.08), V3(-0.4515, 0.12, 0.32), V3(-0.4515, 0.36, 0.08), V3(-0.4515, 0.36, 0.32)], normal: V3(-1, 0, 0), r: 0.003)
        // Insulated line set: two copper lines in foam sleeves running down and back to the wall.
        for (z, r) in [(Float(0.14), Float(0.016)), (0.18, 0.011)] {
            let path = [V3(-0.42, 0.09, z), V3(-0.42, 0.045, z), V3(-0.42, 0.025, z - 0.02), V3(-0.42, 0.022, z - 0.07)]
            FA.path(&m, path, r: r, "rubber.tubing", sides: 14)
            FA.rod(&m, V3(-0.42, 0.093, z), V3(-0.42, 0.1, z), r: r * 0.5, "metal.copper")
        }
        FA.box(&m, V3(0.075, 0.035, 0.01), V3(-0.42, 0.03, 0.0), "plastic.black", r: 0.002)
        // Condensate drain stub and a weathering streak mismatch on the base.
        FA.cylZ(&m, r: 0.011, h: 0.03, at: V3(0.25, 0.04, 0.36), "plastic.black", bevel: 0.002, segments: 12)
        FA.box(&m, V3(bw - 0.06, 0.006, 0.002), V3(bx, y0 + 0.003, d + 0.0002), "metal.galvanized-aged", r: 0.001)
        // Weathering: grime band along the lower front, rust bleed at the base pan corners and below the top screws.
        FA.box(&m, V3(bw - 0.01, 0.07, 0.0016), V3(bx, y0 + 0.045, d + 0.0002), "metal.painted:BDB8A8", r: 0.0006)
        for x in [Float(-0.36), -0.12, 0.2, 0.41] {
            FA.box(&m, V3(0.012 + rng.float(0...0.01), 0.03 + rng.float(0...0.03), 0.0012), V3(x, y0 + 0.02, d + 0.0014), "metal.rust", r: 0.0004)
        }
        for x in [bx - 0.38, bx + 0.38] {
            FA.box(&m, V3(0.008, 0.06 + rng.float(0...0.04), 0.0012), V3(x, y1 - 0.045, d - 0.002), "metal.rust", r: 0.0004)
        }
        FA.box(&m, V3(0.1, 0.0016, 0.012), V3(bx + 0.2, y1 + 0.0125, 0.12), "metal.painted:A9A596", r: 0.0006)
        // Panel seams, nameplate and caution label on the front.
        for x in [bx - bw / 2 + 0.043, bx + bw / 2 - 0.043] {
            FA.box(&m, V3(0.0018, y1 - y0 - 0.05, 0.0012), V3(x, (y0 + y1) / 2, d + 0.0004), "plastic.black", r: 0.0004)
        }
        FA.box(&m, V3(bw - 0.09, 0.0018, 0.0012), V3(bx, y1 - 0.045, d + 0.0004), "plastic.black", r: 0.0004)
        FA.box(&m, V3(0.07, 0.016, 0.0016), V3(bx + 0.3, y1 - 0.08, d + 0.0006), "metal.aluminum-brushed", r: 0.0006)
        FA.box(&m, V3(0.05, 0.035, 0.0012), V3(bx - 0.32, fy - 0.12, d + 0.0006), "label.hazard", r: 0.0004)
        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
