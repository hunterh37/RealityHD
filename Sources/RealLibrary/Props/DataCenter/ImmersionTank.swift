import simd
import Foundation

/// Two-phase immersion tank: brushed stainless bath on a frame, hinged glass lid, dielectric fluid with servers submerged and a vapour-zone condenser coil.
public struct ImmersionTank: RealArticulated {
    public static let id = "immersion-tank"
    public static let summary = "Two-phase immersion tank: stainless bath, hinged glass lid, dielectric fluid with submerged servers, condenser coil, gauges."
    public static let tags = ["prop", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 4.4, studio: true)

    /// Overall size in meters (x width, y height with lid closed, z depth). Front faces +Z.
    public var size = V3(2.4, 1.2, 1.1)
    /// Tank shell material key.
    public var shell: MaterialKey = "metal.stainless"
    /// Lid opening angle for the open state, degrees.
    public var openAngle: Float = 100
    /// Number of submerged server blades.
    public var servers = 14
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let W = size.x - 0.02, D = size.z - 0.04
        let hx = W / 2, hz = D / 2
        let steel = shell
        let nickel: MaterialKey = "metal.nickel"
        let alu: MaterialKey = "metal.aluminum-brushed"
        let black: MaterialKey = "plastic.matte:1A1A1A"
        let legH: Float = 0.16, rim: Float = 1.11, wall: Float = 0.006
        let fluidTop: Float = 0.90
        func b(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.003) {
            rig.base[0].add(r < 0.002 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: p))
        }
        func cyl(_ rad: Float, _ h: Float, _ p: V3, _ mat: MaterialKey, axis: V3 = V3(0, 1, 0), segs: Int = 14) {
            rig.base[0].add(Prim.cylinder(radius: rad, height: h, bevel: min(0.002, rad * 0.25), segments: segs, bevelSegments: 1, material: mat),
                            Xform(translation: p, rotation: facing(axis)))
        }
        // Frame: four legs, side rails, feet.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = V3(sx * (hx - 0.05), 0, sz * (hz - 0.05))
            b(V3(0.07, legH, 0.07), p + V3(0, legH / 2, 0), "metal.powdercoat:2A2D33", r: 0.004)
            cyl(0.04, 0.012, p + V3(0, 0.0, 0), "rubber.seal", segs: 14)
        } }
        b(V3(W - 0.1, 0.05, 0.05), V3(0, legH - 0.025, hz - 0.05), "metal.powdercoat:2A2D33", r: 0.003)
        b(V3(W - 0.1, 0.05, 0.05), V3(0, legH - 0.025, -hz + 0.05), "metal.powdercoat:2A2D33", r: 0.003)
        // Bath: floor, back, side and front walls, with a front viewing window.
        b(V3(W - 0.02, wall, D - 0.04), V3(0, legH + wall / 2, 0), steel, r: 0.003)
        b(V3(W, rim - legH, wall), V3(0, (rim + legH) / 2, -hz + wall / 2), steel, r: 0.003)
        for sx: Float in [-1, 1] { b(V3(wall, rim - legH, D), V3(sx * (hx - wall / 2), (rim + legH) / 2, 0), steel, r: 0.003) }
        let wy0: Float = 0.30, wy1: Float = 0.94, wx: Float = 0.9     // window half-width
        b(V3(W - 2 * wall, wy0 - legH, wall), V3(0, (wy0 + legH) / 2, hz - wall / 2), steel, r: 0.003)
        b(V3(W - 2 * wall, rim - wy1, wall), V3(0, (rim + wy1) / 2, hz - wall / 2), steel, r: 0.003)
        for sx: Float in [-1, 1] { b(V3(hx - wx - wall, wy1 - wy0, wall), V3(sx * ((hx + wx) / 2), (wy0 + wy1) / 2, hz - wall / 2), steel, r: 0.003) }
        b(V3(2 * wx, wy1 - wy0, 0.006), V3(0, (wy0 + wy1) / 2, hz - 0.012), "glass.clear")
        // Window frame: stainless bezel with bolt row.
        for s: Float in [-1, 1] {
            b(V3(2 * wx + 0.05, 0.025, 0.012), V3(0, (wy0 + wy1) / 2 + s * ((wy1 - wy0) / 2 + 0.005), hz + 0.003), steel, r: 0.003)
            b(V3(0.025, wy1 - wy0 + 0.035, 0.012), V3(s * (wx + 0.005), (wy0 + wy1) / 2, hz + 0.003), steel, r: 0.003)
        }
        for k in 0..<10 { for s: Float in [-1, 1] {
            cyl(0.0045, 0.004, V3(-wx + 0.04 + Float(k) * (2 * wx - 0.08) / 9, (wy0 + wy1) / 2 + s * ((wy1 - wy0) / 2 + 0.005), hz + 0.009), nickel, axis: V3(0, 0, 1), segs: 6)
        } }
        // Rolled top rim and outer stiffener band.
        b(V3(W, 0.02, 0.04), V3(0, rim - 0.01, hz - 0.02), steel, r: 0.005)
        b(V3(W, 0.02, 0.04), V3(0, rim - 0.01, -hz + 0.02), steel, r: 0.005)
        for sx: Float in [-1, 1] { b(V3(0.04, 0.02, D - 0.08), V3(sx * (hx - 0.02), rim - 0.01, 0), steel, r: 0.005) }
        for sx: Float in [-1, 1] { for k in 0..<3 {
            b(V3(0.012, 0.04, D - 0.1), V3(sx * (hx + 0.003), 0.35 + Float(k) * 0.3, 0), steel, r: 0.003)
        } }
        // Dielectric fluid, slightly inset from the walls.
        b(V3(W - 2 * wall - 0.004, fluidTop - legH - wall, D - 2 * wall - 0.004), V3(0, (fluidTop + legH + wall) / 2, 0), "fluid.dielectric", r: 0.002)
        // Servers: thin vertical blades standing in the fluid, each with heat-sink block and nickel pull bar.
        let inner = W - 2 * wall - 0.14
        let pitch = inner / Float(servers - 1)
        for i in 0..<servers {
            let x = -inner / 2 + Float(i) * pitch
            let jz = Float(rng.next() % 5) * 0.001
            let y0 = legH + wall + 0.02
            b(V3(0.030, 0.50, 0.78), V3(x, y0 + 0.25, -0.02 + jz), alu, r: 0.0015)
            for s: Float in [-1, 1] {
                b(V3(0.002, 0.44, 0.70), V3(x + s * 0.0155, y0 + 0.25, -0.02 + jz), "plastic.pcb", r: 0.0005)
                b(V3(0.007, 0.14, 0.12), V3(x + s * 0.019, y0 + 0.13, 0.12 + jz), "copper.polished", r: 0.001)
                b(V3(0.007, 0.14, 0.12), V3(x + s * 0.019, y0 + 0.13, -0.18 + jz), "copper.polished", r: 0.001)
            }
            b(V3(0.020, 0.012, 0.16), V3(x, y0 + 0.506, -0.02 + jz), nickel, r: 0.0015)
        }
        // Condenser coil in the vapour zone: copper serpentine with headers through the back wall.
        var coil: [V3] = []
        let cy: Float = 0.985
        let cz: [Float] = [-0.40, -0.20, 0.0, 0.20, 0.40]
        for (k, z) in cz.enumerated() {
            let xa: Float = k % 2 == 0 ? -1.1 : 1.1
            coil.append(V3(xa, cy, z)); coil.append(V3(-xa, cy, z))
        }
        let ctl: [V3] = coil
        var pts: [V3] = []
        for k in 0..<(ctl.count - 1) {
            let a = ctl[k], c = ctl[k + 1]
            if k % 2 == 0 { pts.append(a); pts.append(c) } else {
                // U-bend towards the end of the pass
                let dirx: Float = c.x > 0 ? 1 : -1
                pts.append(contentsOf: catmull([a, V3(a.x + dirx * 0.06, cy, (a.z + c.z) / 2), c], per: 4))
            }
        }
        rig.base[0].add(Prim.tube(pts, radii: Array(repeating: 0.011, count: pts.count), sides: 10, seamTile: 0.03, material: "copper.polished"), Xform())
        for z in [cz.first!, cz.last!] {
            cyl(0.017, 0.012, V3(1.1, cy, z), nickel, axis: V3(1, 0, 0), segs: 12)
            _ = z
        }
        // Coil supply and return stubs through the back wall.
        for (z, band) in [(Float(-0.40), "plastic.matte:2A5CB8"), (Float(0.0), "plastic.matte:B51D17")] {
            let p = V3(-1.1, cy, z)
            cyl(0.02, 0.05, p - V3(0.0, 0.0, 0.0) + V3(-0.0, 0, 0), nickel, axis: V3(-1, 0, 0), segs: 12)
            cyl(0.024, 0.008, p + V3(-0.04, 0, 0), band, axis: V3(-1, 0, 0), segs: 12)
        }
        // Gauges, status light and fill port on the front header.
        let gy: Float = 0.215
        for (i, gx) in [Float(0.5), 0.72].enumerated() {
            cyl(0.045, 0.016, V3(gx, gy, hz), steel, axis: V3(0, 0, 1), segs: 24)
            cyl(0.038, 0.002, V3(gx, gy, hz + 0.016), "plastic.matte:F2F2EE", axis: V3(0, 0, 1), segs: 24)
            cyl(0.04, 0.0016, V3(gx, gy, hz + 0.0178), "glass.gauge-lens", axis: V3(0, 0, 1), segs: 24)
            b(V3(0.0016, 0.03, 0.0008), V3(gx + (i == 0 ? 0.006 : -0.008), gy + 0.008, hz + 0.0176), "plastic.matte:B51D17", r: 0.0005)
        }
        b(V3(0.1, 0.05, 0.012), V3(-0.55, gy, hz + 0.006), black, r: 0.003)
        b(V3(0.082, 0.032, 0.002), V3(-0.55, gy, hz + 0.0125), "emissive.led-green", r: 0.0005)
        cyl(0.03, 0.04, V3(0.95, rim - 0.01, hz - 0.12), steel, segs: 16)
        cyl(0.036, 0.008, V3(0.95, rim + 0.03, hz - 0.12), nickel, segs: 16)
        // Nameplate and hazard decal.
        b(V3(0.18, 0.06, 0.002), V3(-0.95, gy, hz + 0.001), "plastic.matte:E8C21A", r: 0.0005)
        // Lid: glass pane, stainless frame, seal, handles; hinged on the rear top edge.
        let pivot = V3(0, rim + 0.012, -hz + 0.02)
        let name = "tank-lid"
        rig.part(name, pivot: pivot, joint: .hinge(axis: V3(-1, 0, 0), 0...openAngle, duration: 1.4))
        func put(_ s: Surface, _ p: V3, _ rot: simd_quatf = .identity) { rig.add(s, Xform(translation: p, rotation: rot), to: name) }
        let ly = rim + 0.012
        let lw = W - 0.02, ld = D - 0.04, zc = -hz + 0.02 + ld / 2
        put(Prim.roundedBox(V3(lw - 0.12, 0.012, ld - 0.12), radius: 0.003, bevelSegments: 1, material: "glass.clear"), V3(0, ly + 0.004, zc))
        for s: Float in [-1, 1] {
            put(Prim.roundedBox(V3(lw, 0.024, 0.06), radius: 0.004, bevelSegments: 1, material: steel), V3(0, ly + 0.004, zc + s * (ld / 2 - 0.03)))
            put(Prim.roundedBox(V3(0.06, 0.024, ld - 0.12), radius: 0.004, bevelSegments: 1, material: steel), V3(s * (lw / 2 - 0.03), ly + 0.004, zc))
        }
        put(cuboid(V3(lw - 0.1, 0.004, 0.012), material: "rubber.seal"), V3(0, rim + 0.0015, zc + ld / 2 - 0.07))
        // Handles: two bar pulls on the front frame, satin worn aluminium.
        for sx: Float in [-1, 1] {
            let hxp = sx * 0.6, hzp = zc + ld / 2 + 0.005
            put(Prim.cylinder(radius: 0.009, height: 0.28, bevel: 0.003, segments: 10, bevelSegments: 1, material: alu), V3(hxp - 0.14, ly + 0.034, hzp + 0.028), facing(V3(1, 0, 0)))
            for dx: Float in [-0.12, 0.12] {
                put(Prim.cylinder(radius: 0.006, height: 0.034, bevel: 0.001, segments: 8, bevelSegments: 1, material: alu), V3(hxp + dx, ly + 0.01, hzp), facing(V3(0, 0, 1)))
            }
        }
        // Hinge knuckles at the rear.
        for hxp: Float in [-0.9, 0, 0.9] {
            put(Prim.cylinder(radius: 0.014, height: 0.14, bevel: 0.002, segments: 10, bevelSegments: 1, material: nickel), V3(hxp - 0.07, pivot.y, pivot.z), facing(V3(1, 0, 0)))
        }
        rig.states = [RigState("closed", [name: 0]), RigState("open", [name: openAngle])]
        rig.defaultState = "closed"
        groundAO(&rig, height: 0.15, floor: 0.5)
        return rig
    }
}
