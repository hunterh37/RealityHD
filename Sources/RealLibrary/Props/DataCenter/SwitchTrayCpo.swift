import simd
import Foundation

/// CPO switch tray: brushed aluminium 1U-class tray, lid off, ASIC with optical engines, fiber ribbons shuffled to the front MPO port field.
public struct SwitchTrayCpo: RealArticulated {
    public static let id = "switch-tray-cpo"
    public static let summary = "Co-packaged optics switch tray: brushed aluminium chassis, central ASIC with optical engines, fiber shuffle ribbons to front MPO ports, slide rails."
    public static let tags = ["prop", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.1, studio: true)

    /// Overall size in meters (x width incl. rails, y height, z depth). Front faces +Z.
    public var size = V3(0.44, 0.045, 0.6)
    /// Chassis material key.
    public var chassis: MaterialKey = "metal.aluminum-brushed"
    /// Slide-out travel in meters.
    public var travel: Float = 0.35
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let alu = chassis
        let steel: MaterialKey = "metal.stainless"
        let nickel: MaterialKey = "metal.nickel"
        let black: MaterialKey = "plastic.matte:0B0C0E"
        let H: Float = 0.044
        let bodyW = size.x - 0.012, hx = bodyW / 2
        let zF: Float = 0.30, zR: Float = -0.30
        let name = "tray-slide"
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.0012, tray: Bool = true) {
            let sf: Surface = r < 0.0006 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.45), bevelSegments: 1, material: mat)
            if tray { rig.add(sf, Xform(translation: c), to: name) } else { rig.base[0].add(sf, Xform(translation: c)) }
        }
        rig.part(name, pivot: V3(0, 0, zF), joint: .slide(axis: V3(0, 0, 1), 0...travel, duration: 1.2))
        // Fixed outer rails (rack side).
        for sx: Float in [-1, 1] {
            box(V3(0.006, 0.030, 0.58), V3(sx * (hx + 0.003), 0.022, 0.0), steel, r: 0.0015, tray: false)
            for z: Float in [-0.27, 0.27] { box(V3(0.004, 0.036, 0.016), V3(sx * (hx + 0.0075), 0.022, z), steel, r: 0.001, tray: false) }
        }
        // Chassis tub.
        box(V3(bodyW, 0.002, zF - zR), V3(0, 0.003, (zF + zR) / 2), alu, r: 0.0007)
        for sx: Float in [-1, 1] {
            box(V3(0.0016, H, zF - zR), V3(sx * (hx - 0.0008), H / 2 + 0.002, (zF + zR) / 2), alu, r: 0.0007)
            box(V3(0.0012, 0.026, 0.55), V3(sx * (hx + 0.0006), 0.022, -0.0), "plastic.matte:15161A", r: 0.0004)
        }
        box(V3(bodyW, H, 0.002), V3(0, H / 2 + 0.002, zR - 0.001), alu, r: 0.0007)
        // Main board with ASIC package.
        box(V3(bodyW - 0.01, 0.0016, 0.40), V3(0, 0.0056, -0.07), "plastic.pcb", r: 0.0004)
        box(V3(0.11, 0.003, 0.11), V3(0, 0.0086, -0.02), "plastic.pcb", r: 0.0008)
        box(V3(0.052, 0.003, 0.052), V3(0, 0.0116, -0.02), nickel, r: 0.0015)
        // Eight optical engines around the ASIC, each with a copper cold block.
        var engines: [V3] = []
        for sx: Float in [-1, 1] { for k in 0..<4 {
            engines.append(V3(sx * 0.052, 0.0116, -0.02 - 0.036 + Float(k) * 0.024))
        } }
        for e in engines {
            box(V3(0.016, 0.0045, 0.020), e, "plastic.matte:2A2D33", r: 0.0003)
            box(V3(0.012, 0.002, 0.016), e + V3(0, 0.0034, 0), "copper.polished", r: 0.0006)
            box(V3(0.008, 0.0016, 0.004), e + V3(e.x > 0 ? 0.0 : 0.0, 0.0044, 0.0), "emissive.led-green", r: 0.0001)
        }
        // Heatsink: base plate and fin stack over the ASIC.
        box(V3(0.07, 0.003, 0.07), V3(0, 0.0161, -0.02), "copper.polished", r: 0.0012)
        for i in 0..<14 {
            box(V3(0.0012, 0.020, 0.07), V3(-0.0455 + Float(i) * 0.007, 0.0292, -0.02), alu, r: 0.0003)
        }
        // Laser modules (external light sources) in a row behind the ASIC.
        for i in 0..<4 {
            let x = -0.12 + Float(i) * 0.08
            box(V3(0.06, 0.020, 0.07), V3(x, 0.0166, -0.22), "plastic.matte:1A1C20", r: 0.0003)
            box(V3(0.05, 0.0016, 0.05), V3(x, 0.0272, -0.22), alu, r: 0.0008)
            box(V3(0.006, 0.006, 0.004), V3(x + 0.018, 0.017, -0.254), nickel, r: 0.0008)
        }
        // Rear power and fans.
        for sx: Float in [-1, 1] {
            box(V3(0.06, 0.036, 0.04), V3(sx * 0.15, 0.0222, zR + 0.03), "plastic.matte:15161A", r: 0.002)
        }
        // Front bezel with 2 x 16 MPO ports.
        box(V3(bodyW, H, 0.004), V3(0, H / 2 + 0.002, zF + 0.002), alu, r: 0.0012)
        var ports: [V3] = []
        for r in 0..<2 { for c in 0..<16 {
            ports.append(V3(-0.17 + Float(c) * 0.0124 + (c >= 8 ? 0.006 : 0), 0.0165 + Float(r) * 0.0165, zF + 0.0045))
        } }
        for p in ports {
            box(V3(0.0112, 0.0125, 0.012), p + V3(0, 0, 0.0035), steel, r: 0.0003)
            box(V3(0.0082, 0.0058, 0.001), p + V3(0, 0, 0.0095), black, r: 0)
        }
        // LEDs, console port, pull tab.
        for (k, led) in ["emissive.led-green", "emissive.signal-white", "emissive.signal-orange"].enumerated() {
            box(V3(0.0035, 0.0035, 0.0008), V3(0.095 + Float(k) * 0.011, 0.0165, zF + 0.0044), led, r: 0.0001)
        }
        box(V3(0.014, 0.011, 0.012), V3(0.14, 0.0165, zF + 0.0085), steel, r: 0.0003)
        box(V3(0.040, 0.0016, 0.012), V3(0.0, 0.043, zF + 0.012), "plastic.matte:D8D8D4", r: 0.0004)
        // Front handles: tapered bars, worn bare at the grip.
        for sx: Float in [-1, 1] {
            let hxp = sx * (hx - 0.01)
            rig.add(Prim.cylinder(radius: 0.0035, height: 0.030, bevel: 0.0015, segments: 10, bevelSegments: 1, material: alu),
                    Xform(translation: V3(hxp, H / 2 - 0.013, zF + 0.02)), to: name)
            for dy: Float in [-0.011, 0.011] {
                rig.add(Prim.cylinder(radius: 0.0028, height: 0.018, bevel: 0, segments: 8, bevelSegments: 1, material: alu),
                        Xform(translation: V3(hxp, H / 2 + dy, zF + 0.004), rotation: facing(V3(0, 0, 1))), to: name)
            }
        }
        // Fiber shuffle: eight aqua ribbons from the optical engines to the port field, each a tube pair.
        for (i, e) in engines.enumerated() {
            let sx: Float = e.x > 0 ? 1 : -1
            let tx: Float = -0.15 + Float(i) * 0.04
            let ty: Float = 0.022 + Float(i % 2) * 0.004
            let pts = catmull([V3(e.x + sx * 0.008, 0.0165, e.z), V3(sx * 0.085, 0.020, e.z + 0.02), V3(sx * 0.12 + (tx - sx * 0.12) * 0.3, ty, 0.12), V3(tx, ty, zF - 0.02)], per: 3)
            for lane: Float in [-1, 1] {
                let off = V3(lane * 0.0022, 0, 0)
                rig.add(Prim.tube(pts.map { $0 + off }, radii: Array(repeating: 0.0016, count: pts.count), sides: 4, seamTile: 0.02, material: "glass.fiber", capEnd: true), Xform(), to: name)
            }
        }
        // MPO ribbon connectors and strain-relief boots at the front, one pair per ribbon.
        for i in 0..<8 {
            let tx: Float = -0.15 + Float(i) * 0.04
            let ty: Float = 0.022 + Float(i % 2) * 0.004
            for lane: Float in [-1, 1] {
                box(V3(0.0042, 0.0042, 0.016), V3(tx + lane * 0.0022, ty, zF - 0.028), "plastic.matte:15161A", r: 0.0003)
                box(V3(0.0032, 0.0032, 0.010), V3(tx + lane * 0.0022, ty, zF - 0.043), "glass.fiber", r: 0.0003)
            }
        }
        // Board parts: decoupling capacitor rows, VRM chokes and a connector header.
        for sx: Float in [-1, 1] { for k in 0..<8 {
            box(V3(0.006, 0.006, 0.006), V3(sx * 0.17, 0.0086, -0.15 + Float(k) * 0.02), "metal.aluminum-brushed", r: 0.0003)
            box(V3(0.010, 0.007, 0.010), V3(sx * 0.15, 0.009, -0.15 + Float(k) * 0.02), "plastic.matte:0B0C0E", r: 0.0003)
        } }
        // Bare nickel wear patch on the grip face of each handle.
        for sx: Float in [-1, 1] {
            rig.add(Prim.cylinder(radius: 0.0037, height: 0.014, bevel: 0.001, segments: 10, bevelSegments: 1, material: nickel),
                    Xform(translation: V3(sx * (hx - 0.01), H / 2 - 0.005, zF + 0.02)), to: name)
        }
        // Slide stops and thumbscrew detail.
        for sx: Float in [-1, 1] {
            rig.add(Prim.cylinder(radius: 0.0045, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: nickel),
                    Xform(translation: V3(sx * (hx - 0.022), 0.014, zF + 0.0045), rotation: facing(V3(0, 0, 1))), to: name)
        }
        rig.states = [RigState("closed", [name: 0]), RigState("open", [name: travel])]
        rig.defaultState = "closed"
        groundAO(&rig, height: 0.05, floor: 0.5)
        return rig
    }
}
