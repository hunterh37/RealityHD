import simd
import Foundation

/// Crittall-style steel window, 1.2 m wide, 1.5 m tall, 80 mm deep: a rolled-steel outer frame with fixing lugs, 20 mm
/// T-section glazing bars welded at every crossing (visible weld beads), 4 x 6 lights with putty bevels, and an opening
/// vent over the top-right two columns hung on three butt hinges with a cockspur fastener and a friction stay arm.
/// Wear: rust bloom at the sill corners and weld beads, blistered black paint, bare steel on the handle, a replaced
/// light with new putty, a hairline crack, dirt streaks on the glass.
public struct SteelCrittallWindowPanel: RealAsset {
    public static let id = "steel-crittall-window-panel"
    public static let summary = "Crittall steel window 1.2x1.5 m: slim T-section bars, opening vent, fastener, stay."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 3.0)

    /// Paint on the steel.
    public var paint: MaterialKey = "metal.painted:25292D"
    /// Glass.
    public var glass: MaterialKey = "glass.tinted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.2, H: Float = 1.5
        let fw: Float = 0.03, fd: Float = 0.06                                  // outer frame width, depth
        let bw: Float = 0.02                                                    // glazing bar flange width
        let cols = 4, rows = 6
        let iw = W - 2 * fw, ih = H - 2 * fw
        let pw = (iw - Float(cols - 1) * bw) / Float(cols), ph = (ih - Float(rows - 1) * bw) / Float(rows)
        func cx(_ c: Int) -> Float { -iw / 2 + pw / 2 + Float(c) * (pw + bw) }
        func cy(_ r: Int) -> Float { fw + ph / 2 + Float(r) * (ph + bw) }       // r = 0 at the bottom
        let zb: Float = 0.026                                                   // glazing plane

        // Outer frame: four steel members with a front rebate and fixing lugs.
        for sy: Float in [0, 1] {
            FA.box(&m, V3(W, fw, fd), V3(0, sy * (H - fw) + fw / 2, fd / 2), paint, r: 0.003)
        }
        for sx: Float in [-1, 1] { FA.box(&m, V3(fw, H - 2 * fw + 0.004, fd), V3(sx * (W / 2 - fw / 2), H / 2, fd / 2), paint, r: 0.003) }
        // Inner rebate lip (the steel's Z leg) standing proud of the frame face, mitred at the corners.
        for sy: Float in [-1, 1] { FA.box(&m, V3(iw + 0.004, 0.006, 0.012), V3(0, H / 2 + sy * (ih / 2 + 0.003), zb + 0.014), paint, r: 0.0015) }
        for sx: Float in [-1, 1] { FA.box(&m, V3(0.006, ih, 0.012), V3(sx * (iw / 2 + 0.003), H / 2, zb + 0.014), paint, r: 0.0015) }
        for (x, y) in [(-0.45, 0.0), (0.45, 0.0), (-0.45, H), (0.45, H)] as [(Float, Float)] {
            let yy = y == 0 ? 0.0 : y
            FA.box(&m, V3(0.04, 0.012, 0.004), V3(x, yy + (y == 0 ? 0.006 : -0.006), 0.002), paint, r: 0.001)              // fixing lug on the head and sill
        }
        for (y, sx) in [(0.4, -1.0), (1.05, -1.0), (0.4, 1.0), (1.05, 1.0)] as [(Float, Float)] {
            let sxf = Float(sx)
            FA.box(&m, V3(0.012, 0.04, 0.004), V3(sxf * (W / 2 - 0.006), y, 0.002), paint, r: 0.001)
            FA.cylZ(&m, r: 0.0045, h: 0.0035, at: V3(sxf * (W / 2 - 0.006), y, 0.004), "metal.screw-zinc", bevel: 0.001, segments: 8)
        }

        // Glazing bars: T-section (web + back flange), welded at every crossing.
        for c in 1..<cols {
            let x = -iw / 2 + Float(c) * (pw + bw) - bw / 2
            FA.box(&m, V3(0.005, ih + 0.004, 0.032), V3(x, H / 2, zb + 0.004), paint, r: 0.0012)
            FA.box(&m, V3(bw, ih + 0.004, 0.004), V3(x, H / 2, zb - 0.014), paint, r: 0.0012)
        }
        for r in 1..<rows {
            let y = fw + Float(r) * (ph + bw) - bw / 2
            FA.box(&m, V3(iw + 0.004, 0.005, 0.03), V3(0, y, zb + 0.003), paint, r: 0.0012)
            FA.box(&m, V3(iw + 0.004, bw, 0.004), V3(0, y, zb - 0.016), paint, r: 0.0012)
        }
        // Weld beads at crossings.
        for c in 1..<cols { for r in 1..<rows {
            let x = -iw / 2 + Float(c) * (pw + bw) - bw / 2, y = fw + Float(r) * (ph + bw) - bw / 2
            FC.bead(&m, r: 0.006, at: V3(x, y, zb + 0.0185), paint, sub: 3)
        }}

        // Lights: glass with a putty bevel on the front face.
        let ventC0 = 2, ventR0 = 3
        for c in 0..<cols { for r in 0..<rows {
            let isVent = c >= ventC0 && r >= ventR0
            let x = cx(c), y = cy(r)
            let gz = isVent ? zb + 0.0 : zb
            let gmat = glass
            FJ.slab(&m, V3(pw + 0.002, ph + 0.002, 0.004), V3(x, y, gz + 0.004), gmat)
            // Putty bevel: four sloped fillets.
            let pm: MaterialKey = (c == 1 && r == 1) ? "stone.limestone" : "stone.limestone-sooted"
            FJ.slab(&m, V3(pw, 0.007, 0.006), V3(x, y + ph / 2 - 0.0035, gz + 0.0085), pm, rot: FA.q(0, FA.Z))
            FJ.slab(&m, V3(pw, 0.007, 0.006), V3(x, y - ph / 2 + 0.0035, gz + 0.0085), pm)
            FJ.slab(&m, V3(0.007, ph - 0.01, 0.006), V3(x - pw / 2 + 0.0035, y, gz + 0.0085), pm)
            FJ.slab(&m, V3(0.007, ph - 0.01, 0.006), V3(x + pw / 2 - 0.0035, y, gz + 0.0085), pm)
        }}
        // Glass wear: dirt run on two lights, a hairline crack on another.
        for (c, r) in [(0, 4), (2, 1)] as [(Int, Int)] {
            FJ.slab(&m, V3(0.012, ph * 0.8, 0.0012), V3(cx(c) + 0.05, cy(r), zb + 0.0066), "stone.limestone-sooted")
        }
        FJ.slab(&m, V3(0.16, 0.0014, 0.0012), V3(cx(0), cy(2) + 0.02, zb + 0.0066), "metal.satin-aluminum", rot: FA.q(-28, FA.Z))

        // Opening vent: steel sash proud of the frame over the top-right block, plus hinges, cockspur and stay.
        let vx0 = -iw / 2 + Float(ventC0) * (pw + bw) - 0.012, vx1 = iw / 2 + 0.004
        let vy0 = fw + Float(ventR0) * (ph + bw) - 0.012, vy1 = H - fw + 0.004
        let vz: Float = zb + 0.0245
        let vw = vx1 - vx0, vh = vy1 - vy0, vcx = (vx0 + vx1) / 2, vcy = (vy0 + vy1) / 2
        let sb: Float = 0.022
        for sy: Float in [-1, 1] { FA.box(&m, V3(vw, sb, 0.02), V3(vcx, vcy + sy * (vh / 2 - sb / 2), vz), paint, r: 0.0025) }
        for sx: Float in [-1, 1] { FA.box(&m, V3(sb, vh - 2 * sb + 0.002, 0.02), V3(vcx + sx * (vw / 2 - sb / 2), vcy, vz), paint, r: 0.0025) }
        // Butt hinges: two leaves and a barrel with a pin head, on the right.
        for y in [vy0 + 0.1, (vy0 + vy1) / 2, vy1 - 0.1] as [Float] {
            m.add(Prim.cylinder(radius: 0.0075, height: 0.07, bevel: 0.002, segments: 10, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(vx1 + 0.006, y - 0.035, vz)))
            FA.box(&m, V3(0.024, 0.07, 0.003), V3(vx1 - 0.008, y, vz + 0.0115), "metal.steel", r: 0.0012)
            for dy: Float in [-0.022, 0.022] { FA.cylZ(&m, r: 0.0035, h: 0.002, at: V3(vx1 - 0.012, y + dy, vz + 0.013), "metal.bolt-bright", bevel: 0.0008, segments: 8) }
        }
        // Cockspur fastener: keeper plate on the frame bar, plate and rotating cranked handle on the vent.
        let hy = (vy0 + vy1) / 2
        FA.box(&m, V3(0.028, 0.07, 0.004), V3(vx0 - 0.002, hy, vz + 0.012), "metal.brass-aged", r: 0.0015)
        FA.cylZ(&m, r: 0.007, h: 0.012, at: V3(vx0 + 0.001, hy + 0.01, vz + 0.0125), "metal.brass-aged", bevel: 0.0015, segments: 12)
        FA.box(&m, V3(0.075, 0.012, 0.007), V3(vx0 + 0.036, hy + 0.01, vz + 0.0245), "metal.brass-aged", r: 0.003)
        FC.bead(&m, r: 0.0085, at: V3(vx0 + 0.078, hy + 0.01, vz + 0.0245), "metal.brass-aged", sub: 4)
        FA.box(&m, V3(0.012, 0.03, 0.006), V3(vx0 - 0.012, hy - 0.015, vz + 0.0055), "metal.steel", r: 0.002)             // cockspur hook on the frame
        // Friction stay: flat bar from a pivot on the sill of the vent to a slider on the lower glazing bar.
        let y0 = vy0 + 0.0
        let a = V3(vcx - 0.12, y0 + 0.01, vz + 0.0125), b = V3(vcx + 0.05, y0 - 0.12, zb + 0.036)
        FA.rod(&m, a, b, r: 0.0045, "metal.steel", sides: 6)
        FA.cylZ(&m, r: 0.0065, h: 0.006, at: V3(a.x, a.y, vz + 0.0105), "metal.bolt-bright", bevel: 0.0012, segments: 10)
        FA.cylZ(&m, r: 0.0065, h: 0.006, at: V3(b.x, b.y, zb + 0.036), "metal.bolt-bright", bevel: 0.0012, segments: 10)
        FA.box(&m, V3(0.1, 0.008, 0.005), V3(vcx - 0.01, y0 - 0.13, zb + 0.0335), "metal.steel", r: 0.0015)                  // slider track

        // Paint and rust wear.
        for sx: Float in [-1, 1] {
            FJ.slab(&m, V3(0.06, 0.014, 0.0012), V3(sx * (W / 2 - 0.05), 0.006, fd + 0.0004), "metal.rust")                 // sill corner bloom (front face of rail)
            FJ.slab(&m, V3(0.014, 0.08, 0.0012), V3(sx * (W / 2 - 0.015), 0.06, fd + 0.0004), "metal.rust")
        }
        for _ in 0..<9 {
            FJ.slab(&m, V3(rng.float(0.006...0.02), rng.float(0.006...0.02), 0.0012), V3(rng.float(-0.55...0.55), rng.float(0.002...0.02), fd + 0.0005), rng.chance(0.6) ? "metal.rust" : "metal.steel")
        }
        for c in 1..<cols { for r in 1..<rows where rng.chance(0.7) {
            let x = -iw / 2 + Float(c) * (pw + bw) - bw / 2, y = fw + Float(r) * (ph + bw) - bw / 2
            FC.bead(&m, r: 0.0048, at: V3(x + rng.float(-0.003...0.003), y - 0.004, zb + 0.0205), "metal.rust", sub: 2)
            FJ.slab(&m, V3(0.006, rng.float(0.03...0.09), 0.0012), V3(x, y - 0.03, zb + 0.0195), "metal.rust-grime")
        }}
        for _ in 0..<7 {
            FJ.slab(&m, V3(rng.float(0.004...0.01), rng.float(0.03...0.14), 0.0012), V3(rng.float(-0.55...0.55), rng.float(0.3...1.45), fd + 0.0005), "metal.rust-grime")
        }
        // Blistered paint along the sill bar and head bar: bare steel flecks and rust halos.
        for _ in 0..<14 {
            let y: Float = rng.chance(0.7) ? rng.float(0.006...0.024) : H - rng.float(0.006...0.024)
            FJ.slab(&m, V3(rng.float(0.01...0.04), rng.float(0.004...0.01), 0.0012), V3(rng.float(-0.55...0.55), y, fd + 0.0006), rng.chance(0.5) ? "metal.steel" : "metal.rust")
        }
        for sx: Float in [-1, 1] {
            for _ in 0..<5 {
                FJ.slab(&m, V3(rng.float(0.006...0.014), rng.float(0.02...0.06), 0.0012), V3(sx * (W / 2 - 0.015), rng.float(0.05...1.4), fd + 0.0006), rng.chance(0.5) ? "metal.steel" : "metal.rust")
            }
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
