import simd
import Foundation

/// Switchgear lineup: four-bay ANSI 61 grey low-voltage metal-clad lineup. Each bay has an instrument panel (meters, lamps, selector, nameplate), a hinged breaker door with viewing window and a bolted cable cover. A red mimic bus strip runs across all bays. Named parts "door-1"..."door-4" (hinged) and "breaker-rackout-2", "breaker-rackout-3" (slide out 0.55 m).
public struct SwitchgearLineup: RealArticulated {
    public static let id = "switchgear-lineup"
    public static let summary = "Four-bay ANSI-grey switchgear lineup with hinged breaker doors and viewing windows, rack-out breakers, meters, lamps, a red mimic bus strip and arc-flash warning labels."
    public static let tags = ["prop", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.1, studio: true)

    /// Width (x) and depth (z) of one bay, height of the lineup in meters.
    public var bay = V3(0.8, 2.3, 1.4)
    /// Number of bays.
    public var bays = 4
    /// Enclosure paint (ANSI 61 light grey).
    public var paint: MaterialKey = "metal.powdercoat:A7AAA9"
    /// Door angle when open, degrees.
    public var openAngle: Float = 100
    /// Breaker rack-out travel in meters.
    public var travel: Float = 0.55
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let bw = bay.x, H = bay.y, D = bay.z
        let W = bw * Float(bays)
        let zf = D / 2
        let dark: MaterialKey = "plastic.matte:151618"
        let steel: MaterialKey = "metal.steel"
        let trim: MaterialKey = "metal.powdercoat:8E9291"
        let yPlinth: Float = 0.1, yBrk0: Float = 0.62, yBrk1: Float = 1.56

        func add(_ s: Surface, _ x: Xform, to: String? = nil) {
            if let to { rig.add(s, x, to: to) } else { rig.base[0].add(s, x) }
        }
        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey, to: String? = nil) {
            if r < 0.003 || min(s.x, min(s.y, s.z)) < 0.03 { add(cuboid(s, material: mat), Xform(translation: c), to: to); return }
            add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c), to: to)
        }
        func cyl(_ r: Float, _ h: Float, _ c: V3, mat: MaterialKey, to: String? = nil) {
            add(Prim.cylinder(radius: r, height: h, bevel: 0, segments: r < 0.01 ? 5 : 8, bevelSegments: 1, material: mat),
                Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: to)
        }
        func warning(_ c: V3, to: String? = nil) {
            box(V3(0.11, 0.075, 0.0012), c, mat: "plastic.matte:E8C21A", to: to)
            box(V3(0.11, 0.018, 0.0016), c + V3(0, 0.0285, 0), mat: "plastic.matte:B51D17", to: to)
            for k in 0..<2 { box(V3(0.09, 0.0035, 0.0018), c + V3(0, 0.006 - Float(k) * 0.016, 0), mat: "plastic.matte:1A1A1A", to: to) }
            box(V3(0.02, 0.012, 0.0018), c + V3(-0.035, 0.0285, 0), mat: "plastic.matte:F1F1EC", to: to)
        }

        // Shell: plinth, roof, back, outer walls and bay dividers.
        box(V3(W, yPlinth, D - 0.02), V3(0, yPlinth / 2, -0.01), mat: "plastic.matte:2A2C2F")
        box(V3(W, 0.006, D - 0.02), V3(0, yPlinth + 0.003, -0.01), r: 0.001, mat: "metal.powdercoat:5E6160")
        box(V3(W, 0.03, D), V3(0, H - 0.015, 0), r: 0.003, mat: paint)
        box(V3(W - 0.01, 0.012, D - 0.02), V3(0, H - 0.036, -0.01), r: 0.002, mat: trim)   // roof cap
        box(V3(W, H - yPlinth, 0.012), V3(0, (H + yPlinth) / 2, -zf + 0.006), r: 0.002, mat: paint)
        for i in 0...bays {
            let x = -W / 2 + Float(i) * bw
            let e: Float = (i == 0 || i == bays) ? 0.008 : 0.0
            box(V3(0.016, H - yPlinth, D - 0.01), V3(x + (i == 0 ? 0.008 : (i == bays ? -0.008 : 0)) + e * 0, (H + yPlinth) / 2, -0.005), r: 0.002, mat: paint)
        }
        // Roof lift eyes and exhaust vents.
        for s: Float in [-1, 1] {
            add(Prim.torus(major: 0.03, minor: 0.008, segments: 8, sides: 5, material: steel), Xform(translation: V3(s * (W / 2 - 0.12), H + 0.02, -0.4)))
        }

        // Front plates between compartments, per bay.
        for i in 0..<bays {
            let cx = -W / 2 + (Float(i) + 0.5) * bw
            let pw = bw - 0.032
            let panelZ = zf - 0.01
            // Instrument panel (fixed) above the breaker door.
            box(V3(pw, H - 0.03 - yBrk1, 0.02), V3(cx, (yBrk1 + H - 0.03) / 2, panelZ), r: 0.002, mat: paint)
            // Cable compartment cover below, bolted.
            box(V3(pw, yBrk0 - yPlinth, 0.02), V3(cx, (yPlinth + yBrk0) / 2, panelZ), r: 0.002, mat: paint)
            box(V3(pw - 0.1, yBrk0 - yPlinth - 0.1, 0.002), V3(cx, (yPlinth + yBrk0) / 2, panelZ + 0.011), mat: trim)
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] where sy > 0 {
                cyl(0.006, 0.004, V3(cx + sx * (pw / 2 - 0.03), (yPlinth + yBrk0) / 2 + sy * 0.19, panelZ + 0.012), mat: steel)
            } }
            warning(V3(cx + 0.18, 0.33, panelZ + 0.0126))
            box(V3(0.12, 0.034, 0.0008), V3(cx - 0.18, 0.27, panelZ + 0.0124), mat: "plastic.matte:E8E8E4")
            box(V3(0.09, 0.004, 0.0009), V3(cx - 0.18, 0.272, panelZ + 0.0129), mat: "plastic.matte:1A1A1A")
            box(V3(0.07, 0.004, 0.0009), V3(cx - 0.18, 0.262, panelZ + 0.0129), mat: "plastic.matte:1A1A1A")

            // Meters: two square analog meters, selector, three lamps, nameplate.
            let my: Float = 2.02
            for (k, mx) in [Float(-0.17), 0.17].enumerated() {
                let c = V3(cx + mx, my, panelZ + 0.01)
                box(V3(0.13, 0.13, 0.03), c + V3(0, 0, 0.005), r: 0.004, mat: dark)
                box(V3(0.108, 0.108, 0.002), c + V3(0, 0, 0.021), mat: "plastic.matte:EDEDE6")
                for t in 0..<3 {
                    let a = (Float(t) / 2 - 0.5) * 1.6
                    box(V3(0.0018, 0.008, 0.0006), c + V3(sin(a) * 0.04, 0.012 + cos(a) * 0.04 - 0.02, 0.0225), mat: "plastic.matte:1A1A1A")
                }
                let na = (rng.float(0.15...0.7) - 0.4) * (k == 0 ? 1 : -1)
                add(cuboid(V3(0.0018, 0.048, 0.0008), material: "plastic.matte:B51D17"),
                    Xform(translation: c + V3(sin(na) * -0.012, -0.002, 0.0236), rotation: simd_quatf(angle: na, axis: V3(0, 0, 1)), scale: V3(1, 1, 1)))
                cyl(0.005, 0.003, c + V3(0, -0.018, 0.0242), mat: "plastic.matte:2A2A2C")
                box(V3(0.112, 0.112, 0.0035), c + V3(0, 0, 0.0245), mat: "glass.gauge-lens")
                
            }
            // Selector switch with a knob, and lamps.
            cyl(0.026, 0.01, V3(cx - 0.2, 1.8, panelZ + 0.014), mat: "plastic.matte:2A2A2C")
            box(V3(0.008, 0.034, 0.012), V3(cx - 0.2, 1.8, panelZ + 0.022), r: 0.002, mat: dark)
            cyl(0.005, 0.0015, V3(cx - 0.2, 1.8, panelZ + 0.0225), mat: "metal.brass")
            for (k, lm) in ["emissive.signal-red", "emissive.signal-green", "emissive.signal-orange"].enumerated() {
                let lx = cx - 0.02 + Float(k) * 0.075
                cyl(0.018, 0.004, V3(lx, 1.8, panelZ + 0.011), mat: "metal.powdercoat:6A6D70")
                cyl(0.0135, 0.012, V3(lx, 1.8, panelZ + 0.014), mat: i == 3 && k == 2 ? "emissive.signal-orange" : (k == 2 ? "glass.led-lens" : lm))
            }
            box(V3(0.24, 0.026, 0.0008), V3(cx + 0.02, 1.7, panelZ + 0.0106), mat: "plastic.matte:E8E8E4")
            box(V3(0.18, 0.005, 0.0009), V3(cx + 0.02, 1.704, panelZ + 0.0111), mat: "plastic.matte:1A1A1A")
            box(V3(0.12, 0.004, 0.0009), V3(cx + 0.02, 1.692, panelZ + 0.0111), mat: "plastic.matte:1A1A1A")
            warning(V3(cx + 0.26, 1.68, panelZ + 0.0106))
            // Door-side bolts on the instrument panel.
            for sx: Float in [-1, 1] { for y in [H - 0.1] { cyl(0.005, 0.003, V3(cx + sx * (pw / 2 - 0.02), y, panelZ + 0.0106), mat: steel) } }
            // Bay number plate on the roof edge.
            box(V3(0.05, 0.05, 0.0012), V3(cx, H - 0.04, zf + 0.0006), mat: "plastic.matte:1A1A1A")
            box(V3(0.016, 0.03, 0.0014), V3(cx, H - 0.04, zf + 0.0013), mat: "plastic.matte:E8E8E4")

            // Breaker (rack-out parts for bays 2 and 3, fixed behind the window elsewhere).
            let rack: String? = (i == 1 || i == 2) ? "breaker-rackout-\(i + 1)" : nil
            if let rack { rig.part(rack, pivot: V3(cx, (yBrk0 + yBrk1) / 2, zf - 0.1), joint: .slide(axis: V3(0, 0, 1), 0...travel, duration: 1.4)) }
            let bz = zf - 0.42
            box(V3(pw - 0.06, yBrk1 - yBrk0 - 0.06, 0.012), V3(cx, (yBrk0 + yBrk1) / 2, -zf + 0.1), mat: "plastic.matte:0B0B0C")   // cell back
            box(V3(0.54, 0.62, 0.5), V3(cx, (yBrk0 + yBrk1) / 2, bz - 0.05), r: 0.01, mat: "metal.powdercoat:3E4144", to: rack)
            box(V3(0.5, 0.58, 0.012), V3(cx, (yBrk0 + yBrk1) / 2, bz + 0.206), r: 0.004, mat: "metal.powdercoat:565A5D", to: rack)
            box(V3(0.4, 0.09, 0.012), V3(cx, (yBrk0 + yBrk1) / 2 + 0.17, bz + 0.214), mat: "plastic.matte:2A2C2F", to: rack)
            cyl(0.02, 0.014, V3(cx - 0.12, (yBrk0 + yBrk1) / 2 + 0.17, bz + 0.222), mat: "emissive.signal-green", to: rack)
            cyl(0.02, 0.014, V3(cx + 0.12, (yBrk0 + yBrk1) / 2 + 0.17, bz + 0.222), mat: i == 1 ? "emissive.signal-red" : "plastic.matte:3A1210", to: rack)
            box(V3(0.12, 0.05, 0.02), V3(cx, (yBrk0 + yBrk1) / 2 - 0.02, bz + 0.222), r: 0.004, mat: "plastic.orange", to: rack)
            box(V3(0.04, 0.2, 0.016), V3(cx, (yBrk0 + yBrk1) / 2 - 0.15, bz + 0.222), r: 0.004, mat: dark, to: rack)
            for sx: Float in [-1, 1] {
                box(V3(0.06, 0.16, 0.2), V3(cx + sx * 0.2, (yBrk0 + yBrk1) / 2 + 0.12, bz - 0.18), r: 0.004, mat: "plastic.matte:2E3033", to: rack)
                cyl(0.02, 0.06, V3(cx + sx * 0.2, (yBrk0 + yBrk1) / 2 - 0.2, bz - 0.12), mat: "metal.copper", to: rack)
                box(V3(0.018, 0.018, 0.5), V3(cx + sx * 0.25, (yBrk0 + yBrk1) / 2 - 0.27, bz - 0.05), mat: steel, to: rack)  // rails
            }
            box(V3(0.5, 0.012, 0.012), V3(cx, (yBrk0 + yBrk1) / 2 + 0.34, bz + 0.21), mat: "metal.powdercoat:3A3D40", to: rack)

            // Hinged breaker door with viewing window.
            let name = "door-\(i + 1)"
            let hx = cx - pw / 2
            let dw = pw, dh = yBrk1 - yBrk0 - 0.004, dz = zf + 0.003
            rig.part(name, pivot: V3(hx, yBrk0 + 0.002, dz), joint: .hinge(axis: .up, 0...openAngle, duration: 1.1))
            func slab(_ sx: Float, _ sy: Float, _ x: Float, _ y: Float) {
                box(V3(sx, sy, 0.022), V3(hx + x, yBrk0 + 0.002 + y, dz - 0.011), r: 0, mat: paint, to: name)
            }
            let ww: Float = 0.44, wh: Float = 0.5, wy: Float = 0.5
            let side = (dw - ww) / 2
            slab(dw, wy - wh / 2, dw / 2, (wy - wh / 2) / 2)
            slab(dw, dh - (wy + wh / 2), dw / 2, wy + wh / 2 + (dh - wy - wh / 2) / 2)
            slab(side, wh, side / 2, wy); slab(side, wh, dw - side / 2, wy)
            box(V3(ww, wh, 0.004), V3(hx + dw / 2, yBrk0 + 0.002 + wy, dz - 0.012), mat: "glass.clear", to: name)
            for s: Float in [-1, 1] {
                box(V3(ww + 0.024, 0.014, 0.008), V3(hx + dw / 2, yBrk0 + 0.002 + wy + s * wh / 2, dz + 0.002), r: 0.002, mat: dark, to: name)
                box(V3(0.014, wh, 0.008), V3(hx + dw / 2 + s * ww / 2, yBrk0 + 0.002 + wy, dz + 0.002), r: 0.002, mat: dark, to: name)
            }
            // Hinges, T-handle, padlock hasp, warning label, scuffs.
            for hy in [Float(0.12), dh / 2, dh - 0.12] {
                add(Prim.cylinder(radius: 0.008, height: 0.07, bevel: 0, segments: 8, material: steel), Xform(translation: V3(hx - 0.002, yBrk0 + hy - 0.035, dz + 0.004)), to: name)
            }
            let hdx = hx + dw - 0.05
            box(V3(0.04, 0.2, 0.012), V3(hdx, yBrk0 + 0.5, dz + 0.006), r: 0.004, mat: "plastic.matte:2A2C2F", to: name)
            box(V3(0.026, 0.14, 0.02), V3(hdx, yBrk0 + 0.5, dz + 0.016), r: 0.006, mat: "metal.steel", to: name)
            cyl(0.012, 0.005, V3(hdx, yBrk0 + 0.62, dz + 0.0125), mat: "metal.brass", to: name)
            box(V3(0.03, 0.05, 0.003), V3(hdx, yBrk0 + 0.2, dz + 0.0015), mat: steel, to: name)
            warning(V3(hx + dw / 2, yBrk0 + 0.1, dz + 0.0008), to: name)
            for k in 0..<2 {   // scuffs at the handle and lower edge
                box(V3(0.0012, 0.02 + rng.float(0...0.03), 0.0006), V3(hdx + rng.float(-0.03...0.03), yBrk0 + 0.4 + rng.float(0...0.2), dz + 0.0009 + Float(k) * 0), mat: "metal.powdercoat:C9CBCA", to: name)
            }
            box(V3(dw - 0.1, 0.0012, 0.0006), V3(hx + dw / 2, yBrk0 + 0.006, dz + 0.0003), mat: "metal.powdercoat:C9CBCA", to: name)
        }

        // Rear access panels: raised seams, a bolt strip and a vent flap per bay; end-wall louvers; roof arc-vent flaps.
        for i in 0..<bays {
            let cx = -W / 2 + (Float(i) + 0.5) * bw
            box(V3(bw - 0.06, 0.012, 0.006), V3(cx, 0.9, -zf - 0.003), mat: trim)
            box(V3(bw - 0.06, 0.012, 0.006), V3(cx, 1.7, -zf - 0.003), mat: trim)
            box(V3(0.012, 1.6, 0.006), V3(cx - bw / 2 + 0.05, 1.3, -zf - 0.003), mat: trim)
            box(V3(0.012, 1.6, 0.006), V3(cx + bw / 2 - 0.05, 1.3, -zf - 0.003), mat: trim)
            box(V3(0.3, 0.3, 0.008), V3(cx, 1.2, -zf - 0.004), mat: "metal.powdercoat:7E8281")
            box(V3(0.22, 0.01, 0.0095), V3(cx, 1.2, -zf - 0.004), mat: dark)
            box(V3(0.4, 0.004, 0.04), V3(cx, H - 0.05, -0.7), mat: dark)
            box(V3(0.4, 0.014, 0.06), V3(cx, H - 0.03, -0.7), mat: trim)
        }
        for s: Float in [-1, 1] {
            for k in 0..<5 { box(V3(0.006, 0.01, 0.4), V3(s * (W / 2 + 0.003), 1.0 + Float(k) * 0.03, 0), mat: "metal.powdercoat:7A7E7D") }
            box(V3(0.005, 0.14, 0.42), V3(s * (W / 2 + 0.0025), 1.07, 0), mat: dark)
            box(V3(0.005, 1.5, 0.014), V3(s * (W / 2 + 0.0025), 1.2, 0.55), mat: trim)
            box(V3(0.005, 1.5, 0.014), V3(s * (W / 2 + 0.0025), 1.2, -0.55), mat: trim)
        }

        // Red mimic bus strip across the lineup with drops and breaker symbols per bay.
        let mz = zf + 0.0008
        let busY: Float = 1.62
        box(V3(W - 0.08, 0.016, 0.0016), V3(0, busY, mz), mat: "plastic.matte:B51D17")
        for i in 0..<bays {
            let cx = -W / 2 + (Float(i) + 0.5) * bw
            box(V3(0.016, 0.06, 0.0016), V3(cx - 0.3, busY + 0.04, mz), mat: "plastic.matte:B51D17")
            box(V3(0.04, 0.04, 0.0016), V3(cx - 0.3, busY + 0.09, mz), mat: "plastic.matte:E8E8E4")
            box(V3(0.026, 0.0035, 0.0018), V3(cx - 0.3, busY + 0.09, mz), mat: "plastic.matte:1A1A1A")
        }

        // Story detail: bay 3 door carries a lock-out tag and a hand-lettered tape label.
        box(V3(0.05, 0.075, 0.002), V3(-W / 2 + 2.5 * bw + 0.3, yBrk0 + 0.7, zf + 0.0042), r: 0.002, mat: "plastic.orange")
        box(V3(0.12, 0.02, 0.0007), V3(-W / 2 + 2.5 * bw - 0.1, yBrk0 + 0.12 + 0.32, zf + 0.0011 + 0.004), mat: "plastic.matte:D8C86A")

        rig.states = [
            RigState("closed", ["door-1": 0, "door-2": 0, "door-3": 0, "door-4": 0, "breaker-rackout-2": 0, "breaker-rackout-3": 0]),
            RigState("open", ["door-1": 0, "door-2": openAngle, "door-3": openAngle, "door-4": 0, "breaker-rackout-2": travel, "breaker-rackout-3": travel * 0.4]),
        ]
        rig.defaultState = "closed"
        groundAO(&rig.base[0])
        return rig
    }
}
