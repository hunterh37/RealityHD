import simd
import Foundation

/// American vernacular screened porch door, 0.9 x 2.1 m x 36 mm: sun-faded white painted frame with ovolo sticking, a
/// lock rail at 1.0 m, a bead-and-batten kick of eight vertical beaded boards, hardware-cloth mesh above held by screen
/// stops and a cross muntin, three iron butt hinges on the left stile, a thumb-latch plate with D grip, a coil door
/// closer spring and an aluminium kick plate. Paint is cracked and flaking to grey wood, rust runs from the hinges,
/// the mesh bellies out at the lower corner and the kick plate is dented. Hinge edge at -X, wall plane faces +Z.
public struct ScreenedPorchDoor: RealAsset {
    public static let id = "screened-porch-door"
    public static let summary = "American vernacular screened porch door, 0.9 x 2.1 m: white painted frame, beadboard kick, wire mesh, hinges, thumb latch, closer spring."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 3.1)

    /// Paint (worn).
    public var paintKey = "wood.painted-shaker-worn"
    /// Faded white paint (sRGB hex).
    public var white: UInt32 = 0xCBC5AF
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    /// Member section in (across, out) with an ovolo bead on the chosen edges and a plain back.
    func section(w: Float, t: Float, beadLeft: Bool, beadRight: Bool, segs: Int, br: Float = 0.010) -> [V2] {
        let hw = w / 2, ht = t / 2
        var pts: [V2] = [V2(-hw, -ht), V2(hw, -ht)]
        if beadRight {
            pts.append(V2(hw, ht - br))
            for i in 1...segs { let a = Float(i) / Float(segs) * .pi / 2; pts.append(V2(hw - br + br * cos(a), ht - br + br * sin(a))) }
            pts.append(V2(hw - br - 0.0025, ht)); pts.append(V2(hw - br - 0.0025, ht - 0.0012)); pts.append(V2(hw - br - 0.006, ht - 0.0012))
        } else { pts.append(V2(hw, ht)) }
        if beadLeft {
            pts.append(V2(-hw + br + 0.006, ht - 0.0012)); pts.append(V2(-hw + br + 0.0025, ht - 0.0012)); pts.append(V2(-hw + br + 0.0025, ht))
            for i in 0..<segs { let a = Float(i) / Float(segs) * .pi / 2; pts.append(V2(-hw + br - br * sin(a), ht - br + br * cos(a))) }
            pts.append(V2(-hw, ht - br))
        } else { pts.append(V2(-hw, ht)) }
        return pts
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wr = Int((white >> 16) & 0xFF), wg = Int((white >> 8) & 0xFF), wb = Int(white & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(wr + d, wg + d, wb + d - d / 3) }
        let W: Float = 0.9, H: Float = 2.1, T: Float = 0.036
        let sw: Float = 0.095
        let topH: Float = 0.11, botH: Float = 0.20, lockH: Float = 0.095
        let lockY: Float = 0.98
        let segs = lite ? 2 : 4
        let bevel: Float = 0.0012
        let inW = W - 2 * sw
        let hw = "metal.wrought-iron"

        // Stiles: full height, ovolo on the inner edge.
        for sx: Float in [-1, 1] {
            let pts = section(w: sw, t: T, beadLeft: sx > 0, beadRight: sx < 0, segs: segs, br: 0.009)
            m.add(Prim.extrude(pts, depth: H, bevel: bevel, bevelSegments: 1, material: tone(rng.int(-8...4))),
                  Xform(translation: V3(sx * (W / 2 - sw / 2), H / 2, 0), rotation: FA.q(90, FA.X)))
        }
        func rail(_ h: Float, _ y: Float, bead: (Bool, Bool), _ mat: MaterialKey) {
            let s = section(w: h, t: T - 0.002, beadLeft: bead.0, beadRight: bead.1, segs: segs, br: 0.009)
            let pts = s.map { V2($0.y, $0.x) }.reversed()
            m.add(Prim.extrude(Array(pts), depth: inW + 0.012, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, y, 0), rotation: FA.q(-90, FA.Y)))
        }
        rail(topH, H - topH / 2, bead: (false, true), tone(rng.int(-8...4)))
        rail(lockH, lockY, bead: (true, true), tone(rng.int(-8...4)))
        rail(botH, botH / 2, bead: (false, true), tone(rng.int(-8...4)))

        // Beadboard kick: eight tongue-and-groove boards with a bead at each joint, set in a groove.
        let kickLo = botH - 0.004, kickHi = lockY - lockH / 2 + 0.004
        let kh = kickHi - kickLo
        let nb = 8
        let bwid = (inW + 0.008) / Float(nb)
        for i in 0..<nb {
            let pts = section(w: bwid - 0.0006, t: 0.012, beadLeft: true, beadRight: false, segs: segs, br: 0.0035)
            m.add(Prim.extrude(pts, depth: kh, bevel: 0.0006, bevelSegments: 1, material: tone(rng.int(-10...5))),
                  Xform(translation: V3(-inW / 2 - 0.004 + bwid * (Float(i) + 0.5), (kickLo + kickHi) / 2, -0.003), rotation: FA.q(90, FA.X)))
        }

        // Upper opening with hardware-cloth mesh, cross muntin and screen stops.
        let opLo = lockY + lockH / 2 - 0.004, opHi = H - topH + 0.004
        let oh = opHi - opLo
        let meshZ: Float = -0.0115
        let pitch: Float = lite ? 0.03 : 0.020
        let nh = Int((oh + 0.004) / pitch), nv = Int((inW + 0.004) / pitch)
        for i in 0...nh {
            m.add(cuboid(V3(inW + 0.006, 0.0016, 0.0013), material: "metal.galvanized-aged"),
                  Xform(translation: V3(0, opLo - 0.002 + Float(i) * pitch, meshZ)))
        }
        for i in 0...nv {
            m.add(cuboid(V3(0.0016, oh + 0.006, 0.0013), material: "metal.galvanized-aged"),
                  Xform(translation: V3(-inW / 2 - 0.002 + Float(i) * pitch, (opLo + opHi) / 2, meshZ + 0.0012)))
        }
        let hy = opLo + oh * 0.5
        FA.box(&m, V3(inW + 0.004, 0.030, 0.022), V3(0, hy, -0.003), tone(rng.int(-6...4)), r: 0.0025)
        FA.box(&m, V3(inW + 0.004, 0.018, 0.005), V3(0, hy, 0.0095), tone(rng.int(-6...4)), r: 0.001)
        let stopMat = tone(-16)
        FA.box(&m, V3(inW, 0.015, 0.011), V3(0, opLo + 0.0075, -0.0125), stopMat, r: 0.0014)
        FA.box(&m, V3(inW, 0.015, 0.011), V3(0, opHi - 0.0075, -0.0125), stopMat, r: 0.0014)
        for sx: Float in [-1, 1] { FA.box(&m, V3(0.015, oh - 0.030, 0.011), V3(sx * (inW / 2 - 0.0075), (opLo + opHi) / 2, -0.0125), stopMat, r: 0.0014) }

        // Three butt hinges on the left stile: leaf plates, knuckle barrel with pin cap, screws.
        let hx = -W / 2 + 0.0065
        for hyp in [0.24, 1.05, 1.88] as [Float] {
            FA.box(&m, V3(0.055, 0.105, 0.0025), V3(hx + 0.0275, hyp, T / 2 + 0.0005), hw, r: 0.0008)
            m.add(Prim.cylinder(radius: 0.0065, height: 0.105, bevel: 0.001, segments: lite ? 8 : 12, bevelSegments: 1, material: hw),
                  Xform(translation: V3(hx, hyp - 0.0525, T / 2 + 0.0015)))
            m.add(Prim.cylinder(radius: 0.0045, height: 0.004, bevel: 0.001, segments: 8, bevelSegments: 1, material: hw),
                  Xform(translation: V3(hx, hyp + 0.0525, T / 2 + 0.0015)))
        }
        _ = hx
        if !lite {
            for hyp in [0.24, 1.05, 1.88] as [Float] {
                for (dx, dy) in [(0.020 as Float, 0.035 as Float), (0.020, -0.035), (0.042, 0.035), (0.042, -0.035)] {
                    m.add(Prim.cylinder(radius: 0.0036, height: 0.0016, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                          Xform(translation: V3(hx + dx, hyp + dy, T / 2 + 0.0012), rotation: FA.q(90, FA.X)))
                }
                // Rust run below each hinge.
                m.add(cuboid(V3(0.012, rng.float(0.10...0.20), 0.0004), material: "metal.rust"),
                      Xform(translation: V3(hx + 0.03 + rng.float(-0.01...0.01), hyp - 0.06 - 0.07, T / 2 - 0.0001)))
            }
        }

        // Thumb latch: backplate, raised D grip, thumb piece, keeper hook.
        let lx: Float = W / 2 - 0.058
        FA.box(&m, V3(0.038, 0.17, 0.004), V3(lx, lockY - 0.01, T / 2 + 0.0015), hw, r: 0.0015)
        FA.path(&m, [V3(lx, lockY + 0.06, T / 2 + 0.003), V3(lx, lockY + 0.065, T / 2 + 0.005), V3(lx, lockY + 0.01, T / 2 + 0.0065),
                     V3(lx, lockY - 0.045, T / 2 + 0.005), V3(lx, lockY - 0.05, T / 2 + 0.003)], r: 0.005, hw, sides: lite ? 6 : 10)
        FA.box(&m, V3(0.012, 0.03, 0.005), V3(lx, lockY + 0.08, T / 2 + 0.005), "metal.brass-aged", r: 0.002)
        FA.cylZ(&m, r: 0.012, h: 0.003, at: V3(lx, lockY - 0.085, T / 2 + 0.001), hw, bevel: 0.001, segments: lite ? 8 : 12)

        // Closer spring on the face with eye brackets, above the lock rail.
        let sy = H - topH / 2
        FA.box(&m, V3(0.030, 0.024, 0.003), V3(-0.28, sy, T / 2 + 0.0005), hw, r: 0.001)
        FA.box(&m, V3(0.030, 0.024, 0.003), V3(0.22, sy, T / 2 + 0.0005), hw, r: 0.001)
        FA.rod(&m, V3(-0.28, sy, T / 2 + 0.002), V3(-0.28, sy, T / 2 + 0.006), r: 0.002, hw, sides: 6)
        FA.rod(&m, V3(0.22, sy, T / 2 + 0.002), V3(0.22, sy, T / 2 + 0.006), r: 0.002, hw, sides: 6)
        m.add(Prim.helix(radius: 0.0046, pitch: 0.0045, turns: lite ? 10 : 55, wire: 0.0015, perTurn: lite ? 6 : 8, sides: 4, material: "metal.galvanized-aged"),
              Xform(translation: V3(-0.2, sy, T / 2 + 0.0052), rotation: FA.q(-90, FA.Z)))

        // Kick plate: aluminium, screwed through the bottom rail, dented.
        FA.box(&m, V3(inW - 0.02, 0.15, 0.0022), V3(0, 0.095, T / 2 + 0.0005), "metal.aluminum-brushed", r: 0.0008)
        if !lite {
            for k in 0..<6 {
                let x = -inW / 2 + 0.05 + Float(k) * (inW - 0.1) / 5
                for y in [0.035 as Float, 0.155] {
                    m.add(Prim.cylinder(radius: 0.0032, height: 0.0014, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                          Xform(translation: V3(x, y, T / 2 + 0.0017), rotation: FA.q(90, FA.X)))
                }
            }
            // Dents and scuffs on the plate.
            for _ in 0..<7 {
                m.add(cuboid(V3(rng.float(0.01...0.05), rng.float(0.006...0.02), 0.0003), material: "metal.steel"),
                      Xform(translation: V3(rng.float(-0.28...0.28), rng.float(0.04...0.15), T / 2 + 0.0016), rotation: FA.q(rng.float(-40...40), FA.Z)))
            }
            // Mesh belly: bent wires at the lower hinge-side corner and a pulled spline.
            for i in 0..<5 {
                m.add(cuboid(V3(0.0016, 0.07 - Float(i) * 0.008, 0.0013), material: "metal.galvanized-aged"),
                      Xform(translation: V3(inW / 2 - 0.04 - Float(i) * 0.02, opLo + 0.06, meshZ + 0.003 + Float(i) * 0.0003), rotation: FA.q(8, FA.X)))
            }
            // Peeling paint: bare grey patches along the stiles and rails, flakes at the hinge edge.
            for _ in 0..<24 {
                let sx: Float = rng.chance(0.5) ? -1 : 1
                m.add(cuboid(V3(rng.float(0.004...0.014), rng.float(0.01...0.05), 0.0004), material: "wood.weathered:8A8473"),
                      Xform(translation: V3(sx * (W / 2 - sw / 2) + rng.float(-0.035...0.035), 0.22 + rng.float(0...1.7), T / 2 - 0.0001)))
            }
            for _ in 0..<12 {
                m.add(cuboid(V3(rng.float(0.01...0.04), rng.float(0.004...0.012), 0.0004), material: "wood.weathered:8A8473"),
                      Xform(translation: V3(rng.float(-0.34...0.34), rng.chance(0.5) ? H - topH / 2 : lockY + rng.float(-0.03...0.03), T / 2 - 0.0001)))
            }
            // Dirt at hand height by the latch, splash on the kick boards, drip streaks from the lock rail.
            m.add(cuboid(V3(0.10, 0.22, 0.0003), material: "\(paintKey):A39E8A"), Xform(translation: V3(lx - 0.01, lockY - 0.01, T / 2 - 0.0002)))
            for _ in 0..<10 {
                m.add(cuboid(V3(rng.float(0.03...0.07), rng.float(0.006...0.016), 0.0003), material: "\(paintKey):8D8670"),
                      Xform(translation: V3(rng.float(-0.33...0.33), kickLo + rng.float(0.1...0.28), 0.0035)))
            }
            for _ in 0..<6 {
                let sh = rng.float(0.10...0.35)
                m.add(cuboid(V3(rng.float(0.003...0.008), sh, 0.0003), material: "\(paintKey):9C9680"),
                      Xform(translation: V3(rng.float(-0.33...0.33), lockY - lockH / 2 - 0.02 - sh / 2, 0.0035)))
            }
            // Grime gradient on the stiles and bottom rail, rain streaks down the stiles, mildew speckle on the beadboard.
            for sx: Float in [-1, 1] {
                for k in 0..<6 {
                    m.add(cuboid(V3(sw - 0.012, 0.05, 0.0003), material: "\(paintKey):\(hex(wr - 44 + k * 7, wg - 46 + k * 7, wb - 52 + k * 7))"),
                          Xform(translation: V3(sx * (W / 2 - sw / 2), 0.03 + Float(k) * 0.05, T / 2 - 0.0002)))
                }
                for _ in 0..<5 {
                    let sh = rng.float(0.2...0.6)
                    m.add(cuboid(V3(rng.float(0.003...0.007), sh, 0.0003), material: "\(paintKey):A39E8C"),
                          Xform(translation: V3(sx * (W / 2 - sw / 2) + rng.float(-0.03...0.03), 2.0 - sh / 2 - rng.float(0...0.7), T / 2 - 0.0002)))
                }
            }
            for k in 0..<4 {
                m.add(cuboid(V3(inW - 0.02, 0.05, 0.0003), material: "\(paintKey):\(hex(wr - 38 + k * 9, wg - 40 + k * 9, wb - 46 + k * 9))"),
                      Xform(translation: V3(0, kickLo + 0.025 + Float(k) * 0.05, 0.0033)))
            }
            for _ in 0..<26 {
                m.add(cuboid(V3(rng.float(0.002...0.006), rng.float(0.002...0.006), 0.0003), material: "\(paintKey):6F6B55"),
                      Xform(translation: V3(rng.float(-0.33...0.33), kickLo + rng.float(0.02...0.5), 0.0034)))
            }
            // Raw end grain at the stile feet.
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(sw - 0.006, 0.0008, T - 0.006), material: "wood.endgrain-weathered"),
                      Xform(translation: V3(sx * (W / 2 - sw / 2), 0.0004, 0)))
            }
        }
        _ = rng
        groundAO(&m, height: 0.08, floor: 0.85)
        return FC.place(m)
    }
}
