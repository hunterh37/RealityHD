import simd
import Foundation

/// Craftsman sleeping-porch screen panel, 1.2 x 2.2 m x 44 mm: mortised-look painted frame with ovolo sticking on the
/// inner edges, a lock rail at 1.0 m, a raised-and-fielded kick panel below, and woven wire mesh above held behind
/// muntins by screen stops with brad nails. A hook-and-eye latch and bar pull sit on the lock rail, corner angle plates
/// brace the frame. Paint is sun-faded olive, chipped at the foot where bare wood shows, mud splash stains the lower
/// rail and the mesh carries a patched tear. Wall plane faces +Z, z = 0 is the mid thickness.
public struct SleepingPorchScreenPanel: RealAsset {
    public static let id = "sleeping-porch-screen-panel"
    public static let summary = "Craftsman sleeping-porch screen panel, 1.2 x 2.2 m: olive painted frame, raised kick panel, wire mesh with muntins and patch, hook latch."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 3.1)

    /// Paint (worn).
    public var paintKey = "wood.painted-shaker-worn"
    /// Faded olive paint (sRGB hex).
    public var olive: UInt32 = 0x434C37
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    /// Member section in (across, out): rectangle of width w and thickness t with an ovolo bead on the chosen inner edges
    /// (+1 right, -1 left) and a plain back. Returned counter-clockwise in (across, out).
    func section(w: Float, t: Float, beadLeft: Bool, beadRight: Bool, segs: Int) -> [V2] {
        let hw = w / 2, ht = t / 2
        let br: Float = 0.011
        var pts: [V2] = [V2(-hw, -ht)]
        pts.append(V2(hw, -ht))
        if beadRight {
            pts.append(V2(hw, ht - br))
            for i in 1...segs { let a = Float(i) / Float(segs) * .pi / 2; pts.append(V2(hw - br + br * cos(a), ht - br + br * sin(a))) }
            pts.append(V2(hw - br - 0.0025, ht)); pts.append(V2(hw - br - 0.0025, ht - 0.0012)); pts.append(V2(hw - br - 0.006, ht - 0.0012))
        } else {
            pts.append(V2(hw, ht))
        }
        if beadLeft {
            pts.append(V2(-hw + br + 0.006, ht - 0.0012)); pts.append(V2(-hw + br + 0.0025, ht - 0.0012)); pts.append(V2(-hw + br + 0.0025, ht))
            for i in 0..<segs { let a = Float(i) / Float(segs) * .pi / 2; pts.append(V2(-hw + br - br * sin(a), ht - br + br * cos(a))) }
            pts.append(V2(-hw, ht - br))
        } else {
            pts.append(V2(-hw, ht))
        }
        return pts
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let br = Int((olive >> 16) & 0xFF), bg = Int((olive >> 8) & 0xFF), bb = Int(olive & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(br + d, bg + d, bb + d) }
        let W: Float = 1.2, H: Float = 2.2, T: Float = 0.044
        let sw: Float = 0.092            // stile width
        let topH: Float = 0.118, botH: Float = 0.165, lockH: Float = 0.088
        let lockY: Float = 1.02          // lock rail centre
        let segs = lite ? 2 : 4
        let bevel: Float = 0.0012
        let inW = W - 2 * sw

        // Stiles run full height with ovolo on the inner edge. Section (across, out); extrude rotated 90 about X.
        for sx: Float in [-1, 1] {
            let pts = section(w: sw, t: T, beadLeft: sx > 0, beadRight: sx < 0, segs: segs)
            m.add(Prim.extrude(pts, depth: H, bevel: bevel, bevelSegments: 1, material: tone(rng.int(-8...6))),
                  Xform(translation: V3(sx * (W / 2 - sw / 2), H / 2, 0), rotation: FA.q(90, FA.X)))
        }
        // Rails between the stiles: section (out, up) along X. Reverse the swapped section to keep winding.
        func rail(_ h: Float, _ y: Float, bead: (Bool, Bool), _ mat: MaterialKey) {
            let s = section(w: h, t: T - 0.002, beadLeft: bead.0, beadRight: bead.1, segs: segs)
            let pts = s.map { V2($0.y, $0.x) }.reversed()
            m.add(Prim.extrude(Array(pts), depth: inW + 0.012, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, y, 0), rotation: FA.q(-90, FA.Y)))
        }
        rail(topH, H - topH / 2, bead: (false, true), tone(rng.int(-8...6)))
        rail(lockH, lockY, bead: (true, true), tone(rng.int(-8...6)))
        rail(botH, botH / 2, bead: (false, true), tone(rng.int(-8...6)))

        // Raised panel in the kick opening: field with bevelled shoulders, floating in grooves.
        let kickLo = botH - 0.004, kickHi = lockY - lockH / 2 + 0.004
        let kh = kickHi - kickLo, kw = inW + 0.008
        let panelMat = tone(rng.int(-6...4))
        FA.box(&m, V3(kw, kh, 0.012), V3(0, (kickLo + kickHi) / 2, -0.004), panelMat, r: 0.0012)
        let fieldOutline = Shape2D.rounded([V2(-(kw / 2 - 0.036), -(kh / 2 - 0.036)), V2(kw / 2 - 0.036, -(kh / 2 - 0.036)),
                                            V2(kw / 2 - 0.036, kh / 2 - 0.036), V2(-(kw / 2 - 0.036), kh / 2 - 0.036)], radius: 0.002)
        m.add(Prim.extrude(fieldOutline, depth: 0.014, bevel: 0.008, bevelSegments: 3, material: panelMat),
              Xform(translation: V3(0, (kickLo + kickHi) / 2, 0.008)))
        // Shadow gap where the field steps up from the panel.
        for sy: Float in [-1, 1] { FA.box(&m, V3(kw - 0.054, 0.0035, 0.002), V3(0, (kickLo + kickHi) / 2 + sy * (kh / 2 - 0.0305), 0.003), "wood.charred", r: 0.0006) }
        for sx: Float in [-1, 1] { FA.box(&m, V3(0.0035, kh - 0.054, 0.002), V3(sx * (kw / 2 - 0.0305), (kickLo + kickHi) / 2, 0.003), "wood.charred", r: 0.0006) }

        // Upper opening: mesh on the back, muntins and screen stops.
        let opLo = lockY + lockH / 2 - 0.004, opHi = H - topH + 0.004
        let oh = opHi - opLo
        let meshZ: Float = -0.0155
        // Hardware-cloth mesh: real wires so it reads at distance. Horizontal wires behind, vertical wires in front.
        let pitch: Float = lite ? 0.03 : 0.020
        let nh = Int((oh + 0.004) / pitch), nv = Int((inW + 0.004) / pitch)
        for i in 0...nh {
            let y = opLo - 0.002 + Float(i) * pitch
            m.add(cuboid(V3(inW + 0.006, 0.0016, 0.0013), material: "metal.galvanized-aged"), Xform(translation: V3(0, y, meshZ)))
        }
        for i in 0...nv {
            let x = -inW / 2 - 0.002 + Float(i) * pitch
            m.add(cuboid(V3(0.0016, oh + 0.006, 0.0013), material: "metal.galvanized-aged"), Xform(translation: V3(x, (opLo + opHi) / 2, meshZ + 0.0012)))
        }
        // Muntins: one vertical, one horizontal, chamfered, set proud of the mesh.
        let mAcross: Float = 0.032
        FA.box(&m, V3(mAcross, oh + 0.004, 0.028), V3(0, (opLo + opHi) / 2, -0.004), tone(rng.int(-4...6)), r: 0.0025)
        let hy = opLo + oh * 0.58
        FA.box(&m, V3(inW + 0.004, mAcross, 0.028), V3(0, hy, -0.004), tone(rng.int(-4...6)), r: 0.0025)
        FA.box(&m, V3(mAcross - 0.012, oh + 0.004, 0.006), V3(0, (opLo + opHi) / 2, 0.012), tone(rng.int(-4...6)), r: 0.0012)
        // Screen stops on the back around the opening and on both sides of the muntins.
        let stopMat = tone(-14)
        FA.box(&m, V3(inW, 0.016, 0.012), V3(0, opLo + 0.008, -0.016), stopMat, r: 0.0015)
        FA.box(&m, V3(inW, 0.016, 0.012), V3(0, opHi - 0.008, -0.016), stopMat, r: 0.0015)
        for sx: Float in [-1, 1] { FA.box(&m, V3(0.016, oh - 0.032, 0.012), V3(sx * (inW / 2 - 0.008), (opLo + opHi) / 2, -0.016), stopMat, r: 0.0015) }

        // Craftsman bar pull and hook-and-eye latch on the lock rail, forged hardware in aged iron.
        let hw = "metal.wrought-iron"
        let hy2 = lockY
        // Flat forged lift plate with a curled grip, low profile.
        FA.box(&m, V3(0.16, 0.034, 0.004), V3(0.30, hy2, T / 2 + 0.0015), hw, r: 0.0015)
        FA.box(&m, V3(0.09, 0.012, 0.006), V3(0.30, hy2, T / 2 + 0.0035), hw, r: 0.003)
        for sx: Float in [-0.065, 0.065] {
            m.add(Prim.cylinder(radius: 0.0045, height: 0.0016, bevel: 0.0005, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                  Xform(translation: V3(0.30 + sx, hy2, T / 2 + 0.0035), rotation: FA.q(90, FA.X)))
        }
        FA.cylZ(&m, r: 0.018, h: 0.003, at: V3(-0.38, hy2, T / 2 - 0.001), hw, bevel: 0.001, segments: lite ? 8 : 14)
        FA.rod(&m, V3(-0.38, hy2, T / 2 + 0.002), V3(-0.38, hy2, T / 2 + 0.005), r: 0.0025, hw, sides: 6)
        FA.path(&m, [V3(-0.38, hy2, T / 2 + 0.005), V3(-0.368, hy2 - 0.004, T / 2 + 0.006), V3(-0.356, hy2 - 0.012, T / 2 + 0.006)], r: 0.0018, hw, sides: 6)

        if !lite {
            // Corner angle plates on the front, each with four screws.
            for (cx, cy) in [(-1 as Float, 1 as Float), (1, 1), (-1, -1), (1, -1)] {
                let px = cx * (W / 2 - 0.058), py = cy > 0 ? H - 0.074 : 0.100
                FA.box(&m, V3(0.12, 0.016, 0.0025), V3(px - cx * 0.014, py + cy * 0.0, T / 2 - 0.0005), hw, r: 0.0006)
                FA.box(&m, V3(0.016, 0.12, 0.0025), V3(px + cx * 0.026 - cx * 0.040, py - cy * 0.040 + cy * 0.0, T / 2 - 0.0005), hw, r: 0.0006)
                for (dx, dy) in [(-0.034 as Float, 0 as Float), (0.020, 0)] {
                    m.add(Prim.cylinder(radius: 0.0034, height: 0.0016, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                          Xform(translation: V3(px - cx * 0.014 + cx * dx, py, T / 2 + 0.0017), rotation: FA.q(90, FA.X)))
                }
            }
            // Brad nails along the front face of the stiles into rails and filled holes.
            for sx: Float in [-1, 1] {
                for y in [topH * 0.5, lockY, botH * 0.5, H - topH * 0.5] where rng.chance(0.9) {
                    m.add(Prim.cylinder(radius: 0.0016, height: 0.0007, bevel: 0.0002, segments: 6, bevelSegments: 1, material: "wood.charred"),
                          Xform(translation: V3(sx * (W / 2 - sw / 2) + rng.float(-0.006...0.006), y == lockY ? lockY + 0.03 : H - y - 0.0 + (y - (H - y)) * 0, T / 2 + 0.0002), rotation: FA.q(90, FA.X)))
                }
            }
            // Wire mesh patch (galvanized, stapled) over a tear, with a fray.
            let px: Float = 0.24, py: Float = opLo + oh * 0.22
            for i in 0...13 {
                m.add(cuboid(V3(0.14, 0.0016, 0.0013), material: "metal.steel"),
                      Xform(translation: V3(px, py - 0.06 + Float(i) * 0.0092, meshZ + 0.0026), rotation: FA.q(6, FA.Z)))
            }
            for i in 0...15 {
                m.add(cuboid(V3(0.0016, 0.12, 0.0013), material: "metal.steel"),
                      Xform(translation: V3(px - 0.07 + Float(i) * 0.0092, py, meshZ + 0.0039), rotation: FA.q(6, FA.Z)))
            }
            for sx: Float in [-0.06, 0.06] { for sy: Float in [-0.05, 0.05] {
                m.add(cuboid(V3(0.012, 0.0008, 0.0016), material: "metal.screw-zinc"), Xform(translation: V3(px + sx, py + sy, meshZ + 0.0026)))
            }}
            // Mud splash up the lower rail and stiles, paint chips to bare wood at the foot, raw end grain on stile feet.
            for _ in 0..<26 {
                let x = rng.float(-0.55...0.55), h = rng.float(0.01...0.07)
                m.add(cuboid(V3(rng.float(0.01...0.06), h, 0.0004), material: "\(paintKey):4A4636"),
                      Xform(translation: V3(x, h / 2 + rng.float(0.0...0.12), T / 2 - 0.0002)))
            }
            for _ in 0..<14 {
                let x = rng.float(-0.58...0.58)
                m.add(cuboid(V3(rng.float(0.004...0.016), rng.float(0.003...0.012), 0.0005), material: "wood.weathered:7D7260"),
                      Xform(translation: V3(x, 0.008 + rng.float(0.0...0.09), T / 2 - 0.0001)))
            }
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(sw - 0.006, 0.0008, T - 0.006), material: "wood.endgrain-weathered"),
                      Xform(translation: V3(sx * (W / 2 - sw / 2), 0.0004, 0)))
            }
            // Splash gradient on the kick field, chalking on the sun side and rain streaks over the field.
            let fz: Float = 0.0152
            let kc = (kickLo + kickHi) / 2
            for _ in 0..<10 {
                let fy = kickLo + 0.03 + rng.float(0...0.12) * rng.float(0.2...1)
                m.add(cuboid(V3(rng.float(0.03...0.09), rng.float(0.006...0.016), 0.0003), material: "\(paintKey):3A3828"),
                      Xform(translation: V3(rng.float(-0.45...0.45), fy, fz)))
            }
            for _ in 0..<8 {
                let sh = rng.float(0.15...0.5)
                m.add(cuboid(V3(rng.float(0.004...0.012), sh, 0.0003), material: "\(paintKey):2E3426"),
                      Xform(translation: V3(rng.float(-0.45...0.45), kc + kh / 2 - 0.05 - sh / 2 + 0.03, fz)))
            }
            // Chalked paint and chips on stile faces, worst near the top and foot.
            for sx: Float in [-1, 1] {
                for _ in 0..<9 {
                    m.add(cuboid(V3(rng.float(0.004...0.012), rng.float(0.02...0.12), 0.0003), material: rng.chance(0.5) ? "\(paintKey):6E7A5C" : "\(paintKey):2F3827"),
                          Xform(translation: V3(sx * (W / 2 - sw / 2) + rng.float(-0.03...0.03), rng.float(0.2...2.1), T / 2 - 0.0001)))
                }
            }
            // Sun-faded top rail and a drip streak under the lock rail.
            m.add(cuboid(V3(inW - 0.02, 0.0006, 0.0004), material: "\(paintKey):8D9578"), Xform(translation: V3(0, H - 0.002, T / 2 - 0.0002)))
            for _ in 0..<5 {
                m.add(cuboid(V3(rng.float(0.003...0.006), rng.float(0.05...0.18), 0.0004), material: "\(paintKey):45513A"),
                      Xform(translation: V3(rng.float(-0.45...0.45), lockY - lockH / 2 - rng.float(0.03...0.10), T / 2 - 0.0001 - 0.0)))
            }
        }
        _ = rng
        groundAO(&m, height: 0.08, floor: 0.85)
        return FC.place(m)
    }
}
